local Players = game:GetService "Players"
local Workspace = game:GetService "Workspace"

local character = require "@libs/character"
local functions = require "@libs/functions"
local std = require "@libs/std"
local tables = require "@libs/collections/tables"

local mouse = Players.LocalPlayer:GetMouse()

local Follower = std.Mechanic {
	emoji = "👀",
	name = "Follower",
	description = "Continously follows the target by looking at, rotating, positioning, or pivoting towards it.",
	instanceType = std.isA.BasePart(),

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Mode = std.Attribute(
		"Mode",
		std.gt.literals("LookAt", "RotationOf", "PositionOf", "PivotOf", "None"),
		functions.literal "None"
	),
	Target = std.Attribute(
		"Target",
		std.gt.literals("Character", "Mouse", "Camera", "Pointer", "None"),
		functions.literal "None"
	),

	std.AttributeSection "Origin",
	Origin = std.Attribute("Origin", std.gt.optional(std.gt.CFrame()), nil),
	UseOriginRotation = std.Attribute("UseOriginRotation", std.gt.boolean(), false),

	std.AttributeSection "Position Axes",
	UseXPosition = std.Attribute("XPosition", std.gt.boolean(), true),
	UseYPosition = std.Attribute("YPosition", std.gt.boolean(), true),
	UseZPosition = std.Attribute("ZPosition", std.gt.boolean(), true),

	std.AttributeSection "Rotation Axes",
	UseXRotation = std.Attribute("XRotation", std.gt.boolean(), true),
	UseYRotation = std.Attribute("YRotation", std.gt.boolean(), true),
	UseZRotation = std.Attribute("ZRotation", std.gt.boolean(), true),

	std.AttributeSection "Smoothness",
	Smooth = std.Attribute("Smooth", std.gt.boolean(), false),
	Responsiveness = std.Attribute("Responsiveness", std.gt.positiveNumber, 1),
}

export type FollowerMechanic = std.Mechanic<typeof(Follower)>
export type Mode = typeof(Follower.Mode:type())
export type Target = typeof(Follower.Target:type())

function Follower.getTargetCFrame(target: Target): CFrame?
	if target == "Camera" then
		return Workspace.CurrentCamera.CFrame
	elseif target == "Mouse" then
		return mouse.Hit
	elseif target == "Character" then
		local root = character.getMaybeHumanoidRootPart()
		if root then return root.CFrame end
	end
	return nil
end

function Follower:onStart(follower: FollowerMechanic)
	follower.Origin:getOrSet(follower, follower.instance.CFrame :: CFrame?)
end

function Follower.onPreSimulation(self: typeof(Follower), deltaTime: number, level: std.Level)
	local followers = level:getMechanics(self)
	local countFollowers = #followers

	if countFollowers == 0 then return end

	local shouldBulkMove = false
	local bulkInstances: { BasePart } = tables.create(countFollowers)
	local bulkCFrames: { CFrame } = tables.create(countFollowers)

	for _, follower: FollowerMechanic in followers do
		if not follower:Enabled() then continue end

		local targetCFrame = self.getTargetCFrame(follower:Target())
		if not targetCFrame then continue end

		-- Dear basketball

		local mode: Mode = follower:Mode()
		local instance = follower.instance
		if mode == "None" then
			continue
		elseif mode == "LookAt" then
			targetCFrame = CFrame.lookAt(instance:GetPivot().Position, targetCFrame.Position)
		elseif mode == "PositionOf" then
			targetCFrame = CFrame.new(targetCFrame.Position)
		elseif mode == "RotationOf" then
			targetCFrame = CFrame.new(targetCFrame.Position) * instance:GetPivot().Rotation
		end

		local baseTransform = follower:Origin()
		local useRelative = follower:UseOriginRotation()
		if useRelative and baseTransform then
			targetCFrame *= baseTransform.Rotation
		end

		local current = instance:GetPivot()

		local cx, cy, cz = current.Position.X, current.Position.Y, current.Position.Z
		local tx, ty, tz = targetCFrame.Position.X, targetCFrame.Position.Y, targetCFrame.Position.Z

		local rx, ry, rz = current:ToOrientation()
		local trx, try, trz = targetCFrame:ToOrientation()

		if not follower:UseXPosition() then tx = cx end
		if not follower:UseYPosition() then ty = cy end
		if not follower:UseZPosition() then tz = cz end

		if not follower:UseXRotation() then trx = rx end
		if not follower:UseYRotation() then try = ry end
		if not follower:UseZRotation() then trz = rz end

		targetCFrame = CFrame.new(tx, ty, tz) * CFrame.fromOrientation(trx, try, trz)

		if follower:Smooth() then
			local responsiveness = follower:Responsiveness()
			if responsiveness ~= 0 then
				targetCFrame = instance.CFrame:Lerp(targetCFrame, 1 - math.exp(-deltaTime / responsiveness))
			end
		end

		table.insert(bulkInstances, instance)
		table.insert(bulkCFrames, targetCFrame)
		shouldBulkMove = true
	end

	if shouldBulkMove then Workspace:BulkMoveTo(bulkInstances, bulkCFrames) end
end

return Follower
