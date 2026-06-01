local Fluid = require "@roblox_packages/Fluid"
local UILabs = require "@roblox_packages/UILabs"

type function Controls(controls: type)
	assert(controls.tag == "table", "expected controls to be a table")
	for key, values in controls:properties() do
		if values.read then
			controls:setreadproperty(key, types.newfunction({}, { head = { values.read } }))
		end

		if values.write then
			controls:setwriteproperty(key, types.newfunction({}, { head = { values.write } }))
		end
	end
	return controls
end

local function createFluidStory<C>(storyProps: {
	controls: C,
	render: ({ controls: Controls<C> }) -> Instance,
})
	return UILabs.CreateGenericStory({ controls = storyProps.controls }, function(props: UILabs.GenericProps): () -> ()
		return Fluid.root(function()
			local states = UILabs.CreateControlStates(props.converted, props.controls, function(value)
				return Fluid.source(value)
			end)

			props.subscribe(function(values)
				UILabs.UpdateControlStates(states, props.converted, values, function(state, value)
					state(value)
				end)
			end)

			local rendered = storyProps.render { controls = states :: Controls<C> }
			UILabs.Environment.SetStoryHolder(rendered)
			rendered.Parent = props.target
		end)
	end)
end

return createFluidStory
