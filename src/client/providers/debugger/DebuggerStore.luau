local Charm = require("@pkgs/Charm")
local types = require("./types")

local DebuggerStore = {}
DebuggerStore.toolToEnable = Charm.atom(nil :: types.DebuggerTool?)
DebuggerStore.toolToDisable = Charm.atom(nil :: types.DebuggerTool?)
DebuggerStore.enabledTools = Charm.atom({} :: { [types.DebuggerTool]: types.DebuggerTool })
DebuggerStore.isOpen = Charm.atom(false)

local defaults = {}
for key, value in DebuggerStore :: { [string]: any } do
	defaults[key] = value()
end

function DebuggerStore.reset()
	for key, value in defaults do
		DebuggerStore[key](value)
	end
end

return table.freeze(DebuggerStore)
