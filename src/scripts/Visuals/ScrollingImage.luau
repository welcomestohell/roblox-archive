-- local RunService = game:GetService("RunService")

-- local std = require("@libs/std")

-- local ScrollingImage = std.Mechanic("ScrollingImage", std.gt.isA.ImageLabel())({
-- 	RectOffset = std.Attribute("RectOffset", std.gt.Vector2()),
-- 	RectSize = std.Attribute("RectSize", std.gt.Vector2()),
-- 	Speed = std.Attribute("Speed", std.gt.Vector2(), Vector2.zero),
-- 	Loop = std.Attribute("Loop", std.gt.boolean(), true),
-- 	Synchronized = std.Attribute("Synchronized", std.gt.boolean(), true),

-- 	onInit = function(self: Self, level: std.Level)
-- 		level.life:add(RunService.PreRender:Connect(function(dt: number)
-- 			local lifetime = level:getLifetime()
-- 			for _, texture in level:getMechanics(self) do
-- 				if not texture:Enabled() then
-- 					continue
-- 				end

-- 				local speed = texture:Speed()
-- 				local size: Vector2 = texture.instance.ImageRectSize
-- 				local realOffset: Vector2 = texture.instance.ImageRectOffset
-- 				local offset: Vector2 = self.RectOffset:get(texture) or realOffset
-- 				local newOffset = if texture:Synchronized()
-- 					then offset + speed / size * lifetime
-- 					else realOffset + speed * dt

-- 				texture.instance.ImageRectOffset = if texture:Loop() then newOffset % size else newOffset
-- 			end
-- 		end))
-- 	end,

-- 	onStart = function(mechanic: Mechanic)
-- 		local offset = mechanic:RectOffset()
-- 		if not offset then
-- 			mechanic.RectOffset:set(mechanic.instanceConfiguration, mechanic.instance.ImageRectOffset)
-- 		else
-- 			mechanic.instance.ImageRectOffset = offset
-- 		end

-- 		local size = mechanic:RectSize()
-- 		if not size then
-- 			mechanic.ImageRectSize:set(mechanic.instanceConfiguration, mechanic.instance.ImageRectSize)
-- 		else
-- 			mechanic.instance.ImageRectSize = size
-- 		end
-- 	end,
-- })

-- export type Self = typeof(ScrollingImage)
-- export type Mechanic = std.Mechanic<typeof(ScrollingImage)>
-- return ScrollingImage
return nil
