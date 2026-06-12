const Players = game:GetService "Players"

const useAtom = require "@core/shared/fluid/useAtom"
const useRem = require "@core/shared/fluid/useRem"
const Padding = require "@core/ui/components/base/Padding"
const TimerStack = require "@core/ui/components/hud/TimerStack"
const timers = require "@libs/timers"
const Fluid = require "@roblox_packages/Fluid"
const prvd = require "@roblox_packages/prvd"

local GuiProvider = {}
export type GuiProvider = typeof(GuiProvider)

function GuiProvider.onStart(self: GuiProvider)
	self.unmount = Fluid.root(function()
		const rem = useRem()

		Fluid.create "ScreenGui" {
			Name = "HeadsUpGui",
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

			Parent = Players.LocalPlayer:WaitForChild "PlayerGui",

			Padding { all = useRem():intoUdim(1) },

			Fluid.create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = rem:intoUdim(0.5),
			},

			TimerStack { timers = useAtom(timers.store) },
		}
	end)
end

function GuiProvider.onStop(self: GuiProvider) self.unmount() end

return prvd(GuiProvider)
