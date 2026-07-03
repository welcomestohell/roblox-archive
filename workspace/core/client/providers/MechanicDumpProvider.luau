local HttpService = game:GetService "HttpService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Level = require "@libs/core/Level"
local Mechanic = require "@libs/core/Mechanic"
local gt = require "@libs/vendor/gt"
local prvd = require "@pkgs/prvd"
local tables = require "@libs/primitives/tables"

--[=[
	@class MechanicDumpProvider

	Provides a JSON dump of all Welcome To Hell mechanics. It's useful for
	implementing your own plugins that extend Welcome To Hell's kits.

	TODO: this class is temporary so we can get the plugin up and running
]=]
local MechanicDumpProvider = {}
export type MechanicDumpProvider = typeof(MechanicDumpProvider)

function MechanicDumpProvider.onStart()
	local dump = {}
	for _, implementation in Level.baseScripts.mechanicImplementationByName do
		local implementation = Mechanic.downcast(implementation)
		print(implementation.name, implementation.description)
		dump[implementation.name] = {
			name = implementation.name,
			emoji = implementation.emoji,

			attributeSections = tables.pairsMapped(
				implementation._metadata.attributeSections,
				function(index, section: Mechanic.AttributeSection)
					section.attributes = table.clone(section.attributes)
					for index, attribute in section.attributes do
						section.attributes[index] = {
							name = attribute.attribute,
							type = gt.serialize(attribute.check),
						} :: any
					end
					return index, section
				end
			),
		}
	end

	local encodedDump = HttpService:JSONEncode(dump)

	local bind = Instance.new "BindableFunction"
	bind.Name = "GetMechanicDump"
	function bind.OnInvoke()
		return encodedDump
	end
	bind.Parent = ReplicatedStorage
end

return prvd(MechanicDumpProvider)
