local richterm = require("@batteries/richterm")
local log = require("@libs/log")
local banner = require("@libs/banner")
local initialize = require("@libs/build/initialize")
local cli = require("@libs/cli")
local useMonorepo = require("@libs/useMonorepo")
local usePlaceDependencies = require("@libs/usePlaceDependencies")
local useRepositoryConfig = require("@libs/useRepositoryConfig")
local types = require("./libs/types")

local OUTPUT_DIR = ".output"

local args = cli.parser({ description = "Launches and observes the given place for development" })
args:add("place", "positional", { help = "Name of place to build", required = true })
args:parse({ ... })

local repository = useRepositoryConfig()

local monorepo = useMonorepo()
local member = monorepo[args:get("place")] or log.throw(`Unknown place named {args:get("place")}`)
local place = member.place or log.throw(`Member {member.dirName} is not a place (does it have a place field?)`)
local placeId = place.placeId or log.throw(`{place.title} is an abstract place (does it have a placeId?)`)

local state: types.BuildState = {
	monorepo = monorepo,
	repository = repository,

	member = member,
	place = place,
	dependencies = usePlaceDependencies(monorepo, member),

	cache = {},
	sourcemap = {},
}

initialize(state)
