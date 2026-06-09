local Players = game:GetService "Players"

const logger = require "@core/shared/logger"
const Attribute = require "@libs/attributes/Attribute"
const tables = require "@libs/collections/tables"
const properties = require "@libs/properties"
local CullThrottle = require "@roblox_packages/CullThrottle"
local std = require "@libs/std"
const types = require "@libs/types"

--[=[
	@class Culled
	@tag Mechanic

	Culled disables instances and mechanics when they're far away or off-screen.
	Culled is best used for optimizing a tower, but the `Distance` culling mode
	can be used for gameplay.

	`Camera` culling guesses if the instance is on-screen using boatbomber's
	CullThrottle module. `Camera` culling is best for optimizing decoration
	mechanics, such as Flipbooks. It should not be used for gameplay.

	For performance, Culled does not include an `Enabled` attribute. To disable
	culling on an instance completely, remove the `Mechanic: Culled` tag on its
	configuration. Alternatively, enable culling by adding the
	`Mechanic: Culled` tag.
]=]
local Culled = std.Mechanic {}
export type CulledMechanic = std.Mechanic<typeof(Culled)>

Culled.mechanicName = "Culled"
Culled.instanceType = std.gt.union(
	std.isA.BasePart(),
	std.isA.Model(),
	std.isA.Bone(),
	std.isA.Attachment(),
	std.isA.Beam(),
	std.isA.PointLight(),
	std.isA.Sound()
)
Culled.debuggerEmoji = "👻"

Culled.Mode = Culled:attribute("Mode", std.gt.unionLiterals2("Distance", "Camera"), "Distance")
Culled.Distance = Culled:attribute("Distance", std.gt.NumberRange, NumberRange.new(0, math.huge))

Culled.UpdateAncestor = Culled:attribute("UpdateAncestor", std.gt.optional(std.gt.string()), nil)
Culled.UpdateDescendant = Culled:attribute("UpdateDescendant", std.gt.optional(std.gt.string()), nil)

-- Investigate: AttributeMap for properties? Or a PropertyToggler mechanic?
Culled.SetAnchored = Culled:attribute("SetAnchored", std.gt.boolean(), false)
Culled.SetEnabled = Culled:attribute("SetEnabled", std.gt.boolean(), false)
Culled.SetVisible = Culled:attribute("SetVisible", std.gt.boolean(), false)
Culled.SetMechanicsEnabled = Culled:attribute("SetMechanicsEnabled", std.gt.boolean(), false)

Culled.culler = std.LevelState(types.nilAs<<CullThrottle.CullThrottle>>())
Culled.distanceMechanics = std.LevelState<<{ CulledMechanic }>> {}
Culled.culledMechanics = std.LevelState<<{ CulledMechanic }>> {}
Culled.instanceToCulled = std.LevelState<<{ [Instance]: CulledMechanic }>> {}

function Culled.onInit(self: typeof(Culled), level: std.Level)
	self.culler:set(level, level.life:add(CullThrottle.new()))
	self.distanceMechanics:set(level, {} :: { CulledMechanic })
	self.culledMechanics:set(level, {} :: { CulledMechanic })
	self.instanceToCulled:set(level, tables.weak "k" :: { [Instance]: CulledMechanic })
end

function Culled.onStart(self: typeof(Culled), culled: CulledMechanic, level: std.Level)
	local distanceMechanics = self.distanceMechanics:get(level)

	local culler = self.culler:get(level)
	local culledMechanics = self.culledMechanics:get(level)
	local instanceToCulled = self.instanceToCulled:get(level)

	self.Mode:onBind(culled, function(mode)
		if mode == "Distance" then
			if culled.instance:IsA "PVInstance" then
				tables.findAndRemove(culledMechanics, culled)
				table.insert(distanceMechanics, culled)
				if culler._objects[culled.instance] then
					culler:RemoveObject(culled.instance)
					instanceToCulled[culled.instance] = nil
				end
				return
			end

			-- Investigate: Can't we yoink CullThrottle's ObjectDimensions?
			-- CullThrottle somehow supports more instances so...???
			logger:Warn(
				culled.instance:GetFullName(),
				"is not a BasePart and so cannot use Distance culling, falling back to Camera culling..."
			)
		end

		tables.findAndRemove(distanceMechanics, culled)
		table.insert(culledMechanics, culled)
		culler:AddObject(culled.instance)
		instanceToCulled[culled.instance] = culled
	end)
end

-- Investigate: We could track visibility on ie. a LevelState and only call
-- updateVisible when an instance's visibility has changed.
function Culled.updateVisible(culled: CulledMechanic, level: std.Level, isVisible: boolean)
	local target = culled:UpdateAncestor() and culled.instance:FindFirstAncestor(culled:UpdateAncestor())
		or culled:UpdateDescendant() and culled.instance:FindFirstChild(culled:UpdateDescendant(), true)
		or culled.instance

	if culled:SetAnchored() then
		pcall(properties.setUnsafe, target, "Anchored", isVisible)
	end

	if culled:SetEnabled() then
		pcall(properties.setUnsafe, target, "Enabled", isVisible)
	end

	if culled:SetVisible() then
		pcall(properties.setUnsafe, target, "Visible", isVisible)
	end

	if culled:SetMechanicsEnabled() and level.mechanicsByInstance[target] then
		for _, mechanic in level.mechanicsByInstance[target] do
			if mechanic == culled then
				continue
			end

			local enabled: std.Attribute<boolean>? = (mechanic :: any).Enabled
			if enabled and Attribute.isAttribute(enabled) then
				enabled(mechanic, isVisible)
			end
		end
	end
end

-- Investigate: EToH throttles this by 0.2 seconds. Couldn't we do the same?
function Culled.onPreRender(self: typeof(Culled), deltaTime: number, level: std.Level)
	-- Distance culling
	for _, culled: CulledMechanic in self.distanceMechanics:get(level) do
		local instance = culled.instance :: PVInstance

		local distance: NumberRange = culled:Distance()
		local distanceFromCharacter = Players.LocalPlayer:DistanceFromCharacter(instance:GetPivot().Position)
		culled:updateVisible(level, distanceFromCharacter >= distance.Min and distanceFromCharacter <= distance.Max)
	end

	-- Camera culling
	local culler = self.culler:get(level)
	local instanceToCulled = table.clone(self.instanceToCulled:get(level))
	for _, instance in culler:GetVisibleObjects() do
		instanceToCulled[instance]:updateVisible(level, true)
		instanceToCulled[instance] = nil
	end
	for _, culled: CulledMechanic in instanceToCulled do
		culled:updateVisible(level, false)
	end
end

return Culled
