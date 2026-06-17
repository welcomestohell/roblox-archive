const RunService = game:GetService "RunService"
const Workspace = game:GetService "Workspace"

const Oklab = require "@libs/vendor/Oklab"
const PlayerModule = require "@libs/vendor/PlayerModule"
const activation = require "@libs/activation"
const character = require "@libs/character"
const constraints = require "@libs/constraints"
const curves = require "@libs/curves"
const functions = require "@libs/functions"
const lerp = require "@libs/lerp"
const logger = require "@core/shared/logger"
const mounts = require "@libs/mounts"
const std = require "@libs/std"
const toggle = require "@libs/toggle"

const Zipline = std.Mechanic {
	emoji = "🚠",
	name = "Zipline",
	description = "When activated, carries the activator across it's curve.",
	instanceType = std.gt.instanceTree {
		Handle = std.gt.union(std.isA.BasePart(), std.isA.Model()),
		Points = std.isA.Instance(),
	},

	Mode = std.Attribute("Mode", std.gt.literals("Zip", "Grind"), "Zip"),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	HandleHidden = std.Attribute("HandleHidden", std.gt.boolean(), false),
	Speed = std.Attribute("Speed", std.gt.positiveNumber, 1),

	std.AttributeSection "Curve",
	CurveType = std.Attribute("CurveType", std.gt.keysOf(curves.CURVES), "CatmullRom"),
	CurveSlack = std.Attribute("CurveSlack", std.gt.constrainNumberExclusive(1), 1.05),

	std.AttributeSection "Segments",
	SegmentType = std.Attribute("SegmentType", std.gt.literals("Part", "Beam"), "Beam"),
	SegmentCount = std.Attribute("SegmentCount", std.gt.positiveNumber, 20),
	SegmentThickness = std.Attribute("SegmentThickness", std.gt.NumberSequence, NumberSequence.new(0.25)),
	SegmentTransparency = std.Attribute("SegmentTransparency", std.gt.NumberSequence, NumberSequence.new(0)),
	SegmentColor = std.Attribute(
		"SegmentColor",
		std.gt.literals("Startpoint", "Endpoint", "BothEndpoints", "AllPoints"),
		"AllPoints"
	),

	std.AttributeSection "User Control",
	UserControlEnabled = std.Attribute("UserControlEnabled", std.gt.boolean(), false),
	UserControlAcceleration = std.Attribute("UserControlAcceleration", std.gt.positiveNumber, 1 / 0.1),

	std.AttributeSection "Activation",
	StartpointActivation = activation.useAttributes "StartpointActivation",
	EndpointActivation = activation.useAttributes "EndpointActivation",
	SegmentActivation = activation.useAttributes "SegmentActivation",

	std.AttributeSection "Dismount",
	DismountOnEndpoints = std.Attribute("DismountOnEndpoints", std.gt.boolean(), true),
	JumpOnDismount = std.Attribute("JumpOnDismount", std.gt.boolean(), true),
	KeepMomentum = std.Attribute("KeepMomentum", std.gt.boolean(), true),
	DismountDelay = std.Attribute("DismountDelay", std.gt.positiveNumber, 0.1),
	Dismount = activation.useAttributes "Dismount",
}

export type ZiplineMechanic = std.Mechanic<typeof(Zipline), {
	curve: curves.Curve,

	segmentsLife: std.Life?,
	segmentsPartContainer: Instance,
	segments: { CFrame },
	segmentLengths: { number },
	segmentInstances: { BasePart | Beam },

	pointsLife: std.Life?,
	pointInstances: { BasePart },
	points: { Vector3 },

	handle: BasePart | Model,
}>

const LOOKAHEAD = 0.0001
const THRESHOLD = -0.1

-- we bind activation ourselves
Zipline.bindActivation = functions.noop

function Zipline.calculateSegmentCount(zipline: ZiplineMechanic): number
	const numPoints = #zipline.points
	return if numPoints <= 2 then 1 elseif zipline:CurveType() == "Linear" then numPoints - 1 else zipline:SegmentCount()
end

function Zipline.calculateCurveType(zipline: ZiplineMechanic)
	return if zipline:calculateSegmentCount() == 1 then "Linear" else zipline:CurveType()
end

