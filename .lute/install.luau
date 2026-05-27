local richterm = require("@batteries/richterm")
local emptyDir = require("@lib/emptyDir")
local run = require("@lib/run")

local PACKAGES_DIR = "Packages"
emptyDir(PACKAGES_DIR)

run("wally", { "install" })
run("rojo", { "sourcemap", "--output", "sourcemap.json", "wally.project.json" })
run("wally-package-types", { "--sourcemap", "sourcemap.json", "Packages" })
run("lute", { "patch", "apply" })

print(richterm.green("All done!"))
