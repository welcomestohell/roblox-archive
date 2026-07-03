local Players = game:GetService "Players"

local destruction = require "@libs/memory/destruction"
local emission = require "@libs/emission"
local std = require "@libs/std"
local tables = require "@libs/primitives/tables"
local toggle = require "@libs/toggle"
local triplets = require "@libs/primitives/triplets"
local tweens = require "@libs/tweens"

local BeatBlock = std.Mechanic {
	emoji = "🎶",
	name = "BeatBlock",
	description = "Periodically toggles sequential descendants with beat synchronization.",
	instanceType = std.isA.Instance(),

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Interval = std.Attribute("Interval", std.gt.positiveNumber, 1),
	Index = std.Attribute("Index", std.gt.positiveNumber, 0),

	std.AttributeSection "Emission",
	EmitSwitchedTag = std.Attribute("EmitSwitchedTag", std.gt.tag, "BeatBlock: On Switched"),
	ParentEmittersToClosest = std.Attribute("ParentEmittersToClosest", std.gt.boolean(), true),

	std.AttributeSection "Indicator",
	IndicatorEnabled = std.Attribute("IndicatorEnabled", std.gt.boolean(), true),
	IndicatorInterval = std.Attribute("IndicatorInterval", std.gt.positiveNumber, 0.5),
	IndicatorSizeMultiplier = std.Attribute("IndicatorSizeMultiplier", std.gt.NumberRange, NumberRange.new(0.5, 0.995)),
	IndicatorStyle = std.Attribute("IndicatorStyle", std.gt.enumOf(Enum.EasingStyle), Enum.EasingStyle.Linear),
	IndicatorDirection = std.Attribute(
		"IndicatorDirection",
		std.gt.enumOf(Enum.EasingDirection),
		Enum.EasingDirection.Out
	),
}

export type BeatBlockMechanic = std.Mechanic<typeof(BeatBlock), {
	highestIndex: number,
	blocks: { { BasePart } },
	emitters: { [Instance]: true },
}>

function BeatBlock.calculateHighestIndex(beatblock: BeatBlockMechanic)
	local highestIndex = 0
	for index, blocks in beatblock.blocks do
		if #blocks ~= 0 then highestIndex = math.max(highestIndex, index) end
	end
	beatblock.highestIndex = highestIndex
	return highestIndex
end

function BeatBlock.calculateNextIndex(beatblock: BeatBlockMechanic): number
	return beatblock:Index() :: number % beatblock.highestIndex + 1
end

function BeatBlock.processChild(beatblock: BeatBlockMechanic, child: Instance)
	if not child:IsA "BasePart" then return end
	local index = tonumber(child.Name)

	local childLife = beatblock.life:extend()
	childLife:destroyOn(child.Destroying)
	childLife:destroyOn(child:GetPropertyChangedSignal "Parent")
	childLife:add(child:GetPropertyChangedSignal("Name"):Once(function()
		childLife:destroy()
		beatblock:processChild(child)
	end))

	if index then
		triplets.arrayPush(beatblock.blocks, index, child)
		beatblock:calculateHighestIndex()
		childLife:addMany(function()
			triplets.arrayFindAndRemove(beatblock.blocks, index, child)
			beatblock:calculateHighestIndex()
		end)
	end
end

function BeatBlock.onStart(self: typeof(BeatBlock), beatblock: BeatBlockMechanic, level: std.Level)
	beatblock.highestIndex = 0
	beatblock.blocks = {}
	beatblock.emitters = tables.createWeakened<<Instance, true>> "k"

	beatblock.life:addMany(
		beatblock.instance.ChildAdded:Connect(function(child)
			beatblock.processChild(beatblock, child)
		end),
		beatblock.instance.DescendantAdded:Connect(function(descendant)
			if descendant:HasTag(beatblock:EmitSwitchedTag()) then beatblock.emitters[descendant] = true end
		end),
		beatblock.EmitSwitchedTag:onChange(beatblock, function()
			table.clear(beatblock.emitters)
			for _, descendant in beatblock.instance:GetDescendants() do
				if descendant:HasTag(beatblock:EmitSwitchedTag()) then beatblock.emitters[descendant] = true end
			end
		end)
	)

	for _, descendant in beatblock.instance:GetDescendants() do
		if descendant.Parent == beatblock.instance then beatblock:processChild(descendant) end
		if descendant:HasTag(beatblock:EmitSwitchedTag()) then beatblock.emitters[descendant] = true end
	end

	local indicators = {}
	while true do
		local indexNow = beatblock:Index(beatblock:calculateNextIndex()) :: number

		local parentEmittersToClosest = beatblock:ParentEmittersToClosest()
		local closestDistance, closestBlock = math.huge, nil
		for index, blocks in beatblock.blocks do
			local enabled = index == indexNow
			for _, block in blocks do
				toggle.toggleInstance(enabled, block)

				if enabled and parentEmittersToClosest then
					local distance = Players.LocalPlayer:DistanceFromCharacter(block.Position)
					if distance < closestDistance then
						closestDistance, closestBlock = distance, block
					end
				end
			end
		end

		if closestBlock then
			for emitter in beatblock.emitters do
				emitter.Parent = closestBlock
			end
		end

		emission.emitTaggedDescendants(beatblock.instance, beatblock:EmitSwitchedTag())

		local indicatorEnabled = beatblock:IndicatorEnabled()
		local indicatorTime = if indicatorEnabled then beatblock:IndicatorInterval() else 0
		task.wait(beatblock:Interval() - indicatorTime)
		if indicatorEnabled then
			destruction.destroy(indicators)

			local sizeMultiplier = beatblock:IndicatorSizeMultiplier()
			local startingSizeMultiplier = Vector3.one * sizeMultiplier.Min
			local endingSizeMultiplier = Vector3.one * sizeMultiplier.Max

			const tweenConfiguration: tweens.TweenConfiguration = {
				duration = indicatorTime,
				style = beatblock:IndicatorStyle(),
				direction = beatblock:IndicatorDirection(),
			}

			local nextBlocks = beatblock.blocks[beatblock:calculateNextIndex()] or {} :: never

			for index, block in nextBlocks do
				local indicator = Instance.fromExisting(block)
				indicator.Name ..= "Indicator"
				indicator.Material = Enum.Material.SmoothPlastic
				indicator.Transparency = 1
				indicator.Size *= startingSizeMultiplier
				indicators[index] = indicator
				indicator.Parent = block.Parent

				tweens.play(indicator, {
					Size = block.Size * endingSizeMultiplier,
					Transparency = math.map(toggle.TransparencyEnabled(block), 0, 1, 0.5, 1),
				}, tweenConfiguration)
			end

			task.wait(indicatorTime)
		end
	end
end

return BeatBlock
