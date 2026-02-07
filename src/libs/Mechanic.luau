local Attribute = require("./Attribute")
local Life = require("./Life")
local gt = require("./gt")

--[=[
	@interface MechanicImplementationMetadata

	Additional metadata attached to a `MechanicImplementation`. 

	This is primarially used for Welcome To Hell's Debugger, the Hyperborea
	plugin, and the Kitnomicon documentation.
]=]
export type MechanicImplementationMetadata = {
	currentAttributeSection: string?,
	attributeSections: { string },
	attributes: { Attribute.Attribute<any> },
	sectionByAttribute: { [Attribute.Attribute<any>]: string? },
}

--[=[
	@interface Mechanic<Self>

	An instance loaded in a `Level` with user-implemented behavior as defined by a
	`MechanicImplementation`.
]=]
export type Mechanic<Self> = Self & {
	life: Life.Life,
	id: string,
	implementation: Self,
	instance: index<Self, "instanceType">,
	instanceConfiguration: Instance?,
}

--[=[
	@interface MechanicImplementation

	Represents the implementation of a `Mechanic` used in a `Level`.
]=]
export type MechanicImplementation = {
	[unknown]: unknown,

	instanceTag: string,
	instanceType: gt.Type,

	onPreRender: (self: any, deltaTime: number, level: any) -> ()?,
	onPreAnimation: (self: any, deltaTime: number, level: any) -> ()?,
	onPreSimulation: (self: any, deltaTime: number, level: any) -> ()?,
	onPostSimulation: (self: any, deltaTime: number, level: any) -> ()?,

	onInit: (self: any, level: any) -> ()?,
	onStart: (self: any, mechanic: Mechanic<any>, level: any) -> ()?,
	onActivate: (self: any, mechanic: Mechanic<any>, level: any) -> ()?,
}

--[=[
	@class Mechanic
	@tag Library
]=]
local Mechanic = {}
Mechanic.__index = Mechanic
Mechanic._metadata = {} :: { [{}]: MechanicImplementationMetadata }
Mechanic.Enabled = Attribute.new("Enabled", gt.boolean(), false)

function Mechanic.new<T>(implementation: T): setmetatable<T, typeof(Mechanic)>
	local metadata: MechanicImplementationMetadata = {
		attributeSections = {},
		attributes = {},
		sectionByAttribute = {},
	}

	local implementation: any = setmetatable(implementation, Mechanic)
	Mechanic._metadata[implementation] = metadata
	implementation:attributeSection("Configuration")
	implementation.__index = (implementation :: any).__index or implementation
	return implementation
end

function Mechanic.isMechanicImplementation(x: any)
	return typeof(x) == "table" and getmetatable(x) == Mechanic
end

function Mechanic.attributeSection(self: {}, section: string)
	Mechanic._metadata[self].currentAttributeSection = section
end

function Mechanic.attribute<T>(self: {}, name: string, type: T, default: T): Attribute.Attribute<T>
	local attribute = Attribute.new(name, type, default)
	table.insert(Mechanic._metadata[self].attributes, attribute)
	Mechanic._metadata[self].sectionByAttribute[attribute] = Mechanic._metadata[self].currentAttributeSection
	return attribute
end

function Mechanic.getMetadata(self: {}): MechanicImplementationMetadata
	return Mechanic._metadata[self]
end

function Mechanic.__tostring(self: MechanicImplementation)
	return self.instanceTag
end

local a = Mechanic.new({})
type a = Mechanic<typeof(a)>
a.instanceType = nil

return table.freeze(Mechanic)
