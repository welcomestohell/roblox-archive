local Life = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("memory"):WaitForChild("Life"))
local tweens = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("tweens"))
local useAttributes = require("./useAttributes")
local useSeamlessAttributes = require("./useSeamlessAttributes")

export type TeleporterAttributes = typeof(useAttributes(nil :: any))
export type SeamlessAttributes = typeof(useSeamlessAttributes(nil :: any))

export type TeleportContext = {
	teleporter: BasePart,
	teleporterConfiguration: Instance,
	teleporterLife: Life.Life,

	target: BasePart,
	destination: BasePart,
	destinationConfiguration: Instance,

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
