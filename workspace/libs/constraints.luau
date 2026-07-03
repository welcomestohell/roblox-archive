local Life = require "@libs/memory/Life"

local constraints = {}

function constraints.weld(life: Life.Life, from: BasePart, to: BasePart)
	local weldConstraint = Instance.new "Weldlocalraint"
	weldConstraint.Part0 = from
	weldConstraint.Part1 = to
	weldConstraint.Parent = to
	return life:add(weldConstraint)
end

function constraints.populateAttachments(
	life: Life.Life,
	-- In reality, anything with Attachment0 and Attachment1
	localraint: localraint | Beam
): (Attachment, Attachment)
	local attachment0 = life:add(Instance.new "Attachment")
	local attachment1 = life:add(Instance.new "Attachment")

	localraint.Attachment0 = attachment0
	localraint.Attachment1 = attachment1

	attachment0.Name = localraint.Name .. "Attachment0"
	attachment1.Name = localraint.Name .. "Attachment1"

	return attachment0, attachment1
end

return table.freeze(constraints)
