export type function Partial(table: type)
	assert(table.tag == "table")
	local result = types:newtable()
	for key, value in table:properties() do
		if value.read then
			result:setreadproperty(key, types.optional(value.read))
		elseif value.write then
			result:setreadproperty(key, types.optional(value.write))
		end
	end
	return result
end

return nil
