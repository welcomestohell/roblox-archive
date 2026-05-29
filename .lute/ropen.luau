local cli = require("@libs/cli")
local run = require("@libs/run")
local system = require("@lute/system")

local args = cli.parser({ description = "Opens a given place ID in Roblox Studio" })
args:add("placeid", "positional", { help = "Place ID to open", required = true })
args:parse({ ... })

local function open(url)
	run(if system.os == "windows" then "explorer" elseif system.os == "Darwin" then "open" else "xdg-open", { url })
end

open(`roblox-studio:1+task:EditPlace+placeId:{args:get("placeid")}+universeId:0`)
