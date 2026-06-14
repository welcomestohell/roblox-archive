local SoundService = game:GetService "SoundService"

local Attribute = require "@libs/attributes/Attribute"
local flattenAssetPaths = require "@core/shared/assets/flattenAssetPaths"
local gt = require "@libs/vendor/gt"
local logger = require "@core/shared/logger"
local requireAssetModules = require "@core/shared/assets/requireAssetModules"
local threadpool = require "./threadpool"

const SOUND_FROM_ASSET_TAG = "Emission: Sound From Asset"

const Delay = Attribute.new("Delay", gt.positiveNumber, 0)
const GlobalSound = Attribute.new("GlobalSound", gt.boolean(), false)

const assetPaths = flattenAssetPaths(requireAssetModules())
logger:Debug("Asset paths:", assetPaths)

const function emit(instance: Instance)
	task.wait(Delay(instance))

	if instance:IsA "ParticleEmitter" then instance:Emit(instance.Rate) end

	if instance:HasTag(SOUND_FROM_ASSET_TAG) and instance:IsA "StringValue" then
		logger:Debug("Got sound from asset:", instance)
		const soundId = assetPaths[instance.Value]
		if not soundId then
			logger:Warn("Unknown asset:", instance.Value)
			return
		end

		const sound = Instance.new "Sound"
		sound.Name = instance.Value
		sound.Parent = GlobalSound(sound) and SoundService or instance.Parent
		sound.Ended:Connect(function() sound:Destroy() end)
		sound:Play()
	end
end

const function emitTaggedDescendants(parent: Instance, tag: string)
	for _, descendant in parent:GetDescendants() do
		if descendant:HasTag(tag) then threadpool.spawn(emit, descendant) end
	end
end

return table.freeze {
	Delay = Delay,

	emit = emit,
	emitTaggedDescendants = emitTaggedDescendants,
}
