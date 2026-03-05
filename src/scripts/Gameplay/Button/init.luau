local ButtonEnabled = require("./ButtonEnabled")
local Life = require("@libs/Life")
local Signal = require("@pkgs/Signal")
local activation = require("@libs/activation")
local glowButton = require("@self/glowButton")
local sounds = require("@libs/sounds")
local std = require("@libs/std")
local threadpool = require("@libs/threadpool")
local tweens = require("@libs/tweens")
local useAttributes = require("@self/useAttributes")

local Button = std.Mechanic({})
export type ButtonMechanic = std.Mechanic<typeof(Button)>
Button.instanceTag = "Button"
Button.instanceType = std.isA.BasePart()
Button.debuggerEmoji = "🖲️"

local attributes = useAttributes(Button)
Button.Enabled = attributes.Enabled
Button.Active = attributes.Active
Button.Id = attributes.Id
Button.PressedOffset = attributes.PressedOffset
Button.Cooldown = attributes.Cooldown
Button.Duration = attributes.Duration

Button:attributeSection("Activation")
Button.Activation = activation.useAttributes(Button)

Button:attributeSection("Sound Effects")
Button.Sound = sounds.useAttributes(Button)

Button:attributeSection("Transition")
Button.Transition = tweens.useAttributes(Button)

Button.useAttributes = useAttributes
Button.enabledButtonsById = std.LevelState({} :: { [string]: { [ButtonMechanic]: true } })
Button.onPressed = Signal.new() :: Signal.Signal<string>

activation
	.registerMode("ButtonActivated", {
		implement = function(context: activation.ActivationContext) end,
	})
	:expect("Failed to register ButtonActivated activation mode")

function Button.updateId(self: typeof(Button), level: std.Level, id: string)
	local bes = ButtonEnabled.besById:get(level)[id]
	if not bes then
		return
	end

	local enabled = next(self.enabledButtonsById:get(level)[id]) ~= nil

	-- FIXME: why is the cast necessary?????????????????????????????????????????
	for _, be in bes :: { ButtonEnabled.ButtonEnabledMechanic } do
		threadpool.spawn(ButtonEnabled.updateEnabled, ButtonEnabled, be, enabled)
	end
end

function Button.onActivate(self: typeof(Button), button: ButtonMechanic, level: std.Level)
	if not button:Enabled() or button:Active() then
		return
	end

	local id = button:Id()
	if id == nil then
		return
	end

	local enabledButtonsById = self.enabledButtonsById:getOrSet(level, {})
	local enabledButtonsForId = enabledButtonsById[id]
	if not enabledButtonsForId then
		enabledButtonsForId = {}
		enabledButtonsById[id] = enabledButtonsForId
	end

	self.Activation.Enabled(button, false)
	button:Active(true)
	enabledButtonsForId[button] = true

	local deactivationLife = button.life:inner()
	deactivationLife:add(function()
		task.wait(button:Cooldown())
		button:Active(false)
		self.Activation.Enabled(button, true)
		enabledButtonsForId[button] = nil
	end)

	glowButton {
		life = deactivationLife,
		instance = button.instance,
		instanceConfiguration = button.instanceConfiguration,
		tweenAttributes = self.Transition,
	}

	if self.Sound.Play(button) then
		sounds.playMechanic(self.Sound, button :: any, sounds.sfx.button)
	end

	if button.instance.Anchored then
		local originalTransform = button.instance.CFrame
		local pressedOffset = button:PressedOffset()

		tweens.playFromAttributes(button.instance, { CFrame = originalTransform * pressedOffset }, self.Transition)

		deactivationLife:add(function()
			if button.life:isAlive() then
				tweens.playFromAttributes(button.instance, { CFrame = originalTransform }, self.Transition)
			end
		end)
	end

	local duration = button:Duration()
	if duration > 0 then
		task.delay(duration, Life.destroy, deactivationLife)
	end

	deactivationLife:add(self.Enabled:onChange(button, function(enabled)
		if not enabled then
			deactivationLife:destroy()
		end
	end))
end

function Button.onStart(self: typeof(Button), button: ButtonMechanic, level: std.Level)
	button.life:add(self.Active:onChange(button, function(active)
		local id = button:Id()

		if id then
			-- if not active then
			-- 	local enabledButtons = self.enabledButtonsById:get(level)[id]
			-- 	if enabledButtons then
			-- 		enabledButtons[button] = nil
			-- 	end
			-- end

			self:updateId(level, id)
		end
	end))

	button.life:add(self.Id:onChange(button, function(_id)
		-- TODO
	end))
	-- self.
	-- TODO: port when ur home
	--[[
		-- try update once to set initial properties
		tryUpdateIdOfButton(btn)
	]]
end

return Button
