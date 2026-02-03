local Charm = require("@pkgs/Charm")

export type DebuggerWindow = {
	name: string,
	new: () -> DebuggerWindow,
	render: (self: any) -> (),
}

export type DebuggerProps = {
	isOpen: Charm.Atom<boolean>,
}

return nil
