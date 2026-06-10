local ContentProvider = game:GetService "ContentProvider"
local Players = game:GetService "Players"
local SoundService = game:GetService "SoundService"
local StarterGui = game:GetService "StarterGui"

local FireworksSplash = require "@title/ui/components/splashes/FireworksSplash"
local Fluid = require "@roblox_packages/Fluid"
local LoadingScreen = require "@core/ui/components/screens/LoadingScreen"
local TitleScreen = require "@title/ui/components/title/TitleScreen"
local collectAssets = require "@core/shared/assets/collectAssets"
local coreAssets = require "@core/assets"
local flattenAssetIds = require "@core/shared/assets/flattenAssetIds"
local prvd = require "@roblox_packages/prvd"
local universeAssets = require "@universe/assets"
local useDelay = require "@core/shared/fluid/useDelay"
local useNextOrder = require "@core/shared/fluid/useNextOrder"
local useToggled = require "@core/shared/fluid/useToggled"

const DISABLED_CORE_GUIS = {
	Enum.CoreGuiType.All,
	-- Enum.CoreGuiType.AvatarSwitcher,
	-- Enum.CoreGuiType.Backpack,
	-- Enum.CoreGuiType.Captures,
	-- Enum.CoreGuiType.Chat,
	-- Enum.CoreGuiType.EmotesMenu,
	-- Enum.CoreGuiType.Health,
	-- Enum.CoreGuiType.PlayerList,
	-- Enum.CoreGuiType.SelfView,
}

const FIREWORKS_SPLASH_DURATION = 3

local TitleProvider = {}
export type TitleProvider = typeof(TitleProvider)

function TitleProvider.onStart(self: TitleProvider)
	task.spawn(function()
		local numDisabled = 0
		local disabledTypes = {}
		while numDisabled ~= #DISABLED_CORE_GUIS do
			for _, type in DISABLED_CORE_GUIS do
				if disabledTypes[type] then continue end

				if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, type, false) then
					disabledTypes[type] = true
					numDisabled += 1
				end
			end

			task.wait(0.5)
		end

		local disableSuccess = false
		repeat
			disableSuccess = pcall(StarterGui.SetCore, StarterGui, "ResetCallback", false)
			task.wait(0.5)
		until disableSuccess
	end)

	Fluid.root(function()
		local nextOrder = useNextOrder()

		local assetModules = collectAssets()
		local assetIds = {}
		for _, assets in assetModules do
			local ids = flattenAssetIds(assets)
			table.move(ids, 1, #ids, #assetIds + 1, assetIds)
		end

		local assetsLoaded = Fluid.source(0)
		local isAssetsLoading = Fluid.source(true)
		local isFireworksVisible = Fluid.source(false)
		Fluid.cleanup(task.spawn(ContentProvider.PreloadAsync, ContentProvider, assetIds, function()
			assetsLoaded(assetsLoaded() + 1)
			isAssetsLoading(assetsLoaded() ~= #assetIds)
			isFireworksVisible(assetsLoaded() == #assetIds)
		end))

		local isMenuVisible = useDelay<<boolean>>(FIREWORKS_SPLASH_DURATION + 2, isFireworksVisible)

		Fluid.create "Sound" {
			Name = "BackgroundMusic",
			Parent = SoundService,
			SoundId = universeAssets.ost.title,
			Looped = true,
			Volume = Fluid.spring(useToggled<<number>>(isMenuVisible, 1, 0), 15, 0.5),
			Playing = isMenuVisible,
		}

		Fluid.create "Sound" {
			Name = "Fireworks",
			Parent = SoundService,
			SoundId = coreAssets.sfx.speed,
			Volume = 0.5,
			Playing = useDelay<<boolean>>(2 / 3, isFireworksVisible),
		}

		Fluid.create "ScreenGui" {
			Name = "TitleGui",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,

			Parent = Players.LocalPlayer.PlayerGui,

			Fluid.show(isMenuVisible, function(): any return TitleScreen() end, function()
				return {
					LoadingScreen {
						label = "Loading",
						title = function() return `{assetsLoaded()}/{#assetIds} Assets` end,
						visible = isAssetsLoading,
						layoutOrder = nextOrder(),
					},

					FireworksSplash {
						visible = useDelay<<boolean>>(1, isFireworksVisible),
						layoutOrder = nextOrder(),
					},

					Fluid.create "Frame" {
						Name = "Cover",
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = Color3.new(),
						BackgroundTransparency = Fluid.spring(
							useToggled<<number>>(
								useDelay<<boolean>>(FIREWORKS_SPLASH_DURATION, isFireworksVisible),
								0,
								1
							),
							5,
							0.5
						),
						LayoutOrder = nextOrder(),
					},
				}
			end),
		}
	end)
end

return prvd(TitleProvider)
