local TeleporterDestination = require("./TeleporterDestination")
local character = require("@libs/character")
local std = require("@libs/std")

local debounce = false
local debouncedTeleporters: { [Self]: true } = {}

local Teleporter = std.Mechanic("Teleporter", std.gt.isA.BasePart())({
	Id = std.Attribute("Id", std.gt.string()),
	KeepVelocity = std.Attribute("KeepVelocity", std.gt.boolean(), true),
	Cooldown = std.Attribute("Cooldown", std.gt.number(), 0),
	PlaySound = std.Attribute("PlaySound", std.gt.boolean(), true),
	Seamless = std.Attribute("Seamless", std.gt.boolean(), true),
	SeamlessMeasurement = std.Attribute(
		"SeamlessMeasurement",
		std.gt.union2(std.gt.literal("Relative"), std.gt.literal("World")),
		"Relative"
	),
	Offset = std.Attribute("Offset", std.gt.CFrame()),

	calculateTeleportCFrame = function(self: Mechanic, destination: BasePart, root: BasePart)
		local destinationCFrame = destination.CFrame
		if self:Seamless() then
			local rootPosition = root.Position
			local teleporterPosition = self.instance.Position

			local distance = rootPosition - teleporterPosition

			local measurement = self:SeamlessMeasurement()
			if measurement == "World" then
				if not self:SeamlessOverflow() then
					local destinationSize = destination.Size
					local sizeX, sizeY, sizeZ = destinationSize.X, destinationSize.Y, destinationSize.Z
					local halfSizeX, halfSizeY, halfSizeZ = sizeX / 2, sizeY / 2, sizeZ / 2
					distance = Vector3.new(
						math.clamp(distance.X, -halfSizeX, halfSizeX),
						math.clamp(distance.Y, -halfSizeY, halfSizeY),
						math.clamp(distance.Z, -halfSizeZ, halfSizeZ)
					)
				end
				destinationCFrame = destination.CFrame * CFrame.new(distance)
			else
				distance /= self.instance.Size
				if not self:SeamlessOverflow() then
					distance = Vector3.new(
						math.clamp(distance.X, -0.5, 0.5),
						math.clamp(distance.Y, -0.5, 0.5),
						math.clamp(distance.Z, -0.5, 0.5)
					)
				end
				destinationCFrame = destination.CFrame * CFrame.new(destination.Size * distance)
			end
		end
		return destinationCFrame * self:Offset()
	end,

	onActivated = function(self: Mechanic, level: std.Level)
		local root = character.getMaybeHumanoidRootPart()
		if not root then
			return
		end

		if debounce or debouncedTeleporters[self] then
			return
		end

		self:Activatable(false)

		local allDestinations = (TeleporterDestination.idToDestination:get(self.Id:assert(self)))

		local _, first = next(allDestinations)
		if not first then
			return
		end

		debounce = true
		debouncedTeleporters[self] = true
		task.delay(self:Cooldown(), function(self)
			debouncedTeleporters[self] = nil
		end, self)

		local len = #allDestinations

		local originalLinearVelocity = root.AssemblyLinearVelocity
		local originalAngularVelocity = root.AssemblyAngularVelocity

		local targetDestination = if len == 1
			then first
			else allDestinations[Random.new(os.clock() ^ 2):NextInteger(1, len)]

		if self:PlaySound() then
			-- prelude.inferAndPlaySound(teleporter, prelude.AUDIO_ASSETS["core/towerSfx/teleport"], "TeleportSound")
		end

		local targetCFrame = self:calculateTeleportCFrame(targetDestination, root)
		-- local config = prelude.tweenConfigFromAttributes(teleporter, "Transition")

		local wasAnchored = root.Anchored
		-- if not config.time or config.time == 0 then
		root:PivotTo(targetCFrame)
		-- else
		-- 	root.Anchored = true
		-- 	prelude.tween(root, { CFrame = targetCFrame }, config).Completed:Wait()
		-- 	root = prelude.getMaybeHumanoidRootPart()
		-- end

		if root then
			root.Anchored = wasAnchored
			if self:KeepVelocity() then
				root.AssemblyLinearVelocity = originalLinearVelocity
				root.AssemblyAngularVelocity = originalAngularVelocity
			end
		end

		debounce = false
		self:Activatable(true)
	end,
})

export type Self = typeof(Teleporter)
export type Mechanic = std.Mechanic<Self>
return Teleporter
