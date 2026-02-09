local std = require("@libs/std")

local Hidden = std.Mechanic({})
export type Hidden = std.Mechanic<typeof(Hidden)>
Hidden.instanceTag = "Hidden"
Hidden.instanceType = std.isA.Instance()
Hidden.debuggerEmoji = "👻"

Hidden.HideDescendants = Hidden:attribute("HideDescendants", std.gt.boolean(), false)

Hidden.properties = {
	BasePart = { Transparency = 1 },
	ImageLabel = { ImageTransparency = 1 },
	ImageButton = { ImageTransparency = 1 },
	TextLabel = { TextTransparency = 1 },
	TextButton = { TextTransparency = 1 },
	TextBox = { TextTransparency = 1 },
	Frame = { BackgroundTransparency = 1 },
	ParticleEmitter = { Enabled = false, Transparency = NumberSequence.new(1) },
	Beam = { Enabled = false, Transparency = NumberSequence.new(1) },
	Trail = { Enabled = false, Transparency = NumberSequence.new(1) },
} :: { [string]: { [string]: unknown } }

function Hidden.hide(instance: Instance)
	for className, properties in Hidden.properties do
		if instance:IsA(className) then
			for key, value in properties do
				(instance :: any)[key] = value
			end
		end
	end
end

function Hidden:onStart(hidden: Hidden)
	task.spawn(Hidden.hide, hidden.instance)
	local descendantLife = hidden.life:inner()
	Hidden.HideDescendants:onBind(hidden, function(isHidden)
		descendantLife:destroy()
		if isHidden then
			for _, descendant in hidden.instance:GetDescendants() do
				task.spawn(Hidden.hide, descendant)
			end
			hidden.life:add(hidden.instance.DescendantAdded:Connect(Hidden.hide))
		end
	end)
end

return Hidden
