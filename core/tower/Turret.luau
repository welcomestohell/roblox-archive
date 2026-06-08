local Players = game:GetService "Players"

local std = require "@libs/std"

local assets = require "@core/assets"
local character = require "@libs/character"
local damage = require "@libs/damage"
local emission = require "@libs/emission"
local gt = require "@roblox_packages/gt"
local sounds = require "@libs/sounds"

--[=[
	@class Turret
	@tag Mechanic

	Turret continously shoot bullets based on its current orientation.
]=]
local Turret = std.Mechanic {}
export type TurretMechanic = std.Mechanic<typeof(Turret)>

Turret.mechanicName = "Turret"
Turret.instanceType = std.gt.instanceTree(std.isA.Model(), {
	Bullet = std.gt.instanceTree(std.isA.BasePart(), {
		BulletAttachment = std.isA.Attachment(),
		BulletAlignOrientation = std.isA.AlignOrientation(),
		BulletVelocity = std.isA.LinearVelocity(),
	}),
})
Turret.debuggerEmoji = "🔫"

Turret.Enabled = Turret:attribute("Enabled", std.gt.boolean(), true)

Turret:attributeSection "Bullets"
Turret.Firerate = Turret:attribute("Firerate", std.gt.positiveNumber, 1)
Turret.Speed = Turret:attribute("Speed", std.gt.positiveNumber, 25)
Turret.Acceleration = Turret:attribute("Acceleration", std.gt.Vector3(), Vector3.zero)
Turret.Lifetime = Turret:attribute("Lifetime", std.gt.positiveNumber, 2)
Turret.DestroyOnTouch = Turret:attribute("DestroyOnTouch", std.gt.boolean(), true)

Turret:attributeSection "Damage"
Turret.Damage = damage.useAttributes(Turret)
Turret.Cooldown = Turret:attribute("Cooldown", std.gt.positiveNumber, 0.5)

Turret:attributeSection "Spread Angle"
Turret.SpreadAngle = Turret:attribute("SpreadAngle", std.gt.NumberRange, NumberRange.new(0, 0))

Turret:attributeSection "Sound"
Turret.FireSound = sounds.useAttributes(Turret, "FireSound")

Turret:attributeSection "Culling"
Turret.Range = Turret:attribute("Range", std.gt.positiveNumber, 50)

Turret:attributeSection "Tags"
Turret.IgnoreTag = Turret:attribute("IgnoreTag", std.gt.string(), "Turret: Ignore")
Turret.EmitFireTag = Turret:attribute("EmitFireTag", gt.string(), "Turret: On Fire")
Turret.EmitTouchTag = Turret:attribute("EmitTouchTag", gt.string(), "Turret: On Touch")
Turret.EmitExpireTag = Turret:attribute("EmitExpireTag", gt.string(), "Turret: On Expire")

Turret.cooldowns = {} :: { [Player]: number }

function Turret.onTouch(turret: TurretMechanic, hit: BasePart): boolean
	if not hit or not hit.Parent or not character.isFromMaybeCharacter(hit) then
		return false
	end

	local player = character.getPlayerFromHit(hit)

	if not player then
		return false
	end

	local turretDamage, turretCooldown = turret:Damage(), turret:Cooldown()
	local cooldowns = turret.cooldowns

	local now = os.clock()

	if cooldowns[player] and cooldowns[player] > now then
		return false
	end

	cooldowns[player] = now + turretCooldown
	damage.damagePlayer(player, turretDamage)

	return true
end

function Turret.calculateSpreadAngle(turret: TurretMechanic, direction: Vector3): Vector3
	local spreadAngle: NumberRange = turret:SpreadAngle()

	local directionCFrame = CFrame.new(Vector3.zero, direction)
	local spreadDirection = CFrame.fromOrientation(0, 0, math.random() * math.tau)
	local spreadAngle =
		CFrame.fromOrientation(math.rad(spreadAngle.Min + math.random() * (spreadAngle.Max - spreadAngle.Min)), 0, 0)

	return (directionCFrame * spreadDirection * spreadAngle).LookVector
end

function Turret.fireBullet(turret: TurretMechanic, bulletTemplate: Part)
	local instance = turret.instance
	local primaryPart = instance.PrimaryPart

	if not primaryPart then
		return
	end

	if turret.FireSound.Play(turret) then
		sounds.playInstance(turret.FireSound, instance, turret.instanceConfiguration, assets.sfx.tick)
	end

	emission.emitTaggedDescendants(instance, turret:EmitFireTag())

	local bulletLife = turret.life:extend()
	local bulletInstance = bulletLife:add(bulletTemplate:Clone())
	bulletInstance.Massless = true

	local function cleanup(isTouch: boolean?)
		emission.emitTaggedDescendants(
			bulletInstance,
			if isTouch then turret:EmitTouchTag() else turret:EmitExpireTag()
		)
		bulletLife:destroy()
	end

	local spawnCFrame: CFrame = primaryPart.CFrame
	local spreadAngle = turret:calculateSpreadAngle(spawnCFrame.LookVector)

	bulletInstance.CFrame = spawnCFrame

	local mainAttachment = bulletInstance:FindFirstChildOfClass "Attachment"
	local linearVelocity = bulletInstance:FindFirstChildOfClass "LinearVelocity"
	local alignOrientation = bulletInstance:FindFirstChildOfClass "AlignOrientation"

	if not mainAttachment or not linearVelocity or not alignOrientation then
		return cleanup()
	end

	local finalCFrame = CFrame.lookAt(spawnCFrame.Position, spawnCFrame.Position + spreadAngle)

	linearVelocity.Attachment0 = mainAttachment
	linearVelocity.VectorVelocity = finalCFrame.LookVector * turret:Speed()
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.MaxForce = math.huge

	alignOrientation.Attachment0 = mainAttachment
	alignOrientation.CFrame = primaryPart.CFrame.Rotation

	bulletInstance.Anchored = false
	bulletInstance.Parent = instance

	bulletLife:add(bulletInstance.Touched:Connect(function(hit)
		local destroyOnTouch = turret:DestroyOnTouch()
		local validHit = turret:onTouch(hit)

		if destroyOnTouch and hit ~= turret.instance :: Instance or validHit then
			-- cleanup(true)
		end
	end))

	bulletLife:delay(turret:Lifetime(), cleanup, nil)
end

function Turret.onStart(self: typeof(Turret), turret: TurretMechanic, level: std.Level)
	local instance = turret.instance
	local primaryPart = instance.PrimaryPart

	if not primaryPart then
		turret.log:error("Turret", instance:GetFullName(), "is missing the PrimaryPart.")

		return
	end

	local bulletTemplate = turret.life:add(instance.Bullet)
	bulletTemplate.Parent = nil

	turret.life:spawn(function()
		while turret.life.destroyed == false do
			local firerate = turret:Firerate()
			local enabled = turret:Enabled()

			task.wait(1 / firerate)

			if not enabled then
				continue
			end

			local distance = Players.LocalPlayer:DistanceFromCharacter(primaryPart.Position)
			local range = turret:Range()

			if distance <= range then
				turret:fireBullet(bulletTemplate)
			end
		end
	end)
end

return Turret
