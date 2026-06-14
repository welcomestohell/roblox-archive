const std = require "@libs/std"
const toggle = require "@libs/toggle"

const BeatBlock = std.Mechanic {
	emoji = "🎶",
	name = "BeatBlock",
	description = "Currently overrideMusic is always active",
	instanceType = std.isA.Folder(),

	StartingBlockID = std.Attribute("StartingBlockID", std.gt.number { range = { min = 0, max = math.huge } }, 1),
	OverrideMusic = std.Attribute("OverrideBeat", std.gt.boolean(), false),
	BlockSwitchTime = std.Attribute("BlockSwitchTime", std.gt.number { range = { min = 0, max = math.huge } }, 1),
}

export type BeatBlocksMechanic = std.Mechanic<typeof(BeatBlock)>

type BeatBlockContainer = Folder | Model

local function toggleBlock(enabled: boolean, object: Instance)
	for _, v in ipairs(object:GetDescendants()) do
		if
			v:IsA "BasePart"
			or v:IsA "Beam"
			or v:IsA "ParticleEmitter"
			or v:IsA "Trail"
			or v:IsA "PointLight"
			or v:IsA "SpotLight"
			or v:IsA "SurfaceLight"
		then
			toggle.toggleInstance(enabled, v, object)
		end
	end
end

function BeatBlock.onStart(self: typeof(BeatBlock), blocks: BeatBlocksMechanic, level: std.Level)
	local beatBlocks: { BeatBlockContainer } = {}
	for _, v in ipairs(blocks.instance:GetChildren()) do
		if not v:IsA "Folder" and not v:IsA "Model" then
			if v.Name ~= "BeatBlockConfiguration" then
				warn(v.Name .. " is not a valid beat-block container (Folder/Model expected)")
			end
		else
			table.insert(beatBlocks, v :: Folder | Model)
		end
	end

	const blockCount = #beatBlocks

	if blockCount == 0 then
		warn("No beat blocks found in " .. blocks.instance.Name)
		return
	end

	local index = math.clamp(blocks:StartingBlockID(), 1, blockCount)

	while true do
		task.wait(blocks:BlockSwitchTime())
		local current = beatBlocks[index]

		if current then
			for _, b in ipairs(beatBlocks) do
				toggleBlock(false, b)
			end

			toggleBlock(true, current)

			index += 1
			if index > blockCount then index = 1 end
		else
			warn("Invalid beat block index: " .. tostring(index))
		end
	end
end

return BeatBlock
