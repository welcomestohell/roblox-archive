const types = require "@self/types"

export type Curve = types.Curve

const curves = {
	Bezier = require "@self/Bezier",
	CatRom = require "@self/CatRom",
	Catenary = require "@self/Catenary",
	Linear = require "@self/Linear",
}

curves.CURVES = curves :: { [string]: Curve }
return table.freeze(curves)
