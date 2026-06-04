local ContentProvider = game:GetService "ContentProvider"
local Players = game:GetService "Players"

local Fluid = require "@roblox_packages/Fluid"
local LoadingScreen = require "@core/ui/components/screens/LoadingScreen"
local collectAssets = require "@core/shared/assets/collectAssets"
local flattenAssetIds = require "@core/shared/assets/flattenAssetIds"
local net = require "@core/client/generated/net"
local prvd = require "@prvdmwrong/prvdmwrong"
local useDelay = require "@core/shared/fluid/useDelay"

local PreloadProvider = {}
export type PreloadProvider = typeof(PreloadProvider)

function PreloadProvider.onStart(self: PreloadProvider)
	Fluid.root(function()
		local loadingMessage = Fluid.source "Awaiting server"
		local isLoading = Fluid.source(true)

		Fluid.cleanup(task.spawn(function()
			local assetIds: { string }
			repeat
				assetIds = net.fetchAssetIds.invoke():expect() :: { string }
			until assetIds

			local assetModules = collectAssets()
			for _, assets in assetModules do
				local ids = flattenAssetIds(assets)
				table.move(ids, 1, #ids, #assetIds + 1, assetIds)
			end

			local assetsLoaded = 0
			ContentProvider:PreloadAsync(assetIds, function(assetId, fetchStatus: Enum.AssetFetchStatus)
				print(Enum.AssetFetchStatus.Success)
				assetsLoaded += 1
				loadingMessage(`{assetsLoaded}/{#assetIds} assets`)
			end)

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
				title = "A Star Upon A Child",
			},
		}
	end)
end

return prvd(PreloadProvider)
