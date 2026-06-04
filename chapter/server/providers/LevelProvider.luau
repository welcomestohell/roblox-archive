local CollectionService = game:GetService "CollectionService"
local ServerStorage = game:GetService "ServerStorage"
local StarterGui = game:GetService "StarterGui"
local StarterPlayer = game:GetService "StarterPlayer"
local TeleportService = game:GetService "TeleportService"
local Workspace = game:GetService "Workspace"

local Level = require "@libs/Level"
local Log = require "@libs/Log"
local PlayerInstanceLoader = require "@core/server/PlayerInstanceLoader"
local net = require "@chapter/server/generated/net"
local prvd = require "@prvdmwrong/prvdmwrong"

local DEFAULTS: { [Instance]: { [string]: unknown } } = {
	[StarterGui] = { ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor },
	[StarterPlayer] = { AutoJumpEnabled = false, CharacterUseJumpPower = true },
}

local LevelProvider = {}
export type KitServerProvider = typeof(LevelProvider)
LevelProvider.log = Log.new(LevelProvider)
LevelProvider.decorationsLoader = PlayerInstanceLoader.new(15)
LevelProvider.mechanicLoader = PlayerInstanceLoader.new(15)

local function storeOrDefault(fromParent: Instance, childName: string): Instance
	local child = fromParent:FindFirstChild(childName) :: Instance
	if not child then
		child = Instance.new "Folder"
		child.Name = childName
	end
	child.Parent = ServerStorage
	return child
end

function LevelProvider.onStart(self: KitServerProvider)
	for instance, defaults in DEFAULTS do
		for property, expectedValue in defaults do
			(instance :: any)[property] = expectedValue
		end
	end

	local isValid, invalidCause = Level.LevelInstance:matches(Workspace)

	if not isValid then
		self.log:error("Invalid chapter workspace:", invalidCause:formatErr())
	end

	local mechanics, _decorations = storeOrDefault(Workspace, "Mechanics"), storeOrDefault(Workspace, "Decorations")

	net.loadMechanics.on(function(player: Player): Instance
		return self.mechanicLoader:cloneToPlayer(player, mechanics)
	end)
end

return prvd(LevelProvider)
