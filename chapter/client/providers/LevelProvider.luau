local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Workspace = game:GetService "Workspace"

local Level = require "@libs/Level"
local Life = require "@libs/memory/Life"
local Log = require "@libs/Log"
local character = require "@libs/character"
local net = require "@chapter/client/generated/net"
local prvd = require "@prvdmwrong/prvdmwrong"

local LevelProvider = {}
export type LevelProvider = typeof(LevelProvider)
LevelProvider.log = Log.new(LevelProvider)

function LevelProvider.constructor(self: LevelProvider)
	self.life = Life.new()
	Level.baseScripts:tryInstances(ReplicatedStorage.TowerScripts.Core:GetDescendants())
end

function LevelProvider.onStart(self: LevelProvider)
	self.log:debug "Hello??"
	if not game:IsLoaded() then
		self.log:debug "Waiting for game to load"
		game.Loaded:Wait()
	end

	local existingMechanics = Workspace:FindFirstChild "Mechanics"
	if existingMechanics then
		self.log:trace "Removing existing mechanics"
		existingMechanics:Destroy()
	end

	local mechanics = net.loadMechanics.invoke():expect()
	mechanics:Clone().Parent = Workspace
	mechanics:Destroy()

	local levelResult = Level.new(self.life, "Chapter", Workspace)
	levelResult:match({
		Ok = function(level: Level.Level)
			self.log:trace "Starting chapter..."
			character.getCharacter():PivotTo(level.instance.SpawnCharacter.CFrame)
			level:start()
			self.log:info "Chapter has started!"
		end,
		Err = function(e)
			if e.id == "invalidInstance" then
				self.log:error("Invalid chapter instance client-side:", e.cause:formatErr())
			end
			self.log:error("Unknown error while initializing kit:", e)
		end,
	} :: any)
end

return prvd(LevelProvider)
