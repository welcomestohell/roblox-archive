local Mechanic = require("@libs/Mechanic")
local gt = require("@libs/gt")

local Test = Mechanic.new("Test", gt.Instance())({
	onActivated = function(self: Self)
		print("WOW", self.id)
	end,
})

export type Self = Mechanic.Mechanic<typeof(Test)>
return Test
