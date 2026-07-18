--!strict
-- Player detail (replaces the old PlayerCard): header with position/name/dev-trait,
-- OVR count-up riding its tier color, staggered attribute bar fills, contract line,
-- and an optional context action (e.g. SIGN from free agency).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)
local motion = require(script.Parent.Parent.motion)
local Modal = require(script.Parent.Modal)
local Badge = require(script.Parent.Badge)
local Button = require(script.Parent.Button)
local AnimatedNumber = require(script.Parent.AnimatedNumber)

local e = React.createElement

export type Action = {
	text: string,
	onActivated: () -> (),
	disabled: boolean?,
}

export type Props = {
	player: Franchise.RosterPlayer | Franchise.FreeAgent,
	action: Action?,
	onClose: () -> (),
}

local ATTRS = {
	{ key = "speed", label = "SPD" },
	{ key = "strength", label = "STR" },
	{ key = "awareness", label = "AWR" },
}

local function attrBar(
	label: string,
	value: number,
	entrance: React.Binding<number>,
	order: number
): any
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = order,
	}, {
		_label = e("TextLabel", {
			Text = label,
			Font = Theme.type.eyebrow.font,
			TextSize = Theme.type.eyebrow.size,
			TextColor3 = Theme.text.tertiary,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(40, 24),
		}),
		_track = e("Frame", {
			BackgroundColor3 = Theme.surface.sunken,
			Position = UDim2.fromOffset(48, 8),
			Size = UDim2.new(1, -48 - 44, 0, Theme.size.barH),
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			fill = e("Frame", {
				BackgroundColor3 = Theme.ovrColor(value),
				BorderSizePixel = 0,
				Size = entrance:map(function(p: number): UDim2
					return UDim2.new(p * math.clamp(value / 99, 0, 1), 0, 1, 0)
				end),
			}, { corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
		}),
		_num = e("TextLabel", {
			Text = tostring(value),
			Font = Theme.font.mono,
			TextSize = Theme.type.monoSm.size,
			TextColor3 = Theme.text.secondary,
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 4),
			Size = UDim2.fromOffset(36, 16),
		}),
	})
end

local function PlayerDetailModal(props: Props)
	local p = props.player
	local ovrColor = Theme.ovrColor(p.overall)

	local bars = motion.useProgress(nil, { duration = 0.45, easing = motion.Solver.easeOutQuint })

	local rows: { [string]: any } = {
		_layout = e("UIListLayout", {
			Padding = UDim.new(0, Theme.space.sm),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		_header = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 56),
			LayoutOrder = 1,
		}, {
			pos = e(Badge, { text = p.position, variant = "brand" :: Badge.Variant }),
			name = e("TextLabel", {
				Text = p.name,
				Font = Theme.type.h1.font,
				TextSize = Theme.type.h1.size,
				TextColor3 = Theme.text.primary,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 28),
				Size = UDim2.new(1, -80, 0, 26),
			}),
			ovr = e(AnimatedNumber, {
				value = p.overall,
				animateOnMount = true,
				textColor3 = ovrColor,
				textSize = 40,
				size = UDim2.fromOffset(72, 44),
				position = UDim2.new(1, -72, 0, 4),
			}),
			ovrLabel = e("TextLabel", {
				Text = "OVERALL",
				Font = Theme.type.eyebrow.font,
				TextSize = 9,
				TextColor3 = Theme.text.tertiary,
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 46),
				Size = UDim2.fromOffset(72, 10),
			}),
		}),
		_meta = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = 2,
		}, {
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, Theme.space.sm),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			age = e(Badge, { text = `AGE {p.age}`, layoutOrder = 1 }),
			trait = e(Badge, {
				text = p.devTrait :: string,
				variant = (if p.devTrait == "superstar"
					then "brand"
					elseif p.devTrait == "star" then "gold"
					else "neutral") :: Badge.Variant,
				layoutOrder = 2,
			}),
			pot = e(Badge, { text = `POT {p.potential}`, layoutOrder = 3 }),
			morale = e(Badge, { text = `MRL {p.morale}`, layoutOrder = 4 }),
		}),
	}
	for i, attr in ATTRS do
		rows["_attr" .. i] = attrBar(attr.label, (p :: any)[attr.key], bars, 2 + i)
	end
	rows._contract = e("TextLabel", {
		Text = string.format("CONTRACT · $%s · %d YRS", tostring(p.salary), p.contractYears),
		Font = Theme.font.mono,
		TextSize = Theme.type.monoSm.size,
		TextColor3 = Theme.text.secondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 6,
	})
	if props.action then
		local action = props.action :: Action
		rows._action = e(Button, {
			text = action.text,
			onActivated = action.onActivated,
			disabled = action.disabled,
			layoutOrder = 7,
		})
	end

	return e(Modal, { title = nil, onClose = props.onClose }, {
		body = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, rows),
	})
end

return PlayerDetailModal
