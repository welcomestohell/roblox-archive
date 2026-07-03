local RunService = game:GetService "RunService"

local Charm = require "@pkgs/Charm"
local Signal = require "@pkgs/Signal"
local character = require "@libs/character"
local threadpool = require "@libs/threadpool"

local jump = {
	isJumping = Charm.atom(false),
	onJumpStart = Signal.new<<()>>(),
	onJumpEnd = Signal.new<<()>>(),
}

if RunService:IsClient() then
	RunService:BindToRenderStep("JumpDetection", Enum.RenderPriority.Character.Value, function()
		local humanoid = character.getMaybeHumanoid()
		if not humanoid then return end

		local newIsJumping = humanoid.Jump
		if jump.isJumping() ~= newIsJumping then
			jump.isJumping(newIsJumping)
			if newIsJumping then
				jump.onJumpStart:Fire()
			else
				jump.onJumpEnd:Fire()
			end
		end
	end)
end

function jump.onBind(callback: () -> ())
	if jump.isJumping() then threadpool.spawn(callback) end
	local connection = jump.onJumpStart:Connect(callback)
	return connection
end

return table.freeze(jump)
