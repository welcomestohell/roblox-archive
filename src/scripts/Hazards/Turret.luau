local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local std = require("@libs/std")

local Turret = std.Mechanic({})
export type TurretMechanic = std.Mechanic<typeof(Turret)>

Turret.instanceTag = "Turret"
Turret.instanceType = std.gt.instanceTree(std.isA.Part(), { Bullet = std.isA.Instance() })
Turret.debuggerEmoji = "🔫"

Turret.Enabled = Turret:withEnabled()

Turret:attributeSection("Bullets")
Turret.Firerate = Turret:attribute("Firerate", std.gt.number(), 1)
Turret.Speed = Turret:attribute("Speed", std.gt.number(), 5)
Turret.Acceleration = Turret:attribute("Acceleration", std.gt.number(), Vector3.zero)
Turret.Lifetime = Turret:attribute("Lifetime", std.gt.number(), 1)

Turret:attributeSection("Spread Angle")
Turret.MinSpread = Turret:attribute("MinSpread", std.gt.number(), 0)
Turret.MaxSpread = Turret:attribute("MaxSpread", std.gt.number(), 0)

Turret:attributeSection("Culling")
Turret.Range = Turret:attribute("Range", std.gt.number(), 50)

function Turret.calculateSpreadAngle(self: typeof(Turret), direction: Vector3): Vector3
	local maxSpread, minSpread = self:MaxSpread(), self:MinSpread()

	local directionCFrame = CFrame.new(Vector3.zero, direction)
	local spreadDirection = CFrame.fromOrientation(0, 0, math.random(0, math.pi * 2))
	local spreadAngle = CFrame.fromOrientation(math.rad(math.random(minSpread, maxSpread)), 0, 0)

	return (directionCFrame * spreadDirection * spreadAngle).LookVector
end

function Turret.fireBullet(turret: TurretMechanic, bulletTemplate: Part)
	print("firing bullet")

	local instance = turret.instance

	local bulletScope = turret.life:inner()
	local bulletInstance = bulletScope:add(bulletTemplate:Clone())

	local function cleanup()
		bulletScope:destroy()
	end

	local spawnCFrame: CFrame = instance.CFrame

	local spreadAngle = turret:calculateSpreadAngle(spawnCFrame.LookVector)
	local target = spawnCFrame * spreadAngle

	bulletInstance.CFrame = spawnCFrame

	local mainAttachment = bulletInstance:FindFirstChildOfClass("Attachment")
	local linearVelocity = bulletInstance:FindFirstChildOfClass("LinearVelocity")

	if not mainAttachment or not linearVelocity then
		cleanup()

		return
	end

	local spawnLV = spawnCFrame.Rotation
	local targetPosition = CFrame.new(target)

	local targetLV = spawnLV * CFrame.fromOrientation(targetPosition.X, targetPosition.Y, targetPosition.Z)

	linearVelocity.Attachment0 = mainAttachment
	linearVelocity.VectorVelocity = targetLV.LookVector * turret:Speed()

	local alignOrientation = bulletInstance:FindFirstChildOfClass("AlignOrientation")

	if not alignOrientation then
		cleanup()

		return
	end

	alignOrientation.Attachment0 = mainAttachment
	alignOrientation.CFrame = instance.CFrame.Rotation

	bulletInstance.Anchored = false
	bulletInstance.Parent = instance

	-- how are we handling damage?
	-- imo it should be something like this (below)
	--[[
        local damage = require("@libs/damage")
        local player = game.Players.LocalPlayer

        damage.damage(player, 50)
        damage.heal(player, 38.2)
    ]]

	bulletScope:add(function()
		task.wait(turret:Lifetime())

		cleanup()
	end)
end

function Turret.onStart(self: typeof(Turret), turret: TurretMechanic, level: std.Level)
	local instance = turret.instance
	local bulletTemplate = instance:FindFirstChild("Bullet")

	if not bulletTemplate then
		return
	end

	turret.life:add(task.spawn(function()
		local fallbackRate = 1

		while turret.life:isAlive() do
			local firerate = turret:Firerate() or fallbackRate

			-- local enabled = turret:Enabled()
			local enabled = true

			task.wait(1 / firerate)

			if not enabled then
				continue
			end

			local distance = localPlayer:DistanceFromCharacter(instance.Position)
			local range = turret:Range()

			if distance <= range then
				turret:fireBullet(bulletTemplate)
			end
		end
	end))
end

return Turret
