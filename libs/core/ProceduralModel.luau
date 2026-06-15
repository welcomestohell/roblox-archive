const Attribute = require "@libs/attributes/Attribute"
const objects = require "@libs/collections/objects"

export type function ReduceAttributes(attributes: type)
	assert(attributes.tag == "table", "Expected attributes to be a table")
	const result = types.newtable()
	for key, value in attributes:properties() do
		const attribute = value.read
		assert(attribute, `Key {key} is readonly`)
		assert(attribute.tag == "table", `Expected {key} to be an Attribute table`)

		const defaultValue = attribute:readproperty(types.singleton "defaultValue")
		if defaultValue then result:setproperty(key, defaultValue) end
	end
	return result
end

export type GenerateParams<Attributes> = {
	Size: Vector3,
	Attributes: Attributes,
	Pause: (self: GenerateParams<Attributes>) -> (),
}

const ProceduralModel = {}
ProceduralModel.__index = ProceduralModel

export type ProceduralModel<Attributes> = {
	Attributes: Attributes,
	OnGenerate: (params: GenerateParams<Attributes>, container: GeneratedFolder) -> (),
}

function ProceduralModel.new<ExpectedAttributes>(
	expectedAttributes: ExpectedAttributes & { [string]: Attribute.Attribute<unknown> },
	onGenerate: (
		params: GenerateParams<ReduceAttributes<ExpectedAttributes>>,
		container: GeneratedFolder
	) -> ()
): ProceduralModel<ReduceAttributes<ExpectedAttributes>>
	return {
		Attributes = objects.map(expectedAttributes, function(attribute: Attribute.Attribute<unknown>)
			return attribute.defaultValue
		end) :: any,
		OnGenerate = function(params: GenerateParams<ReduceAttributes<ExpectedAttributes>>, container: GeneratedFolder)
			const realAttributes = params.Attributes :: { [string]: any }
			for key, attribute in expectedAttributes :: { [string]: Attribute.Attribute<unknown> } do
				const isValid, cause = attribute.check:matches(realAttributes[key])
				if not isValid then error(`Invalid value for attribute {key}: {cause:formatErr()}`) end
			end
			onGenerate(params, container)
		end,
	}
end

return ProceduralModel
