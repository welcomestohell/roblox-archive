local Players = game:GetService("Players")

local Log = require("@libs/Log")
local input = require("@libs/combat/input")
local prvd = require("@shared/prvdmwrong/prvdmwrong")

local WeaponsProvider = {}
export type WeaponsProvider = typeof(WeaponsProvider)
WeaponsProvider.log = Log.new(WeaponsProvider)

function WeaponsProvider.onStart(self: WeaponsProvider)
	local context = input.new("test")

	context.Priority = 1000
	context.Parent = Players.LocalPlayer.PlayerGui

	local jump = context:CreateAction("Jump"):AddBinding("Keyboard", Enum.KeyCode.Space)

	jump:OnPressed(function(state)
		self.log:trace("Jump Pressed! State:", state)
	end)
		:OnReleased(function(state)
			self.log:trace("Jump released! State:", state)
		end)
		:OnStateChanged(function(state)
			self.log:trace("Jump state changed! State:", state)
		end)
end

function WeaponsProvider.onFinish() end

return prvd(WeaponsProvider)
