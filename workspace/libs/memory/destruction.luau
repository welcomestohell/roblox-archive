local functions = require "@libs/functions"
local logger = require "@core/shared/logger"

-- LUAU: Destroyable is set to any so types using Destroyable are readable
export type Destroyable = any

local destructorMethods = {
	"Destroy",
	"destroy",
	"Disconnect",
	"disconnect",
}

local connection = game.Close:Connect(functions.noop)
local disconnect = connection.Disconnect
connection:Disconnect()

local destroy
local typeDestructors: { [string]: (any) -> () } = {
	["Instance"] = game.Destroy,
	["RBXScriptConnection"] = disconnect,

	["function"] = function(fn: () -> ())
		local co = coroutine.create(fn)
		local success, result = coroutine.resume(co)

		if not success or coroutine.status(co) ~= "dead" then
			local source, line, name = debug.info(fn, "sln")
			name = if name == "" or name == nil then "Anonymous function" else "Function " .. name :: string
			if success then
				logger:Error(name, "from line", line, "of", source, "attempted to yield during cleanup")
			else
				logger:Error(name, "from line", line, "of", source, "errored while cleaning up:", result)
			end
		end
	end,

	["thread"] = function(thread: thread)
		pcall(task.cancel, thread)
	end,

	["table"] = function(tbl: { [any]: any })
		for _, method in destructorMethods do
			if type(tbl[method]) == "function" then
				tbl[method](tbl)
				return
			end
		end

		local len = #tbl
		if len ~= 0 then
			for index = #tbl, 1, -1 do
				destroy(tbl[index])
			end
		end
	end,
}

function destroy(x: Destroyable)
	local destructor = typeDestructors[typeof(x)]
	if destructor then destructor(x) end
end

return table.freeze {
	destroy = destroy,
	destructorMethods = destructorMethods,
	typeDestructors = typeDestructors,
}
