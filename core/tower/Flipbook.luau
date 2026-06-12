local std = require "@libs/std"

local Flipbook = std.Mechanic {}
export type FlipbookMechanic = std.Mechanic<typeof(Flipbook)>
Flipbook.mechanicName = "Flipbook"
Flipbook.instanceType = std.gt.union(std.isA.ImageLabel(), std.isA.Decal())
Flipbook.debuggerEmoji = "🎞️"

Flipbook.Enabled = Flipbook:attribute("Enabled", std.gt.boolean(), true)
Flipbook.Framerate = Flipbook:attribute("Framerate", std.gt.number(), 1)
Flipbook.NumFrames = Flipbook:attribute("NumFrames", std.gt.optional(std.gt.number()), nil)
Flipbook.SetDefaults = Flipbook:attribute("SetDefaults", std.gt.boolean(), true)
Flipbook.Synchronize = Flipbook:attribute("Synchronize", std.gt.boolean(), false)
Flipbook.Index = Flipbook:attribute("Index", std.gt.number(), 0)
Flipbook.Elapsed = Flipbook:attribute("Elapsed", std.gt.number(), 0)

Flipbook.GridSize = Flipbook:attribute("GridSize", std.gt.Vector2(), Vector2.one)

Flipbook.Mode = Flipbook:attribute(
	"Mode",
	std.gt.enumOf<<Enum.ParticleFlipbookMode>>(Enum.ParticleFlipbookMode),
	Enum.ParticleFlipbookMode.Loop
)

function Flipbook:onStart(flipbook: FlipbookMechanic)
	flipbook.GridSize:onBind(flipbook, function(gridSize)
		if flipbook.instance.ClassName == "ImageLabel" then
			flipbook.instance.Size = UDim2.fromScale(gridSize.X, gridSize.Y)
		elseif flipbook.instance.ClassName == "Decal" then
			flipbook.instance.UVScale = Vector2.one / gridSize
		end
	end)

	flipbook.Synchronize:onChange(flipbook, function() flipbook:Elapsed(0) end)
end

-- FIXME: PingPong desyncs :(
function Flipbook.onPreRender(self: typeof(Flipbook), deltaTime: number, level: std.Level)
	local lifetime = level:getLifetime()
	for _, flipbook: FlipbookMechanic in level:getMechanics(self) do
		if not flipbook:Enabled() then continue end

		local framerate = flipbook:Framerate()
		if framerate == 0 then continue end

		local mode = flipbook:Mode()
		local isPingPong = mode == Enum.ParticleFlipbookMode.PingPong

		local gridSize = flipbook:GridSize()
		local numFrames = flipbook:NumFrames() or gridSize.X * gridSize.Y
		local cycleDuration = (if isPingPong and numFrames > 1 then (numFrames - 1) * 2 else numFrames) / framerate

		local elapsed = if flipbook:Synchronize() then lifetime else flipbook:Elapsed(flipbook:Elapsed() + deltaTime)
		local cycleStep = math.floor(elapsed % cycleDuration * framerate)

		local oldIndex, newIndex =
			flipbook:Index(),
			flipbook:Index(
				if isPingPong and cycleStep >= numFrames
					then (numFrames - 1) - (cycleStep - (numFrames - 1))
					else cycleStep
			)

		if oldIndex == newIndex then continue end

        -- stylua: ignore
		local position: Vector2 =
            if mode == Enum.ParticleFlipbookMode.Random then
                Vector2.new(math.random(0, gridSize.X - 1), math.random(0, gridSize.Y - 1))
			else
                Vector2.new(newIndex % gridSize.X , math.floor(newIndex / gridSize.X))

		if flipbook.instance.ClassName == "ImageLabel" then
			flipbook.instance.Position = UDim2.fromScale(-position.X, -position.Y)
		elseif flipbook.instance.ClassName == "Decal" then
			flipbook.instance.UVOffset = position * (Vector2.one / gridSize)
		end
	end
end

return Flipbook
