local actions = require("@game/ReplicatedStorage/Libs/dialogues/nodes")
local replacements = require("@game/ReplicatedStorage/Libs/dialogues/replacements")
local text = require("@game/ReplicatedStorage/Libs/dialogues/text")
local tree = require("@game/ReplicatedStorage/Libs/dialogues/tree")

return tree {
	yieldFinish = true,
	yieldFadeout = true,
	fadeoutDelay = 0.02,
	destroyAfter = 0.5,
	destroyAfterFinish = true,

	actions.activateTagged("Example"),

	actions.dialog {
		text("Hello ", replacements.playerName, "!"),
		text("Example effect"):wave(),
		text("Fonts"):font(Font.fromName("Ubuntu")),
	},

	actions.choose {
		actions.option "Foo" {},
		actions.option "Bar" {},
		actions.option "Qux" {},
	},

	actions.wait(1),

	actions.callback(function() end),
}
