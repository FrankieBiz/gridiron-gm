--!strict
-- Bottom tab bar. Active tab shows a filled rounded pill; each tab has an icon.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

type Props = {
	active: string,
	onSelect: (tab: string) -> (),
}

local TABS = {
	{ id = "Season", icon = "🏈" },
	{ id = "Roster", icon = "📋" },
	{ id = "League", icon = "🏆" },
	{ id = "HQ", icon = "🏟️" },
	{ id = "Career", icon = "💼" },
}

local function TabBar(props: Props)
	local children: { [string]: any } = {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		topline = e("Frame", {
			BackgroundColor3 = Theme.line,
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 3,
		}),
	}

	for i, tab in TABS do
		local isActive = props.active == tab.id
		children["tab_" .. tab.id] = e("TextButton", {
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1 / #TABS, 1),
			LayoutOrder = i,
			AutoButtonColor = false,
			[React.Event.Activated] = function()
				props.onSelect(tab.id)
			end,
		}, {
			pill = e("Frame", {
				BackgroundColor3 = Theme.flag,
				BackgroundTransparency = if isActive then 0 else 1,
				Size = UDim2.new(1, -14, 1, -16),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0,
			}, {
				corner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
				grad = if isActive
					then e(
						"UIGradient",
						{ Rotation = 90, Color = ColorSequence.new(Theme.flag, Theme.flagDeep) }
					)
					else nil,
				label = e("TextLabel", {
					Text = tab.icon .. "  " .. string.upper(tab.id),
					Font = Theme.font.bold,
					TextScaled = true,
					TextColor3 = if isActive then Theme.chalk else Theme.chalkSoft,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0.86, 0.42),
					Position = UDim2.fromScale(0.07, 0.29),
				}, { max = e("UITextSizeConstraint", { MaxTextSize = 13 }) }),
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		Position = UDim2.new(0, 0, 1, -64),
		BackgroundColor3 = Theme.field3,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, children)
end

return TabBar
