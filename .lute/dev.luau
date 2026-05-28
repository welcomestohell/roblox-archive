local cli = require("@batteries/cli")
local copyInto = require("@lib/utils/copyInto")
local emptyDir = require("@lib/utils/emptyDir")
local fs = require("@std/fs")
local json = require("@std/json")
local path = require("@std/path")
local places = require("@lib/places")
local repositoryConfig = require("@lib/utils/repositoryConfig")()
local richterm = require("@batteries/richterm")
local rojo = require("@lib/rojo")
local run = require("@lib/utils/run")
local task = require("@std/task")

local args = cli.parser()
args:add("script", "positional", { help = "This script", required = true })
args:add("place", "positional", { help = `Place under {repositoryConfig.wth.dirs.source}`, required = true })
args:parse({ ... })

places.initialize()
local place = places.fromDir(args:get("place"))

print(richterm.dim(`Resolving dependencies for {place.name}...`))
local dependencies = places.resolveDependencies(place)

print(richterm.dim("Preparing output folder..."))
if fs.exists(repositoryConfig.wth.dirs.output) then
	emptyDir(repositoryConfig.wth.dirs.output)
else
	fs.createDirectory(repositoryConfig.wth.dirs.output, { makeParents = true })
end
copyInto(place.sourcePath, place.outputPath)
copyInto(path.join(repositoryConfig.wth.dirs.source, "libs"), path.join(repositoryConfig.wth.dirs.output, "libs"))
for _, dependency in dependencies do
	copyInto(dependency.sourcePath, dependency.outputPath)
end

print(richterm.dim("Preparing require aliases..."))
run("lute", { "aliases" })

print(richterm.dim("Preparing Rojo projects..."))
local rojoPlaces = table.clone(dependencies)
table.insert(rojoPlaces, place)
local sourceProject = rojo.projectFromPlace("source", rojoPlaces)
local outputProject = rojo.projectFromPlace("output", rojoPlaces)
fs.writeStringToFile("default.project.json", json.serialize(outputProject, true))
fs.writeStringToFile("sourcemap.project.json", json.serialize(sourceProject, true))

print(richterm.dim("Preparing Rojo sourcemap..."))
-- run it once synchronously so darklua has something to work with
run("rojo", { "sourcemap", "--output", "sourcemap.json", "sourcemap.project.json" })
task.spawn(run, "rojo", { "sourcemap", "--watch", "--output", "sourcemap.json", "sourcemap.project.json" })

print(richterm.dim("Launch!"))
for _, p in rojoPlaces do
	run("blink", { ".blink", "--yes" }, { cwd = p.sourcePath, ignoreFailure = true })
	task.spawn(run, "blink", { ".blink", "--watch" }, { cwd = p.sourcePath } :: run.Options)
end
task.spawn(run, "darklua", { "process", "--watch", repositoryConfig.wth.dirs.source, repositoryConfig.wth.dirs.output })
task.spawn(run, "rojo", { "serve" })

print()
print(richterm.green("Now watching for changes!"))
