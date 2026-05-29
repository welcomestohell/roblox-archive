local richterm = require("@batteries/richterm")
local log = require("@libs/log")
local logo = require("@libs/logo")
local useMonorepo = require("@libs/useMonorepo")

log.info(useMonorepo())

log.info()
log.info(logo.RICH_TOP, richterm.bold("Chapter 1"), richterm.dim("A Star Upon A Child"))
log.info(logo.RICH_BOT, "[o] Open Roblox Studio ⋅ [b] Rebuild ⋅ [r] Restart ⋅ [q] Quit")
