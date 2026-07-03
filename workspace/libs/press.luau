local Attribute = require "@libs/attributes/Attribute"
local Life = require "@libs/memory/Life"
local gt = require "@libs/vendor/gt"
local tweens = require "@libs/tweens"

local GLOW_PADDING = Vector3.new(0.05, 0.05, 0.05)

const function useAttributes(basename: string?)
	basename = basename or "Press"
	return {
		Enabled = Attribute.new(basename .. "Enabled", gt.boolean(), true),
		Offset = Attribute.new(basename .. "Offset", gt.CFrame(), CFrame.new(0, -0.5, 0)),
		OffsetEnabled = Attribute.new(basename .. "OffsetEnabled", gt.boolean(), true),
		GlowEnabled = Attribute.new(basename .. "GlowEnabled", gt.boolean(), true),
		ShockwaveEnabled = Attribute.new(basename .. "ShockwaveEnabled", gt.boolean(), true),
		Tween = tweens.useAttributes(basename .. "Tween"),
	}
end

export type PressAttributes = typeof(useAttributes(...))

const function usePress(
	attributes: PressAttributes,
	instance: BasePart,
	instanceConfiguration: Instance,
	flash: boolean?
)
	local life = Life.new()
	local instanceConfiguration = instanceConfiguration or instance

	if not attributes.Enabled(instanceConfiguration) then return life end

	local tweenConfiguration = tweens.configurationFromAttributes(attributes.Tween, instanceConfiguration)
	tweenConfiguration.duration = tweenConfiguration.duration or 0.5

	if attributes.OffsetEnabled(instanceConfiguration) then
		local offsetTween: any = table.clone(tweenConfiguration)
		local originalCFrame = instance.CFrame

		if flash then
			offsetTween.isReversed = true
			offsetTween.duration /= 2
		else
			life:add(function()
				tweens.play(instance, { CFrame = originalCFrame }, offsetTween)
			end)
		end

		tweens.play(instance, { CFrame = instance.CFrame * attributes.Offset(instanceConfiguration) }, offsetTween)
	end

	if attributes.GlowEnabled(instanceConfiguration) then
		local adornment = life:add(Instance.new "BoxHandleAdornment")
		adornment.Adornee = instance
		adornment.Color3 = instance.Color:Lerp(Color3.new(1, 1, 1), 0.1)
		adornment.Name = instance.Name .. "Glow"
		adornment.Size = instance.Size + GLOW_PADDING
		adornment.Parent = instance

		if flash then
			adornment.Transparency = 0
			tweens.play(adornment, { Transparency = 1 }, tweenConfiguration)
			task.delay(tweenConfiguration.duration, function()
				life:destroy()
			end)
		else
			adornment.Transparency = 1
			tweens.play(adornment, { Transparency = 0 }, tweenConfiguration)
			life:add(function()
				tweens.play(adornment, { Transparency = 1 }, tweenConfiguration)
				task.delay(tweenConfiguration.duration, function()
					life:destroy()
				end)
			end)
		end
	end

	return life
end

return table.freeze {
	GLOW_PADDING = GLOW_PADDING,

	useAttributes = useAttributes,
	usePress = usePress,
}
