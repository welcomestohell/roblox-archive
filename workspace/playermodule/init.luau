--[[
	PlayerModule - This module requires and instantiates the camera and control modules,
	and provides getters for developers to access methods on these singletons without
	having to modify Roblox-supplied scripts.

	2018 PlayerScripts Update - AllYourBlox
--]]

-- Forked for use in Welcome To Hell
local CameraModule = require "@self/CameraModule"
local ControlModule = require "@self/ControlModule"

local PlayerModule = {}
PlayerModule.__index = PlayerModule

function PlayerModule.new()
	local self = setmetatable({}, PlayerModule)
	self.cameras = CameraModule
	self.controls = ControlModule
	return self
end

function PlayerModule.GetCameras(self: any): typeof(CameraModule)
	return self.cameras
end

function PlayerModule.GetControls(self: any): typeof(ControlModule)
	return self.controls
end

function PlayerModule:GetClickToMoveController()
	return self.controls:GetClickToMoveController()
end

return PlayerModule.new()
