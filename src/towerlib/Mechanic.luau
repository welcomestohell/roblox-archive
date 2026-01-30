local types = require "./types"

export type MechanicSelf = {
	tag: string?,

	[any]: any,
}

export type MechanicImplementation<T> = T & {
	[any]: any,
	tag: string?,
	onActivate: (self: never) -> ()?,
	onLoad: (self: never) -> ()?,
}

export type Mechanic<T> = setmetatable<{
	instance: Instance,
}, { __index: T }>

local Mechanic = {}

function Mechanic.extend<T, Super>(super: Super, extension: MechanicImplementation<T>): MechanicImplementation<T & Super>
	local extended = {}
	error "todo"
end

function Mechanic.reimplement<T, Super>(super: Super, extension: MechanicImplementation<T>): MechanicImplementation<T & Super>
	if super == Mechanic then
		return error "Cannot reimplement the base `Mechanic` class. Instead, use `Mechanic:extend` to implement a new Mechanic."
	end
	error "todo"
end

function Mechanic.getLoadType<T>(_: T): Mechanic<T>
	error "This function only provides Luau types (ie. `typeof(...)`) and cannot be used at runtime."
end

local Damager = Mechanic:reimplement {
	tag = "Damager",

	method = function(self: Damager)
		print(self.instance.Name)
	end,

	onActivate = function(self: Damager) end,
}

export type Damager = typeof(Damager:getLoadType())
