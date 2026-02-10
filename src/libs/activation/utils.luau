local gt = require("@libs/gt")
local types = require("./types")

-- TODO: gt types suck

local function createChildOfClass<K>(
	ctx: types.ActivationContext,
	childName: string,
	childClass: K | keyof<typeof(gt.isA)>
): index<typeof(gt.isA), K>
	local instance = ctx.activationLife:add(Instance.new(childClass))
	instance.Name = childName
	instance.Parent = ctx.instance
	return function()
		return instance
	end :: any
end

local function expectChildOfClass<K>(
	ctx: types.ActivationContext,
	childName: string,
	childClass: K | keyof<typeof(gt.isA)>
): index<typeof(gt.isA), K>
	local child = ctx.instance:FindFirstChild(childName)

	if not child then
		child = (createChildOfClass(ctx, childName, childClass) :: any)()
	elseif child.ClassName ~= childClass then
		child.Name ..= "_FAKE"
		child = (createChildOfClass(ctx, childName, childClass) :: any)()
	end

	return function()
		return child
	end :: any
end

return table.freeze {
	createChildOfClass = createChildOfClass,
	expectChildOfClass = expectChildOfClass,
}
