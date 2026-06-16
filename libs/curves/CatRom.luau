const Base = require "@roblox_packages/CatRom"

const CatRom = {}
CatRom.__index = CatRom

export type CatRom = setmetatable<{ points: { Vector3 }, solver: typeof(Base.new(...)) }, typeof(CatRom)>

function CatRom.new(props: { points: { Vector3 } }): CatRom
	return setmetatable({ points = props.points, solver = Base.new(props.points :: { any }, 0.5, 0) }, CatRom)
end

function CatRom.solvePosition(self: CatRom, alpha: number): Vector3
	return self.solver:SolvePosition(alpha) :: Vector3
end

return table.freeze(CatRom)
