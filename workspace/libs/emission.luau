const SoundService = game:GetService "SoundService"

const Attribute = require "@libs/attributes/Attribute"
const gt = require "@libs/vendor/gt"
const threadpool = require "./threadpool"

const emission = {
	Delay = Attribute.new("Delay", gt.positiveNumber, 0),

	Volume = Attribute.new("Volume", gt.positiveNumber, 0.5),
	PlaybackSpeed = Attribute.new("PlaybackSpeed", gt.positiveNumber, 1),
	PlaybackRegionsEnabled = Attribute.new("PlaybackRegionsEnabled", gt.boolean(), false),
	PlaybackRegion = Attribute.new("PlaybackRegion", gt.NumberRange, NumberRange.new(0, 60000)),
	RollOffMode = Attribute.new("RollOffMode", gt.enumOf(Enum.RollOffMode), Enum.RollOffMode.InverseTapered),
	RollOffMinDistance = Attribute.new("RollOffMinDistance", gt.positiveNumber, 10000),
	RollOffMaxDistance = Attribute.new("RollOffMinDistance", gt.positiveNumber, 10),
	PlaybackSpatial = Attribute.new("PlaybackSpatial", gt.boolean(), true),
}

function emission.emit(instance: Instance)
	if instance:IsA "ParticleEmitter" then instance:Emit(instance.Rate) end

	if instance:IsA "Sound" then
		const sound = instance:Clone()
		sound.Volume = emission.Volume:peek(instance) or sound.Volume
		sound.PlaybackSpeed = emission.PlaybackSpeed:peek(instance) or sound.PlaybackSpeed
		sound.PlaybackRegionsEnabled = emission.PlaybackRegionsEnabled:peek(instance) or sound.PlaybackRegionsEnabled
		sound.PlaybackRegion = emission.PlaybackRegion:peek(instance) or sound.PlaybackRegion
		sound.RollOffMode = emission.RollOffMode:peek(instance) or sound.RollOffMode
		sound.RollOffMinDistance = emission.RollOffMinDistance:peek(instance) or sound.RollOffMinDistance
		sound.RollOffMaxDistance = emission.RollOffMaxDistance:peek(instance) or sound.RollOffMaxDistance
		sound.PlayOnRemove = true
		sound.Parent = emission.PlaybackSpatial:peek(instance) and instance.Parent or SoundService

		sound:Destroy()
	end
end

function emission.emitTaggedDescendants(parent: Instance, tag: string)
	for _, descendant in parent:GetDescendants() do
		if descendant:HasTag(tag) then threadpool.spawn(emission.emit, descendant) end
	end
end

return table.freeze(emission)
