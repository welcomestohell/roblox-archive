local RunService = game:GetService "RunService"
local Workspace = game:GetService "Workspace"

local Oklab = require "@libs/vendor/Oklab"
local PlayerModule = require "@libs/vendor/PlayerModule"
local activation = require "@libs/activation"
local character = require "@libs/character"
local constraints = require "@libs/constraints"
local curves = require "@libs/curves"
local functions = require "@libs/primitives/functions"
local lerp = require "@libs/lerp"
local logger = require "@core/shared/logger"
local mounts = require "@libs/mounts"
local std = require "@libs/std"
local toggle = require "@libs/toggle"

local Zipline = std.Mechanic {
	emoji = "🚠",
	name = "Zipline",
	description = "When activated, carries the activator across it's curve.",
	instanceType = std.gt.instanceTree {
		Handle = std.gt.union(std.isA.BasePart(), std.isA.Model()),
		Points = std.isA.Instance(),
	},

	Mode = std.Attribute("Mode", std.gt.literals { "Zip", "Grind" }, "Zip"),
	Active = std.Attribute("Active", std.gt.boolean(), false),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	HideHandle = std.Attribute("HideHandle", std.gt.boolean(), false),
	Speed = std.Attribute("Speed", std.gt.positiveNumber, 1),

	std.AttributeSection "Curve",
	CurveType = std.Attribute("CurveType", std.gt.keysOf(curves.CURVES), "CatmullRom"),
	CurveSlack = std.Attribute("CurveSlack", std.gt.constrainNumberExclusive(1), 1.05),

	std.AttributeSection "Segments",
	SegmentType = std.Attribute("SegmentType", std.gt.literals { "Part", "Beam" }, "Beam"),
	SegmentCount = std.Attribute("SegmentCount", std.gt.positiveNumber, 20),
	SegmentThickness = std.Attribute("SegmentThickness", std.gt.NumberSequence, NumberSequence.new(0.25)),
	SegmentTransparency = std.Attribute("SegmentTransparency", std.gt.NumberSequence, NumberSequence.new(0)),
	SegmentColor = std.Attribute(
		"SegmentColor",
		std.gt.literals { "Startpoint", "Endpoint", "BothEndpoints", "AllPoints" },
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

local LOOKAHEAD = 0.0001
local THRESHOLD = -0.1

-- we bind activation ourselves
Zipline.bindActivation = functions.noop

function Zipline.calculateSegmentCount(zipline: ZiplineMechanic): number
	local numPoints = #zipline.points
	return if numPoints <= 2 then 1 elseif zipline:CurveType() == "Linear" then numPoints - 1 else zipline:SegmentCount()
end

function Zipline.calculateCurveType(zipline: ZiplineMechanic)
	return if zipline:calculateSegmentCount() == 1 then "Linear" else zipline:CurveType()
end

function Zipline.calculateSegmentPartColor(zipline: ZiplineMechanic, index: number, count: number): Color3
	local segmentColor = zipline:SegmentColor()
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
		local alpha = index / count

		local totalGaps = #zipline.points - 1
		local scaledAlpha = alpha * totalGaps

		local pointIndex = math.clamp(math.floor(scaledAlpha) + 1, 1, totalGaps)
		local nextPointIndex = pointIndex + 1

		local localAlpha = scaledAlpha - (pointIndex - 1)

		local startColor = zipline.pointInstances[pointIndex].Color
		local endColor = zipline.pointInstances[nextPointIndex].Color
		return Oklab.lerpColor3s(startColor, endColor, localAlpha)
	else
		return Color3.new()
	end
end

function Zipline.createSegments(zipline: ZiplineMechanic)
	if zipline.segmentsLife and zipline.segmentsLife.alive then zipline.segmentsLife:destroy() end
	local segmentsLife = zipline.life:extend()
	zipline.segmentsLife = segmentsLife
	table.clear(zipline.segments)
	table.clear(zipline.segmentInstances)
	table.clear(zipline.segmentLengths)

	local segmentType = zipline:SegmentType()
	local segmentCount = zipline:calculateSegmentCount()

	local startPoint = zipline.pointInstances[1]
	local startPointPosition = zipline.points[1]
	local previousPosition = zipline.curve:solvePosition(0)

	for index = 1, segmentCount do
		local alpha = index / segmentCount
		local nextPosition = zipline.curve:solvePosition(alpha)

		if previousPosition == nextPosition then
			previousPosition = nextPosition
			continue
		end

		local segmentLength = (nextPosition - previousPosition).Magnitude
		local centerPosition = previousPosition:Lerp(nextPosition, 0.5)
		local segmentCFrame = CFrame.lookAt(centerPosition, nextPosition) * CFrame.Angles(0, math.pi * 0.5, 0)

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

			local attachment0, attachment1 = constraints.populateAttachments(segmentsLife, segmentInstance)
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
	local segmentCount = zipline:calculateSegmentCount()
	local thickness = zipline:SegmentThickness()
	local transparency = zipline:SegmentTransparency()

	if zipline:SegmentType() == "Part" then
		for _, part in zipline.segmentInstances :: { BasePart } do
			local index = tonumber(part.Name) :: number
			local alpha = index / segmentCount

			part.Color = zipline:calculateSegmentPartColor(index, segmentCount)
			part.Transparency = lerp.evaluateNumberSequence(transparency, alpha)

			local partThickness = lerp.evaluateNumberSequence(thickness, alpha)
			part.Size = Vector3.new(part.Size.X, partThickness, partThickness)
		end
	else
		for _, beam in zipline.segmentInstances :: { Beam } do
			local index = tonumber(beam.Name) :: number
			local alpha = index / segmentCount
			local nextAlpha = index / segmentCount
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

	local pointsLife = zipline.life:extend()
	zipline.pointsLife = pointsLife
	pointsLife:add(function()
		if zipline.life.alive then zipline:solvePoints() end
	end)

	table.clear(zipline.points)
	table.clear(zipline.pointInstances)

	local container = zipline.instance.Points
	for index = 1, #container:GetChildren() do
		local point = container:FindFirstChild(tostring(index))
		if not point then continue end

		local part = if point:IsA "BasePart" then point elseif point:IsA "Model" then point.PrimaryPart else nil
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

	local pointCount = #zipline.pointInstances
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
	local activator = if event.kind == "Touch" then event.toucher else character.getMaybeHumanoidRootPart()
	local isPlayer = activator and character.isFromCharacter(activator)
	local toucher = if isPlayer
		then if zipline:Mode() == "Zip" then character.getCharacter().Head else character.getHumanoidRootPart()
		else activator

	if not toucher then return end

	local mountInstance = mounts.castToucher(toucher) :: BasePart
	if mounts.isMechanicMounted(mountInstance, zipline) then return end

	local activationLife = zipline.life:extend()
	local handleModel = activationLife:add(zipline.handle:Clone())
	local handle = handleModel:IsA "BasePart" and handleModel or handleModel.PrimaryPart
	if not handle then
		logger:Error(zipline.instance, "is missing a Handle part")
		return activationLife:destroy()
	end

	zipline:Active(true)
	zipline:Debounced(true)

	local totalLength, totalSegments = 0, #zipline.segmentLengths
	local segmentTotalLengths = table.create(totalSegments) :: { number }
	for index, length in zipline.segmentLengths do
		segmentTotalLengths[index] = totalLength
		totalLength += length
	end

	local endpoint = zipline.pointInstances[#zipline.pointInstances]
	local currentLength = 0
	if event.kind == "Touch" then
		if event.instance == endpoint then
			currentLength = totalLength
		else
			local segmentIndex = table.find(zipline.segmentInstances, event.instance)
			currentLength = if segmentIndex then segmentTotalLengths[segmentIndex] else 0
		end
	end

	-- stylua: ignore
	local segmentIndex = math.clamp(math.floor(currentLength / totalLength * #segmentTotalLengths) + 1, 1, totalSegments)
	local initialCFrame = zipline.segments[segmentIndex]
	local initialTangent = initialCFrame.RightVector

	local currentDirection = 1
	if currentLength >= totalLength or (event.kind == "Touch" and event.instance == endpoint) then
		currentDirection = -1
	elseif currentLength > 0 and Workspace.CurrentCamera.CFrame.LookVector:Dot(initialTangent) < 0 then
		currentDirection = -1
	end

	local function onDismount()
		zipline:Active(false)
		mounts.dismountMechanic(toucher, zipline)

		if isPlayer then
			local humanoid = character.getMaybeHumanoid()
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

		zipline.life:delay(zipline:Cooldown(), function(zipline: typeof(zipline), toucher: typeof(toucher))
			zipline:Debounced(false)
		end, zipline, toucher)
	end

	activationLife:destroyOn(mounts.mountMechanic(mountInstance, zipline))
	activationLife:destroyOn(toucher.Destroying)
	activationLife:add(onDismount)

	local dismountDelay = zipline:DismountDelay()
	local dismountStart = os.clock() + dismountDelay
	activationLife:delay(dismountDelay, activation.bindActivation, {
		attributes = self.Dismount,
		instanceLife = activationLife,
		instance = zipline.instance,
		instanceConfiguration = zipline.instanceConfiguration,
		onActivate = activationLife:wrapDestroy(),
	})

	if zipline:HideHandle() or zipline:Mode() == "Grind" then
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
			local moveVector: Vector3 = PlayerModule:GetControls():GetMoveVector()

			local targetDirection = 0
			if moveVector.Magnitude > 0 then
				local cameraCFrame = Workspace.CurrentCamera.CFrame
				local worldMoveDirection = Workspace.CurrentCamera.CFrame.RightVector * moveVector.X
					+ cameraCFrame.LookVector * -moveVector.Z

				local currentTangent = zipline.segments[segmentIndex].RightVector
				local projection = worldMoveDirection.Unit:Dot(currentTangent)

				targetDirection = if projection > THRESHOLD then 1 elseif projection < -THRESHOLD then -1 else 0
			end

			local directionIncrement = zipline:UserControlAcceleration() * deltaTime
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

		local isOutOfBounds = (currentLength <= 0 and currentDirection < 0)
			or (currentLength >= totalLength and currentDirection > 0)

		local appliedDirection = if isOutOfBounds then 0 else currentDirection
		currentLength = math.clamp(currentLength + appliedDirection * zipline:Speed() * deltaTime, 0, totalLength)

		if zipline:DismountOnEndpoints() and os.clock() > dismountStart then
			if
				(currentLength <= 0 and currentDirection < 0)
				or (currentLength >= totalLength - LOOKAHEAD and currentDirection > 0)
			then
				return activationLife:destroy()
			end
		end

		local alpha = math.clamp(currentLength / totalLength, 0, 1)
		local currentPosition = zipline.curve:solvePosition(alpha)

		local lookDirection = if currentDirection == 0 then 1 else math.sign(currentDirection)
		local isEndpoint = alpha + (lookDirection * LOOKAHEAD) > 1 or alpha + (lookDirection * LOOKAHEAD) < 0
		local targetAlpha = math.clamp(alpha + (if isEndpoint then -lookDirection else lookDirection) * LOOKAHEAD, 0, 1)

		local targetPosition = zipline.curve:solvePosition(targetAlpha)
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
