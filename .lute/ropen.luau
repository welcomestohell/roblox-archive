local cli = require("@batteries/cli")
local run = require("@lib/utils/run")
local system = require("@lute/system")

local args = cli.parser()
args:add("script", "positional", { help = "This script", required = true })
args:add("placeid", "positional", { help = "Place ID to open", required = true })
args:parse({ ... })

local function open(url)
	run(if system.os == "windows" then "explorer" elseif system.os == "Darwin" then "open" else "xdg-open", { url })
end

open(`roblox-studio:1+task:EditPlace+placeId:{args:get("placeid")}+universeId:0`)
