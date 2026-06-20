const SoundService = game:GetService "SoundService"

local Attribute = require "@libs/attributes/Attribute"
local gt = require "@libs/vendor/gt"
local threadpool = require "./threadpool"

const Delay = Attribute.new("Delay", gt.positiveNumber, 0)

const Volume = Attribute.new("Volume", gt.positiveNumber, 0.5)
const PlaybackSpeed = Attribute.new("PlaybackSpeed", gt.positiveNumber, 1)
const PlaybackRegionsEnabled = Attribute.new("PlaybackRegionsEnabled", gt.boolean(), false)
const PlaybackRegion = Attribute.new("PlaybackRegion", gt.NumberRange, NumberRange.new(0, 60000))
const RollOffMode = Attribute.new("RollOffMode", gt.enumOf(Enum.RollOffMode), Enum.RollOffMode.InverseTapered)
const RollOffMinDistance = Attribute.new("RollOffMinDistance", gt.positiveNumber, 10000)
const RollOffMaxDistance = Attribute.new("RollOffMinDistance", gt.positiveNumber, 10)
const PlaybackSpatial = Attribute.new("PlaybackSpatial", gt.boolean(), true)

const function emit(instance: Instance)
	if instance:IsA "ParticleEmitter" then instance:Emit(instance.Rate) end

	if instance:IsA "Sound" then
		const sound = instance:Clone()
		sound.Volume = Volume:peek(instance) or sound.Volume
		sound.PlaybackSpeed = PlaybackSpeed:peek(instance) or sound.PlaybackSpeed
		sound.PlaybackRegionsEnabled = PlaybackRegionsEnabled:peek(instance) or sound.PlaybackRegionsEnabled
		sound.PlaybackRegion = PlaybackRegion:peek(instance) or sound.PlaybackRegion
		sound.RollOffMode = RollOffMode:peek(instance) or sound.RollOffMode
		sound.RollOffMinDistance = RollOffMinDistance:peek(instance) or sound.RollOffMinDistance
		sound.RollOffMaxDistance = RollOffMaxDistance:peek(instance) or sound.RollOffMaxDistance
		sound.PlayOnRemove = true
		sound.Parent = PlaybackSpatial:peek(instance) and instance.Parent or SoundService

		sound:Destroy()
	end
end

const function emitTaggedDescendants(parent: Instance, tag: string)
	for _, descendant in parent:GetDescendants() do
		if descendant:HasTag(tag) then threadpool.spawn(emit, descendant) end
	end
end

return table.freeze {
	Delay = Delay,

	Volume = Volume,
	PlaybackSpeed = PlaybackSpeed,
	PlaybackRegionsEnabled = PlaybackRegionsEnabled,
	PlaybackRegion = PlaybackRegion,
	RollOffMode = RollOffMode,
	RollOffMinDistance = RollOffMinDistance,
	RollOffMaxDistance = RollOffMaxDistance,
	PlaybackSpatial = PlaybackSpatial,

	emit = emit,
	emitTaggedDescendants = emitTaggedDescendants,
}
