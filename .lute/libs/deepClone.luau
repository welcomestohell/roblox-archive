local function deepClone<T>(tbl: T & {}): T
	local clone = table.clone(tbl)
	for key, value in clone :: any do
		if type(value) == "table" then
			clone[key] = deepClone(value)
		end
	end
	return clone
end

return deepClone
