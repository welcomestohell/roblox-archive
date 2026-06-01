local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerScriptService = game:GetService "ServerScriptService"

local Log = require "@libs/Log"
local prvd = require "@prvdmwrong/prvdmwrong"
local rbxLifecycles = require "@prvdmwrong/rbx-lifecycles"

local log = Log.new(script)
local root = prvd.root()
	:useProvider(rbxLifecycles :: any)
	:willStart(function()
		log:debug "Starting up!"
	end)
	:willFinish(function()
		log:debug "Finishing up!"
	end)

local function useProvidersFromMembers(memberParent: Instance)
	for _, member in memberParent:GetChildren() do
		local providers = member:FindFirstChild "providers"
		if providers then
			root:useModules(providers:GetDescendants())
		end
	end
end

local function bootstrapClient()
	assert(RunService:IsClient(), "Wrong bootstrapper used on client/server")

	local internal = ReplicatedStorage:WaitForChild "Internal"
	useProvidersFromMembers(internal:WaitForChild "Client")
	useProvidersFromMembers(internal:WaitForChild "Shared")

	local startedRoot = root:start()
	game.Close:Once(function()
		startedRoot:finish()
	end)
end

local function bootstrapServer()
	assert(RunService:IsServer(), "Wrong bootstrapper used on client/server")

	useProvidersFromMembers(ReplicatedStorage:WaitForChild("Internal"):WaitForChild "Shared")
	useProvidersFromMembers(ServerScriptService:WaitForChild("Internal"):WaitForChild "Server")

	local startedRoot = root:start()
	game:BindToClose(function()
		startedRoot:finish()
	end)
end

return table.freeze {
	root = root,
	useProvidersFromMembers = useProvidersFromMembers,
	bootstrapClient = bootstrapClient,
	bootstrapServer = bootstrapServer,
}
