local TeleporterDestination = require("./TeleporterDestination")
local character = require("@libs/character")
local std = require("@libs/std")

local Teleporter = std.Mechanic({})
export type TeleporterMechanic = std.Mechanic<typeof(Teleporter)>
Teleporter.instanceTag = "Teleporter"
Teleporter.instanceType = std.isA.BasePart()

Teleporter.Id = Teleporter:attribute("Id", std.gt.optional(std.gt.string()), nil)
Teleporter.KeepVelocity = Teleporter:attribute("KeepVelocity", std.gt.boolean(), true)
Teleporter.Cooldown = Teleporter:attribute("Cooldown", std.gt.number(), 0)
Teleporter.PlaySound = Teleporter:attribute("PlaySound", std.gt.boolean(), true)
Teleporter.Offset = Teleporter:attribute("Offset", std.gt.CFrame(), CFrame.identity)

Teleporter:attributeSection("Seamless Teleportation")
Teleporter.Seamless = Teleporter:attribute("Seamless", std.gt.boolean(), true)
Teleporter.SeamlessMeasurement = Teleporter:attribute(
	"SeamlessMeasurement",
	std.gt.union2(std.gt.literal("Relative"), std.gt.literal("World")),
	"Relative"
)
Teleporter.SeamlessOverflow = Teleporter:attribute("SeamlessOverflow", std.gt.boolean(), false)

Teleporter.debounce = false
Teleporter.debouncedTeleporters = {} :: { [TeleporterMechanic]: true }

function Teleporter.calculateTeleportCFrame(teleporter: TeleporterMechanic, destination: BasePart, root: BasePart)
	local destinationCFrame = destination.CFrame
	if teleporter:Seamless() then
		local rootPosition = root.Position
		local teleporterPosition = teleporter.instance.Position

		local distance = rootPosition - teleporterPosition

		local measurement = teleporter:SeamlessMeasurement()
		if measurement == "World" then
			if not teleporter:SeamlessOverflow() then
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
			distance /= teleporter.instance.Size
			if not teleporter:SeamlessOverflow() then
				distance = Vector3.new(
					math.clamp(distance.X, -0.5, 0.5),
					math.clamp(distance.Y, -0.5, 0.5),
					math.clamp(distance.Z, -0.5, 0.5)
				)
			end
			destinationCFrame = destination.CFrame * CFrame.new(destination.Size * distance)
		end
	end
	return destinationCFrame * teleporter:Offset()
end

function Teleporter:onActivate(teleporter: TeleporterMechanic, level: std.Level)
	local root = character.getMaybeHumanoidRootPart()
	if not root then
		return
	end

	if Teleporter.debounce or Teleporter.debouncedTeleporters[teleporter] then
		return
	end

	-- teleporter:Activatable(false)

	local allDestinations = (TeleporterDestination.destinationsById:get(teleporter.Id:assert(teleporter)))

	local _, first = next(allDestinations)
	if not first then
		return
	end

	Teleporter.debounce = true
	Teleporter.debouncedTeleporters[teleporter] = true
	task.delay(teleporter:Cooldown(), function(teleporter)
		Teleporter.debouncedTeleporters[teleporter] = nil
	end, teleporter)

	local len = #allDestinations

	local originalLinearVelocity = root.AssemblyLinearVelocity
	local originalAngularVelocity = root.AssemblyAngularVelocity

	local targetDestination = if len == 1
		then first
		else allDestinations[Random.new(os.clock() ^ 2):NextInteger(1, len)]

	if teleporter:PlaySound() then
		-- prelude.inferAndPlaySound(teleporter, prelude.AUDIO_ASSETS["core/towerSfx/teleport"], "TeleportSound")
	end

	local targetCFrame = teleporter:calculateTeleportCFrame(targetDestination, root)
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
		if teleporter:KeepVelocity() then
			root.AssemblyLinearVelocity = originalLinearVelocity
			root.AssemblyAngularVelocity = originalAngularVelocity
		end
	end

	Teleporter.debounce = false
	-- teleporter:Activatable(true)
end

return Teleporter
