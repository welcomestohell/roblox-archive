-- Based on: https://github.com/luau-lang/lute/blob/52852e07d80f5a7f7974a9efcc3933d957154860/lute/std/libs/stringext.luau

local strings = {}

function strings.hasPrefix(str: string, prefix: string): boolean
	return #prefix <= #str and string.sub(str, 1, #prefix) == prefix
end

function strings.removePrefix(str: string, prefix: string): string
	return if strings.hasPrefix(str, prefix) then string.sub(str, #prefix + 1) else str
end

function strings.hasSuffix(str: string, suffix: string): boolean
	return string.sub(str, -#suffix) == suffix
end

function strings.removeSuffix(str: string, suffix: string): string
	return if strings.hasSuffix(str, suffix) then string.sub(str, 0, -#suffix - 1) else str
end

function strings.trim(str: string): string
	-- Pattern is guaranteed to return a result
	return string.match(str, "^%s*(.-)%s*$") :: string
end

--- Counts the number of occurrences of `pattern` in `str`, optionally restricted to the range `[startPos, endPos]`.
function strings.count(str: string, pattern: string, startPos: number?, endPos: number?): number
	if startPos and endPos then
		str = string.sub(str, startPos, endPos)
	elseif startPos then
		str = string.sub(str, startPos)
	elseif endPos then
		str = string.sub(str, 1, endPos)
	end

	local count = 0
	for _ in str:gmatch(pattern) do
		count += 1
	end

	return count
end

return table.freeze(strings)
