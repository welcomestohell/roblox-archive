local json = require("@std/json")
local path = require("@std/path")
local deepClone = require("./deepClone")
local log = require("./log")
local useMonorepo = require("./useMonorepo")
local useRepositoryConfig = require("./useRepositoryConfig")

export type RojoMappings = { [keyof<typeof(useRepositoryConfig().wth.rojo.mappings)>]: { RojoMappingSegment } }

export type RojoMappingSegment = {
	name: string,
	className: string?,
}

export type RojoPath = string | { optional: string }

export type RojoNode = {
	["$className"]: string?,
	["$path"]: RojoPath?,
	[string]: RojoNode,
}

local function insertMapping(
	tree: RojoNode,
	segments: { RojoMappingSegment },
	sourceName: string?,
	sourcePath: path.Pathlike?
)
	local current = tree

	for _, segment in segments do
		if not current[segment.name] then
			current[segment.name] = {}
		end

		current = current[segment.name]

		if segment.className then
			current["$className"] = segment.className
		end
	end

	if sourceName and sourcePath then
		if not current[sourceName] then
			current[sourceName] = {}
		end

		current = current[sourceName]

		current["$path"] = {
			optional = path.format(sourcePath),
		}
	end
end

local function projectFromMembers(kind: "source" | "output", members: { useMonorepo.MonorepoMember }): json.Object
	local firstMember = members[1] or log.throw("Must specify atleast 1 member to build Rojo")
	local place = firstMember.place or log.throw("First Rojo member must be a place")

	local repository = useRepositoryConfig()
	local mappings = repository.wth.rojo.mappings :: RojoMappings
	local tree = deepClone(repository.wth.rojo.tree) :: RojoNode

	for dir, segments in mappings do
		for _, member in members do
			insertMapping(tree, segments, member.folderName, member.rojoMappings[kind][dir])
		end
	end

	return {
		name = `Welcome To Hell: {place.title}`,
		emitLegacyScripts = false,
		servePlaceIds = { place.placeId },
		placeId = place.placeId,
		globIgnorePaths = { "**/.config.luau" },
		tree = tree,
	}
end

return table.freeze({
	projectFromMembers = projectFromMembers,
})
