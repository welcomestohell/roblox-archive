local Fluid = require("@roblox_packages/Fluid")
local Text = require("@core/ui/components/base/Text")
local WTHLogo = require("@core/ui/components/branding/WTHLogo")
local useInterval = require("@core/shared/fluid/useInterval")
local useNextOrder = require("@core/shared/fluid/useNextOrder")
local useRem = require("@core/shared/fluid/useRem")

local function LoadingScreen(props: {
	label: Fluid.UsedAs<string>?,
	title: Fluid.UsedAs<string>?,

	name: Fluid.UsedAs<string>?,
	zIndex: Fluid.UsedAs<number>?,
})
	local rem = useRem()
	local nextOrder = useNextOrder()

	local logoVisible = Fluid.source(true)
	useInterval(1, function()
		logoVisible(not logoVisible())
	end)

	return Fluid.create("ImageLabel")({
		Name = props.name or "LoadingScreen",
		BackgroundColor3 = Color3.new(0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		ZIndex = props.zIndex,

		Fluid.create("Frame")({
			Name = "Bottom",
			BackgroundTransparency = 1,
			Size = UDim2.new(),
			AutomaticSize = Enum.AutomaticSize.XY,

			Fluid.create("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = function()
					return UDim.new(0, rem(0.25))
				end,
			}),

			WTHLogo({
				visible = logoVisible,
				layoutOrder = nextOrder(),
				size = function()
					return UDim2.fromOffset(rem(4), rem(4))
				end,
			}),

			Fluid.create("Frame")({
				Name = "Text",
				BackgroundTransparency = 1,
				Size = UDim2.new(),
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = nextOrder(),

				Fluid.create("UIListLayout")({
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = function()
						return UDim.new(0, -rem(0.5))
					end,
				}),

				Text({
					name = "Label",
					layoutOrder = nextOrder(),
					text = props.label,
					textSize = function()
						return rem(1)
					end,
				}),

				Text({
					name = "Title",
					layoutOrder = nextOrder(),
					text = props.title,
					textSize = function()
						return rem(2.75)
					end,
					fontWeight = Enum.FontWeight.Bold,
				}),
			}),
		}),
	})
end

return LoadingScreen
