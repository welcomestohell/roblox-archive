const RunService = game:GetService "RunService"

const activation = require "@libs/activation"
const character = require "@libs/character"
const constraints = require "@libs/constraints"
const curves = require "@libs/curves"
const functions = require "@libs/functions"
const lerp = require "@libs/lerp"
const mounts = require "@libs/mounts"
const std = require "@libs/std"
const toggle = require "@libs/toggle"
const Oklab = require "@libs/vendor/Oklab"
const PlayerModule = require "@libs/vendor/PlayerModule"

const Zipline = std.Mechanic {
	emoji = "🚠",
	name = "Zipline",
	description = "When activated, carries the activator across it's curve.",
	instanceType = std.gt.instanceTree {
		Handle = std.isA.BasePart(),
		Points = std.isA.Instance(),
	},

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Mode = std.Attribute("Mode", std.gt.literals("Zip", "Grind"), "Zip"),
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
	UserControlAcceleration = std.Attribute("UserControlAcceleration", std.gt.positiveNumber, 1 / 0.25),

	std.AttributeSection "Activation",
	StartpointActivation = activation.useAttributes "StartpointActivation",
	EndpointActivation = activation.useAttributes "EndpointActivation",
	SegmentActivation = activation.useAttributes "SegmentActivation",

	std.AttributeSection "Dismount",
	DismountOnEndpoints = std.Attribute("DismountOnEndpoints", std.gt.boolean(), true),
	JumpOnDismount = std.Attribute("JumpOnDismount", std.gt.boolean(), true),
	KeepMomentum = std.Attribute("KeepMomentum", std.gt.boolean(), true),
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

	handle: BasePart,
}>

const LOOKAHEAD = 0.0001

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

-- FIXME: there are bugs when removing points at runtime, fix tmr morning
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

	const startpointActivatable = self.StartpointActivation.Enabled(zipline)
	const endpointActivatable = self.EndpointActivation.Enabled(zipline)
	const segmentActivatable = self.SegmentActivation.Enabled(zipline)

	self.StartpointActivation.Enabled(zipline, false)
	self.EndpointActivation.Enabled(zipline, false)
	self.SegmentActivation.Enabled(zipline, false)

	local totalLength = 0
	local segmentTotalLengths = {}
	for index, length in zipline.segmentLengths do
		segmentTotalLengths[index] = totalLength
		totalLength += length
	end

	const endpoint = zipline.pointInstances[#zipline.pointInstances]

	local currentDirection = if event.kind == "Touch" and event.instance == endpoint then -1 else 1

	local currentLength = if event.kind ~= "Touch" or event.instance == zipline.pointInstances[1]
		then 0
		elseif event.instance == endpoint then totalLength
		else segmentTotalLengths[table.find(zipline.segmentInstances, event.instance) or 1]

	const function currentSegment(): number
		const totalSegments = #segmentTotalLengths
		for index = totalSegments, 1, -1 do
			if currentLength >= segmentTotalLengths[index] then return index end
		end
		return totalSegments
	end

	const activationLife = zipline.life:extend()
	activationLife:destroyOn(mounts.mountMechanic(toucher, zipline))
	activationLife:destroyOn(toucher.Destroying)
	activationLife:add(function()
		mounts.dismountMechanic(toucher, zipline)

		if isPlayer then
			const humanoid = character.getMaybeHumanoid()
			if humanoid then
				humanoid.PlatformStand = false
				if zipline:JumpOnDismount() then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end

		if zipline:KeepMomentum() then
			toucher.AssemblyLinearVelocity = zipline.segments[currentSegment()].RightVector
				* zipline:Speed()
				* currentDirection
		end

		zipline.life:delay(
			zipline:Cooldown(),
			function(zipline: ZiplineMechanic, startpointActivatable, endpointActivatable, segmentActivatable)
				zipline.StartpointActivation.Enabled(zipline, startpointActivatable)
				zipline.EndpointActivation.Enabled(zipline, endpointActivatable)
				zipline.SegmentActivation.Enabled(zipline, segmentActivatable)
			end,
			zipline,
			startpointActivatable,
			endpointActivatable,
			segmentActivatable
		)
	end)

	const handle = activationLife:add(zipline.handle:Clone())
	handle.CFrame = zipline.segments[currentSegment() :: number]
	if zipline:Mode() == "Grind" then
		handle.Size = Vector3.zero
		handle.Transparency = 1
	end
	handle.Parent = zipline.instance

	toucher.CFrame = if zipline:Mode() == "Zip"
		then handle.CFrame - handle.CFrame.UpVector * (toucher.Size.X / 2)
		else (if isPlayer
			then handle.CFrame + handle.CFrame.UpVector * 3
			else handle.CFrame + handle.CFrame.UpVector * (toucher.Size.X / 2)) * CFrame.Angles(0, -math.pi / 2, 0)

	constraints.weld(activationLife, handle, toucher)

	activation.bindActivation {
		attributes = self.Dismount,
		instanceLife = activationLife,
		instance = zipline.instance,
		instanceConfiguration = zipline.instanceConfiguration,
		onActivate = activationLife:wrapDestroy(),
	}

	activationLife:add(RunService.PreSimulation:Connect(function(deltaTime: number)
		-- FIXME: starting from endpoint fucks this up
		-- ...usercontrol needs a rework imo to use the camera direction
		-- also, segmentactivation always face to endpoint, this should use
		-- camera as well
		-- we got much bigger fish to fry rn tho
		if zipline:UserControlEnabled() then
			const controlVector = -PlayerModule:GetControls():GetMoveVector().Z
			const directionIncrement = zipline:UserControlAcceleration() * deltaTime

			currentDirection = if currentDirection < controlVector
				then math.clamp(currentDirection + directionIncrement, -1, controlVector)
				else math.clamp(currentDirection - directionIncrement, controlVector, 1)
		end

		const currentSegment = currentSegment()
		if not currentSegment then return activationLife:destroy() end

		currentLength = math.clamp(currentLength + currentDirection * zipline:Speed() * deltaTime, 0, totalLength)
		if zipline:DismountOnEndpoints() and (currentLength >= totalLength - LOOKAHEAD or currentLength <= 0) then
			return activationLife:destroy()
		end

		const alpha = math.clamp(currentLength / totalLength, 0, 1)
		const currentPosition = zipline.curve:solvePosition(alpha)

		const lookDirection = if currentDirection == 0 then 1 else math.sign(currentDirection)
		const targetAlpha = alpha + (lookDirection * LOOKAHEAD)
		const targetPosition = zipline.curve:solvePosition(math.clamp(targetAlpha, 0, 1))

		handle.CFrame = CFrame.lookAt(currentPosition, targetPosition)
	end))
end

return Zipline
