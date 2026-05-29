local fs = require("@std/fs")
local luau = require("@std/luau")
local path = require("@std/path")
local log = require("@libs/log")

type PlaceConfig = {
	title: string,
	subtitle: string?,
	placeId: string?,
	dependencies: { string }?,
}

type PlaceMixinConfig = {
	transpile: boolean?,
	folderName: string,
	rojo: string,
}

type Config = {
	wth: {
		place: PlaceConfig?,
		placeMixin: PlaceMixinConfig?,
	},
}

export type MonorepoMember = {
	place: PlaceConfig?,
	placeMixin: PlaceMixinConfig?,

	dirName: string,
	dirPath: path.Pathlike,
	configPath: path.Pathlike,
}

export type Monorepo = { [any]: MonorepoMember }

local function useMonorepo(): Monorepo
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

		local member: MonorepoMember = {
			place = placeConfig,
			placeMixinConfig = placeMixinConfig,

			dirName = entry.name,
			dirPath = entry.name,
			configPath = configPath,
		}

		table.insert(monorepo, member)
		monorepo[entry.name] = member
	end

	table.sort(monorepo, function(lhs: MonorepoMember, rhs: MonorepoMember)
		return lhs.dirName < rhs.dirName
	end)

	return monorepo
end

return useMonorepo
