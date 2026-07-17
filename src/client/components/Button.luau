--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

type Props = {
	text: string,
	onActivated: () -> (),
	color: Color3?, -- solid override (used for secondary buttons)
	textColor: Color3?,
	size: UDim2?,
	layoutOrder: number?,
	disabled: boolean?,
}

local function Button(props: Props)
	local primary = props.color == nil
	local base = props.color or Theme.flag
	local disabled = props.disabled == true

	local children: { [string]: any } = {
		corner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
		stroke = e("UIStroke", {
			Color = Theme.stroke,
			Transparency = 0.82,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
	}
	-- Primary buttons get a warm vertical gradient for depth.
	if primary and not disabled then
		children.grad = e("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Theme.flag, Theme.flagDeep),
		})
	end

	return e("TextButton", {
		Text = props.text,
		Font = Theme.font.display,
		TextScaled = true,
		TextColor3 = if disabled then Theme.chalkSoft else (props.textColor or Theme.chalk),
		BackgroundColor3 = if disabled then Theme.field3 else base,
		Size = props.size or UDim2.fromScale(0.72, 0.12),
		AutoButtonColor = not disabled,
		LayoutOrder = props.layoutOrder or 0,
		BorderSizePixel = 0,
		Active = not disabled,
		[React.Event.Activated] = function()
			if not disabled then
				props.onActivated()
			end
		end,
	}, children)
end

return Button
