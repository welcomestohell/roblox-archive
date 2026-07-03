local Fluid = require "@pkgs/Fluid"
local Liquid = require "@pkgs/Liquid"
local NumberSpinner = require "@core/ui/components/base/NumberSpinner"
local Oklab = require "@libs/vendor/Oklab"
local Padding = require "@core/ui/components/base/Padding"
local Text = require "@core/ui/components/base/Text"
local assets = require "@core/assets"

-- TODO: hoursHidden, secondsHidden, millisecondsHidden
export type TimerProps = {
	name: Fluid.UsedAs<string>?,
	position: Fluid.UsedAs<UDim2>?,
	anchorPoint: Fluid.UsedAs<Vector2>?,
	size: Fluid.UsedAs<UDim2>?,
	automaticSize: Fluid.UsedAs<Enum.AutomaticSize>?,
	layoutOrder: Fluid.UsedAs<number>?,
	zIndex: Fluid.UsedAs<number>?,

	icon: Fluid.UsedAs<string>?,
	color: Fluid.UsedAs<Color3>?,
	count: Fluid.UsedAs<number>?,
	valueSeconds: Fluid.UsedAs<number>,
	totalSeconds: Fluid.UsedAs<number>?,
	visible: Fluid.UsedAs<boolean>?,
}

