-- awaiting rewrite to use Vector2s for configs
-- local RunService = game:GetService("RunService")

-- local std = require("@libs/std")

-- local ScrollingTexture = std.Mechanic("ScrollingTexture", std.gt.isA.Texture())({
-- 	HorizontalSpeed = std.Attribute("HorizontalSpeed", std.gt.number()),
-- 	VerticalSpeed = std.Attribute("HorizontalSpeed", std.gt.number()),

-- 	HorizontalOffset = std.Attribute("HorizontalOffset", std.gt.number(), 0),
-- 	VerticalOffset = std.Attribute("VerticalOffset", std.gt.number(), 0),

-- 	HorizontalLoop = std.Attribute("HorizontalLoop", std.gt.boolean(), true),
-- 	VerticalLoop = std.Attribute("VerticalLoop", std.gt.boolean(), true),

-- 	Synchronized = std.Attribute("Synchronized", std.gt.boolean(), true),

-- 	onInit = function(self: Self, level: std.Level)
-- 		level.life:add(RunService.PreRender:Connect(function(dt: number)
-- 			local lifetime = level:getLifetime()
-- 			for _, texture in level:getMechanics(self) do
-- 				if not texture:IsEnabled() then
-- 					continue
-- 				end

-- 				local horizontalSpeed = texture:HorizontalSpeed()
-- 				local verticalSpeed = texture:VerticalSpeed()

-- 				if horizontalSpeed ~= 0 then
-- 					local offset = texture:HorizontalOffset() or texture.instance.OffsetStudsU :: number
-- 					local newOffset = if texture:Synchronized()
-- 						then offset + horizontalSpeed / texture.instance.StudsPerTileU * lifetime
-- 						else texture.instance.OffsetStudsU + horizontalSpeed * dt
-- 					texture.instance.OffsetStudsU = if texture:HorizontalLoop()
-- 						then newOffset % texture.instance.StudsPerTileU
-- 						else newOffset
-- 				end

-- 				if verticalSpeed ~= 0 then
-- 					local offset = texture:VerticalOffset() or texture.instance.OffsetStudsV :: number
-- 					local newOffset = if texture:Synchronized()
-- 						then offset + verticalSpeed / texture.instance.StudsPerTileV * lifetime
-- 						else texture.instance.OffsetStudsV + verticalSpeed * dt
-- 					texture.instance.OffsetStudsV = if texture:VerticalLoop()
-- 						then newOffset % texture.instance.StudsPerTileV
-- 						else newOffset
-- 				end
-- 			end
-- 		end))
-- 	end,

-- 	onStart = function(mechanic: Mechanic)
-- 		local offset = mechanic:HorizontalOffset()
-- 		if not offset then
-- 			mechanic.HorizontalOffset:set(mechanic.instanceConfiguration, mechanic.instance.OffsetStudsU)
-- 		else
-- 			mechanic.instance.OffsetStudsU = offset
-- 		end

-- 		offset = mechanic:VerticalOffset()
-- 		if not offset then
-- 			mechanic.VerticalOffset:set(mechanic.instanceConfiguration, mechanic.instance.OffsetStudsV)
-- 		else
-- 			mechanic.instance.OffsetStudsV = offset
-- 		end
-- 	end,
-- })

-- export type Self = typeof(ScrollingTexture)
-- export type Mechanic = std.Mechanic<typeof(ScrollingTexture)>
-- return ScrollingTexture
return nil
