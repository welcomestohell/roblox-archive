local fs = require "@std/fs"
local process = require "@lute/process"
local system = require("@lute/system")
local task = require "@lute/task"

process.run(if system.os ~= "Darwin" then { "robocopy", "src", "out", "/E" } else { "cp", "-r", "src", "out" })

if not fs.exists("sourcemap.json") then
	process.run(
		{ "rojo", "sourcemap", "-o", "sourcemap.json", "sourcemap.project.json" },
		{ stdio = "inherit" } :: process.ProcessRunOptions
	)
end
task.spawn(
	process.run,
	{ "rojo", "sourcemap", "-o", "sourcemap.json", "sourcemap.project.json", "--watch" },
	{ stdio = "inherit" } :: process.ProcessRunOptions
)

task.wait(1)

task.spawn(
	process.run,
	{ "darklua", "process", "--watch", "src", "out" },
	{ stdio = "inherit" } :: process.ProcessRunOptions
)
task.spawn(process.run, { "blink", ".blink", "--watch" }, { stdio = "inherit" } :: process.ProcessRunOptions)

task.spawn(process.run, { "rojo", "serve" }, { stdio = "inherit" } :: process.ProcessRunOptions)

task.wait(1)
print "Now watching for changes"
