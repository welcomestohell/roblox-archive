local emptyDir = require "@scripts/libs/emptyDir"
const fs = require "@std/fs"
const run = require "@scripts/libs/run"

const LUAU_CONFIG = [[return {
	luau = {
		languageMode = "nocheck",
		lint = { ["*"] = false },
	},
	wth = {
		placeMixin = {
			folderName = "Packages",
			rojo = {
				{ name = "ReplicatedStorage" },
			},
		},
	},
}
]]

pcall(emptyDir, "roblox_packages")
run("pesde", { "install" })
fs.writeStringToFile("roblox_packages/.config.luau", LUAU_CONFIG)