local function Timer(props: TimerProps)
	local rem = Liquid.useRem()
	local nextOrder = Liquid.useNextOrder()

	local color = props.color or Color3.new(1, 1, 1)
	local function colorLch()
		return Oklab.color3ToOklch(Fluid.read(color))
	end

	local function colorLightness()
		return math.clamp(colorLch().X, 2 / 3, 1)
	end
	local function colorChroma()
		return math.clamp(colorLch().Y * 1.5, 0, 0.2)
	end

	local function baseColor()
		return Oklab.oklchToColor3(Vector3.new(colorLightness(), colorChroma(), colorLch().Z))
	end

	local function darkColor()
		return Oklab.oklchToColor3(Vector3.new(colorLightness() * 0.7, colorChroma(), colorLch().Z))
	end

	local function progressColor()
		return Oklab.oklchToColor3(Vector3.new(colorLightness() * 1.5, colorChroma(), colorLch().Z))
	end

	local function lightColor()
		return Oklab.oklchToColor3(Vector3.new(colorLightness() * 1.25, colorChroma(), colorLch().Z))
	end

	local function minutes()
		return Fluid.read(props.valueSeconds) // 60
	end
	local function seconds()
		return Fluid.read(props.valueSeconds) % 60
	end
	local function milliseconds()
		return Fluid.read(props.valueSeconds) * 100 % 100
	end

	local digitSize = rem:intoUdim2(4, 4)
	local digitTextSize = rem:intoPx(5)
	local millisecondsDigitSize = rem:intoPx(3)

	local contentAbsoluteSize = Fluid.source(Vector2.zero)
	local scale = Fluid.spring(Liquid.useToggled(props.visible, 1, 0), 15, 2 / 3)

	return Fluid.create "CanvasGroup" {
		Name = props.name or "Timer",

		Position = props.position,
		AnchorPoint = props.anchorPoint,
		Size = props.size or function()
			local contentAbsoluteSize = contentAbsoluteSize()
			local padding = rem:px(0.5)
			return UDim2.fromOffset(contentAbsoluteSize.X + padding, contentAbsoluteSize.Y + padding)
		end,
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.None,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,

		Fluid.create "UICorner" { CornerRadius = rem:intoUdim(0.75) },
		BackgroundColor3 = Liquid.useToggled<<Color3>>(props.visible, progressColor, darkColor),
		ClipsDescendants = true,

		GroupTransparency = Fluid.spring(Liquid.useToggled(props.visible, 0, 1), 30, 1),
		Visible = function()
			return scale() >= 0.01
		end,
		Fluid.create "UIScale" { Scale = scale },

		Liquid.useShow(props.totalSeconds, Fluid.untrack :: any, function()
			local totalSeconds = props.totalSeconds :: Fluid.UsedAs<number>

			local function progress()
				return (Fluid.read(totalSeconds) - Fluid.read(props.valueSeconds)) / Fluid.read(totalSeconds)
			end

			local function isHalfway()
				return progress() >= 0.5
			end

			return {
				-- First 50%
				Fluid.create "ImageLabel" {
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromScale(2, 2),
					Sizelocalraint = Enum.Sizelocalraint.RelativeXX,
					Image = assets.ui.fillRight,
					ImageColor3 = Liquid.useToggled<<Color3>>(isHalfway, progressColor, darkColor),
					Rotation = function()
						local p = progress()
						return if isHalfway() then 0 else p * 360
					end,
					ZIndex = 0,
				},
				-- Last 50%
				Fluid.create "ImageLabel" {
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromScale(2, 2),
					Sizelocalraint = Enum.Sizelocalraint.RelativeXX,
					Image = assets.ui.fillLeft,
					ImageColor3 = darkColor,
					Rotation = function()
						local p = progress()
						return if p <= 0.5 then 0 else (p - 0.5) * 360
					end,
					ZIndex = -1,
				},
			}
		end),

		Fluid.create "Frame" {
			Name = "Content",
			Size = UDim2.new(),
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),

			Fluid.create "UIGradient" {
				Color = function()
					return ColorSequence.new(lightColor(), baseColor())
				end,
				Rotation = 90,
			},

			Liquid.outProperty("AbsoluteSize", contentAbsoluteSize),

			Fluid.create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			},

			Fluid.create "UICorner" { CornerRadius = rem:intoUdim(0.5) },
			Padding { horizontal = rem:intoUdim(1), bottom = rem:intoUdim(0.125) },

			-- useShow(
			-- 	props.icon,
			-- 	Fluid.untrack :: any,
			-- 	function()
			-- 		return Fluid.create "Frame" {
			-- 			Name = "Icon",
			-- 			BackgroundTransparency = 1,
			-- 			Size = rem:intoUdim2(4, 4),

			-- 			Padding { all = rem:intoUdim(0.25) },
			-- 			Fluid.create "ImageLabel" {
			-- 				BackgroundTransparency = 1,
			-- 				Position = UDim2.fromScale(0.5, 0.5),
			-- 				AnchorPoint = Vector2.new(0.5, 0.5),
			-- 				Size = UDim2.fromScale(1, 1),
			-- 				Image = props.icon,
			-- 				ImageColor3 = darkColor,
			-- 			},
			-- 		}
			-- 	end
			-- ),

			NumberSpinner {
				name = "MinutesSpinner",
				value = minutes,
				numDigits = 2,

				size = digitSize,
				textSize = digitTextSize,
				textColor = darkColor,
				fontWeight = Enum.FontWeight.SemiBold,

				layoutOrder = nextOrder(),
			},

			Text {
				name = "Colon",
				text = ":",
				textSize = millisecondsDigitSize,
				textColor = darkColor,
				font = Font.fromEnum(Enum.Font.Gotham),
				fontWeight = Enum.FontWeight.SemiBold,

				layoutOrder = nextOrder(),

				Padding { bottom = rem:intoUdim(1 / 3) },
			},

			NumberSpinner {
				name = "SecondsSpinner",
				value = seconds,
				numDigits = 2,

				size = digitSize,
				textSize = digitTextSize,
				textColor = darkColor,
				fontWeight = Enum.FontWeight.SemiBold,

				layoutOrder = nextOrder(),
			},

			Text {
				name = "MillisecondsSpinner",
				text = function()
					return string.format("%02i", milliseconds())
				end,
				textSize = millisecondsDigitSize,
				textColor = darkColor,

				layoutOrder = nextOrder(),
			},
		},
	}
end

return Timer
