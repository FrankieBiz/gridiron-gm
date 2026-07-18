--!strict
-- The reusable player list row (Roster, FreeAgency): dev-trait rail, position block,
-- name + meta, right-hand OVR column with POT or cost. Memoized; entrance-animated via
-- the cheap per-row recipe (inner-frame offset + transparency maps — no CanvasGroup).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)
local motion = require(script.Parent.Parent.motion)

local e = React.createElement

export type Props = {
	player: Franchise.RosterPlayer | Franchise.FreeAgent,
	index: number,
	entrance: React.Binding<number>?, -- stagger.item(i); nil = mounted settled
	right: ("potential" | "cost")?, -- right column mode, default potential
	disabled: boolean?, -- e.g. unaffordable free agent
	onTap: (() -> ())?,
	actionButton: any?, -- optional trailing element (SIGN button etc.)
	layoutOrder: number?,
}

local function PlayerRow(props: Props)
	local p = props.player
	local entrance = props.entrance
	local dim = props.disabled == true

	local scale, scaleApi = motion.useMotor(1)

	local actionWidth = if props.actionButton then 88 else 0
	local ovrRight = -Theme.space.md - actionWidth

	local inner: { [string]: any } = {
		_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
		_stroke = e("UIStroke", {
			Color = Theme.strokes.edge.color,
			Thickness = 1,
			Transparency = if entrance
				then entrance:map(function(v: number): number
					return motion.Motion.alpha(v, Theme.strokes.edge.transparency)
				end)
				else Theme.strokes.edge.transparency,
		}),
		_rail = e("Frame", {
			BackgroundColor3 = Theme.devColor(p.devTrait),
			Size = UDim2.new(0, 3, 1, -2),
			Position = UDim2.fromOffset(1, 1),
			BorderSizePixel = 0,
		}, { corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.xs) }) }),
		_pos = e("TextLabel", {
			Text = p.position,
			Font = Theme.font.display,
			TextSize = Theme.type.caption.size,
			TextColor3 = if dim then Theme.text.disabled else Theme.flag,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(Theme.space.md, 0),
			Size = UDim2.new(0, 40, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		_name = e("TextLabel", {
			Text = p.name,
			Font = Theme.type.h2.font,
			TextSize = Theme.type.h2.size,
			TextColor3 = if dim then Theme.text.disabled else Theme.text.primary,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(Theme.space.md + 44, 8),
			Size = UDim2.new(1, -Theme.space.md - 44 - 96 - actionWidth, 0, 20),
		}),
		_meta = e("TextLabel", {
			Text = string.format("%d · %s", p.age, string.upper(p.devTrait)),
			Font = Theme.type.caption.font,
			TextSize = Theme.type.caption.size,
			TextColor3 = Theme.text.secondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(Theme.space.md + 44, 30),
			Size = UDim2.new(1, -Theme.space.md - 44 - 96 - actionWidth, 0, 14),
		}),
		_ovr = e("TextLabel", {
			Text = tostring(p.overall),
			Font = Theme.font.mono,
			TextSize = Theme.type.h1.size,
			TextColor3 = if dim then Theme.text.disabled else Theme.ovrColor(p.overall),
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, ovrRight - 48, 0, 8),
			Size = UDim2.fromOffset(48, 24),
		}),
		_sub = e("TextLabel", {
			Text = if props.right == "cost"
				then string.format("%d 🪙", (p :: Franchise.FreeAgent).cost)
				else string.format("POT %d", p.potential),
			Font = Theme.font.mono,
			TextSize = Theme.type.monoSm.size,
			TextColor3 = if props.right == "cost" then Theme.gold else Theme.text.secondary,
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, ovrRight - 64, 0, 32),
			Size = UDim2.fromOffset(64, 14),
		}),
	}
	if props.actionButton then
		inner._action = e("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -Theme.space.sm, 0.5, 0),
			Size = UDim2.fromOffset(actionWidth - Theme.space.sm, 40),
		}, { btn = props.actionButton })
	end
	if props.onTap then
		inner._scale = e("UIScale", { Scale = scale })
	end

	local innerProps: { [any]: any } = {
		BackgroundColor3 = Theme.surface.base,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Position = if entrance
			then entrance:map(function(v: number): UDim2
				return UDim2.fromOffset(math.floor(-motion.Motion.dist.slide * 0.75 * (1 - v)), 0)
			end)
			else nil,
		BackgroundTransparency = if entrance
			then entrance:map(function(v: number): number
				return motion.Motion.alpha(v, 0)
			end)
			else 0,
	}

	local innerElement: any
	if props.onTap then
		innerProps.Text = ""
		innerProps.AutoButtonColor = false
		innerProps[React.Event.InputBegan] = function(_rbx, input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				scaleApi.setTarget(0.97, motion.Motion.spring.snappy)
			end
		end
		innerProps[React.Event.InputEnded] = function(_rbx, input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				scaleApi.setTarget(1, motion.Motion.spring.pop)
			end
		end
		innerProps[React.Event.Activated] = function()
			if props.onTap then
				props.onTap()
			end
		end
		innerElement = e("TextButton", innerProps, inner)
	else
		innerElement = e("Frame", innerProps, inner)
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Theme.size.rowH),
		LayoutOrder = props.layoutOrder,
	}, { inner = innerElement })
end

return React.memo(PlayerRow)
