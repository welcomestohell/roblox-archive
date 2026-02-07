local Attribute = require("@libs/Attribute")
local character = require("@libs/character")
local gt = require("./gt")

local isFromMaybeCharacter = character.isFromMaybeCharacter

local SupportsCharacter = Attribute.new("SupportsCharacter", gt.boolean(), false)
local SupportsBoxes = Attribute.new("SupportsBoxes", gt.boolean(), false)
local BoxesRequiresMatchingId = Attribute.new("BoxesRequiresMatchingId", gt.boolean(), false)
local RequiredBoxId = Attribute.new("RequiredBoxId", gt.string())

local function isToucherValid(target: Attribute.ResolvableInstance, toucher: BasePart)
	if SupportsCharacter(target) and isFromMaybeCharacter(toucher) then
		return true
	end

	return false
end

local function isToucherCharacter(target: Attribute.ResolvableInstance, toucher: BasePart)
	return SupportsCharacter(target) and isFromMaybeCharacter(toucher)
end

return {
	isToucherValid = isToucherValid,
	isToucherCharacter = isToucherCharacter,
	SupportsCharacter = SupportsCharacter,
	SupportsBoxes = SupportsBoxes,
	BoxesRequiresMatchingId = BoxesRequiresMatchingId,
	RequiredBoxId = RequiredBoxId,
}
