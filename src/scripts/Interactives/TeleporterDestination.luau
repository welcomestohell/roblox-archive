local gt = require("@pkgs/gt")
local std = require("@libs/std")

local TeleporterDestination = std.Mechanic("TeleporterDestination", gt.isA.BasePart())({
	destinationsById = std.LevelState({} :: { [string]: { Self } }),

	TeleporterId = std.Attribute("TeleporterId", gt.string()),
	TeleporterOffset = std.Attribute("TeleporterOffset", gt.CFrame()),

	onInit = function(self: Implementation, level: std.Level)
		self.destinationsById:getOrSet(level, {})
	end,

	onStart = function(self: Self, level: std.Level)
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
export type Self = std.Mechanic<typeof(TeleporterDestination)>
return TeleporterDestination