function Zipline.calculateSegmentPartColor(zipline: ZiplineMechanic, index: number, count: number): Color3
	const segmentColor = zipline:SegmentColor()
	if segmentColor == "Startpoint" then
		return zipline.pointInstances[1].Color
	elseif segmentColor == "Endpoint" then
		return zipline.pointInstances[#zipline.pointInstances].Color
	elseif segmentColor == "BothEndpoints" then
		return Oklab.lerpColor3s(
			zipline.pointInstances[1].Color,
			zipline.pointInstances[#zipline.pointInstances].Color,
			index / count
		)
	elseif segmentColor == "AllPoints" then
		const alpha = index / count

		const totalGaps = #zipline.points - 1
		const scaledAlpha = alpha * totalGaps

		const pointIndex = math.clamp(math.floor(scaledAlpha) + 1, 1, totalGaps)
		const nextPointIndex = pointIndex + 1

		const localAlpha = scaledAlpha - (pointIndex - 1)

		const startColor = zipline.pointInstances[pointIndex].Color
		const endColor = zipline.pointInstances[nextPointIndex].Color
		return Oklab.lerpColor3s(startColor, endColor, localAlpha)
	else
		return Color3.new()
	end
end

function Zipline.createSegments(zipline: ZiplineMechanic)
	if zipline.segmentsLife and zipline.segmentsLife.alive then zipline.segmentsLife:destroy() end
	const segmentsLife = zipline.life:extend()
	zipline.segmentsLife = segmentsLife
	table.clear(zipline.segments)
	table.clear(zipline.segmentInstances)
	table.clear(zipline.segmentLengths)

	const segmentType = zipline:SegmentType()
	const segmentCount = zipline:calculateSegmentCount()

	const startPoint = zipline.pointInstances[1]
	const startPointPosition = zipline.points[1]
	local previousPosition = zipline.curve:solvePosition(0)

	for index = 1, segmentCount do
		const alpha = index / segmentCount
		const nextPosition = zipline.curve:solvePosition(alpha)

		if previousPosition == nextPosition then
			previousPosition = nextPosition
			continue
		end

		const segmentLength = (nextPosition - previousPosition).Magnitude
		const centerPosition = previousPosition:Lerp(nextPosition, 0.5)
		const segmentCFrame = CFrame.lookAt(centerPosition, nextPosition) * CFrame.Angles(0, math.pi * 0.5, 0)

		local segmentInstance
		if segmentType == "Part" then
			segmentInstance = segmentsLife:add(Instance.new "Part")
			segmentInstance.Name = tostring(index)
			segmentInstance.Anchored = false
			segmentInstance.CanCollide = false
			segmentInstance.CFrame = segmentCFrame
			segmentInstance.Material = Enum.Material.SmoothPlastic
			segmentInstance.Shape = Enum.PartType.Cylinder
			segmentInstance.Size = Vector3.new(segmentLength, 0, 0)

			constraints.weld(segmentsLife, startPoint, segmentInstance)
			segmentInstance.Parent = zipline.segmentsPartContainer

			activation.bindActivation {
				attributes = zipline.SegmentActivation,
				instanceLife = segmentsLife,
				instance = segmentInstance,
				instanceConfiguration = zipline.instanceConfiguration,
				onActivate = zipline.onActivateCallback,
			}
		else
			segmentInstance = segmentsLife:add(Instance.new "Beam")
			segmentInstance.Name = tostring(index)
			segmentInstance.FaceCamera = true
			segmentInstance.LightInfluence = 1
			segmentInstance.Segments = 1
			segmentInstance.Transparency = NumberSequence.new(0)

			segmentInstance.Parent = startPoint

			const attachment0, attachment1 = constraints.populateAttachments(segmentsLife, segmentInstance)
			attachment0.Position = previousPosition - startPointPosition
			attachment1.Position = nextPosition - startPointPosition
			attachment0.Parent = startPoint
			attachment1.Parent = startPoint
		end

		table.insert(zipline.segments, segmentCFrame)
		table.insert(zipline.segmentLengths, segmentLength)
		table.insert(zipline.segmentInstances :: { BasePart | Beam }, segmentInstance)

		previousPosition = nextPosition
	end

	zipline:updateSegments()
	return zipline.segments
end

function Zipline.updateSegments(zipline: ZiplineMechanic)
	const segmentCount = zipline:calculateSegmentCount()
	const thickness = zipline:SegmentThickness()
	const transparency = zipline:SegmentTransparency()

	if zipline:SegmentType() == "Part" then
		for _, part in zipline.segmentInstances :: { BasePart } do
			const index = tonumber(part.Name) :: number
			const alpha = index / segmentCount

			part.Color = zipline:calculateSegmentPartColor(index, segmentCount)
			part.Transparency = lerp.evaluateNumberSequence(transparency, alpha)

			const partThickness = lerp.evaluateNumberSequence(thickness, alpha)
			part.Size = Vector3.new(part.Size.X, partThickness, partThickness)
		end
	else
		for _, beam in zipline.segmentInstances :: { Beam } do
			const index = tonumber(beam.Name) :: number
			const alpha = index / segmentCount
			const nextAlpha = index / segmentCount
			beam.Color = ColorSequence.new(
				zipline:calculateSegmentPartColor(index - 1, segmentCount),
				zipline:calculateSegmentPartColor(index, segmentCount)
			)
			beam.Transparency = NumberSequence.new(
				lerp.evaluateNumberSequence(transparency, alpha),
				lerp.evaluateNumberSequence(transparency, nextAlpha)
			)
			beam.Width0 = lerp.evaluateNumberSequence(thickness, alpha)
			beam.Width1 = lerp.evaluateNumberSequence(thickness, nextAlpha)
		end
	end
end

function Zipline.createCurve(zipline: ZiplineMechanic)
	zipline.curve = curves.CURVES[zipline:calculateCurveType()].new {
		points = zipline.points,
		slack = zipline:CurveSlack(),
	}

	zipline:createSegments()
end

-- FIXME: there are bugs when removing points at runtime
function Zipline.solvePoints(zipline: ZiplineMechanic): { Vector3 }
	if zipline.pointsLife and zipline.pointsLife.alive then zipline.pointsLife:destroy() end

	const pointsLife = zipline.life:extend()
	zipline.pointsLife = pointsLife
	pointsLife:add(function()
		zipline:solvePoints()
	end)

	table.clear(zipline.points)
	table.clear(zipline.pointInstances)

	const container = zipline.instance.Points
	for index = 1, #container:GetChildren() do
		const point = container:FindFirstChild(tostring(index))
		if not point then continue end

		const part = if point:IsA "BasePart" then point elseif point:IsA "Model" then point.PrimaryPart else nil
		if part then
			table.insert(zipline.points, part.Position)
			table.insert(zipline.pointInstances, part)
			toggle.SetCollision(part, false)
			-- FIXME: Name property doesn't fire??
			pointsLife:destroyOn(point:GetPropertyChangedSignal "Name")
			pointsLife:destroyOn(part:GetPropertyChangedSignal "Position")
			pointsLife:add(part:GetPropertyChangedSignal("Color"):Connect(zipline.updateSegmentsCallback))
			pointsLife:add(part:GetPropertyChangedSignal("Transparency"):Connect(zipline.updateSegmentsCallback))
		end
	end

	zipline:createCurve()

	const pointCount = #zipline.pointInstances
	for index, point in zipline.pointInstances do
		toggle.toggleInstance(index % pointCount <= 1, point)

		if index == 1 then
			activation.bindActivation {
				attributes = zipline.StartpointActivation,
				instanceLife = pointsLife,
				instance = zipline.pointInstances[1],
				instanceConfiguration = zipline.instanceConfiguration,
				onActivate = zipline.onActivateCallback,
			}
		end

		if index == #zipline.pointInstances then
			activation.bindActivation {
				attributes = zipline.EndpointActivation,
				instanceLife = pointsLife,
				instance = zipline.pointInstances[#zipline.pointInstances],
				instanceConfiguration = zipline.instanceConfiguration,
				onActivate = zipline.onActivateCallback,
			}
		end
	end

	return zipline.points
end

-- TODO: Move/refactor curve generation to the curves library, there are
-- further usecases such as camera splines and tightrope ProceduralModels
function Zipline.onStart(self: typeof(Zipline), zipline: ZiplineMechanic, level: std.Level)
	function zipline.onActivateCallback(_, event: activation.ActivationEvent)
		self:onActivate(zipline, level, event)
	end

	function zipline.solvePointsCallback()
		zipline:solvePoints()
	end

	function zipline.createCurveCallback()
		zipline:createCurve()
	end

	function zipline.updateSegmentsCallback()
		zipline:updateSegments()
	end

	zipline.segmentsPartContainer = Instance.new "Folder"
	zipline.segmentsPartContainer.Name = "SegmentParts"
	zipline.segmentsPartContainer.Parent = zipline.instance

	zipline.handle = zipline.instance.Handle
	zipline.handle.Parent = nil

	zipline.segments = {}
	zipline.segmentInstances = {}
	zipline.segmentLengths = {}
	zipline.points = {}
	zipline.pointInstances = {}
	zipline:solvePoints()

	zipline.life:addMany(
		zipline.instance.Points.ChildAdded:Connect(zipline.solvePointsCallback),
		zipline.instance.Points.ChildRemoved:Connect(zipline.solvePointsCallback),
		self.CurveType:onChange(zipline, zipline.createCurveCallback),
		self.CurveSlack:onChange(zipline, zipline.createCurveCallback),
		self.SegmentType:onChange(zipline, zipline.createCurveCallback),
		self.SegmentCount:onChange(zipline, zipline.createCurveCallback),
		self.SegmentColor:onChange(zipline, zipline.updateSegmentsCallback),
		self.SegmentThickness:onChange(zipline, zipline.updateSegmentsCallback),
		self.SegmentTransparency:onChange(zipline, zipline.updateSegmentsCallback)
	)
end

function Zipline.onActivate(
	self: typeof(Zipline),
	zipline: ZiplineMechanic,
	level: std.Level,
	event: activation.ActivationEvent
)
	const activator = if event.kind == "Touch" then event.toucher else character.getMaybeHumanoidRootPart()
	const isPlayer = activator and character.isFromCharacter(activator)
	const toucher = if isPlayer
		then if zipline:Mode() == "Zip" then character.getCharacter().Head else character.getHumanoidRootPart()
		else activator

	if not toucher or mounts.isMechanicMounted(toucher, zipline) then return end

	const activationLife = zipline.life:extend()
	const handleModel = activationLife:add(zipline.handle:Clone())
	const handle = handleModel:IsA "BasePart" and handleModel or handleModel.PrimaryPart
	if not handle then
		logger:Error(zipline.instance, "is missing a Handle part")
		return activationLife:destroy()
	end

	local totalLength, totalSegments = 0, #zipline.segmentLengths
	local segmentTotalLengths = table.create(totalSegments) :: { number }
	for index, length in zipline.segmentLengths do
		segmentTotalLengths[index] = totalLength
		totalLength += length
	end

	const endpoint = zipline.pointInstances[#zipline.pointInstances]
	local currentLength = 0
	if event.kind == "Touch" then
		if event.instance == endpoint then
			currentLength = totalLength
		else
			const segmentIndex = table.find(zipline.segmentInstances, event.instance)
			currentLength = if segmentIndex then segmentTotalLengths[segmentIndex] else 0
		end
	end

	-- stylua: ignore
	local segmentIndex = math.clamp(math.floor(currentLength / totalLength * #segmentTotalLengths) + 1, 1, totalSegments)
	const initialCFrame = zipline.segments[segmentIndex]
	const initialTangent = initialCFrame.RightVector

	local currentDirection = 1
	if currentLength >= totalLength or (event.kind == "Touch" and event.instance == endpoint) then
		currentDirection = -1
	elseif currentLength > 0 and Workspace.CurrentCamera.CFrame.LookVector:Dot(initialTangent) < 0 then
		currentDirection = -1
	end

	const function onDismount()
		if isPlayer then
			const humanoid = character.getMaybeHumanoid()
			if humanoid then
				humanoid.PlatformStand = false
				if zipline:JumpOnDismount() then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end

		if zipline:KeepMomentum() then
			toucher.AssemblyLinearVelocity = zipline.segments[segmentIndex].RightVector
				* zipline:Speed()
				* currentDirection
		end

		zipline.life:delay(zipline:Cooldown(), mounts.dismountMechanic, toucher, zipline)
	end

	activationLife:destroyOn(mounts.mountMechanic(toucher, zipline))
	activationLife:destroyOn(toucher.Destroying)
	activationLife:add(onDismount)

	const dismountDelay = zipline:DismountDelay()
	const dismountStart = os.clock() + dismountDelay
	activationLife:delay(dismountDelay, activation.bindActivation, {
		attributes = self.Dismount,
		instanceLife = activationLife,
		instance = zipline.instance,
		instanceConfiguration = zipline.instanceConfiguration,
		onActivate = activationLife:wrapDestroy(),
	})

	if zipline:HandleHidden() or zipline:Mode() == "Grind" then
		handle.Size = Vector3.zero
		toggle.ToggleDescendants(handleModel, true)
		toggle.ToggleDescendantsInheritAttributes(handleModel, true)
		toggle.toggleInstance(false, handleModel)
	end

	handle.CFrame = initialCFrame
	handleModel.Parent = zipline.instance

	toucher.CFrame = if zipline:Mode() == "Zip"
		then handle.CFrame - handle.CFrame.UpVector * (toucher.Size.X / 2)
		else (if isPlayer
			then handle.CFrame + handle.CFrame.UpVector * 3
			else handle.CFrame + handle.CFrame.UpVector * (toucher.Size.X / 2)) * CFrame.Angles(0, -math.pi / 2, 0)
	constraints.weld(activationLife, handle, toucher)

	activationLife:add(RunService.PreSimulation:Connect(function(deltaTime: number)
		debug.profilebegin "Zipline"

		if zipline:UserControlEnabled() then
			const moveVector: Vector3 = PlayerModule:GetControls():GetMoveVector()

			local targetDirection = 0
			if moveVector.Magnitude > 0 then
				const cameraCFrame = Workspace.CurrentCamera.CFrame
				const worldMoveDirection = Workspace.CurrentCamera.CFrame.RightVector * moveVector.X
					+ cameraCFrame.LookVector * -moveVector.Z

				const currentTangent = zipline.segments[segmentIndex].RightVector
				const projection = worldMoveDirection.Unit:Dot(currentTangent)

				targetDirection = if projection > THRESHOLD then 1 elseif projection < -THRESHOLD then -1 else 0
			end

			const directionIncrement = zipline:UserControlAcceleration() * deltaTime
			currentDirection = if currentDirection < targetDirection
				then math.min(currentDirection + directionIncrement, targetDirection)
				else math.max(currentDirection - directionIncrement, targetDirection)
		end

		while segmentIndex < totalSegments and currentLength >= segmentTotalLengths[segmentIndex + 1] do
			segmentIndex += 1
		end

		while segmentIndex > 1 and currentLength < segmentTotalLengths[segmentIndex] do
			segmentIndex -= 1
		end

		const isOutOfBounds = (currentLength <= 0 and currentDirection < 0)
			or (currentLength >= totalLength and currentDirection > 0)

		const appliedDirection = if isOutOfBounds then 0 else currentDirection
		currentLength = math.clamp(currentLength + appliedDirection * zipline:Speed() * deltaTime, 0, totalLength)

		if zipline:DismountOnEndpoints() and os.clock() > dismountStart then
			if
				(currentLength <= 0 and currentDirection < 0)
				or (currentLength >= totalLength - LOOKAHEAD and currentDirection > 0)
			then
				return activationLife:destroy()
			end
		end

		const alpha = math.clamp(currentLength / totalLength, 0, 1)
		const currentPosition = zipline.curve:solvePosition(alpha)

		const lookDirection = if currentDirection == 0 then 1 else math.sign(currentDirection)
		const isEndpoint = alpha + (lookDirection * LOOKAHEAD) > 1 or alpha + (lookDirection * LOOKAHEAD) < 0
		const targetAlpha = math.clamp(alpha + (if isEndpoint then -lookDirection else lookDirection) * LOOKAHEAD, 0, 1)

		const targetPosition = zipline.curve:solvePosition(targetAlpha)
		if currentPosition == targetPosition then
			handle.CFrame = zipline.segments[segmentIndex] - zipline.segments[segmentIndex].Position + currentPosition
		else
			local baseOrientation = CFrame.lookAt(currentPosition, targetPosition)
			handle.CFrame = if isEndpoint then baseOrientation * CFrame.Angles(0, math.pi, 0) else baseOrientation
		end

		debug.profileend()
	end))
end

return Zipline
