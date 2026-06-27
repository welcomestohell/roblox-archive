const ReplicatedStorage = game:GetService "ReplicatedStorage"

const Lazy = require "@libs/Lazy"
const prvd = require "@pkgs/prvd"

const CONTAINER_NAME = "ModulePointers"

--[[
	Provides ModuleScript pointers intended for reusing smaller configurations
	such as mechanic configurations. This helps reduce memory usage as less
	modules overall are required.

	Consumers should use `ModulePointerProvider:tryCacheInstance(instance)` to
	cache a ModuleScript.
]]
const ModulePointerProvider = {}
export type ModulePointerProvider = typeof(ModulePointerProvider)

ModulePointerProvider.container = Lazy.new(function()
	const defaultContainer = ReplicatedStorage:FindFirstChild(CONTAINER_NAME)
	if defaultContainer and defaultContainer:IsA "Folder" then return defaultContainer end

	const container = Instance.new "Folder"
	container.Name = CONTAINER_NAME
	container.Parent = ReplicatedStorage
	return container
end)

ModulePointerProvider.templatePointer = Lazy.new(function()
	const templatePointer = Instance.new "ObjectValue"
	templatePointer:AddTag "Welcome To Hell: Module Pointer"
	return templatePointer
end)

function ModulePointerProvider.tryCacheInstance(self: ModulePointerProvider, instance: Instance)
	if instance:IsA "ModuleScript" then
		const pointer = self.templatePointer:get():Clone()
		pointer.Name = instance.Name
		pointer.Value = instance

		for _, tag in instance:GetTags() do
			pointer:AddTag(tag)
			instance:RemoveTag(tag)
		end

		pointer.Parent = instance.Parent
		instance.Name = instance:GetFullName()
		instance.Parent = self.container:get()
	end
end

return prvd(ModulePointerProvider)
