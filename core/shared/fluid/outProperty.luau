const properties = require "@libs/properties"
const Fluid = require "@roblox_packages/Fluid"

const function outProperty(propertyName: string, source: (any) -> any)
	return Fluid.action(function(instance)
		source(properties.getUnsafe(instance, propertyName))
		Fluid.cleanup(
			instance
				:GetPropertyChangedSignal(propertyName)
				:Connect(function() source(properties.getUnsafe(instance, propertyName)) end)
		)
	end)
end

return outProperty
