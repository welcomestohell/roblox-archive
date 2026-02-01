local fs = require "@std/fs"
local process = require "@lute/process"
local task = require "@lute/task"

fs.removedirectory("out", { recursive = true })
process.run { "cp", "-r", "src", "out" }
process.run { "rojo", "sourcemap", "-o", "sourcemap.json", "sourcemap.project.json" }
task.spawn(process.run, { "rojo", "sourcemap", "-o", "sourcemap.json", "sourcemap.project.json", "--watch" }, nil)
task.spawn(
	process.run,
	{ "darklua", "process", "--watch", "src", "out" },
	{ stdio = "inherit" } :: process.ProcessRunOptions
)
task.spawn(process.run, { "rojo", "serve" }, nil)

print "Now serving Welcome To Hell"
