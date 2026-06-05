local ContentProvider = game:GetService "ContentProvider"
local Players = game:GetService "Players"

local Fluid = require "@roblox_packages/Fluid"
local LoadingScreen = require "@core/ui/components/screens/LoadingScreen"
local assets = require "@core/assets"
local flattenAssetModules = require "@core/shared/assets/flattenAssetModules"
local net = require "@core/client/generated/net"
local prvd = require "@prvdmwrong/prvdmwrong"
local useDelay = require "@core/shared/fluid/useDelay"

local PreloadProvider = {}
export type PreloadProvider = typeof(PreloadProvider)

function PreloadProvider.onStart(self: PreloadProvider)
	Fluid.root(function()
		local loadingMessage = Fluid.source "Preparing"
		local isLoading = Fluid.source(true)

		Fluid.cleanup(task.spawn(function()
			loadingMessage "Awaiting server"
			local assetIds: { string }
			repeat
				assetIds = net.fetchAssetIds.invoke():expect() :: { string }
			until assetIds
			flattenAssetModules(assetIds)

			local assetsLoaded = 0
			ContentProvider:PreloadAsync(assetIds, function(assetId, fetchStatus: Enum.AssetFetchStatus)
				assetsLoaded += 1
				loadingMessage(`{assetsLoaded}/{#assetIds} assets`)
			end)

			if not Players.LocalPlayer.Character then
				loadingMessage "Awaiting character"
				Players.LocalPlayer.CharacterAdded:Wait()
			end

			loadingMessage "Finishing up"
			isLoading(false)
		end))

		Fluid.create "ScreenGui" {
			Name = "LoadingUI",
			IgnoreGuiInset = true,
			ResetOnSpawn = true,
			Parent = Players.LocalPlayer:WaitForChild "PlayerGui",

			Enabled = useDelay<<boolean>>(1, isLoading),

			LoadingScreen {
				visible = isLoading,
				label = loadingMessage,
				title = _G.WTH_PLACE_SUBTITLE or _G.WTH_PLACE_TITLE,
				imageId = assets.placeholder,
			},
		}
	end)
end

return prvd(PreloadProvider)
