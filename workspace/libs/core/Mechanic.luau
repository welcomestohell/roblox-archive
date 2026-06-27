local Attribute = require "@libs/attributes/Attribute"
local Life = require "@libs/memory/Life"
local types = require "@libs/types"

export type AttributeSection = {
	title: string?,
	attributes: { Attribute.Attribute<any> },
}

export type MechanicImplementationMetadata = {
	currentAttributeSection: AttributeSection,
	attributeSections: { AttributeSection },
}

export type Mechanic<Implementation = { [unknown]: unknown }, Mixin = {}> = Implementation & Mixin & {
	life: Life.Life,
	id: string,
	implementation: Implementation,
	instance: index<Implementation, "instanceType">,
	instanceConfiguration: Instance,
}

-- TODO: How do we type this?
export type AnyMechanic = any

export type AnyMechanicImplementation = {
	name: string,
	instanceType: Instance,

	emoji: string,

	onPreRender: (self: any, deltaTime: number, level: any) -> ()?,
	onPreAnimation: (self: any, deltaTime: number, level: any) -> ()?,
	onPreSimulation: (self: any, deltaTime: number, level: any) -> ()?,
	onPostSimulation: (self: any, deltaTime: number, level: any) -> ()?,

	onInit: (self: any, level: any) -> ()?,
	onStart: (self: any, mechanic: Mechanic<any>, level: any) -> ()?,
	onActivate: (self: any, mechanic: Mechanic<any>, level: any, activationEvent: any) -> ()?,
	bindActivation: (self: any, mechanic: Mechanic<any>, level: any) -> ()?,
	getActivationInstances: (self: any, mechanic: Mechanic<any>, level: any) -> (Instance | { Instance })?,
}

local Mechanic = {}
Mechanic.__index = Mechanic
Mechanic.type = "MechanicImplementation"

-- Instance properties can't be defined on Mechanic because it
-- breaks metatable typing...
Mechanic._proxy = types.any :: {}
Mechanic._metadata = types.any :: MechanicImplementationMetadata

export type MechanicImplementation<Self = {}> = setmetatable<Self, typeof(Mechanic)>

function Mechanic.new<Self>(self: Self): MechanicImplementation<Self>
	local implementation: any = setmetatable(self, Mechanic)

	local firstSection: AttributeSection = { attributes = {} }

	local metadata: MechanicImplementationMetadata = {
		currentAttributeSection = firstSection,
		attributeSections = { firstSection },
	}

	implementation._metadata = metadata

	local proxy = {
		__newindex = rawset,
	}

	-- Investigate: we could get rid of the closure by storing implementation
	-- on the proxy and then using getmetatable
	function proxy.__index(self: any, key: any)
		local value = rawget(self, key)
		return if value == nil then implementation[key] else value
	end

	function proxy.__tostring(self: Mechanic<AnyMechanicImplementation>)
		return `{self.implementation.name}({self.instance:GetFullName()})`
	end

	implementation._proxy = proxy

	return implementation
end

function Mechanic.isMechanicImplementation(x: any)
	return typeof(x) == "table" and getmetatable(x) == Mechanic
end

function Mechanic.downcast(self: {}): MechanicImplementation<AnyMechanicImplementation>
	return self :: any
end

return table.freeze(Mechanic)
