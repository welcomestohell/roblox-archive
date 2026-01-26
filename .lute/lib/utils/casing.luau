local function toPascalCase(str: string)
	local segments = string.split(str, "-")
	for index, substring in segments do
		segments[index] = string.upper(string.sub(substring, 1, 1)) .. string.sub(substring, 2, -1)
	end
	return table.concat(segments)
end

return table.freeze {
	toPascalCase = toPascalCase,
}
