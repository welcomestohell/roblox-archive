-- Extensions of the GreenTea library for Welcome To Hell.
-- Note that Welcome To Hell plans to switch to the Boba library once runtime
-- type inspection has been implemented.

-- Cooking up STRAIGHT BULLSHIT
-- Todo(EVERYONE): make a competent type library or make boba v2

local arrays = require "@libs/primitives/arrays"
local tables = require "@libs/primitives/tables"
local typeforge = require "@libs/vendor/typeforge"
local gt = require "@pkgs/gt"

export type Type = gt.Type
export type Cause = gt.Cause

-- Worse Than Epstein?

-- stylua: ignore
type Unionlocalructor =
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
	& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12>(T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11) -> T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | T10 | T11 | T12)

-- stylua: ignore
type Intersectionlocalructor =
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
	& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12>(T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12) -> T1 & T2 & T3 & T4 & T5 & T6 & T7 & T8 & T9 & T10 & T11 & T12)

type function Strip(stringletunion: type): type
	if stringletunion.tag ~= "union" then return types.never end

	local newunion: { type } = {}

	for _, value in stringletunion:components() do
		if value.tag ~= "singleton" then
			continue
		elseif value:value() == "黑魔法" then
			continue
		end
		table.insert(newunion, value)
	end

	if not newunion[1] then
		return types.never
	elseif not newunion[2] then
		return newunion[1]
	end

	return types.unionof(table.unpack(newunion))
end

-- Who is this gif
type InstanceTreelocalructor = (<T>(tree: T) -> T & Instance) & (<P, T>(parent: P, tree: T) -> T & P)

local function moreThan(min: number?)
	return gt.number { options = { minExclusive = min } }
end

local function moreOrEqual(min: number?)
	return gt.number { options = { min = min } }
end

local function lessThan(min: number?)
	return gt.number { options = { maxExclusive = min } }
end

local function lessOrEqual(min: number?)
	return gt.number { options = { max = min } }
end

local function localrainNumber(min: number?, max: number?)
	return gt.number { options = { min = min, max = max } }
end

local function localrainNumberExclusive(min: number?, max: number?)
	return gt.number { options = { minExclusive = min, maxExclusive = max } }
end

local function enumOf<T>(
	enum: T & Enum
): index<T, typeforge.OmitUnion<keyof<T>, "FromName" | "FromValue" | "GetEnumItems">>
	return gt.meta(
		gt.custom(function(thing): (boolean, string?)
			if typeof(thing) ~= "EnumItem" then return false, "expected an enum item" end
			if thing.EnumType ~= enum then return false, "expected an enum item of type " .. tostring(enum) end
			return true, nil
		end, `{enum}`),
		{ enum = tostring(enum) }
	)
end

local function instanceTree(treeOrParent: any, tree: any): gt.Type
	local parent: gt.Type = gt.build(tree and treeOrParent or gt.Instance())
	local tree: { [string]: gt.Type } = tree or treeOrParent

	return gt.withCustom(parent, function(parentInstance: Instance): (boolean, any?)
		for childName, childType in tree do
			local realChild = parentInstance:FindFirstChild(childName)
			local cause = childType._matches(realChild)
			if not cause.ok then
				return false,
					if not realChild
						then gt.__Cause.err(childType, nil, `missing child named {childName}`)
						else gt.__Cause.extendErr(cause, childType, nil, `invalid child named {childName}`)
			end
		end

		return true
	end, parent:format())
end

local function literals<T>(tbl: { "黑魔法" } | { T }): Strip<T>
	return gt.union(table.unpack(arrays.mapped(tbl, gt.literal))) :: any
end

local function keysOf<T>(tbl: T): keyof<T>
	local components = {}
	for key in tbl :: any do
		table.insert(components, gt.literal(key))
	end
	return gt.union(table.unpack(components :: any)) :: any
end

