const std = require "@libs/std"
const Oklab = require "@libs/vendor/Oklab"

const Fountain = std.Mechanic {
	emoji = "☀️",
	name = "Fountain",
	description = "Hello, Welcome To Hell!",
	instanceType = std.gt.instanceTree {
		Base = std.isA.BasePart(),
	},
}

export type FountainMechanic = std.Mechanic<typeof(Fountain), {
	effects: { [Beam | ParticleEmitter]: true },
	lights: { [Light]: true },
}>

const CYCLE_DURATION_SECONDS = 10

function Fountain.onStart(self: typeof(Fountain), fountain: FountainMechanic, level: std.Level)
	fountain.effects = {}
	fountain.lights = {}

	for _, descendant in fountain.instance:GetDescendants() do
		if descendant:IsA "Beam" or descendant:IsA "ParticleEmitter" then
			fountain.effects[descendant] = true
		elseif descendant:IsA "Light" then
			fountain.lights[descendant] = true
		end
	end
end

function Fountain.onPreRender(self: typeof(Fountain), fountain: FountainMechanic, level: std.Level)
	const lifetime = level:getLifetime()
	const progress = lifetime % CYCLE_DURATION_SECONDS / CYCLE_DURATION_SECONDS

	const effectColor = ColorSequence.new(Oklab.oklchToColor3(Vector3.new(0.25, 0.05, progress)))
	const lightColor = Oklab.oklchToColor3(Vector3.new(0.5, 0.2, progress))

	for _, fountain: FountainMechanic in level:getMechanics(self) do
		for effect in fountain.effects do
			effect.Color = effectColor
		end

		for light in fountain.lights do
			light.Color = lightColor
		end
	end
end

return Fountain
