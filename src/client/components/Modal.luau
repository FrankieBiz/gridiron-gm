--!strict
-- The modal card shell used inside overlay.open builds: overlay-surface card, title
-- bar with a 44px close target, inert body (taps never fall through).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

export type Props = {
	title: string?,
	onClose: () -> (),
	width: number?, -- default min(viewport-32, modalMaxW)
	children: { [string]: any }?,
}

local function Modal(props: Props)
	local camera = workspace.CurrentCamera
	local viewportW = if camera then camera.ViewportSize.X else 375
	local width = props.width or math.min(viewportW - 32, Theme.chrome.modalMaxW)

	local body: { [string]: any } = {
		_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.xl) }),
		_grad = e("UIGradient", { Rotation = 90, Color = Theme.grad.overlay }),
		_stroke = e("UIStroke", {
			Color = Theme.stroke,
			Transparency = 0.8,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		_pad = e("UIPadding", {
			PaddingTop = UDim.new(0, Theme.space.lg),
			PaddingBottom = UDim.new(0, Theme.space.lg),
			PaddingLeft = UDim.new(0, Theme.space.lg),
			PaddingRight = UDim.new(0, Theme.space.lg),
		}),
	}
	if props.title then
		body._title = e("TextLabel", {
			Text = string.upper(props.title),
			Font = Theme.type.h1.font,
			TextSize = Theme.type.h1.size,
			TextColor3 = Theme.text.primary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -44, 0, 28),
		})
	end
	body._close = e("TextButton", {
		Text = "✕",
		Font = Theme.type.h2.font,
		TextSize = Theme.type.h2.size,
		TextColor3 = Theme.text.secondary,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, Theme.space.sm, 0, -Theme.space.sm),
		Size = UDim2.fromOffset(Theme.size.touchMin, Theme.size.touchMin),
		ZIndex = 2,
		[React.Event.Activated] = props.onClose,
	})
	if props.children then
		for k, v in props.children do
			body[k] = v
		end
	end

	-- Inert TextButton surface: swallows taps so they never reach the scrim.
	return e("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Active = true,
		BackgroundColor3 = Theme.surface.overlay,
		Size = UDim2.fromOffset(width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
	}, body)
end

return Modal
