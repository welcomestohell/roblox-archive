local fs = require "@std/fs"
local path = require "@std/path"

local function copyInto(from: string, to: string)
	if fs.type(from) == "dir" then
		if not fs.exists(to) then
			fs.createdirectory(to, { makeparents = true })
		end

		for _, entry in fs.listdirectory(from) do
			copyInto(path.join(from, entry.name), path.join(to, entry.name))
		end
	else
		fs.copy(from, to)
	end
end

return copyInto
