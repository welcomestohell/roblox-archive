const function evaluateSequence(sequence: { read Keypoints: { { read Time: number, read Value: any } } }, time: number)
	if time == 0 then
		return sequence.Keypoints[1].Value
	elseif time == 1 then
		return sequence.Keypoints[#sequence.Keypoints].Value
	end

	for i = 1, #sequence.Keypoints - 1 do
		const currKeypoint = sequence.Keypoints[i]
		const nextKeypoint = sequence.Keypoints[i + 1]
		if time >= currKeypoint.Time and time < nextKeypoint.Time then
			const alpha = (time - currKeypoint.Time) / (nextKeypoint.Time - currKeypoint.Time)
			return currKeypoint.Value + (nextKeypoint.Value - currKeypoint.Value) * alpha
		end
	end

	error "unreachable"
end

const lerp = {
	evaluateColorSequence = evaluateSequence :: (sequence: ColorSequence, time: number) -> Color3,
	evaluateNumberSequence = evaluateSequence :: (sequence: NumberSequence, time: number) -> number,
}

return table.freeze(lerp)
