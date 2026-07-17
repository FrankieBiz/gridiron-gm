--!strict
-- Bottom tab bar for the main app (Season / Roster / League).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

type Props = {
	active: string,
	onSelect: (tab: string) -> (),
}

local TABS = { "Season", "Roster", "League" }

local function TabBar(props: Props)
	local children: { [string]: any } = {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for i, tab in TABS do
		local isActive = props.active == tab
		children["tab_" .. tab] = e("TextButton", {
			Text = string.upper(tab),
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			TextColor3 = if isActive then Theme.flag else Theme.chalkSoft,
			BackgroundColor3 = Theme.field3,
			Size = UDim2.fromScale(1 / #TABS, 1),
			LayoutOrder = i,
			BorderSizePixel = 0,
			AutoButtonColor = true,
			[React.Event.Activated] = function()
				props.onSelect(tab)
			end,
		}, {
			pad = e("UIPadding", {
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			bar = if isActive
				then e("Frame", {
					BackgroundColor3 = Theme.flag,
					Size = UDim2.new(1, 0, 0, 3),
					Position = UDim2.new(0, 0, 0, 0),
					BorderSizePixel = 0,
				})
				else nil,
		})
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.new(0, 0, 1, -60),
		BackgroundColor3 = Theme.field3,
		BorderSizePixel = 0,
	}, children)
end

return TabBar
