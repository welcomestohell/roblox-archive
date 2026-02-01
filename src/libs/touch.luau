local Attribute = require("@libs/Attribute")
local character = require("@libs/character")
local std = require("@libs/std")

local isFromMaybeCharacter = character.isFromMaybeCharacter

local SupportsCharacter = Attribute.new("SupportsCharacter", std.gt.boolean, false)
local SupportsBoxes = Attribute.new("SupportsBoxes", std.gt.boolean, false)
local BoxesRequiresMatchingId = Attribute.new("BoxesRequiresMatchingId", std.gt.boolean, false)
local RequiredBoxId = Attribute.new("RequiredBoxId", std.gt.string)

local function isToucherValid(target: Instance, toucher: BasePart)
	if SupportsCharacter:get(target) and isFromMaybeCharacter(toucher) then
		return true
	end

	return false
end

local function isToucherCharacter(target: Instance, toucher: BasePart)
	return SupportsCharacter:get(target) and isFromMaybeCharacter(toucher)
end

return {
	isToucherValid = isToucherValid,
	isToucherCharacter = isToucherCharacter,
	SupportsCharacter = SupportsCharacter,
	SupportsBoxes = SupportsBoxes,
	BoxesRequiresMatchingId = BoxesRequiresMatchingId,
	RequiredBoxId = RequiredBoxId,
}
