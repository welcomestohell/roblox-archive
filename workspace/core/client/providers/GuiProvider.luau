local Players = game:GetService "Players"

local Padding = require "@core/ui/components/base/Padding"
local TimerStack = require "@core/ui/components/hud/TimerStack"
local timers = require "@libs/timers"
local Fluid = require "@pkgs/Fluid"
local Liquid = require "@pkgs/Liquid"
local prvd = require "@pkgs/prvd"

local GuiProvider = {}
export type GuiProvider = typeof(GuiProvider)

function GuiProvider.onStart(self: GuiProvider)
	self.unmount = Fluid.root(function()
		local rem = Liquid.useRem()

		Fluid.create "ScreenGui" {
			Name = "HeadsUpGui",
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

			Parent = Players.LocalPlayer:WaitForChild "PlayerGui",

			Padding { all = rem:intoUdim(1) },

			Fluid.create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = rem:intoUdim(0.5),
			},

			TimerStack { timers = Liquid.useAtom(timers.store) },
		}
	end)
end

function GuiProvider.onStop(self: GuiProvider)
	self.unmount()
end

return prvd(GuiProvider)
