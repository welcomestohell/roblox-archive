local character = require("@libs/character")
local types = require("../types")

local HumanoidStateChanged = {} :: types.ActivationMode

function HumanoidStateChanged.implement(ctx: types.ActivationContext)
	local humanoid = character.getHumanoid()
	ctx.activationLife:add(
		humanoid.StateChanged:Connect(function(_: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
			if new == ctx.attributes.HumanoidStateType(ctx.instanceConfiguration) then
				ctx:onActivate()
			end
		end)
	)
end

return HumanoidStateChanged
