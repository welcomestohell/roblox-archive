local std = require("@libs/std")

local HIDDEN_PROPERTIES: { [string]: { [string]: unknown } } = {
	BasePart = {
		Transparency = 1,
	},
	ImageLabel = {
		ImageTransparency = 1,
	},
	ImageButton = {
		ImageTransparency = 1,
	},
	TextLabel = {
		TextTransparency = 1,
	},
	TextButton = {
		TextTransparency = 1,
	},
	TextBox = {
		TextTransparency = 1,
	},
	Frame = {
		BackgroundTransparency = 1,
	},
	ParticleEmitter = {
		Enabled = false,
		Transparency = NumberSequence.new(1),
	},
	Beam = {
		Enabled = false,
		Transparency = NumberSequence.new(1),
	},
	Trail = {
		Enabled = false,
		Transparency = NumberSequence.new(1),
	},
}

local function hide(instance: Instance)
	for className, properties in HIDDEN_PROPERTIES do
		if instance:IsA(className) then
			for key, value in properties do
				(instance :: any)[key] = value
			end
		end
	end
end

local Hidden = std.Mechanic("Hidden", std.gt.Instance())({
	HideDescendants = std.Attribute("HideDescendants", std.gt.boolean(), false),

	onStart = function(self: Self)
		task.spawn(hide, self.instance)
		local descendantLife = self.life:inner()
		self.HideDescendants:onBind(self, function(isHidden)
			descendantLife:destroy()
			descendantLife = self.life:inner()
			if isHidden then
				for _, descendant in self.instance:GetDescendants() do
					task.spawn(hide, descendant)
				end
				descendantLife:Add(self.instance.DescendantAdded:Connect(hide))
			end
		end)
	end,
})

export type Self = std.Mechanic<typeof(Hidden)>
return Hidden
