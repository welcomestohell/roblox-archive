const RunService = game:GetService "RunService"

const character = require "@libs/character"
const threadpool = require "@libs/threadpool"
const Charm = require "@pkgs/Charm"
const Signal = require "@pkgs/Signal"

const jump = {
	isJumping = Charm.atom(false),
	onJumpStart = Signal.new<<()>>(),
	onJumpEnd = Signal.new<<()>>(),
}

if RunService:IsClient() then
	RunService:BindToRenderStep("JumpDetection", Enum.RenderPriority.Character.Value, function()
		const humanoid = character.getMaybeHumanoid()
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
	const connection = jump.onJumpStart:Connect(callback)
	return connection
end

return table.freeze(jump)
