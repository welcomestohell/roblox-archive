local richterm = require("@batteries/richterm")
local log = require("@libs/log")
local banner = require("@libs/banner")
local cli = require("@libs/cli")
local useMonorepo = require("@libs/useMonorepo")

local args = cli.parser({ description = "Launches and observes the given place for development" })
args:add("place", "positional", { help = "Name of place to build", required = true })
args:parse({ ... })

log.info(useMonorepo())

log.info()
log.info(banner.RICH_TOP, richterm.bold("Chapter 1"), richterm.dim("A Star Upon A Child"))
log.info(banner.RICH_BOT, "[o] Open Roblox Studio ⋅ [b] Rebuild ⋅ [r] Restart ⋅ [q] Quit")
