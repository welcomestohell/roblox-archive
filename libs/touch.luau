local Mechanic = require "@libs/core/Mechanic"
local character = require "./character"
local gt = require "@libs/vendor/gt"

const function useAttributes(implementation: Mechanic.MechanicImplementation, basename: string?)
	basename = basename or "Touch"

	implementation:attributeSection "Touch"
	local attributes = {
		CollisionGroup = implementation:attribute(basename .. "CollisionGroup", gt.optional(gt.string()), nil),
		SupportsCharacter = implementation:attribute(basename .. "SupportsCharacter", gt.boolean(), false),
		SupportsBullets = implementation:attribute(basename .. "SupportsBullets", gt.boolean(), false),
		SupportsBoxes = implementation:attribute(basename .. "SupportsBoxes", gt.boolean(), false),
	}
	implementation:endAttributeSection()
	return attributes
end

export type TouchAttributes = typeof(useAttributes(nil :: any))

const function isToucherValid(
	attributes: TouchAttributes,
	instance: Instance,
	instanceConfiguration: Instance,
	toucher: BasePart
)
	-- local collisionGroup = attributes.CollisionGroup(instanceConfiguration)
	-- local isCollisionGroupEmpty = collisionGroup == nil or collisionGroup == ""
	-- local isCollisionGroupValid = (
	-- 	collisionGroup == nil
	-- 	or collisionGroup == ""
	-- 	or PhysicsService:CollisionGroupsAreCollidable(toucher.CollisionGroup, collisionGroup :: string)
	-- )

	-- if not isCollisionGroupValid then
	-- 	return false
	-- end

    -- stylua: ignore
	return (attributes.SupportsCharacter(instanceConfiguration) and character.isFromMaybeCharacter(toucher))
		or (attributes.SupportsBullets(instanceConfiguration) and (toucher:HasTag("Bullet") or toucher:FindFirstAncestor("Bullet") ~= nil))
		or (attributes.SupportsBoxes(instanceConfiguration) and (toucher:HasTag("Box") or toucher:FindFirstAncestor("Box") ~= nil))
end

const function castIntoTarget(toucher: BasePart)
	if character.isFromMaybeCharacter(toucher) then
		return character.getHumanoidRootPart()
	else
		return toucher
	end
end

return table.freeze {
	useAttributes = useAttributes,
	isToucherValid = isToucherValid,
	castIntoTarget = castIntoTarget,
}
