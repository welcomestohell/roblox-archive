local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local std = require("@libs/std")

local OneWay = std.Mechanic("OneWay", std.gt.isA.BasePart())({
	Offset = std.Attribute("Offset", std.gt.CFrame(), CFrame.identity),

	onInit = function(self: Self, level: std.Level)
		local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
		local character = player.Character or player.CharacterAdded:Wait()
		local root: Part = character:WaitForChild("HumanoidRootPart")

		level.life:add(RunService.PreSimulation:Connect(function()
			if root then
				local rootPivot = root:GetPivot()
				local platforms = level.mechanicsByImplementations[self]

				if platforms == nil then
					return
				end

				for _, platform: Self in platforms do
					local config: Configuration = platform.instance
					local instance: BasePart = config.Parent

					-- this is nil for some reason???
					local enabled: boolean = platform:Enabled()

					if enabled then
						local offset: CFrame = platform:Offset()

						local partPivot = instance:GetPivot()
						local upVector = partPivot.UpVector

						instance.CanCollide = rootPivot.Position.Y > partPivot.Position.Y
						-- this just breaks??? "invalid argument #2 (Vector3 expected, got nil)"
						--  upVector:Dot(
						-- 	CFrame.lookAt(
						-- 		(partPivot * (CFrame.new(Vector3.yAxis * (instance.Size.Y * 0.5)) * offset)).Position, -- breaks around here
						-- 		(rootPivot * CFrame.new(0, -math.sign(upVector:Dot(Vector3.yAxis)), 0)).Position
						-- 	).LookVector
						-- ) > 0
					else
						instance.CanCollide = false
					end
				end
			end
		end))
	end,
})

export type Self = std.Mechanic<typeof(OneWay)>
return OneWay
