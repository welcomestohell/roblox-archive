local Life = require("@libs/Life")
local Mechanics = {}
Mechanics.__index = Mechanics
Mechanics.title = "Mechanics"

export type Mechanics = setmetatable<{ life: Life.Life }, typeof(Mechanics)>

function Mechanics.new(life: Life.Life)
	return setmetatable({ life = life }, Mechanics)
end

function Mechanics.renderViewport() end

function Mechanics.renderWindow() end

return Mechanics
