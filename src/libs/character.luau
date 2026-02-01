local Players = game:GetService("Players")

export type Character = Model & {
	Humanoid: Humanoid & {
		HumanoidDescription: HumanoidDescription,
		Animator: Animator,
	},
	HumanoidRootPart: BasePart,
	BodyColors: BodyColors,
	PrimaryPart: BasePart,
	Animate: LocalScript,
	Head: BasePart,
}

local function isCharacter(character: Instance): boolean
	return Players:GetPlayerFromCharacter(character :: Model) ~= nil
end

local function isLocalPlayerCharacter(character: Instance): boolean
	return Players:GetPlayerFromCharacter(character :: Model) == Players.LocalPlayer
end

local function getMaybeCharacter(): Character?
	return Players.LocalPlayer.Character
end

local function waitForCharacter(): Character
	return Players.LocalPlayer.CharacterAdded:Wait() :: any
end

local function getCharacter(): Character
	return getMaybeCharacter() or waitForCharacter()
end

local function isFromMaybeCharacter(instance: Instance): boolean
	local character = getMaybeCharacter()
	return if character then character:IsAncestorOf(instance) else false
end

local function isFromCharacter(instance: Instance): boolean
	return getCharacter():IsAncestorOf(instance)
end

local function getMaybeHumanoidRootPart(): BasePart?
	local character = getMaybeCharacter()
	if character then
		return character:FindFirstChild("HumanoidRootPart") :: BasePart
	end
	return nil
end

local function getHumanoidRootPart(): BasePart
	return getCharacter():WaitForChild("HumanoidRootPart") :: BasePart
end

local function getMaybeHumanoid(): Humanoid?
	local character = getMaybeCharacter()
	if character then
		return character:FindFirstChild("Humanoid") :: Humanoid
	end
	return nil
end

local function getHumanoid(): Humanoid
	return getCharacter():WaitForChild("Humanoid") :: Humanoid
end

local function isCharacterAlive(): boolean
	local humanoid = getMaybeHumanoid()
	return humanoid ~= nil and humanoid.Health > 0
end

return {
	isCharacter = isCharacter,
	isLocalPlayerCharacter = isLocalPlayerCharacter,
	getMaybeCharacter = getMaybeCharacter,
	waitForCharacter = waitForCharacter,
	getCharacter = getCharacter,
	isFromMaybeCharacter = isFromMaybeCharacter,
	isFromCharacter = isFromCharacter,
	getMaybeHumanoidRootPart = getMaybeHumanoidRootPart,
	getHumanoidRootPart = getHumanoidRootPart,
	getMaybeHumanoid = getMaybeHumanoid,
	getHumanoid = getHumanoid,
	isCharacterAlive = isCharacterAlive,
}
