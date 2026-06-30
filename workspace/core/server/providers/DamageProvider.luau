const net = require "@core/server/generated/net"
const damage = require "@libs/damage"
const prvd = require "@pkgs/prvd"

const PRESET_DAMAGES = damage.PRESET_DAMAGES :: { [damage.DamagePreset]: number }

const DamageProvider = { EVENT = net.mechanics.damage, debounce = {} :: { [Player]: true } }
export type DamageProvider = typeof(DamageProvider)

function DamageProvider.onInit(self: DamageProvider)
	self.EVENT.on(function(player: Player, configuration)
		const humanoid = player.Character and player.Character:FindFirstChildOfClass "Humanoid"
		if not humanoid then return end

		const base = if configuration.mode == "Preset" and configuration.preset
			then PRESET_DAMAGES[configuration.preset]
			else configuration.value

		if not base then return end
		if self.debounce[player] then return end
		self.debounce[player] = true

		const maxHealth = humanoid.MaxHealth
		const health = math.clamp(configuration.measurement == "Raw" and base or base / 100 * maxHealth, 0, maxHealth)

		humanoid:TakeDamage(configuration.asHeal and -health or health)

		if health ~= 0 and not configuration.asHeal then task.wait(1 / 20) end
		self.debounce[player] = nil
	end)
end

function DamageProvider.onPlayerRemoving(self: DamageProvider, player: Player)
	self.debounce[player] = nil
end

return prvd(DamageProvider)
