local Log = require("@libs/Log")
local input = require("@shared/combat/input")
local prvd = require("@shared/prvdmwrong/prvdmwrong")

local WeaponsProvider = {}

export type WeaponsProvider = typeof(WeaponsProvider)

WeaponsProvider.log = Log.new(WeaponsProvider)
WeaponsProvider.inputManager = input.new()

-- is it worth using prvd lifecycles here??
-- are they even a thing with this version of prvd
function WeaponsProvider.onClick(self: WeaponsProvider)
	print("evil click of doom and despair")
end

function WeaponsProvider.onStart(self: WeaponsProvider)
	print(1)

	local context = self.inputManager:createContext({
		identifier = "combat",
	})

	print(2)

	if not context then
		return
	end

	print(3)

	local action = self.inputManager:attachAction({
		identifier = "action",
		actionType = Enum.InputActionType.Bool,

		pressed = function()
			self:onClick()
		end,
	}, {
		context = context,
	})

	print(4)

	if not action then
		return
	end

	print(5)

	-- this gives me rust ptsd
	local _ = self.inputManager:attachBinding({
		identifier = "binding",
		keybind = Enum.KeyCode.F,
	}, {
		context = context,
		action = action,
	})

	print(6)
end

return prvd(WeaponsProvider)
