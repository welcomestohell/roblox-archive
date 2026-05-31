local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local FireworksLogo = require("@core/ui/components/FireworksLogo")
local Fluid = require("@roblox_packages/Fluid")
local prvd = require("@prvdmwrong/prvdmwrong")
local useRem = require("@core/shared/fluid/useRem")

local TitleProvider = {}
export type TitleProvider = typeof(TitleProvider)

function TitleProvider.onStart(self: TitleProvider)
	task.spawn(function()
		while task.wait(1) do
			StarterGui:SetCore("ResetButtonCallback", false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.AvatarSwitcher, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Captures, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.ExperienceShop, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.SelfView, false)
		end
	end)

	Fluid.mount(function()
		local ready = Fluid.source(false)
		local rem = useRem()

		Fluid.cleanup(task.delay(2, ready, true))

		return {
			Fluid.create("ScreenGui")({
				Name = "TitleGui",
				ResetOnSpawn = false,
				IgnoreGuiInset = true,

				Fluid.create("Frame")({
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),

					Fluid.create("UIListLayout")({
						Padding = function()
							return UDim.new(0, rem(4))
						end,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),

					FireworksLogo({
						visible = ready,
						size = function()
							return UDim2.fromOffset(rem(64), rem(64))
						end,
						color = Color3.fromRGB(255, 255, 255),
					}),
				}),
			}),
		}
	end, Players.LocalPlayer.PlayerGui)
end

return prvd(TitleProvider)
