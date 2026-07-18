--!strict
-- Text-monogram team crest (no image assets): team-gradient square, secondary stroke +
-- accent bar, abbr in guarded ink. The team identity mark used everywhere.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

export type Props = {
	abbr: string,
	primary: Color3,
	secondary: Color3,
	size: number,
	layoutOrder: number?,
	zIndex: number?,
}

local function TeamCrest(props: Props)
	local size = props.size
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.fromOffset(size, size),
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		BorderSizePixel = 0,
	}, {
		_corner = e("UICorner", { CornerRadius = UDim.new(0, math.floor(size * 0.28)) }),
		_grad = e("UIGradient", {
			Rotation = 115,
			Color = ColorSequence.new(props.primary, Theme.darken(props.primary, 0.6)),
		}),
		_stroke = e("UIStroke", {
			Color = props.secondary,
			Transparency = 0.15,
			Thickness = 2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		_accent = e("Frame", {
			BackgroundColor3 = props.secondary,
			Size = UDim2.new(1, 0, 0, math.max(2, math.floor(size * 0.1))),
			Position = UDim2.new(0, 0, 1, -math.max(2, math.floor(size * 0.1))),
			BorderSizePixel = 0,
		}),
		_abbr = e("TextLabel", {
			Text = string.upper(props.abbr),
			Font = Theme.font.display,
			TextSize = math.max(8, math.floor(size * 0.38)),
			TextColor3 = Theme.contrastOn(props.primary),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
		}),
	})
end

return TeamCrest
