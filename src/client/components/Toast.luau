--!strict
-- One toast card: kind-colored accent rail, broadcast headline + optional detail,
-- tap-to-dismiss. Vertical position arrives as a binding from ToastStack's slot motors.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

export type Kind = "error" | "success" | "info"

export type Props = {
	kind: Kind,
	title: string,
	detail: string?,
	y: React.Binding<number>, -- slot position from ToastStack
	width: number,
	onDismiss: () -> (),
}

local KIND_COLOR: { [Kind]: Color3 } = {
	error = Theme.semantic.danger,
	success = Theme.semantic.success,
	info = Theme.gold,
}

local function Toast(props: Props)
	local accent = KIND_COLOR[props.kind]

	return e("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.surface.raised,
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(props.width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = props.y:map(function(y: number): UDim2
			return UDim2.new(0.5, 0, 0, math.floor(y))
		end),
		BorderSizePixel = 0,
		ZIndex = Theme.z.toast,
		[React.Event.Activated] = props.onDismiss,
	}, {
		_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
		_stroke = e("UIStroke", { Color = accent, Transparency = 0.55, Thickness = 1 }),
		_rail = e("Frame", {
			BackgroundColor3 = accent,
			Size = UDim2.new(0, 4, 1, -2),
			Position = UDim2.fromOffset(1, 1),
			BorderSizePixel = 0,
			ZIndex = Theme.z.toast,
		}, { corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.xs) }) }),
		_pad = e("UIPadding", {
			PaddingTop = UDim.new(0, Theme.space.md),
			PaddingBottom = UDim.new(0, Theme.space.md),
			PaddingLeft = UDim.new(0, Theme.space.lg),
			PaddingRight = UDim.new(0, Theme.space.md),
		}),
		_title = e("TextLabel", {
			Text = string.upper(props.title),
			Font = Theme.type.bodyBold.font,
			TextSize = Theme.type.body.size,
			TextColor3 = accent,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			ZIndex = Theme.z.toast,
		}),
		_detail = if props.detail
			then e("TextLabel", {
				Text = props.detail,
				Font = Theme.type.caption.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = Theme.text.secondary,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.fromOffset(0, 18),
				ZIndex = Theme.z.toast,
			})
			else nil,
	})
end

return Toast
