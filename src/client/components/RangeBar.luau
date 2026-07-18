--!strict
-- Fog-of-war range bar (the draft's signature visual): min/max edges spring toward each
-- other as scouting narrows the range; a collapsed range (≤2 wide) snaps gold.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)

local e = React.createElement

export type Props = {
	min: number,
	max: number,
	floor: number?, -- domain low, default 40
	ceil: number?, -- domain high, default 99
	color: Color3?, -- default flag; collapse overrides to gold
	height: number?, -- default Theme.size.barH
	layoutOrder: number?,
}

local function RangeBar(props: Props)
	local lo = props.floor or 40
	local hi = props.ceil or 99
	local span = math.max(hi - lo, 1)

	local minScale =
		motion.useSpring(math.clamp((props.min - lo) / span, 0, 1), motion.Motion.spring.slide)
	local maxScale =
		motion.useSpring(math.clamp((props.max - lo) / span, 0, 1), motion.Motion.spring.slide)

	local collapsed = (props.max - props.min) <= 2
	local fillColor = if collapsed then Theme.gold else (props.color or Theme.flag)

	return e("Frame", {
		BackgroundColor3 = Theme.surface.sunken,
		Size = UDim2.new(1, 0, 0, props.height or Theme.size.barH),
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
			BackgroundColor3 = fillColor,
			BorderSizePixel = 0,
			Position = minScale:map(function(s: number): UDim2
				return UDim2.fromScale(s, 0)
			end),
			Size = React.joinBindings({ lo = minScale, hi = maxScale } :: { [string]: any })
				:map(function(v: any): UDim2
					return UDim2.new(math.max(v.hi - v.lo, 0.02), 0, 1, 0)
				end),
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			grad = e("UIGradient", {
				Rotation = 0,
				Color = ColorSequence.new(fillColor, Theme.lighten(fillColor, 0.22)),
			}),
		}),
	})
end

return RangeBar
