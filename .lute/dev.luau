local richterm = require("@batteries/richterm")
local log = require("@libs/log")
local banner = require("@libs/banner")
local cli = require("@libs/cli")
local rojo = require("@libs/rojo")
local useMonorepo = require("@libs/useMonorepo")
local usePlaceDependencies = require("@libs/usePlaceDependencies")
local useRepositoryConfig = require("@libs/useRepositoryConfig")
local io = require("@lute/io")
local fs = require("@std/fs")
local json = require("@std/json")

local OUTPUT_DIR = ".output"

local args = cli.parser({ description = "Launches and observes the given place for development" })
args:add("place", "positional", { help = "Name of place to build", required = true })
args:parse({ ... })

local repository = useRepositoryConfig()
local outputProject = repository.wth.paths.outputProject
local sourcemapProject = repository.wth.paths.sourcemapProject
local outputDir = repository.wth.paths.output

local monorepo = useMonorepo()
local member = monorepo[args:get("place")] or log.throw(`Unknown place named {args:get("place")}`)
local place = member.place or log.throw(`Member {member.dirName} is not a place (does it have a place field?)`)
local placeId = place.placeId or log.throw(`{place.title} is an abstract place (does it have a placeId?)`)

local dependencies = usePlaceDependencies(monorepo, member)
local rojoMembers = table.clone(dependencies)
table.insert(rojoMembers, 1, member)

fs.writeStringToFile(outputProject, json.serialize(rojo.projectFromMembers("output", rojoMembers), true))
fs.writeStringToFile(sourcemapProject, json.serialize(rojo.projectFromMembers("source", rojoMembers), true))
fs.createDirectory(outputDir, { makeParents = true })
