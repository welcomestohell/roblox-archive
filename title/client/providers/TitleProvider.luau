local Players = game:GetService "Players"
local StarterGui = game:GetService "StarterGui"

local FireworksLogo = require "@core/ui/components/branding/FireworksLogo"
local Fluid = require "@roblox_packages/Fluid"
local LoadingScreen = require "@core/ui/components/screens/LoadingScreen"
local prvd = require "@prvdmwrong/prvdmwrong"
local useRem = require "@core/shared/fluid/useRem"

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

		Fluid.cleanup(task.delay(2, ready, true))

		return {
			Fluid.create "ScreenGui" {
				Name = "TitleGui",
				ResetOnSpawn = false,
				IgnoreGuiInset = true,

				LoadingScreen {
					label = "Loading",
					title = "67/256 Assets",
					visible = true,
				},
			},
		}
	end, Players.LocalPlayer.PlayerGui)
end

return prvd(TitleProvider)
