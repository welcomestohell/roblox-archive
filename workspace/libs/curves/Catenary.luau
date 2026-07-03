-- Speed hieroglyphics gif
--
-- Sources:
--   https://www.alanzucconi.com/2020/12/13/catenary-1/
--   https://www.alanzucconi.com/2020/12/13/catenary-2/
--   https://en.wikipedia.org/wiki/Catenary#Mathematical_description

local PRECISION = 0.00001

local Catenary = {}
Catenary.__index = Catenary

export type Catenary = setmetatable<{
	points: { Vector3 },
	solvers: { (t: number) -> Vector3 },
}, typeof(Catenary)>

const function coth(x: number)
	return 1 / math.tanh(x)
end

function Catenary.solve2D(h: number, v: number, l: number): (number, number, number)
	local target = math.sqrt(l ^ 2 - v ^ 2)

	local aLow = 0.001
	local aHigh = 100000.0
	local a = (aLow + aHigh) / 2

	while aHigh - aLow > PRECISION do
		a = (aLow + aHigh) / 2

		if target >= 2 * a * math.sinh(h / (2 * a)) then
			aHigh = a
		else
			aLow = a
		end
	end

	local n = (l + v) / (l - v)

	local p = (h - a * math.log(n)) / 2
	local q = (v - l * coth(h / (2 * a))) / 2

	return a, p, q
end

function Catenary.create3DSolver(p1: Vector3, p2: Vector3, l: number): (t: number) -> Vector3
	local horizontalDirection = Vector3.new(p2.X - p1.X, 0, p2.Z - p1.Z)
	local h = horizontalDirection.Magnitude
	local v = p2.Y - p1.Y

	const a, p, q = Catenary.solve2D(h, v, l)

	local horizontalUnit = horizontalDirection.Unit

	return function(t)
		local x = h * t
		local y = a * math.cosh((x - p) / a) + q
		return Vector3.new(p1.X + horizontalUnit.X * x, p1.Y + y, p1.Z + horizontalUnit.Z * x)
	end
end

function Catenary.new(props: { points: { Vector3 }, slack: number }): Catenary
	local points = props.points

	local solverCount = #points - 1
	local solvers = table.create(solverCount) :: index<Catenary, "solvers">
	for index = 1, solverCount do
		local p1 = points[index]
		local p2 = points[index + 1]
		local l = (p2 - p1).Magnitude * props.slack
		solvers[index] = Catenary.create3DSolver(p1, p2, l)
	end

	return setmetatable({ points = points, solvers = solvers }, Catenary)
end

function Catenary.solvePosition(self: Catenary, alpha: number): Vector3
	alpha = math.clamp(alpha, 0, 1 - PRECISION)

	local segmentCount = #self.solvers
	if segmentCount <= 1 then return self.points[1] or Vector3.zero end

	local index = alpha * segmentCount
	local segmentIndex = math.clamp(math.floor(index) + 1, 1, segmentCount)
	local t = index - math.floor(index)

	return self.solvers[segmentIndex](t)
end

return table.freeze(Catenary)
