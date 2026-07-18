--!strict
-- Eyebrow label over a big mono number — the broadcast stat tile (spec: visual §M3).
-- Used on Dashboard header, CareerProfile career strip, DraftRoom scout points.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local AnimatedNumber = require(script.Parent.AnimatedNumber)

local e = React.createElement

export type Props = {
	label: string,
	value: number | string,
	accent: Color3?, -- number color, default chalk
	animate: boolean?, -- AnimatedNumber when numeric
	size: UDim2?,
	layoutOrder: number?,
}

local function StatChip(props: Props)
	local accent = props.accent or Theme.text.primary

	local valueChild: any
	if type(props.value) == "number" and props.animate then
		valueChild = e(AnimatedNumber, {
			value = props.value,
			animateOnMount = true,
			textColor3 = accent,
			textSize = 22,
			textXAlignment = Enum.TextXAlignment.Left,
			size = UDim2.new(1, 0, 0, 26),
			position = UDim2.fromOffset(0, 18),
		})
	else
		valueChild = e("TextLabel", {
			Text = tostring(props.value),
			Font = Theme.font.mono,
			TextSize = 22,
			TextColor3 = accent,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 26),
			Position = UDim2.fromOffset(0, 18),
		})
	end

	return e("Frame", {
		BackgroundColor3 = Theme.surface.raised,
		Size = props.size or UDim2.new(1, 0, 0, 56),
		LayoutOrder = props.layoutOrder,
		BorderSizePixel = 0,
	}, {
		_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
		_grad = e("UIGradient", { Rotation = 90, Color = Theme.grad.raised }),
		_stroke = e("UIStroke", {
			Color = Theme.strokes.edgeRaised.color,
			Transparency = Theme.strokes.edgeRaised.transparency,
			Thickness = Theme.strokes.edgeRaised.thickness,
		}),
		_pad = e("UIPadding", {
			PaddingTop = UDim.new(0, Theme.space.sm),
			PaddingBottom = UDim.new(0, Theme.space.sm),
			PaddingLeft = UDim.new(0, Theme.space.md),
			PaddingRight = UDim.new(0, Theme.space.md),
		}),
		_eyebrow = e("TextLabel", {
			Text = string.upper(props.label),
			Font = Theme.type.eyebrow.font,
			TextSize = Theme.type.eyebrow.size,
			TextColor3 = Theme.text.tertiary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 12),
		}),
		_value = valueChild,
	})
end

return StatChip
