export type DestroyableClass = {
	[any]: any,
	read Destroy: (self: any) -> ()?,
	read destroy: (self: any) -> ()?,
	read Disconnect: (self: any) -> ()?,
	read disconnect: (self: any) -> ()?,
}

export type Destroyable = | Instance | RBXScriptConnection | thread | DestroyableClass | { any } | () -> ...any

local DESTRUCTORS = {
	"Destroy",
	"destroy",
	"Disconnect",
	"disconnect",
}

local function destroy(x: any)
	if typeof(x) == "Instance" then
		x:Destroy()
	elseif typeof(x) == "RBXScriptConnection" and x.Connected then
		x:Disconnect()
	elseif type(x) == "thread" then
		pcall(task.cancel, x)
	elseif type(x) == "function" then
		(x :: () -> ())()
	elseif type(x) == "table" then
		for _, method in DESTRUCTORS do
			if type(x[method]) == "function" then
				x[method](x)
				return
			end
		end

		local len = #(x :: any)
		if len ~= 0 then
			for index = #(x :: any), 1, -1 do
				destroy(x[index])
			end
		end
	end
end

return destroy
