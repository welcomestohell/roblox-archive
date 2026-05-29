local types = require("@libs/types")
local initializeSourcemap = require("./initializeSourcemap")
local initializeRojo = require("./initializeRojo")
local initializeOutput = require("./initializeOutput")

local function initialize(state: types.BuildState)
	initializeOutput(state)
	initializeRojo(state)
	initializeSourcemap(state)
end

return initialize
