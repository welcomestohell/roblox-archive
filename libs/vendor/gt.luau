-- Extensions of the GreenTea library for Welcome To Hell.
-- Note that Welcome To Hell plans to switch to the Boba library once runtime
-- type inspection has been implemented.

local GreenTea = require "@roblox_packages/gt"

export type Type = GreenTea.Type
export type Cause = GreenTea.Cause

local gt = {
	allOf = GreenTea.allOf,
	any = GreenTea.any,
	anyfn = GreenTea.anyfn,
	anyTable = GreenTea.anyTable,
	args = GreenTea.args,
	array = GreenTea.array,
	asGreenTeaType = GreenTea.asGreenTeaType,
	boolean = GreenTea.boolean,
	BrickColor = GreenTea.BrickColor,
	buffer = GreenTea.buffer,
	build = GreenTea.build,
	CFrame = GreenTea.CFrame,
	Color3 = GreenTea.Color3,
	ColorSequence = GreenTea.isTypeof "ColorSequence" :: ColorSequence,
	coroutine = GreenTea.coroutine,
	custom = GreenTea.custom,
	dictionary = GreenTea.dictionary,
	Enum = GreenTea.Enum,
	EnumItem = GreenTea.EnumItem,
	fn = GreenTea.fn,
	Font = GreenTea.Font,
	Instance = GreenTea.Instance,
	isA = GreenTea.isA,
	isGtType = GreenTea.isGtType,
	isType = GreenTea.isType,
	isTypeof = GreenTea.isTypeof,
	meta = GreenTea.meta,
	never = GreenTea.never,
	none = GreenTea.none,
	number = GreenTea.number,
	NumberRange = GreenTea.isTypeof "NumberRange" :: NumberRange,
	NumberSequence = GreenTea.isTypeof "NumberSequence" :: NumberSequence,
	oneOf = GreenTea.oneOf,
	optional = GreenTea.optional,
	Ray = GreenTea.Ray,
	Rect = GreenTea.Rect,
	Region3 = GreenTea.Region3,
	returns = GreenTea.returns,
	string = GreenTea.string,
	table = GreenTea.table,
	thread = GreenTea.thread,
	tuple = GreenTea.tuple,
	tuplePacked = GreenTea.tuplePacked,
	typecast = GreenTea.typecast,
	typeof = GreenTea.typeof,
	UDim = GreenTea.UDim,
	UDim2 = GreenTea.UDim2,
	unknown = GreenTea.unknown,
	userdata = GreenTea.userdata,
	vararg = GreenTea.vararg,
	vector = GreenTea.vector,
	Vector2 = GreenTea.Vector2,
	Vector3 = GreenTea.Vector3,
	withCustom = GreenTea.withCustom,
	wrapFn = GreenTea.wrapFn,
	wrapFnArgs = GreenTea.wrapFnArgs,
	wrapFnReturns = GreenTea.wrapFnReturns,

	-- stylua: ignore
	union = GreenTea.union ::
		& (<T1, T2>(T1, T2) -> T1 | T2)
		& (<T1, T2, T3>(T1, T2, T3) -> T1 | T2 | T3)
		& (<T1, T2, T3, T4>(T1, T2, T3, T4) -> T1 | T2 | T3 | T4)
		& (<T1, T2, T3, T4, T5>(T1, T2, T3, T4, T5) -> T1 | T2 | T3 | T4 | T5)
		& (<T1, T2, T3, T4, T5, T6>(T1, T2, T3, T4, T5, T6) -> T1 | T2 | T3 | T4 | T5 | T6)
		& (<T1, T2, T3, T4, T5, T6, T7>(T1, T2, T3, T4, T5, T6, T7) -> T1 | T2 | T3 | T4 | T5 | T6 | T7)
		& (<T1, T2, T3, T4, T5, T6, T7, T8>(T1, T2, T3, T4, T5, T6, T7, T8) -> T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, T9>(T1, T2, T3, T4, T5, T6, T7, T8, T9) -> T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10>(T1, T2, T3, T4, T5, T6, T7, T8, T9, T10) -> T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | T10)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11>(T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11) -> T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | T10 | T11)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12>(T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11) -> T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | T10 | T11 | T12),

	-- stylua: ignore
	intersection = GreenTea.intersection ::
		& (<T1, T2>(T1, T2) -> T1 & T2)
		& (<T1, T2, T3>(T1, T2, T3) -> T1 & T2 & T3)
		& (<T1, T2, T3, T4>(T1, T2, T3, T4) -> T1 & T2 & T3 & T4)
		& (<T1, T2, T3, T4, T5>(T1, T2, T3, T4, T5) -> T1 & T2 & T3 & T4 & T5)
		& (<T1, T2, T3, T4, T5, T6>(T1, T2, T3, T4, T5, T6) -> T1 & T2 & T3 & T4 & T5 & T6)
		& (<T1, T2, T3, T4, T5, T6, T7>(T1, T2, T3, T4, T5, T6, T7) -> T1 & T2 & T3 & T4 & T5 & T6 & T7)
		& (<T1, T2, T3, T4, T5, T6, T7, T8>(T1, T2, T3, T4, T5, T6, T7, T8) -> T1 & T2 & T3 & T4 & T5 & T6 & T7 & T8)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, T9>(T1, T2, T3, T4, T5, T6, T7, T8, T9) -> T1 & T2 & T3 & T4 & T5 & T6 & T7 & T8 & T9)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10>(T1, T2, T3, T4, T5, T6, T7, T8, T9, T10) -> T1 & T2 & T3 & T4 & T5 & T6 & T7 & T8 & T9 & T10)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11>(T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11) -> T1 & T2 & T3 & T4 & T5 & T6 & T7 & T8 & T9 & T10 & T11)
		& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12>(T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12) -> T1 & T2 & T3 & T4 & T5 & T6 & T7 & T8 & T9 & T10 & T11 & T12),
}

