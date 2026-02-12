local character = require("@libs/character")
local std = require("@libs/std")

local Wind = std.Mechanic({})
export type WindMechanic = std.Mechanic<typeof(Wind)>

Wind.instanceTag = "Wind"
Wind.instanceType = std.isA.BasePart()

Wind.Speed = Wind:attribute("Speed", std.gt.number(), 40)
Wind.MaxForce = Wind:attribute("MaxForce", std.gt.number(), math.huge)
Wind.Direction = Wind:attribute("Direction", std.gt.Vector3(), Vector3.zAxis)
Wind.ContinuousUpdates = Wind:attribute("ContinuousUpdates", std.gt.boolean(), true)

local UPDATE_INTERVAL = 1 / 30 --idk i think this is fine

function Wind:onStart(wind: WindMechanic)
	local touching = {}

	wind.instance.Touched:Connect(function(hit)
		local root = character.getMaybeHumanoidRootPart()
		if not root or touching[root] then
			return
		end

		touching[root] = true

		local attachment = Instance.new("Attachment")
		attachment.Parent = root

		local velocity = Instance.new("LinearVelocity")
		velocity.Attachment0 = attachment
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		velocity.MaxAxesForce = Vector3.one * wind:MaxForce()
		velocity.VectorVelocity = wind.instance.CFrame:VectorToWorldSpace(wind:Direction()) * wind:Speed()
		velocity.Parent = root

		task.spawn(function()
			while touching[root] and wind.instance:IsDescendantOf(workspace) do
				if wind:ContinuousUpdates() then
					velocity.VectorVelocity = wind.instance.CFrame:VectorToWorldSpace(wind:Direction()) * wind:Speed()
				end
				task.wait(UPDATE_INTERVAL)
			end

			velocity:Destroy()
			attachment:Destroy()
		end)
	end)

	wind.instance.TouchEnded:Connect(function()
		local root = character.getMaybeHumanoidRootPart()
		if root then
			touching[root] = nil
		end
	end)
end

return Wind
