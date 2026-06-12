const Mechanic = require "@libs/core/Mechanic"
const gt = require "@libs/vendor/gt"
const Life = require "@libs/memory/Life"
const sounds = require "@libs/sounds"
const tweens = require "@libs/tweens"
const assets = require "@core/assets"

const GLOW_PADDING = Vector3.new(0.05, 0.05, 0.05) 

const function useAttributes(implementation: Mechanic.MechanicImplementation, basename: string?)
	basename = basename or "Press"
	return {
		Enabled = implementation:attribute(basename .. "Enabled", gt.boolean(), true),
		Offset = implementation:attribute(basename .. "Offset", gt.CFrame(), CFrame.new(0, -0.5, 0)),
		OffsetEnabled = implementation:attribute(basename .. "OffsetEnabled", gt.boolean(), true),
		GlowEnabled = implementation:attribute(basename .. "GlowEnabled", gt.boolean(), true),
		ShockwaveEnabled = implementation:attribute(basename .. "ShockwaveEnabled", gt.boolean(), true),
		Sound = sounds.useAttributes(implementation, basename .. "Sound"),
		Tween = tweens.useAttributes(implementation, basename .. "Tween"),
	}
end

export type PressAttributes = typeof(useAttributes(...))

const function usePress(props: {
	instance: BasePart,
	instanceConfiguration: Instance,
	attributes: PressAttributes,
	flash: boolean?,
})
	const life = Life.new()
	const instanceConfiguration = props.instanceConfiguration or props.instance

	if not props.attributes.Enabled(instanceConfiguration) then return life end

	const tweenConfiguration = tweens.configurationFromAttributes(props.attributes.Tween, props.instanceConfiguration)
	tweenConfiguration.duration = tweenConfiguration.duration or 0.5

	if props.attributes.Sound.Play(instanceConfiguration) then
		sounds.playInstance(props.attributes.Sound, props.instance, props.instanceConfiguration, assets.sfx.button)
	end

	if props.attributes.OffsetEnabled(instanceConfiguration) then
		local offsetTween: any = table.clone(tweenConfiguration)
		local originalCFrame = props.instance.CFrame

		if props.flash then
			offsetTween.isReversed = true
			offsetTween.duration /= 2
		else
			life:add(function() tweens.play(props.instance, { CFrame = originalCFrame }, offsetTween) end)
		end

		tweens.play(
			props.instance,
			{ CFrame = props.instance.CFrame * props.attributes.Offset(instanceConfiguration) },
			offsetTween
		)
	end

	if props.attributes.GlowEnabled(instanceConfiguration) then
		const adornment = life:add(Instance.new "BoxHandleAdornment")
		adornment.Adornee = props.instance
		adornment.Color3 = props.instance.Color:Lerp(Color3.new(1, 1, 1), 0.1)
		adornment.Name = props.instance.Name .. "Glow"
		adornment.Size = props.instance.Size + GLOW_PADDING
		adornment.Parent = props.instance

		if props.flash then
			adornment.Transparency = 0
			tweens.play(adornment, { Transparency = 1 }, tweenConfiguration)
			task.delay(tweenConfiguration.duration, function() life:destroy() end)
		else
			adornment.Transparency = 1
			tweens.play(adornment, { Transparency = 0 }, tweenConfiguration)
			life:add(function()
				tweens.play(adornment, { Transparency = 1 }, tweenConfiguration)
				task.delay(tweenConfiguration.duration, function() life:destroy() end)
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
