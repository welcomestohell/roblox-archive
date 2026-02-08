local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local gt = require("@libs/gt")
local life = require("@libs/Life")
local touch = require("@libs/touch")

local attributes = require("./attributes")

local localPlayer = Players.LocalPlayer

export type ActivationBehaviorImpl = {
	predicate: ((instance: Instance) -> boolean)?,
	implement: (
		life: life.Life,
		instanceLife: life.Life,
		instance: Instance,
		configurationInstance: Instance,
		onActivated: (life: life.Life, instance: Instance) -> ()
	) -> (),
}

local function createActivationClickDetector(life: life.Life, parent: Instance)
	local clickDetector = life:add(Instance.new("ClickDetector"))

	clickDetector.Name = "ActivationClickDetector"
	clickDetector.MaxActivationDistance = math.huge
	clickDetector.Parent = parent

	return clickDetector
end

local function getActivationClickDetector(life: life.Life, parent: Instance)
	local detect = parent:FindFirstChild("ActivationClickDetector") :: ClickDetector

	if not detect then
		detect = createActivationClickDetector(life, parent)
	elseif detect.ClassName ~= "ClickDetector" then
		-- someones trying to troll the game
		detect.Name ..= "_FAKE"
		detect = createActivationClickDetector(life, parent)
	end

	local max = attributes.MaxActivationDistance(parent)

	if max then
		detect.MaxActivationDistance = max
	end

	return detect
end

local function createActivationProximityPrompt(life: life.Life, parent: Instance)
	local prompt = life:add(Instance.new("ProximityPrompt"))

	prompt.Name = "ActivationProximityPrompt"
	prompt.ActionText = ""
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = math.huge
	prompt.Parent = parent

	return prompt
end

local function getActivationProximityPrompt(life: life.Life, parent: Instance)
	local prompt = parent:FindFirstChild("ActivationProximityPrompt") :: ProximityPrompt

	if not prompt then
		prompt = createActivationProximityPrompt(life, parent)
	elseif prompt.ClassName ~= "ProximityPrompt" then
		-- someones trying to troll the game
		prompt.Name ..= "_FAKE"
		prompt = createActivationProximityPrompt(life, parent)
	end

	local max = attributes.MaxActivationDistance(parent)

	if max then
		prompt.MaxActivationDistance = max
	end

	life:add(function()
		prompt.Enabled = false
	end)

	prompt.Enabled = true

	return prompt
end

return table.freeze {
	Touch = {
		predicate = gt.Instance("BasePart"),
		implement = function(life, instanceLife, instance, configurationInstance, onActivated)
			life:add((instance :: BasePart).Touched:Connect(function(toucher: BasePart)
				if touch.isToucherValid(instance, toucher) then
					onActivated(instanceLife, instance)
				end
			end))
		end,
	},
	Prompt = {
		implement = function(life, instanceLife, instance, configurationInstance, onActivated)
			local prompt: ProximityPrompt?

			if instance:IsA("ProximityPrompt") then
				prompt = instance
			elseif instance:IsA("BasePart") then
				prompt = getActivationProximityPrompt(life, instance)
			end

			if prompt then
				life:add(prompt.Triggered:Connect(function(player)
					if player == localPlayer then
						onActivated(instanceLife, instance)
					end
				end))
			end
		end,
	},
	Click = {
		implement = function(life, instanceLife, instance, configurationInstance, onActivated)
			local click: ClickDetector?

			if instance:IsA("ClickDetector") then
				click = instance
			elseif instance:IsA("BasePart") then
				click = getActivationClickDetector(life, instance)
			end

			if click then
				life:add(click.MouseClick:Connect(function(player)
					if player == localPlayer then
						onActivated(instanceLife, instance)
					end
				end))
			end
		end,
	},
	KeyCode = {
		implement = function(life, instanceLife, instance, configurationInstance, onActivated)
			life:add(UserInputService.InputBegan, function(inputObject, gameProcessed)
				if not gameProcessed and inputObject == attributes.ActivationKeyCode(instance) then
					onActivated(instanceLife, instance)
				end
			end)
		end,
	},
	HumanoidStateChanged = {
		implement = function(life, instanceLife, instance, configurationInstance, onActivated)
			-- TODO
		end,
	},
	Interval = {
		implement = function(life, instanceLife, instance, configurationInstance, onActivated)
			-- TODO
		end,
	},
	Node = {
		implement = function(life, instanceLife, instance, configurationInstance, onActivated)
			-- TODO
		end,
	},
}
