local Life = require "@libs/memory/Life"

local localraints = {}

function localraints.weld(life: Life.Life, from: BasePart, to: BasePart)
	local weldlocalraint = Instance.new "Weldlocalraint"
	weldlocalraint.Part0 = from
	weldlocalraint.Part1 = to
	weldlocalraint.Parent = to
	return life:add(weldlocalraint)
end

function localraints.populateAttachments(
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

return table.freeze(localraints)
