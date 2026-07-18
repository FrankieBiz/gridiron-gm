--!strict
-- Pill chip: phase tags, offer tags (REBUILD / WIN NOW), dev traits, W/L records,
-- "SIGNED", news kinds. Auto-width with fixed-size eyebrow text.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

export type Variant = "neutral" | "brand" | "gold" | "success" | "danger" | "outline"

export type Props = {
	text: string,
	variant: Variant?, -- default "neutral"
	color: Color3?, -- outline/context color override
	small: boolean?, -- 18px instead of 24px
	layoutOrder: number?,
	zIndex: number?,
}

local function Badge(props: Props)
	local variant: Variant = props.variant or "neutral"
	local height = if props.small then 18 else Theme.size.chipH

	local fill: Color3
	local ink: Color3
	local fillT = 0
	local strokeColor: Color3? = nil
	if variant == "brand" then
		fill, ink = Theme.flag, Theme.chalk
	elseif variant == "gold" then
		fill, ink = Theme.gold, Theme.text.inverse
	elseif variant == "success" then
		fill, ink = Theme.semantic.success, Theme.text.inverse
	elseif variant == "danger" then
		fill, ink = Theme.semantic.danger, Theme.chalk -- alarm reads white-on-red
	elseif variant == "outline" then
		local c = props.color or Theme.chalkSoft
		fill, ink, fillT, strokeColor = c, c, 1, c
	else
		fill, ink = Theme.alpha(Theme.chalk, 0.05, Theme.field2), Theme.text.secondary
	end

	return e("Frame", {
		BackgroundColor3 = fill,
		BackgroundTransparency = fillT,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, height),
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		BorderSizePixel = 0,
	}, {
		_corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		_stroke = if strokeColor
			then e("UIStroke", { Color = strokeColor, Transparency = 0.5, Thickness = 1 })
			else nil,
		_pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		_label = e("TextLabel", {
			Text = string.upper(props.text),
			Font = Theme.type.eyebrow.font,
			TextSize = Theme.type.eyebrow.size,
			TextColor3 = ink,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
		}),
	})
end

return Badge
