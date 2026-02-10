local attributes = require("@libs/activation/attributes")
local character = require("@libs/character")
local types = require("@libs/activation/types")

local HumanoidStateChanged = {} :: types.ActivationMode

function HumanoidStateChanged.implement(ctx: types.ActivationContext)
	local humanoid = character.getHumanoid()
	ctx.activationLife:add(
		humanoid.StateChanged:Connect(function(_: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
			if new == attributes.ActivationHumanoidStateType(ctx.instanceConfiguration) then
				ctx:onActivate()
			end
		end)
	)
end

return HumanoidStateChanged
