const Level = require "@libs/core/Level"
const sounds = require "@libs/sounds"
const std = require "@libs/std"
const assets = require "@core/assets"
const Promise = require "@roblox_packages/Promise"

local BoxSpawner = std.Mechanic {}
export type BoxSpawnerMechanic = std.Mechanic<typeof(BoxSpawner), { template: PVInstance, boxLife: std.Life? }>
BoxSpawner.mechanicName = "BoxSpawner"
BoxSpawner.instanceType = std.gt.instanceTree {
	Button = std.isA.BasePart(),
	Box = std.isA.PVInstance(),
	Spawn = std.isA.BasePart(),
}
BoxSpawner.debuggerEmoji = "📦"

BoxSpawner.Cooldown = BoxSpawner:attribute("Cooldown", std.gt.positiveNumber, 0)
BoxSpawner.Debounced = BoxSpawner:attribute("Debounced", std.gt.boolean(), false)
BoxSpawner.SpawnOnStart = BoxSpawner:attribute("SpawnOnStart", std.gt.boolean(), false)

BoxSpawner.AnchoredTag = BoxSpawner:attribute("AnchoredTag", std.gt.string(), "Box: Anchored")

BoxSpawner:attributeSection "Activation"
BoxSpawner.Activation = std.useActivation(BoxSpawner)

BoxSpawner:attributeSection "Sound"
BoxSpawner.Sound = std.useSound(BoxSpawner)

function BoxSpawner.spawn(spawner: BoxSpawnerMechanic, level: std.Level)
	if spawner.boxLife then spawner.boxLife:destroy() end

	local boxLife = spawner.life:extend()
	spawner.boxLife = boxLife

	local box = boxLife:add(spawner.template:Clone())
	box.Parent = spawner.instance
	box:PivotTo(spawner.instance.Spawn.CFrame)

	local anchoredTag = spawner:AnchoredTag()

	local descendants = box:GetDescendants()
	table.insert(descendants, box)
	for _, descendant in descendants do
		descendant:AddTag "Box"
		if descendant:IsA "BasePart" and not descendant:HasTag(anchoredTag) then descendant.Anchored = false end
	end

	local instancePromises, loadPromises = level:loadDescendantInstancesAsync(box)
	Promise.all(instancePromises):await()
	Promise.all(loadPromises):await()
end

function BoxSpawner:getActivationInstance(spawner: BoxSpawnerMechanic) return spawner.instance.Button end

function BoxSpawner.onActivate(self: typeof(BoxSpawner), spawner: BoxSpawnerMechanic, level: std.Level)
	if spawner:Debounced() then return end

	spawner:Debounced(true)
	spawner.Activation.Enabled(spawner, false)

	spawner:spawn(level)
	sounds.playMechanic(self.Sound, spawner :: any, assets.sfx.button)

	spawner.life:delay(spawner:Cooldown(), function(spawner: BoxSpawnerMechanic)
		spawner:Debounced(false)
		spawner.Activation.Enabled(spawner, true)
	end, spawner)
end

function BoxSpawner:onStart(spawner: BoxSpawnerMechanic, level: std.Level)
	-- BoxSpawner is already loaded by the time this is called. We add the tag
	-- here so spawned boxes don't automatically load until we're done
	-- intializing them.
	spawner.instance:AddTag(Level.DO_NOT_LOAD_TAG)

	spawner.template = spawner.instance.Box
	spawner.template.Parent = nil

	spawner.life:add(spawner.template)

	if spawner:SpawnOnStart() then spawner:spawn(level) end
end

return BoxSpawner
