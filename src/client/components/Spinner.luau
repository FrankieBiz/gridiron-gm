--!strict
-- Inline pending indicator: three dots on a staggered sine (no rotation — no clipping
-- hazard). Replaces a button label while its remote call is in flight.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)

local e = React.createElement

export type Props = {
	size: number?, -- dot diameter, default 6
	color: Color3?,
	layoutOrder: number?,
}

local function Spinner(props: Props)
	local dot = props.size or 6
	local color = props.color or Theme.text.secondary
	local pulse = motion.usePulse({ period = 0.9 })

	local children: { [string]: any } = {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, dot // 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for i = 1, 3 do
		local phase = (i - 1) / 3
		children["dot" .. i] = e("Frame", {
			BackgroundColor3 = color,
			Size = UDim2.fromOffset(dot, dot),
			BorderSizePixel = 0,
			LayoutOrder = i,
			BackgroundTransparency = pulse:map(function(p: number): number
				local wave = 0.5 - 0.5 * math.cos(2 * math.pi * ((p + phase) % 1))
				return 0.7 - 0.6 * wave
			end),
		}, { corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(dot * 5, dot * 2),
		LayoutOrder = props.layoutOrder,
	}, children)
end

return Spinner
