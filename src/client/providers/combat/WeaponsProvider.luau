local input = require("@libs/combat/input")
local prvd = require("@shared/prvdmwrong/prvdmwrong")

local WeaponsProvider = {}

function WeaponsProvider.onStart()
	print("weapons provider starting")

	local context = input.new("test")

	context.Priority = 1000
	context.Parent = game.Players.LocalPlayer.PlayerGui

	local jump = context:CreateAction("Jump"):AddBinding("Keyboard", Enum.KeyCode.Space)

	jump:OnPressed(function(state)
		print("Jump Pressed! State:", state)
	end)
		:OnReleased(function(state)
			print("Jump released! State:", state)
		end)
		:OnStateChanged(function(state)
			print("Jump state changed! State:", state)
		end)
end

function WeaponsProvider.onFinish() end

export type WeaponsProvider = typeof(WeaponsProvider)
return prvd(WeaponsProvider)
