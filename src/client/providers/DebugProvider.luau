local Stats = game:GetService "Stats"

local Iris = require "@pkgs/Iris"
local prvd = require "@shared/prvdmwrong/prvdmwrong"

local DebugProvider = {}
export type DebugProvider = typeof(DebugProvider)
DebugProvider.renderDebuggerTab = prvd.lifecycle("renderDebuggerTab", prvd.fireSequential)
DebugProvider.priority = math.huge

function DebugProvider.onStart()
	Iris.Init()
	Iris:Connect(function()
		Iris.Text { `FPS: {math.floor(1 / Stats.FrameTime)}` }
	end)
end

function DebugProvider.onFinish()
	Iris.Shutdown()
end

return prvd(DebugProvider)
