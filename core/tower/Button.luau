const logger = require "@core/shared/logger"
const activation = require "@libs/activation"
const Attribute = require "@libs/attributes/Attribute"
const press = require "@libs/press"
const std = require "@libs/std"

const Button = std.Mechanic {}
export type ButtonMechanic = std.Mechanic<typeof(Button)>
Button.mechanicName = "Button"
Button.instanceType = std.gt.union(std.isA.BasePart(), std.isA.Model())
Button.debuggerEmoji = "🖲️"

Button.Active = Button:attribute("Active", std.gt.boolean(), true)
Button.Cooldown = Button:attribute("Cooldown", std.gt.positiveNumber, 0.5)
Button.Duration = Button:attribute("Duration", std.gt.number(), 5)
Button.Group = Button:attribute("Group", std.gt.string(), "")

Button:attributeSection "Timer"
Button.TimerEnabled = Button:attribute("TimerEnabled", std.gt.boolean(), true)
Button.HoursHidden = Button:attribute("HoursHidden", std.gt.boolean(), false)
Button.MinutesHidden = Button:attribute("MinutesHidden", std.gt.boolean(), false)
Button.MillisecondsHidden = Button:attribute("MillisecondsHidden", std.gt.boolean(), false)

Button.Activation = activation.useAttributes(Button)
Button.Press = press.useAttributes(Button)

function Button.getActivationInstance(self: typeof(Button), button: ButtonMechanic)
	return if button.instance:IsA "BasePart"
		then button.instance :: BasePart
		else button.instance.PrimaryPart or button.instance:FindFirstChild "Button" :: BasePart
end

function Button.onActivate(self: typeof(Button), button: ButtonMechanic, level: std.Level)
	if button:Active() then return end

	local buttonPart: BasePart = self:getActivationInstance(button)
	if not buttonPart then
		logger:Warn("Missing primary part on button", button.instance:GetFullName())
		return
	end

	self.Activation.Enabled(button, false)
	button:Active(true)

	local deactivationLife = button.life:extend()
	deactivationLife:addMany(
		press.usePress {
			instance = buttonPart,
			instanceConfiguration = button.instanceConfiguration,
			attributes = self.Press,
		},
		function()
			button:Active(false)
			task.delay(button:Cooldown(), Attribute.set :: any, self.Activation.Enabled, button, true)
		end,
		self.Active:onChange(button, function(value)
			if not value then deactivationLife:destroy() end
		end)
	)

	local duration = button:Duration()
	if duration > 0 then deactivationLife:delay(duration, deactivationLife:wrapDestroy()) end
end

return Button
