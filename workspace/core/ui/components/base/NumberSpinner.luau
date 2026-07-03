local Fluid = require "@pkgs/Fluid"
local Liquid = require "@pkgs/Liquid"
local Text = require "@core/ui/components/base/Text"
local arrays = require "@libs/primitives/arrays"
local tables = require "@libs/primitives/tables"

local DIGITS = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 }

local function NumberSpinner(props: {
	name: Fluid.UsedAs<string>?,
	position: Fluid.UsedAs<UDim2>?,
	anchorPoint: Fluid.UsedAs<Vector2>?,
	size: Fluid.UsedAs<UDim2>?,
	automaticSize: Fluid.UsedAs<Enum.AutomaticSize>?,
	layoutOrder: Fluid.UsedAs<number>?,
	zIndex: Fluid.UsedAs<number>?,

	transparency: Fluid.UsedAs<number>?,
	lineHeight: Fluid.UsedAs<number>?,

	text: Fluid.UsedAs<string>?,
	textSize: Fluid.UsedAs<number>?,
	textScaled: Fluid.UsedAs<boolean>?,
	textColor: Fluid.UsedAs<Color3>?,
	textRich: Fluid.UsedAs<boolean>?,
	textWraps: Fluid.UsedAs<boolean>?,
	textTruncate: Fluid.UsedAs<Enum.TextTruncate>?,
	font: Fluid.UsedAs<Font>?,
	fontWeight: Fluid.UsedAs<Enum.FontWeight>?,
	fontStyle: Fluid.UsedAs<Enum.FontStyle>?,

	value: Fluid.UsedAs<number>,
	numDigits: Fluid.UsedAs<number>,
	isCountingDown: Fluid.UsedAs<boolean>?,
	speed: number?,
	damping: number?,
})
	return Fluid.create "Frame" {
		Name = props.name or "NumberSpinner",

		Position = props.position,
		AnchorPoint = props.anchorPoint,
		Size = props.size or UDim2.new(0, 0),
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.X,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		BackgroundTransparency = 1,

		Fluid.create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		},

		-- LUAU FIXME: having to set forRange as any
		Liquid.forRange<<any>>(function(index: number)
			local function fauxRotation()
				return math.floor(Fluid.read(props.value) / 10 ^ (index - 1))
			end
			local function moverPosition()
				return UDim2.fromScale(0, -(fauxRotation() % 10))
			end

			return Fluid.create "Frame" {
				Name = `Digit{index}`,

				-- Digits are written right to left
				LayoutOrder = -index,
				Size = UDim2.fromScale(0.5, 1),
				Sizelocalraint = Enum.Sizelocalraint.RelativeYY,
				BackgroundTransparency = 1,
				ClipsDescendants = true,

				Fluid.create "Frame" {
					Name = "Mover",
					Position = Fluid.spring(moverPosition, props.speed or 15, props.damping or 0.8),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,

					tables.pairsMapped(DIGITS, function(index: number, digit: number): any
						return index,
							Text {
								name = `Digit{digit}`,
								position = UDim2.fromScale(0, index - 1),
								size = UDim2.fromScale(1, 1),
								automaticSize = Enum.AutomaticSize.None,

								text = tostring(digit),
								textSize = props.textSize,
								textScaled = props.textScaled,
								textColor = props.textColor,
								textRich = props.textRich,
								textWraps = props.textWraps,
								textTruncate = props.textTruncate,
								font = props.font,
								fontWeight = props.fontWeight,
								fontStyle = props.fontStyle,
							}
					end),
				},
			}
		end, 1, props.numDigits),
	}
end

return NumberSpinner
