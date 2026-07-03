local Charm = require "@pkgs/Charm"
local assets = require "@core/assets"
local logger = require "@core/shared/logger"

export type TimerProps = {
	icon: string,
	color: Color3,
	duration: number,
}

export type Timer = TimerProps & {
	timestamps: { number },
}

local BUTTON_ICON = assets.phosphor.hourglassSimple
local WALK_BOOST_ICON = assets.phosphor.caretLineDown
local JUMP_BOOST_ICON = assets.phosphor.caretLineDown
local GRAVITY_BOOST_ICON = assets.phosphor.caretLineDown

local store = Charm.atom<<{ [string]: Timer }>> {}
Charm.subscribe(store, function(store)
	logger:Debug("timers.store:", store)
end)

-- FIXME: this doesnt account for the longest durations
local function increment(key: string, props: TimerProps)
	store(function(store: typeof(store()))
		local timestamp = os.clock()
		store = table.clone(store)

		local timer = store[key]
		if timer then
			timer = table.clone(timer)

			local timestamps = table.clone(timer.timestamps)
			table.insert(timestamps, timestamp)
			timer.timestamps = timestamps
			timer.color = props.color
			timer.duration = props.duration
			timer.icon = props.icon

			store[key] = timer
		else
			timer = table.clone(props) :: Timer
			timer.timestamps = { timestamp }
			store[key] = timer
		end

		return store
	end)
end

local function decrement(key: string)
	store(function(store: typeof(store()))
		store = table.clone(store)

		local timer = store[key]
		if timer then
			timer = table.clone(timer)

			local timestamps = table.clone(timer.timestamps)
			if #timestamps <= 1 then
				store[key] = nil
			else
				table.remove(timestamps, 1)
				timer.timestamps = timestamps
				store[key] = timer
			end
		end

		return store
	end)
end

local function remove(key: string)
	store(function(store: typeof(store()))
		store = table.clone(store)
		store[key] = nil
		return store
	end)
end

return table.freeze {
	BUTTON_ICON = BUTTON_ICON,
	WALK_BOOST_ICON = WALK_BOOST_ICON,
	JUMP_BOOST_ICON = JUMP_BOOST_ICON,
	GRAVITY_BOOST_ICON = GRAVITY_BOOST_ICON,

	store = store,

	increment = increment,
	decrement = decrement,
	remove = remove,
}
