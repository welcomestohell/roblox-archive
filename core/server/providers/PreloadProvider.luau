local Workspace = game:GetService "Workspace"

local net = require "@core/server/generated/net"
local prvd = require "@prvdmwrong/prvdmwrong"

local PreloadProvider = {}
export type PreloadProvider = typeof(PreloadProvider)
PreloadProvider.priority = -1
PreloadProvider.knownAssetIds = {}

function PreloadProvider.castMeshId(self: PreloadProvider, instance: Instance)
	return if instance:IsA "MeshPart"
			or (instance:IsA "SpecialMesh" and instance.MeshType == Enum.MeshType.FileMesh)
		then instance.MeshId
		else nil
end

function PreloadProvider.constructor(self: PreloadProvider)
	local assetIds = {}
	for _, descendant in Workspace:GetDescendants() do
		local meshId = self:castMeshId(descendant)
		if meshId and not self.knownAssetIds[meshId] then
			self.knownAssetIds[meshId] = true
			table.insert(assetIds, meshId)
		end
	end

	net.fetchAssetIds.on(function(player: Player) return assetIds end)
end

return prvd(PreloadProvider)
