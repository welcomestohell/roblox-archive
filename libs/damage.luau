local RunService = game:GetService("RunService")

local Mechanic = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("Mechanic"))
local gt = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("gt"))

local attribute = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("Attribute"))
local character = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("character"))

local damage = {}

function damage.useAttributes(mechanic: Mechanic.MechanicImplementationLike): attribute.Attribute<number>
	return mechanic:attribute("Damage", gt.number(), 20)
end

function damage.damagePlayer(player: Player, damage: number): boolean
	if not player or not damage then
		return false
	end

	local char = character.getMaybeCharacter(player)

	if char == nil then
		return false
	end

	local humanoid = char:FindFirstChild("Humanoid")

	if not humanoid or not humanoid:IsA("Humanoid") or humanoid.Health <= 0 then
		return false
	end

	if RunService:IsServer() then
		humanoid:TakeDamage(damage)
	elseif RunService:IsClient() then
		local net = require("@core/client/generated/net")

		net.damage.fire(damage)
	end

	return true
end

return table.freeze(damage)
