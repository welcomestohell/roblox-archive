local copyInto = require("@libs/copyInto")
local emptyDir = require("@libs/emptyDir")
local types = require("@libs/types")

local function initializeOutput(state: types.BuildState)
	local output = state.repository.wth.paths.output

	pcall(emptyDir, output)

	copyInto(state.member.dirPath, state.member.outputDirPath)
	for _, member in state.dependencies do
		if member.place or (member.placeMixin and member.placeMixin.transpile) then
			copyInto(member.dirPath, member.outputDirPath)
		end
	end
end

return initializeOutput
