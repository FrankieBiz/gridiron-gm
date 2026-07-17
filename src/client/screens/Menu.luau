--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Parent.components.Button)

local e = React.createElement

type Props = {
	hasFranchise: boolean,
	onNew: () -> (),
	onContinue: () -> (),
}

local function Menu(props: Props)
	local menuChildren: { [string]: any } = {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		newBtn = e(Button, {
			text = "NEW FRANCHISE",
			onActivated = props.onNew,
			layoutOrder = 1,
			size = UDim2.fromScale(0.7, 0.13),
		}),
	}
	if props.hasFranchise then
		menuChildren.continueBtn = e(Button, {
			text = "CONTINUE",
			onActivated = props.onContinue,
			color = Theme.field2,
			layoutOrder = 2,
			size = UDim2.fromScale(0.7, 0.13),
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		title = e("TextLabel", {
			Text = "GRIDIRON GM",
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			TextColor3 = Theme.chalk,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.8, 0.14),
			Position = UDim2.fromScale(0.1, 0.16),
		}),
		subtitle = e("TextLabel", {
			Text = "FRONT-OFFICE FOOTBALL SIM",
			Font = Enum.Font.GothamMedium,
			TextScaled = true,
			TextColor3 = Theme.flag,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.6, 0.04),
			Position = UDim2.fromScale(0.2, 0.31),
		}),
		menu = e("Frame", {
			Size = UDim2.fromScale(0.9, 0.34),
			Position = UDim2.fromScale(0.05, 0.5),
			BackgroundTransparency = 1,
		}, menuChildren),
	})
end

return Menu
