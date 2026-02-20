local std = require("@libs/std")
local tables = require("@libs/tables")

local TeleporterDestination = std.Mechanic({})
export type TeleporterDestinationMechanic = std.Mechanic<typeof(TeleporterDestination)>

TeleporterDestination.instanceTag = "TeleporterDestination"
TeleporterDestination.instanceType = std.isA.BasePart()
TeleporterDestination.debuggerEmoji = "📍"

TeleporterDestination.Id = std.Attribute("Id", std.gt.string())
TeleporterDestination.Offset = std.Attribute("Offset", std.gt.CFrame(), CFrame.new(0, 2.5, 0))

-- LUAU: FUCK GENERICS
TeleporterDestination.destinationsById = std.LevelState({} :: any)

function TeleporterDestination.onStart(
	self: typeof(TeleporterDestination),
	destination: TeleporterDestinationMechanic,
	level: std.Level
)
	local oldId: string? = nil
	local destinationsById = self.destinationsById:getOrSet(level, {})
	destination.Id:onBind(destination, function(newId: string?)
		if oldId then
			local oldIdDestinations = destinationsById[oldId]
			tables.findAndRemove(oldIdDestinations, destination)
		end

		if newId then
			local newIdDestinations = destinationsById[newId]
			if not newIdDestinations then
				newIdDestinations = {}
				destinationsById[newId] = newIdDestinations
			end
			table.insert(newIdDestinations, destination)
		end

		oldId = newId
	end)
end

return TeleporterDestination
