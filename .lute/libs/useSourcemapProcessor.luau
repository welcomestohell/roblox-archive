local fs = require("@std/fs")
local path = require("@std/path")
local types = require("./types")

--[=[
    Watches the project's sourcemap.json for files added and removed. Also
    watches all listed files in the sourcemap for file changes. 
    
    Although limited, this is significantly more reliable than Lute's `fs.watch`
    and more performant than long polling.
]=]
local function watchSourcemap(sourcemapPath: path.Pathlike)
	local oldIndices: types.SourcemapIndices = {}
	local filesAdded, filesChanged: { [string]: true }, filesRemoved = {}, {}, {}
	local fileWatchers: { [string]: types.Watcher } = {}

	local function onChanged(newIndices: types.SourcemapIndices)
		for absolutePath in newIndices do
			if not oldIndices[absolutePath] and not filesAdded[absolutePath] then
				filesAdded[absolutePath] = true

				local watcher = fs.watch(absolutePath)
				fileWatchers[absolutePath] = watcher
			end
		end

		for absolutePath, hash in oldIndices do
			if not newIndices[absolutePath] and not filesRemoved[absolutePath] then
				filesRemoved[absolutePath] = true

				local watcher = fileWatchers[absolutePath]
				if watcher then
					watcher:close()
					fileWatchers[absolutePath] = nil
				end
			end
		end

		oldIndices = newIndices
	end

	return {
		filesAdded = filesAdded,
		filesChanged = filesChanged,
		filesRemoved = filesRemoved,
		fileWatchers = fileWatchers,
		onChanged = onChanged,
	}
end

return watchSourcemap
