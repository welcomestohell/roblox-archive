local Players = game:GetService("Players")

local Life = require("@libs/Life")
local tweens = require("@libs/tweens")

local function glowButton(props: {
	life: Life.Life,
	instance: BasePart,
	instanceConfiguration: Instance,
	tweenAttributes: tweens.TweenAttributes,
	flash: boolean?,
})
	local life = props.life:inner()

	local glow = Instance.new("Highlight")
	glow.Name = props.instance.Name .. "Glow"
	glow.Adornee = props.instance
	glow.OutlineTransparency = 1
	glow.FillColor = props.instance.Color
	glow.FillTransparency = 1
	glow.DepthMode = Enum.HighlightDepthMode.Occluded

	glow.Parent = Players.LocalPlayer.PlayerGui

	local tweenConfiguration = tweens.configurationFromAttributes(props.tweenAttributes, props.instanceConfiguration)
	if props.flash then
		tweenConfiguration.duration = tweenConfiguration.duration or 0.5
		tweenConfiguration.isReversed = true
		tweens.play(glow, { FillTransparency = 0 }, tweenConfiguration)

		task.delay(tweenConfiguration.duration, function()
			life:destroy()
		end)
	else
		tweens.play(glow, { FillTransparency = 0 }, tweenConfiguration)
		life:add(function()
			local duration = tweenConfiguration.duration or 1
			tweens.play(glow, { FillTransparency = 1 }, tweenConfiguration)
			task.delay(duration, function()
				life:destroy()
			end)
		end)
	end
end

return glowButton
