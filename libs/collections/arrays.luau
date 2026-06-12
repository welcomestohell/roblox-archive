const function map<VI, VO>(array: { VI }, map: (VI) -> VO)
	const transformed = table.create(#array) :: { VO }
	for index, original in array do
		transformed[index] = map(original)
	end
	return transformed
end

return table.freeze {
	map = map,
}
