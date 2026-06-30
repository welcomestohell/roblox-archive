const std = require "@libs/std"

const ConsistentParticleEmitter = std.Mechanic {
	emoji = "🫧",
	name = "ConsistentParticleEmitter",
	description = "Emits it's ParticleEmitter at it's rate regardless of graphics level.",
	instanceType = std.isA.ParticleEmitter(),

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Rate = std.Attribute("Rate", std.gt.positiveNumber, 0),

	previousGraphicsLevel = std.LevelState(-1),
	fixedEmitters = std.LevelTable<<Mechanic, true>>(),
}

export type Implementation = typeof(ConsistentParticleEmitter)
export type Mechanic = std.Mechanic<Implementation>

function ConsistentParticleEmitter.onPreRender(self: Implementation, deltaTime: number, level: std.Level)
	const graphicsLevel = UserSettings().GameSettings.SavedQualityLevel.Value
	const isGraphicsLevelChanged = graphicsLevel == self.previousGraphicsLevel:get(level)
	self.previousGraphicsLevel:set(level, graphicsLevel)

	for _, emitter: Mechanic in level:getMechanics(self) do
		if isGraphicsLevelChanged or not self.fixedEmitters:index(level, emitter) then
			local rate = emitter.Rate:getOrSet(emitter, emitter.instance.Rate)
			emitter.instance.Rate = rate * 10 / graphicsLevel
			self.fixedEmitters:set(level, emitter, true :: true)
		end
	end
end

return ConsistentParticleEmitter
