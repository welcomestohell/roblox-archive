local copyInto = require("@libs/copyInto")
local emptyDir = require("@libs/emptyDir")
local types = require("@libs/types")

local function initializeOutput(state: types.BuildState)
	pcall(emptyDir, state.outputPath)
	for _, member in state.rojoMembers do
		if member.place or (member.placeMixin and member.placeMixin.transpile) then
			copyInto(member.dirPath, member.outputDirPath)
		end
	end
end

return initializeOutput
