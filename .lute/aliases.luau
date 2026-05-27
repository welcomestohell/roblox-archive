local fs = require("@std/fs")
local json = require("@std/json")
local path = require("@std/path")
local places = require("@lib/places")
local pp = require("@batteries/pp")
local repositoryConfig = require("@lib/utils/repositoryConfig")()

places.initialize()

local luauAliases = {
	pkgs = `../{repositoryConfig.wth.dirs.packages}`,
	libs = "./libs",
}

local darkluaAliases = {
	["@pkgs"] = `./{repositoryConfig.wth.dirs.packages}`,
	["@libs"] = `./{repositoryConfig.wth.dirs.source}/libs`,
}

for _, place in places.allPlaces do
	luauAliases[place.name] = `./{place.dirName}`
	darkluaAliases["@" .. place.name] = `./{path.format(place.sourcePath)}`
end

local luauContents = table.concat({
	"-- This file is @generated. Do not edit!",
	"",
	`return {pp(luauAliases)}`,
	"",
}, "\n")

local darklua: json.Object = {
	rules = {
		{
			rule = "convert_require",
			current = {
				name = "luau",
				aliases = darkluaAliases,
				use_luau_configuration = false,
			},
			target = {
				name = "roblox",
				rojo_sourcemap = "./sourcemap.json",
				indexing_style = "wait_for_child",
			},
		},
	} :: json.Array,
}

fs.writeStringToFile(path.join(repositoryConfig.wth.dirs.source, ".config.luau"), luauContents)
fs.writeStringToFile(".darklua.json", json.serialize(darklua, true))
