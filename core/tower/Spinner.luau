const TweenService = game:GetService "TweenService"

const std = require "@libs/std"
const touch = require "@libs/touch"
const tweens = require "@libs/tweens"

const Spinner = std.Mechanic {}
export type SpinnerMechanic = std.Mechanic<typeof(Spinner)>
Spinner.name = "Spinner"
Spinner.instanceType = std.gt.instanceTree {
	Center = std.isA.BasePart(),
	Platform = std.isA.BasePart(),
}
Spinner.emoji = "🌀"

Spinner.Enabled = Spinner:attribute("Enabled", std.gt.boolean(), true)
Spinner.Reversed = Spinner:attribute("Reversed", std.gt.boolean(), false)
Spinner.Angle = Spinner:attribute("Angle", std.gt.NumberRange, NumberRange.new(0, 360))
Spinner.Offset = Spinner:attribute("Offset", std.gt.Vector3(), Vector3.zero)

Spinner:attributeSection "Timing"
Spinner.Synchronized = Spinner:attribute("Synchronized", std.gt.boolean(), true)
Spinner.TimeOffset = Spinner:attribute("TimeOffset", std.gt.positiveNumber, 0)
Spinner.Elapsed = Spinner:attribute("Elapsed", std.gt.number(), 0)

Spinner:attributeSection "Axes"
Spinner.XEnabled = Spinner:attribute("XEnabled", std.gt.boolean(), false)
Spinner.YEnabled = Spinner:attribute("YEnabled", std.gt.boolean(), true)
Spinner.ZEnabled = Spinner:attribute("ZEnabled", std.gt.boolean(), false)

Spinner.Touch = touch.useAttributes(Spinner)
Spinner.Tween = tweens.useAttributes(Spinner)

function Spinner.onStart(self: typeof(Spinner), spinner: SpinnerMechanic)
	spinner.Synchronized:onBind(spinner, function() spinner:Elapsed(0) end)
end

function Spinner.onPreSimulation(self: typeof(Spinner), deltaTime: number, level: std.Level)
	const lifetime = level:getLifetime()
	for _, spinner: SpinnerMechanic in level:getMechanics(self) do
		if not spinner:Enabled() then continue end

		local elapsed = if spinner:Synchronized()
			then lifetime
			else spinner:Elapsed(spinner:Elapsed() :: number + deltaTime)
		elapsed += spinner:TimeOffset()

		const duration = self.Tween.Duration(spinner)
		local cycleProgress = (elapsed % duration) / duration
		if spinner:Reversed() then cycleProgress = math.map(cycleProgress, 0, 1, 1, 0) end
		const angle = spinner:Angle() :: NumberRange
		const alpha = TweenService:GetValue(cycleProgress, self.Tween.Style(spinner), self.Tween.Direction(spinner))
		const axisRotation = math.rad(math.map(alpha, 0, 1, angle.Min, angle.Max))
		spinner.instance.Platform.CFrame = spinner.instance.Center.CFrame
			* CFrame.Angles(
				spinner:XEnabled() and axisRotation or 0,
				spinner:YEnabled() and axisRotation or 0,
				spinner:ZEnabled() and axisRotation or 0
			)
			* CFrame.new(spinner:Offset())
	end
end

return Spinner
