local Life = require("@libs/Life")
local tweens = require("@libs/tweens")
local useSeamlessAttributes = require("./useSeamlessAttributes")
local useTeleportAttributes = require("./useTeleportAttributes")

export type TeleporterAttributes = typeof(useTeleportAttributes(nil :: any))
export type SeamlessAttributes = typeof(useSeamlessAttributes(nil :: any))

export type TeleportContext = {
	teleporter: BasePart,
	teleporterConfiguration: Instance,
	teleporterLife: Life.Life,

	target: BasePart,
	destination: BasePart,

	attributes: TeleporterAttributes,
	seamlessAttributes: SeamlessAttributes,
	tweenAttributes: tweens.TweenAttributes,
}

export type TransitionContext = TeleportContext & {
	destinationCFrame: CFrame,
	destinationCameraCFrame: CFrame,
}

export type Transition = (context: TransitionContext) -> ()

return nil
