--!strict
-- First-run / empty-list treatment: glyph + headline + one-sentence sub, optional ghost
-- action. Every list screen ships one — blank panels are banned.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Button)

local e = React.createElement

export type Props = {
	icon: string?, -- emoji glyph
	title: string,
	body: string?,
	actionText: string?,
	onAction: (() -> ())?,
	compact: boolean?,
	layoutOrder: number?,
}

local function EmptyState(props: Props)
	local children: { [string]: any } = {
		_layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, Theme.space.sm),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	if props.icon then
		children._glyph = e("TextLabel", {
			Text = props.icon,
			Font = Theme.font.body,
			TextSize = if props.compact then 28 else 40,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, if props.compact then 34 else 48),
			LayoutOrder = 1,
		})
	end
	children._title = e("TextLabel", {
		Text = string.upper(props.title),
		Font = Theme.type.h2.font,
		TextSize = Theme.type.h2.size,
		TextColor3 = Theme.text.primary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 2,
	})
	if props.body then
		children._body = e("TextLabel", {
			Text = props.body,
			Font = Theme.type.body.font,
			TextSize = Theme.type.body.size,
			TextColor3 = Theme.text.secondary,
			TextWrapped = true,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = 3,
		})
	end
	if props.actionText and props.onAction then
		children._action = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Theme.size.buttonH + Theme.space.lg),
			LayoutOrder = 4,
		}, {
			_pad = e("UIPadding", { PaddingTop = UDim.new(0, Theme.space.lg) }),
			btn = e(Button, {
				text = props.actionText :: string,
				variant = "ghost" :: Button.Variant,
				onActivated = props.onAction :: () -> (),
				size = UDim2.new(1, 0, 0, Theme.size.buttonH),
			}),
		})
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(280, if props.compact then 110 else 190),
		LayoutOrder = props.layoutOrder,
	}, children)
end

return EmptyState
