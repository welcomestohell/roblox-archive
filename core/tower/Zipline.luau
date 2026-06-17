const RunService = game:GetService "RunService"

const activation = require "@libs/activation"
const Attribute = require "@libs/attributes/Attribute"
const character = require "@libs/character"
const constraints = require "@libs/constraints"
const curves = require "@libs/curves"
const functions = require "@libs/functions"
const mounts = require "@libs/mounts"
const std = require "@libs/std"
const toggle = require "@libs/toggle"
const Oklab = require "@libs/vendor/Oklab"

const Zipline = std.Mechanic {
	emoji = "🚠",
	name = "Zipline",
	description = "When activated, carries the activator across it's curve.",
	instanceType = std.gt.instanceTree {
		Handle = std.isA.BasePart(),
		Points = std.isA.Instance(),
	},

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Speed = std.Attribute("Speed", std.gt.positiveNumber, 1),

	std.AttributeSection "Curve",
	CurveType = std.Attribute("CurveType", std.gt.keysOf(curves.CURVES), "CatmullRom"),
	CatenarySlack = std.Attribute("CatenarySlack", std.gt.constrainNumberExclusive(1), 1.05),

	std.AttributeSection "Segments",
	SegmentType = std.Attribute("SegmentType", std.gt.literals("Part", "Beam"), "Part"),
	SegmentCount = std.Attribute("SegmentCount", std.gt.positiveNumber, 20),
	SegmentThickness = std.Attribute("SegmentThickness", std.gt.positiveNumber, 0.25),
	SegmentColor = std.Attribute(
		"SegmentColor",
		std.gt.literals("Startpoint", "Endpoint", "BothEndpoints", "AllPoints"),
		"AllPoints"
	),
	SegmentTransparency = std.Attribute(
		"SegmentTransparency",
		std.gt.literals("Startpoint", "Endpoint", "BothEndpoints"),
		"BothEndpoints"
	),

	std.AttributeSection "Activation",
	StartpointActivation = activation.useAttributes "StartpointActivation",
	EndpointActivation = activation.useAttributes "EndpointActivation",
	SegmentActivation = activation.useAttributes "SegmentActivation",

	std.AttributeSection "Dismount",
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

-- we bind activation ourselves
Zipline.bindActivation = functions.noop

function Zipline.calculateSegmentCount(zipline: ZiplineMechanic): number
	const numPoints = #zipline.points
	return if numPoints <= 2 then 1 elseif zipline:CurveType() == "Linear" then numPoints - 1 else zipline:SegmentCount()
end

function Zipline.calculateCurveType(zipline: ZiplineMechanic)
	return if zipline:calculateSegmentCount() == 1 then "Linear" else zipline:CurveType()
end

function Zipline.calculateSegmentTransparency(zipline: ZiplineMechanic, index: number, count: number): number
	const segmentTransparency = zipline:SegmentTransparency()
	return if segmentTransparency == "Startpoint"
		then zipline.pointInstances[1].Transparency
		elseif segmentTransparency == "Endpoint" then zipline.pointInstances[#zipline.pointInstances].Transparency
		elseif segmentTransparency == "BothEndpoints" then math.lerp(
			zipline.pointInstances[1].Transparency,
			zipline.pointInstances[#zipline.pointInstances].Transparency,
			index / count
		)
		else 1
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

		local segment
		if segmentType == "Part" then
			segment = segmentsLife:add(Instance.new "Part")
			segment.Name = tostring(index)
			segment.Anchored = false
			segment.CanCollide = false
			segment.CFrame = segmentCFrame
			segment.Material = Enum.Material.SmoothPlastic
			segment.Shape = Enum.PartType.Cylinder
			segment.Size = Vector3.new(segmentLength, 0, 0)

			constraints.weld(segmentsLife, startPoint, segment)
			segment.Parent = zipline.segmentsPartContainer

			activation.bindActivation {
				attributes = zipline.SegmentActivation,
				instanceLife = segmentsLife,
				instance = segment,
				instanceConfiguration = zipline.instanceConfiguration,
				onActivate = zipline.onActivateCallback,
			}
		else
			segment = segmentsLife:add(Instance.new "Beam")
			segment.Name = tostring(index)
			segment.FaceCamera = true
			segment.LightInfluence = 1
			segment.Segments = 1
			segment.Transparency = NumberSequence.new(0)

			segment.Parent = startPoint

			const attachment0, attachment1 = constraints.populateAttachments(segmentsLife, segment)
			attachment0.Position = previousPosition - startPointPosition
			attachment1.Position = nextPosition - startPointPosition
			attachment0.Parent = startPoint
			attachment1.Parent = startPoint
		end

		table.insert(zipline.segments, segmentCFrame)
		table.insert(zipline.segmentLengths, segmentLength)
		table.insert(zipline.segmentInstances :: { BasePart | Beam }, segment)

		previousPosition = nextPosition
	end

	zipline:updateSegments()
	return zipline.segments
end

function Zipline.updateSegments(zipline: ZiplineMechanic)
	const segmentCount = zipline:calculateSegmentCount()
	const thickness = zipline:SegmentThickness()

	if zipline:SegmentType() == "Part" then
		for _, part in zipline.segmentInstances :: { BasePart } do
			const index = tonumber(part.Name) :: number
			part.Color = zipline:calculateSegmentPartColor(index, segmentCount)
			part.Transparency = zipline:calculateSegmentTransparency(index, segmentCount)
			part.Size = Vector3.new(part.Size.X, thickness, thickness)
		end
	else
		for _, beam in zipline.segmentInstances :: { Beam } do
			const index = tonumber(beam.Name) :: number
			beam.Color = ColorSequence.new(
				zipline:calculateSegmentPartColor(index - 1, segmentCount),
				zipline:calculateSegmentPartColor(index, segmentCount)
			)
			beam.Transparency = NumberSequence.new(
				zipline:calculateSegmentTransparency(index - 1, segmentCount),
				zipline:calculateSegmentTransparency(index, segmentCount)
			)
			beam.Width0 = thickness
			beam.Width1 = thickness
		end
	end
end

function Zipline.createCurve(zipline: ZiplineMechanic)
	zipline.curve = curves.CURVES[zipline:calculateCurveType()].new {
		points = zipline.points,
		slack = zipline:CatenarySlack(),
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
		if point and point:IsA "BasePart" then
			table.insert(zipline.points, point.Position)
			table.insert(zipline.pointInstances, point)
			toggle.SetCollision(point, false)
			-- FIXME: Name property doesn't fire??
			pointsLife:destroyOn(point:GetPropertyChangedSignal "Name")
			pointsLife:destroyOn(point:GetPropertyChangedSignal "Position")
			pointsLife:add(point:GetPropertyChangedSignal("Color"):Connect(zipline.updateSegmentsCallback))
			pointsLife:add(point:GetPropertyChangedSignal("Transparency"):Connect(zipline.updateSegmentsCallback))
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
		self.CatenarySlack:onChange(zipline, zipline.createCurveCallback),
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
	const toucher = if activator and character.isFromCharacter(activator)
		then character.getCharacter().Head
		else activator

	if not toucher or mounts.isMechanicMounted(toucher, zipline) then return end

	const startpointActivatable = self.StartpointActivation.Enabled(zipline)
	const endpointActivatable = self.EndpointActivation.Enabled(zipline)
	const segmentActivatable = self.SegmentActivation.Enabled(zipline)

	self.StartpointActivation.Enabled(zipline, false)
	self.EndpointActivation.Enabled(zipline, false)
	self.SegmentActivation.Enabled(zipline, false)

	const activationLife = zipline.life:extend()
	activationLife:destroyOn(mounts.mountMechanic(toucher, zipline))
	activationLife:add(function()
		mounts.dismountMechanic(toucher, zipline)

		zipline.life:delay(
			zipline:Cooldown(),
			Attribute.set :: any,
			self.StartpointActivation.Enabled,
			zipline,
			startpointActivatable
		)

		zipline.life:delay(
			zipline:Cooldown(),
			Attribute.set :: any,
			self.EndpointActivation.Enabled,
			zipline,
			endpointActivatable
		)

		zipline.life:delay(
			zipline:Cooldown(),
			Attribute.set :: any,
			self.SegmentActivation.Enabled,
			zipline,
			segmentActivatable
		)

		--[[
			-- 	------------------------------------------------------------------------
			-- 	--> Dismount function
			-- 	local function dismountZipline()
			-- 		rideScope:cleanup(true, true)

			-- 		if isPlayer and humanoid then
			-- 			utility.Character.carryPart(false, ropeBar, not configuration.HandleAnimation)
			-- 			humanoid.PlatformStand = false

			-- 			if configuration.JumpOnDismount then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
			-- 		end
			-- 		utility.Functions.playSoundFromInstance(attachTo, soundsFolder, "Jump")

			-- 		if mountedCOs[attachTo] and mountedCOs[attachTo][zipline] then
			-- 			mountedCOs[attachTo][zipline] = nil
			-- 			if utility.Table.IsEmpty(mountedCOs[attachTo]) then mountedCOs[attachTo] = nil end
			-- 		end

			-- 		task.delay(TOUCH_COOLDOWN, function()
			-- 			rideDebounce[attachTo] = nil
			-- 		end)

			-- 		if not attachTo then return end
			-- 		if configuration.KeepMomentum and segments[currentSegment] then
			-- 			attachTo.AssemblyLinearVelocity = segments[currentSegment].CFrame.RightVector
			-- 				* configuration.Speed
			-- 				* currentDirection
			-- 		else
			-- 			attachTo.AssemblyLinearVelocity = Vector3.zero
			-- 		end
			-- 	end
		]]
	end)

	const handle = activationLife:add(zipline.handle:Clone())
	handle.CFrame = CFrame.lookAt(zipline.points[1], zipline.segments[1].Position)
	handle.Parent = zipline.instance

	toucher.CFrame = handle.CFrame - handle.CFrame.UpVector * (toucher.Size.X / 2)
	constraints.weld(activationLife, handle, toucher)

	local currentDirection = 1
	local currentProgress = 0
	local currentSegment = if event.kind ~= "Touch" or event.toucher == zipline.pointInstances[1]
		then 1
		elseif event.toucher == zipline.pointInstances[#zipline.pointInstances] then #zipline.segments
		else table.find(zipline.segmentInstances, event.instance) or 1

	activation.bindActivation {
		attributes = self.Dismount,
		instanceLife = activationLife,
		instance = zipline.instance,
		instanceConfiguration = zipline.instanceConfiguration,
		onActivate = activationLife:wrapDestroy(),
	}

	activationLife:add(RunService.PreSimulation:Connect(function(deltaTime: number)
		const segment = zipline.segments[currentSegment]
		const segmentLength = zipline.segmentLengths[currentSegment]
		const goal = segment + segment.RightVector * (currentProgress - (segmentLength / 2))

		handle.CFrame = goal * CFrame.Angles(0, -math.pi / 2, 0)
		currentProgress = math.clamp(
			currentProgress + currentDirection * zipline:Speed() * deltaTime,
			if currentSegment <= 1 then 0 else -math.huge,
			if currentDirection >= #zipline.segments then segmentLength else math.huge
		)

		while true do
			if currentProgress < segmentLength or currentSegment > #zipline.segments then break end

			currentSegment += 1
			currentProgress -= segmentLength
			if not zipline.segments[currentSegment] then return activationLife:destroy() end
		end
	end))

	-- 	------------------------------------------------------------------------
	-- 	--> Move ride
	-- 	rideScope:add(RunService.Heartbeat:Connect(function(deltaTime: number)
	-- 		debug.profilebegin "Zipline Movement"
	-- 		local segmentPart = segments[currentSegment]
	-- 		if not segmentPart then
	-- 			rideScope:cleanup(true, true)
	-- 			return
	-- 		end

	-- 		local goalCF = segmentPart.CFrame
	-- 			+ segmentPart.CFrame.RightVector * (segmentProgress - (segmentPart.Size.X * 0.5))
	-- 		ropeGuide.CFrame = goalCF * CFrame.Angles(0, -math.pi * 0.5, 0)

	-- 		segmentProgress += currentDirection * configuration.Speed * deltaTime
	-- 		segmentProgress = math.clamp(
	-- 			segmentProgress,
	-- 			if currentSegment <= 1 then 0 else -math.huge,
	-- 			if currentSegment >= #segments then segmentPart.Size.X else math.huge
	-- 		)
	-- 		local ziplineBlocked = (currentSegment <= 1 and segmentProgress <= 0)
	-- 			or (currentSegment >= #segments and segmentProgress >= segmentPart.Size.X)

	-- 		local finishedSegmentUpdate = false
	-- 		if currentDirection > 0 then
	-- 			repeat
	-- 				if segmentProgress > segmentPart.Size.X and currentSegment < #segments then
	-- 					currentSegment += 1
	-- 					segmentProgress -= segmentPart.Size.X

	-- 					local newSegment = segments[currentSegment]
	-- 					if not newSegment then
	-- 						rideScope:cleanup(true, true)
	-- 						return
	-- 					end
	-- 					segmentPart = newSegment
	-- 				else
	-- 					finishedSegmentUpdate = true
	-- 				end
	-- 			until finishedSegmentUpdate
	-- 		elseif currentDirection < 0 then
	-- 			repeat
	-- 				if segmentProgress < 0 and currentSegment > 1 then
	-- 					currentSegment -= 1
	-- 					local newSegment = segments[currentSegment]
	-- 					if not newSegment then
	-- 						rideScope:cleanup(true, true)
	-- 						return
	-- 					end
	-- 					segmentProgress += newSegment.Size.X
	-- 					segmentPart = newSegment
	-- 				else
	-- 					finishedSegmentUpdate = true
	-- 				end
	-- 			until finishedSegmentUpdate
	-- 		end

	-- 		if configuration.AllowUserControl then
	-- 			local controlVector = -controls:GetMoveVector().Z

	-- 			local directionIncrement = CONTROL_ACCEL_TIME * deltaTime
	-- 			if currentDirection < controlVector then
	-- 				currentDirection = math.clamp(currentDirection + directionIncrement, -1, controlVector)
	-- 			elseif currentDirection > controlVector then
	-- 				currentDirection = math.clamp(currentDirection - directionIncrement, controlVector, 1)
	-- 			end

	-- 			if currentDirection == 0 or ziplineBlocked then
	-- 				if particleClone.Enabled then particleClone.Enabled = false end
	-- 				if loopSoundClone.Playing then loopSoundClone:Stop() end
	-- 			elseif currentDirection ~= 0 and not ziplineBlocked then
	-- 				if not particleClone.Enabled then particleClone.Enabled = true end
	-- 				if not loopSoundClone.Playing then loopSoundClone:Play() end
	-- 			end
	-- 		end

	-- 		if not attachTo or not attachTo.Parent or not (mountedCOs[attachTo] and mountedCOs[attachTo][zipline]) then
	-- 			dismountZipline()
	-- 		end

	-- 		if currentSegment >= #segments and segmentProgress >= segmentPart.Size.X then
	-- 			if configuration.AllowEndDismount then
	-- 				dismountZipline()
	-- 			elseif configuration.Loop then
	-- 				currentSegment = 1
	-- 				segmentProgress = 0
	-- 			end
	-- 		elseif currentSegment == 1 and segmentProgress <= 0 and configuration.Loop and currentDirection < 0 then
	-- 			currentSegment = #segments
	-- 			segmentProgress = segments[#segments].Size.X
	-- 		end
	-- 		debug.profileend()
	-- 	end))
	-- end
end

return Zipline