local function instanceTree(treeOrParent: any, tree: any): GreenTea.Type
	local parent: GreenTea.Type = GreenTea.build(tree and treeOrParent or GreenTea.Instance())
	local tree: { [string]: GreenTea.Type } = tree or treeOrParent

	return GreenTea.withCustom(parent, function(parentInstance: Instance): (boolean, any?)
		for childName, childType in tree do
			local realChild = parentInstance:FindFirstChild(childName)
			local cause = childType._matches(realChild)
			if not cause.ok then
				return false,
					if not realChild
						then GreenTea.__Cause.err(childType, nil, `missing child named {childName}`)
						else GreenTea.__Cause.extendErr(cause, childType, nil, `invalid child named {childName}`)
			end
		end

		return true
	end, parent:format())
end

function gt.moreThan(min: number?) return gt.number { options = { minExclusive = min } } end
function gt.moreOrEqual(min: number?) return gt.number { options = { min = min } } end
function gt.lessThan(min: number?) return gt.number { options = { maxExclusive = min } } end
function gt.lessOrEqual(min: number?) return gt.number { options = { max = min } } end
function gt.constrainNumber(min: number?, max: number?) return gt.number { options = { min = min, max = max } } end
function gt.constrainNumberExclusive(min: number?, max: number?)
	return gt.number { options = { minExclusive = min, maxExclusive = max } }
end
gt.positiveNumber = gt.constrainNumberExclusive(0)
gt.negativeNumber = gt.constrainNumberExclusive(nil, 0)

function gt.enumOf<T>(enum: Enum): any
	return GreenTea.custom(function(thing)
		if typeof(thing) ~= "EnumItem" then return false, "expected an enum item" end
		if thing.EnumType ~= enum then return false, "expected an enum item of type " .. tostring(enum) end
		return true
	end, `{enum}`)
end

function gt.unionLiterals(...: any): any
	local len = select("#", ...)
	local components = table.create(len)
	for index = 1, len do
		components[index] = gt.literal(select(index, ...))
	end
	return (gt.union :: any)(table.unpack(components, 1, len))
end

gt.literal = (GreenTea.literal :: any) :: <T>(x: T | "") -> T
gt.instanceTree = instanceTree :: (<T>(tree: T) -> T & Instance) & (<P, T>(parent: P, tree: T) -> T & P)

gt.unionLiterals1 = gt.unionLiterals :: <T1>(T1 | "") -> T1
gt.unionLiterals2 = gt.unionLiterals :: <T1, T2>(T1 | "", T2 | "") -> T1 | T2
gt.unionLiterals3 = gt.unionLiterals :: <T1, T2, T3>(T1 | "", T2 | "", T3 | "") -> T1 | T2 | T3
gt.unionLiterals4 = gt.unionLiterals :: <T1, T2, T3, T4>(T1 | "", T2 | "", T3 | "", T4 | "") -> T1 | T2 | T3 | T4
gt.unionLiterals5 =
	gt.unionLiterals :: <T1, T2, T3, T4, T5>(T1 | "", T2 | "", T3 | "", T4 | "", T5 | "") -> T1 | T2 | T3 | T4 | T5

return table.freeze(gt)
