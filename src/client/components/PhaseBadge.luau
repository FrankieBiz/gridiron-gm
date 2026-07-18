--!strict
-- The "LIVE"-style phase bug: pulsing dot + phase label, tinted by season phase
-- (regular green / playoffs gold / offseason info-blue).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)

local e = React.createElement

export type Props = {
	phase: string, -- SeasonPhase
	text: string, -- e.g. "WEEK 7 · REGULAR SEASON"
	layoutOrder: number?,
	zIndex: number?,
}

local function PhaseBadge(props: Props)
	local color = Theme.phaseColor(props.phase)
	local live = props.phase == "regular" or props.phase == "playoffs"
	local pulse = motion.usePulse({ period = 2, enabled = live })

	return e("Frame", {
		BackgroundColor3 = Theme.alpha(color, 0.18, Theme.field2),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, Theme.size.chipH),
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		BorderSizePixel = 0,
	}, {
		_corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		_stroke = e("UIStroke", { Color = color, Transparency = 0.55, Thickness = 1 }),
		_layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		_pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 12),
		}),
		_dot = e("Frame", {
			BackgroundColor3 = color,
			Size = UDim2.fromOffset(6, 6),
			LayoutOrder = 1,
			BorderSizePixel = 0,
			BackgroundTransparency = pulse:map(function(p: number): number
				return 0.55 * p
			end),
		}, { corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
		_label = e("TextLabel", {
			Text = string.upper(props.text),
			Font = Theme.type.eyebrow.font,
			TextSize = Theme.type.eyebrow.size,
			TextColor3 = Theme.text.primary,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			LayoutOrder = 2,
		}),
	})
end

return PhaseBadge
