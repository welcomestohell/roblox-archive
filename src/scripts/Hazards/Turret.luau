local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local character = require("@libs/character")
local std = require("@libs/std")

local Turret = std.Mechanic({})
export type TurretMechanic = std.Mechanic<typeof(Turret)>

Turret.instanceTag = "Turret"
Turret.instanceType = std.gt.instanceTree(std.isA.Model(), { Base = std.isA.Part(), Bullet = std.isA.Part() })
Turret.debuggerEmoji = "🔫"

Turret.Enabled = Turret:withEnabled()

Turret:attributeSection("Bullets")
Turret.Firerate = Turret:attribute("Firerate", std.gt.number(), 5)
Turret.Speed = Turret:attribute("Speed", std.gt.number(), 25)
Turret.Acceleration = Turret:attribute("Acceleration", std.gt.number(), Vector3.zero)
Turret.Lifetime = Turret:attribute("Lifetime", std.gt.number(), 2)
Turret.DestroyOnTouch = Turret:attribute("DestroyOnTouch", std.gt.boolean(), true)

Turret:attributeSection("Spread Angle")
Turret.MinSpread = Turret:attribute("MinSpread", std.gt.number(), 0)
Turret.MaxSpread = Turret:attribute("MaxSpread", std.gt.number(), 0)

Turret:attributeSection("Culling")
Turret.Range = Turret:attribute("Range", std.gt.number(), 50)

function Turret.onTouch(turret: TurretMechanic, hit: Part): boolean
	if not hit or not hit.Parent or not character.isFromMaybeCharacter(hit) then
		return false
	end

	-- it should be safe to damage player here

	return true
end

function Turret.calculateSpreadAngle(turret: TurretMechanic, direction: Vector3): Vector3
	local maxSpread, minSpread = turret:MaxSpread(), turret:MinSpread()

	local directionCFrame = CFrame.new(Vector3.zero, direction)
	local spreadDirection = CFrame.fromOrientation(0, 0, math.random(0, math.pi * 2))
	local spreadAngle = CFrame.fromOrientation(math.rad(math.random(minSpread, maxSpread)), 0, 0)

	return (directionCFrame * spreadDirection * spreadAngle).LookVector
end

function Turret.fireBullet(turret: TurretMechanic, bulletTemplate: Part)
	local instance = turret.instance
	local primaryPart = instance.PrimaryPart

	if not primaryPart then
		return
	end

	local bulletScope = turret.life:inner()
	local bulletInstance = bulletScope:add(bulletTemplate:Clone())

	local function cleanup()
		bulletScope:destroy()
	end

	local spawnCFrame: CFrame = primaryPart.CFrame
	local spreadAngle = turret:calculateSpreadAngle(spawnCFrame.LookVector)

	bulletInstance.CFrame = spawnCFrame

	local mainAttachment = bulletInstance:FindFirstChildOfClass("Attachment")
	local linearVelocity = bulletInstance:FindFirstChildOfClass("LinearVelocity")

	if not mainAttachment or not linearVelocity then
		cleanup()

		return
	end

	local finalCFrame = CFrame.lookAt(spawnCFrame.Position, spawnCFrame.Position + spreadAngle)

	linearVelocity.Attachment0 = mainAttachment
	linearVelocity.VectorVelocity = finalCFrame.LookVector * turret:Speed()

	local alignOrientation = bulletInstance:FindFirstChildOfClass("AlignOrientation")

	if not alignOrientation then
		cleanup()

		return
	end

	alignOrientation.Attachment0 = mainAttachment
	alignOrientation.CFrame = primaryPart.CFrame.Rotation

	bulletInstance.Anchored = false
	bulletInstance.Parent = instance

	bulletScope:connect(bulletInstance.Touched, function(hit: Part)
		local destroyOnTouch = turret:DestroyOnTouch()
		local validHit = turret:onTouch(hit)

		if destroyOnTouch and validHit then
			cleanup()
		end
	end)

	bulletScope:add(task.spawn(function()
		task.wait(turret:Lifetime())

		cleanup()
	end))
end

function Turret.onStart(self: typeof(Turret), turret: TurretMechanic, level: std.Level)
	local instance = turret.instance
	local primaryPart = instance.PrimaryPart

	local bulletTemplate = instance:FindFirstChild("Bullet")

	if not bulletTemplate or not primaryPart then
		return
	end

	bulletTemplate.Parent = nil

	turret.life:add(task.spawn(function()
		while turret.life:isAlive() do
			local firerate = turret:Firerate()
			-- local enabled = turret:Enabled()
			local enabled = true

			task.wait(1 / firerate)

			if not enabled then
				continue
			end

			local distance = localPlayer:DistanceFromCharacter(primaryPart.Position)
			local range = turret:Range()

			if distance <= range then
				turret:fireBullet(bulletTemplate)
			end
		end
	end))
end

return Turret
