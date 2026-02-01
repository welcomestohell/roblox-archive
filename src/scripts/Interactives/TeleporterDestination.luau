local Attribute = require("@libs/Attribute")
local LevelState = require("@libs/LevelState")
local Mechanic = require("@libs/Mechanic")
local gt = require("@pkgs/gt")

local TeleporterDestination = Mechanic.new("TeleporterDestination", gt.isA.BasePart())({
	destinationsById = LevelState.new({}) :: LevelState.LevelState<{ [string]: { Self } }>,

	TeleporterId = Attribute.new("TeleporterId", gt.string()),
	TeleporterOffset = Attribute.new("TeleporterOffset", gt.CFrame()),

	onInit = function(self: Implementation, level: Mechanic.Level)
		self.destinationsById:getOrSet(level, {})
	end,

	onStart = function(self: Self, level: Mechanic.Level)
		local oldId: string? = nil
		local destinationsById = self.destinationsById:getOrDefault(level)
		self.TeleporterId.onBind(self, function(newId: string?)
			if oldId then
				local oldIdDestinations = destinationsById[oldId]
				table.remove(oldIdDestinations, table.find(oldIdDestinations, self))
			end

			if newId then
				local newIdDestinations = destinationsById[newId]
				if not newIdDestinations then
					newIdDestinations = {}
					destinationsById[newId] = newIdDestinations
				end
				table.insert(newIdDestinations, self)
			end

			oldId = newId
		end)
	end,
})

export type Implementation = typeof(TeleporterDestination)
export type Self = Mechanic.Mechanic<typeof(TeleporterDestination)>
return TeleporterDestination
