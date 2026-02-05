local gt = require("@pkgs/gt")
local std = require("@libs/std")

local TeleporterDestination = std.Mechanic("TeleporterDestination", gt.isA.BasePart())({
	destinationsById = std.LevelState({} :: { [string]: { Mechanic } }),

	Id = std.Attribute("Id", gt.string()),
	Offset = std.Attribute("Offset", gt.CFrame()),

	onInit = function(self: Mechanic, level: std.Level)
		self.destinationsById:getOrSet(level, {})
	end,

	onStart = function(self: Mechanic, level: std.Level)
		local oldId: string? = nil
		local destinationsById = self.destinationsById:getOrDefault(level)
		self.Id.onBind(self, function(newId: string?)
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

export type Self = typeof(TeleporterDestination)
export type Mechanic = std.Mechanic<Self>
return TeleporterDestination
