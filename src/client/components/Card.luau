--!strict
-- Card v2: elevation-skinned panel (flat/raised/highlight/team) with optional selection
-- state and tap handling. Built-in children are underscore-prefixed so caller keys can
-- never collide (spec: ui-v2-visual §8.2).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)

local e = React.createElement

export type Variant = "flat" | "raised" | "highlight" | "team"

export type Props = {
	variant: Variant?, -- default "flat"
	team: Theme.TeamPalette?, -- required for variant "team"
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	automaticSize: Enum.AutomaticSize?,
	layoutOrder: number?,
	zIndex: number?,
	selectable: boolean?, -- swaps Frame -> TextButton with press dip
	selected: boolean?,
	onActivated: (() -> ())?,
	children: { [string]: any }?,
}

local function Card(props: Props)
	local variant: Variant = props.variant or "flat"
	local team = props.team
	local selected = props.selected == true
	local interactive = props.selectable == true or props.onActivated ~= nil

	local scale, scaleApi = motion.useMotor(1)

	local fill: Color3
	local grad: ColorSequence
	local strokeSpec: Theme.StrokeSpec
	if variant == "raised" then
		fill = Theme.surface.raised
		grad = Theme.grad.raised
		strokeSpec = Theme.strokes.edgeRaised
	elseif variant == "highlight" then
		fill = Theme.alpha(Theme.flag, 0.10, Theme.panel)
		grad = Theme.grad.raised
		strokeSpec = { color = Theme.flag, transparency = 0.45, thickness = 2 }
	elseif variant == "team" and team then
		fill = team.tint
		grad = Theme.grad.surface
		strokeSpec = { color = team.accent, transparency = 0.70, thickness = 1 }
	else
		fill = Theme.surface.base
		grad = Theme.grad.surface
		strokeSpec = Theme.strokes.edge
	end
	if selected then
		strokeSpec = Theme.strokes.focus
	end

	local children: { [string]: any } = {
		_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.lg) }),
		_grad = e("UIGradient", { Rotation = 90, Color = grad }),
		_stroke = e("UIStroke", {
			Color = strokeSpec.color,
			Transparency = strokeSpec.transparency,
			Thickness = strokeSpec.thickness,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	}
	if variant == "team" and team then
		children._rail = e("Frame", {
			BackgroundColor3 = team.accent,
			Size = UDim2.new(0, 3, 1, -2),
			Position = UDim2.fromOffset(1, 1),
			BorderSizePixel = 0,
		}, { corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.xs) }) })
	end
	if interactive then
		children._scale = e("UIScale", { Scale = scale })
	end
	if props.children then
		for k, v in props.children do
			children[k] = v
		end
	end

	local hostProps: { [any]: any } = {
		BackgroundColor3 = fill,
		Size = props.size,
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		AutomaticSize = props.automaticSize,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		BorderSizePixel = 0,
	}

	if not interactive then
		return e("Frame", hostProps, children)
	end

	hostProps.Text = ""
	hostProps.AutoButtonColor = false
	hostProps[React.Event.InputBegan] = function(_rbx, input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			scaleApi.setTarget(0.97, motion.Motion.spring.snappy)
		end
	end
	hostProps[React.Event.InputEnded] = function(_rbx, input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			scaleApi.setTarget(1, motion.Motion.spring.pop)
		end
	end
	hostProps[React.Event.Activated] = function()
		if props.onActivated then
			props.onActivated()
		end
	end

	return e("TextButton", hostProps, children)
end

return Card
