--!strict
-- Progress: continuous pill bar (job security, reputation, week progress with an
-- optional gold notch) or segmented pips (facility levels — gap math avoids the old
-- overflow bug). Fill springs to its value.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)

local e = React.createElement

export type Props = {
	value: number,
	max: number,
	color: Color3?, -- default flag
	height: number?, -- default Theme.size.barH
	segments: number?, -- discrete pips instead of a continuous fill
	notch: number?, -- 0..1 gold tick position (continuous only)
	layoutOrder: number?,
}

local GAP = 4

local function ProgressBar(props: Props)
	local height = props.height or Theme.size.barH
	local color = props.color or Theme.flag
	local ratio = if props.max > 0 then math.clamp(props.value / props.max, 0, 1) else 0
	local fillScale = motion.useSpring(ratio, motion.Motion.spring.slide)

	if props.segments then
		local n = props.segments
		local children: { [string]: any } = {
			_layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}
		local filled = math.floor(props.value + 0.5)
		local allMaxed = filled >= n
		for i = 1, n do
			local isFilled = i <= filled
			children["pip" .. i] = e("Frame", {
				BackgroundColor3 = if not isFilled
					then Theme.surface.sunken
					elseif allMaxed then Theme.gold
					else color,
				Size = UDim2.new(1 / n, -math.floor(GAP * (n - 1) / n), 1, 0),
				LayoutOrder = i,
				BorderSizePixel = 0,
			}, {
				corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.xs) }),
				stroke = if not isFilled
					then e("UIStroke", {
						Color = Theme.strokes.hairline.color,
						Transparency = Theme.strokes.hairline.transparency,
						Thickness = 1,
					})
					else nil,
			})
		end
		return e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, height),
			LayoutOrder = props.layoutOrder,
		}, children) :: any
	end

	return e("Frame", {
		BackgroundColor3 = Theme.surface.sunken,
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = props.layoutOrder,
		BorderSizePixel = 0,
	}, {
		_corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		_stroke = e("UIStroke", {
			Color = Theme.strokes.hairline.color,
			Transparency = Theme.strokes.hairline.transparency,
			Thickness = 1,
		}),
		_fill = e("Frame", {
			BackgroundColor3 = Theme.chalk,
			Size = fillScale:map(function(s: number): UDim2
				return UDim2.new(
					math.clamp(s, 0, 1),
					if s > 0 then math.max(8 - 8 * s, 0) else 0,
					1,
					0
				)
			end),
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			grad = e("UIGradient", {
				Rotation = 0,
				Color = ColorSequence.new(color, Theme.lighten(color, 0.22)),
			}),
		}),
		_notch = if props.notch
			then e("Frame", {
				BackgroundColor3 = Theme.gold,
				Size = UDim2.new(0, 2, 1, 2),
				Position = UDim2.new(math.clamp(props.notch, 0, 1), -1, 0, -1),
				BorderSizePixel = 0,
				ZIndex = 2,
			})
			else nil,
	})
end

return ProgressBar
