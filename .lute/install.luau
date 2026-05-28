local emptyDir = require("@lib/utils/emptyDir")
local richterm = require("@batteries/richterm")
local run = require("@lib/utils/run")

local PACKAGES_DIR = "Packages"
emptyDir(PACKAGES_DIR)

run("wally", { "install" })
run("wally-package-types", { "--sourcemap", "sourcemap.json", "Packages" })
run("wally-package-types", { "--sourcemap", "sourcemap.json", "DevPackages" })
run("lute", { "patch", "apply" })

print(richterm.green("All done!"))
