local RunService = game:GetService "RunService"
local Workspace = game:GetService "Workspace"

local character = require "@libs/character"
local std = require "@libs/std"
local touch = require "@libs/touch"

local Elevator = std.Mechanic {}
export type ElevatorMechanic = std.Mechanic<typeof(Elevator), { touching: { [BasePart]: true } }>
Elevator.mechanicName = "Elevator"
Elevator.instanceType = std.isA.BasePart()
Elevator.debuggerEmoji = "🛗"

Elevator.Enabled = Elevator:attribute("Enabled", std.gt.boolean(), true)
Elevator.Speed = Elevator:attribute("Speed", std.gt.number(), 40)
Elevator.MaxForce = Elevator:attribute("MaxForce", std.gt.number(), math.huge)
Elevator.Vector = Elevator:attribute(
	"Vector",
	std.gt.literals("UpVector", "RightVector", "LookVector", "ZVector", "WorldYVector"),
	"WorldYVector"
)
Elevator.ContinuousUpdates = Elevator:attribute("ContinuousUpdates", std.gt.boolean(), true)

Elevator.Touch = std.useTouch(Elevator)

export type Vector = typeof(Elevator.Vector:type())

function Elevator.isActive(elevator: ElevatorMechanic, overlap: OverlapParams)
	return elevator.instance.CanTouch
		and elevator.instance.CanQuery
		and elevator:Enabled()
		and next(Workspace:GetPartsInPart(elevator.instance, overlap))
end

function Elevator.faceVector(elevator: ElevatorMechanic): Vector3
	local elevatorVector: Vector = elevator:Vector()
	return if elevatorVector == "WorldYVector" then Vector3.yAxis else (elevator.instance.CFrame :: any)[elevatorVector]
end

function Elevator.maxForce(elevator: ElevatorMechanic, faceVector: Vector3)
	local elevatorMaxForce = elevator:MaxForce()

	-- do not ever do Vector3.yAxis * math.huge
	local maxForce = Vector3.zero
	if faceVector.X ~= 0 then
		maxForce += Vector3.new(elevatorMaxForce, 0, 0)
	end
	if faceVector.Y ~= 0 then
		maxForce += Vector3.new(0, elevatorMaxForce, 0)
	end
	if faceVector.Z ~= 0 then
		maxForce += Vector3.new(0, 0, elevatorMaxForce)
	end

	return maxForce
end

function Elevator.spawnPart(elevator: ElevatorMechanic, part: BasePart, overlap: OverlapParams)
	if elevator.touching[part] or not elevator:Enabled() then return end

	local faceVector = elevator:faceVector()

	local spawnLife = elevator.life:extend()
	spawnLife:destroyOn(part.Destroying)
	spawnLife:add(function() elevator.touching[part] = nil end)

	local velocityAttachment = spawnLife:add(Instance.new "Attachment")
	velocityAttachment.Parent = part

	local velocity = spawnLife:add(Instance.new "LinearVelocity")
	velocity.Name = "ElevatorVelocity"
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	velocity.Attachment0 = velocityAttachment
	velocity.ForceLimitsEnabled = true
	velocity.MaxAxesForce = elevator:maxForce(faceVector)
	velocity.VectorVelocity = faceVector * elevator:Speed()
	velocity.Parent = part

	elevator.touching[part] = true
	while elevator:isActive(overlap) and not spawnLife.destroyed do
		if elevator:ContinuousUpdates() then
			faceVector = elevator:faceVector()
			velocity.MaxAxesForce = elevator:maxForce(faceVector)
			velocity.VectorVelocity = faceVector * elevator:Speed()
		end
		RunService.PreSimulation:Wait()
	end

	spawnLife:destroy()
end

function Elevator:onStart(elevator: ElevatorMechanic)
	elevator.touching = {}

	elevator.life:add(elevator.instance.Touched:Connect(function(toucher)
		if not touch.isToucherValid(elevator.Touch, elevator.instance, elevator.instanceConfiguration, toucher) then
			return
		end

		local overlap = OverlapParams.new()

		local maybeCharacter = character.getMaybeCharacter() :: Instance?
		if maybeCharacter and toucher:IsDescendantOf(maybeCharacter) then
			elevator:spawnPart(character.getHumanoidRootPart(), overlap)
		else
			overlap:AddToFilter(toucher)
			elevator:spawnPart(toucher, overlap)
		end
	end))
end

return Elevator
