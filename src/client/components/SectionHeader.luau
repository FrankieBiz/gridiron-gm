--!strict
-- Section title row: accent tick + ALL-CAPS eyebrow title + optional right-aligned meta.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

export type Props = {
	text: string,
	right: string?,
	accent: Color3?, -- default flag
	layoutOrder: number?,
}

local function SectionHeader(props: Props)
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = props.layoutOrder,
	}, {
		_tick = e("Frame", {
			BackgroundColor3 = props.accent or Theme.flag,
			Size = UDim2.fromOffset(3, 14),
			Position = UDim2.new(0, 0, 0.5, -7),
			BorderSizePixel = 0,
		}),
		_title = e("TextLabel", {
			Text = string.upper(props.text),
			Font = Theme.type.eyebrow.font,
			TextSize = Theme.type.caption.size,
			TextColor3 = Theme.text.secondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(11, 0),
			Size = UDim2.new(0.6, -11, 1, 0),
		}),
		_right = if props.right
			then e("TextLabel", {
				Text = props.right,
				Font = Theme.type.caption.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = Theme.text.tertiary,
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.6, 0),
				Size = UDim2.fromScale(0.4, 1),
			})
			else nil,
	})
end

return SectionHeader
