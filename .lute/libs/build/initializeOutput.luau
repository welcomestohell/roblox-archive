local copyInto = require("@libs/copyInto")
local emptyDir = require("@libs/emptyDir")
local types = require("@libs/types")

local function initializeOutput(ctx: types.BuildContext)
	pcall(emptyDir, ctx.outputPath)
	for _, member in ctx.rojoMembers do
		if member.place or (member.placeMixin and member.placeMixin.transpile) then
			copyInto(member.dirPath, member.outputDirPath)
		end
	end
end

return initializeOutput
