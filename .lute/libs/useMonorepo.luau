local fs = require("@std/fs")
local luau = require("@std/luau")
local path = require("@std/path")
local useRepositoryConfig = require("./useRepositoryConfig")
local log = require("@libs/log")

type RojoMappings = typeof(useRepositoryConfig().wth.rojo.mappings)
type RojoProjectTarget = "source" | "output"

export type Place = {
	title: string,
	subtitle: string?,
	folderName: string,
	placeId: string?,
	dependencies: { string }?,
}

export type PlaceMixin = {
	folderName: string,
	rojo: string,
}

export type Config = {
	wth: {
		place: Place?,
		placeMixin: PlaceMixin?,
	},
}

export type MonorepoMember = {
	place: Place?,
	placeMixin: PlaceMixin?,

	folderName: string,
	dirName: string,
	dirPath: path.Pathlike,
	configPath: path.Pathlike,
	outputPath: path.Pathlike,

	rojoMappings: {
		[RojoProjectTarget]: { [keyof<RojoMappings>]: path.Pathlike? },
	},
}

export type Monorepo = { [any]: MonorepoMember }

local function useMonorepo(): Monorepo
	local repository = useRepositoryConfig()
	local monorepo: Monorepo = {}

	for _, entry in fs.listDirectory(".") do
		if entry.type ~= "dir" then
			continue
		end

		local configPath = path.join(entry.name, ".config.luau")
		if not fs.exists(configPath) or fs.type(configPath) ~= "file" then
			continue
		end

		local config: Config = luau.loadModule(configPath)
		local wthConfig = config.wth
		if not wthConfig then
			continue
		end

		local placeConfig, placeMixinConfig = wthConfig.place, wthConfig.placeMixin
		if placeConfig and placeMixinConfig then
			log.warn(entry.name, "config specifies place AND placeMixin, which is mutually exclusive")
			continue
		elseif not (placeConfig or placeMixinConfig) then
			continue
		end

		local folderName = if placeConfig
			then placeConfig.folderName
			elseif placeMixinConfig then placeMixinConfig.folderName
			else log.throw(`Missing folderName for {entry.name}`)

		local member: MonorepoMember = {
			place = placeConfig,
			placeMixinConfig = placeMixinConfig,

			folderName = folderName,
			dirName = entry.name,
			dirPath = entry.name,
			configPath = configPath,
			outputPath = path.join(repository.wth.paths.output, entry.name),

			rojoMappings = {
				source = {},
				output = {},
			},
		}

		for key in repository.wth.rojo.mappings :: any do
			member.rojoMappings.source[key] = member.dirPath
			member.rojoMappings.output[key] = path.join(repository.wth.paths.output, member.dirPath)
		end

		table.insert(monorepo, member)
		monorepo[entry.name] = member
	end

	table.sort(monorepo, function(lhs: MonorepoMember, rhs: MonorepoMember)
		return lhs.dirName < rhs.dirName
	end)

	return monorepo
end

return useMonorepo
