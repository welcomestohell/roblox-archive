const Players = game:GetService "Players"

const logger = require "@core/shared/logger"
const activation = require "@libs/activation"
const instances = require "@libs/instances"
const std = require "@libs/std"
const Fluid = require "@pkgs/Fluid"

const GuiDisplayer = std.Mechanic {
	emoji = "🖥️",
	name = "GuiDisplayer",
	description = "When activated, mounts itself onto the PlayerGui.",
	instanceType = std.gt.instanceTree {
		Activator = std.isA.Instance(),
		Component = std.gt.optional(instances.ModulePointerLike),
		ScreenGui = std.gt.optional(std.isA.ScreenGui()),
	},

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	RemoveAfter = std.Attribute("RemoveAfter", std.gt.positiveNumber, 0),
	Active = std.Attribute("Active", std.gt.boolean(), false),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	std.AttributeSection "Deactivation",
	Deactivation = activation.useAttributes "Deactivation",
}

export type GuiDisplayerModule = typeof(GuiDisplayer)
export type GuiDisplayerMechanic = std.Mechanic<GuiDisplayerModule>

function GuiDisplayer:getActivationInstances(displayer: GuiDisplayerMechanic)
	return displayer.instance.Activator
end

function GuiDisplayer.onActivate(self: GuiDisplayerModule, displayer: GuiDisplayerMechanic, level: std.Level)
	if displayer:Active() or displayer:Debounced() then return end
	displayer:Debounced(true)

	const wasActivatable = self.Activation.Enabled(displayer)
	self.Activation.Enabled(displayer, false)
	displayer:Active(true)

	const activationLife = displayer.life:extend()
	activationLife:addMany(
		function()
			displayer:Active(false)
			displayer.life:delay(displayer:Cooldown(), function()
				self.Activation.Enabled(displayer, wasActivatable)
				displayer:Debounced(false)
			end)
		end,
		self.RemoveAfter:onBind(displayer, function(duration)
			if duration > 0 then
				task.wait(duration)
				activationLife:destroy()
			end
		end)
	)

	const component = displayer.instance:FindFirstChild "Component"
	if component then
		const requireSuccess, componentOrError = pcall(require, instances.resolveModulePointer(component))

		if not requireSuccess then
			logger:Error("Failed to require component of", displayer.instance, "because:", componentOrError)
			activationLife:destroy()
			return
		end

		if type(componentOrError) ~= "function" then
			logger:Error(
				"Expected",
				displayer.instance,
				"to return a function component, got",
				typeof(componentOrError)
			)
			activationLife:destroy()
			return
		end

		const mountSuccess, cleanupOrError = pcall(Fluid.root, function()
			const result = (componentOrError :: () -> unknown)()
			if typeof(result) == "Instance" then
				if result:IsA "ScreenGui" then
					activationLife:add(result).Parent = Players.LocalPlayer.PlayerGui
					return
				end
				result:Destroy()
			end
			error(`Expected component in {displayer.instance:GetFullName()} to return a ScreenGui, got {result}`)
		end)

		if mountSuccess then
			activationLife:add(cleanupOrError)
		else
			logger:Error("Failed to mount", displayer.instance, "because:", cleanupOrError)
			activationLife:destroy()
			return
		end
	end

	const templateScreenGui = displayer.instance:FindFirstChild "ScreenGui"
	if templateScreenGui then
		const screenGui = activationLife:add(templateScreenGui:Clone())
		screenGui.Parent = Players.LocalPlayer.PlayerGui
		level:loadDescendantInstancesAsync(screenGui)
	end

	activation.bindActivation {
		instanceLife = activationLife,
		instance = displayer.instance.Activator,
		instanceConfiguration = displayer.instanceConfiguration,
		attributes = self.Deactivation,
		onActivate = activationLife:wrapDestroy(),
	}
end

return GuiDisplayer
