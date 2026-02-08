local Life = require("@libs/Life")

local Explorer = {}
Explorer.__index = Explorer
Explorer.title = "Explorer"

export type Explorer = setmetatable<{ life: Life.Life }, typeof(Explorer)>

function Explorer.new(life: Life.Life)
	return setmetatable({ life = life }, Explorer)
end

function Explorer.renderViewport() end

function Explorer.renderWindow() end

return Explorer
