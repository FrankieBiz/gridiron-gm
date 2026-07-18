--!strict
-- Draft prospect detail: fog-of-war OVR/POT range bars large, scout hint, SCOUT/PICK
-- actions mirrored from the board row.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)
local Modal = require(script.Parent.Modal)
local Badge = require(script.Parent.Badge)
local Button = require(script.Parent.Button)
local RangeBar = require(script.Parent.RangeBar)

local e = React.createElement

export type Props = {
	prospect: Franchise.ScoutedProspect,
	scoutPoints: number,
	scouting: boolean?,
	isMyPick: boolean,
	onScout: () -> (),
	onPick: (() -> ())?,
	onClose: () -> (),
}

local function rangeSection(label: string, lo: number, hi: number, order: number): any
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = order,
	}, {
		_label = e("TextLabel", {
			Text = label,
			Font = Theme.type.eyebrow.font,
			TextSize = Theme.type.eyebrow.size,
			TextColor3 = Theme.text.tertiary,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -80, 0, 14),
		}),
		_range = e("TextLabel", {
			Text = if hi - lo <= 2 then tostring(hi) else string.format("%d–%d", lo, hi),
			Font = Theme.font.mono,
			TextSize = Theme.type.mono.size,
			TextColor3 = if hi - lo <= 2 then Theme.ovrColor(hi) else Theme.text.secondary,
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(76, 14),
		}),
		_bar = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 22),
			Size = UDim2.new(1, 0, 0, Theme.size.barH + 4),
		}, {
			bar = e(RangeBar, { min = lo, max = hi, height = Theme.size.barH + 2 }),
		}),
	})
end

local function ProspectDetailModal(props: Props)
	local p = props.prospect
	local canScout = props.scoutPoints > 0 and (p.ovrMax - p.ovrMin) > 2

	local rows: { [string]: any } = {
		_layout = e("UIListLayout", {
			Padding = UDim.new(0, Theme.space.md),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		_header = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 52),
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
				Position = UDim2.fromOffset(0, 26),
				Size = UDim2.new(1, 0, 0, 24),
			}),
			age = e("TextLabel", {
				Text = `AGE {p.age}`,
				Font = Theme.type.caption.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = Theme.text.secondary,
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -52, 0, 6),
				Size = UDim2.fromOffset(60, 14),
			}),
		}),
		_ovr = rangeSection("PROJECTED OVERALL", p.ovrMin, p.ovrMax, 2),
		_pot = rangeSection("CEILING", p.potMin, p.potMax, 3),
		_hint = e("TextLabel", {
			Text = if canScout
				then string.format(
					"Scouting narrows the fog. %d point%s left.",
					props.scoutPoints,
					if props.scoutPoints == 1 then "" else "s"
				)
				elseif p.ovrMax - p.ovrMin <= 2 then "Fully scouted — the tape doesn't lie."
				else "No scout points left. Trust your gut.",
			Font = Theme.type.caption.font,
			TextSize = Theme.type.caption.size,
			TextColor3 = Theme.text.secondary,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 4,
		}),
		_scout = e(Button, {
			text = `SCOUT · 🔭 {props.scoutPoints}`,
			variant = "secondary" :: Button.Variant,
			onActivated = props.onScout,
			disabled = not canScout,
			loading = props.scouting,
			layoutOrder = 5,
		}),
	}
	if props.isMyPick and props.onPick then
		rows._pick = e(Button, {
			text = "TURN IN THE PICK",
			onActivated = props.onPick :: () -> (),
			sfx = "pick",
			layoutOrder = 6,
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

return ProspectDetailModal