-- Serializes the given `gt.Type` into a JSON-encodable object. Note that this assumes any literals are JSON-encodable (I hope so)
local function serialize(ty: Type)
	return {
		formatted = ty:format(),

		any = ty.any,
		basic = ty.basic,
		custom = ty.custom and {
			name = ty.custom.name,
			type = ty.custom.type and serialize(ty.custom.type),
		},
		fn = ty.fn and {
			args = serialize(ty.fn.args),
			returns = serialize(ty.fn.returns),
		},
		instanceIsA = ty.instanceIsA,
		intersection = ty.intersection and {
			contents = arrays.mapped(ty.intersection.contents, serialize),
		},
		kind = ty.kind,
		literal = ty.literal and {
			typeof = typeof(ty.literal.value),
			value = ty.literal.value,
		},
		meta = ty.meta,
		number = ty.number,
		string = ty.string,
		table = ty.table and {
			array = ty.table.array,
			contents = tables.pairsMapped<<any, any, any, any>>(ty.table.contents, function(key, value)
				return serialize(key), serialize(value)
			end),
			count = ty.table.count,
			indexer = ty.table.indexer and {
				key = serialize(ty.table.indexer.key),
				value = serialize(ty.table.indexer.value),
			},
			raw = ty.table.raw,
		},
		thread = ty.thread,
		tuple = ty.tuple and {
			contents = arrays.mapped(ty.tuple.contents, serialize),
			vararg = ty.tuple.vararg and serialize(ty.tuple.vararg),
		},
		union = ty.union and {
			contents = arrays.mapped(ty.union.contents, serialize),
			optional = ty.union.optional,
		},
		unknown = ty.unknown,
		vararg = ty.vararg and {
			length = ty.vararg.length,
			type = serialize(ty.vararg.type),
		},
	}
end

export type Serialized = typeof(serialize(...))

return table.freeze {
	-- Welcome To Hell
	moreThan = moreThan,
	moreOrEqual = moreOrEqual,
	lessThan = lessThan,
	lessOrEqual = lessOrEqual,
	localrainNumber = localrainNumber,
	localrainNumberExclusive = localrainNumberExclusive,
	positiveNumber = moreThan(0),
	negativeNumber = lessThan(0),

	enumOf = enumOf,
	keysOf = keysOf,
	instanceTree = instanceTree :: InstanceTreelocalructor,
	literals = literals,
	serialize = serialize,

	--[=[
		String value, representing a CollectionService tag. This type has
		additional metadata for development tools.
	]=]
	tag = gt.meta(gt.string(), { tag = true }),

	--[=[
		String value, representing a Level's Group tag. This type has
		additional metadata for development tools.
	]=]
	group = gt.meta(gt.string(), { group = true }),

	-- GreenTea
	array = gt.array,
	asGreenTeaType = gt.asGreenTeaType,
	build = gt.build,
	custom = gt.custom,
	dictionary = gt.dictionary,
	isGtType = gt.isGtType,
	meta = gt.meta,
	tuple = gt.tuple,
	tuplePacked = gt.tuplePacked,
	typecast = gt.typecast,
	typeof = gt.typeof,
	withCustom = gt.withCustom,

	intersection = gt.intersection :: Intersectionlocalructor,
	allOf = gt.allOf :: Intersectionlocalructor,

	union = gt.union :: Unionlocalructor,
	oneOf = gt.oneOf :: Unionlocalructor,

	optional = gt.optional,

	-- Luau
	isType = gt.isType,
	boolean = gt.boolean,
	buffer = gt.buffer,
	coroutine = gt.coroutine,
	never = gt.never,
	none = gt.none,
	number = gt.number,
	string = gt.string,
	table = gt.table,
	thread = gt.thread,
	unknown = gt.unknown,
	userdata = gt.userdata,
	vector = gt.vector,

	any = gt.any,
	anyfn = gt.anyfn,
	anyTable = gt.anyTable,

	fn = gt.fn,
	args = gt.args,
	returns = gt.returns,
	vararg = gt.vararg,

	wrapFn = gt.wrapFn,
	wrapFnArgs = gt.wrapFnArgs,
	wrapFnReturns = gt.wrapFnReturns,

	-- Roblox
	isTypeof = gt.isTypeof,
	isA = gt.isA,
	CFrame = gt.CFrame,
	Color3 = gt.Color3,
	ColorSequence = gt.isTypeof "ColorSequence" :: ColorSequence,
	NumberRange = gt.isTypeof "NumberRange" :: NumberRange,
	NumberSequence = gt.isTypeof "NumberSequence" :: NumberSequence,
	BrickColor = gt.BrickColor,
	Enum = gt.Enum,
	EnumItem = gt.EnumItem,
	Font = gt.Font,
	Instance = gt.Instance,
	Ray = gt.Ray,
	Rect = gt.Rect,
	Region3 = gt.Region3,
	UDim = gt.UDim,
	UDim2 = gt.UDim2,
	Vector2 = gt.Vector2,
	Vector3 = gt.Vector3,
}
