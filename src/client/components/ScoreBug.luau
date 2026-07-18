--!strict
-- The persistent GameResult scoreboard: crests + abbrs + fixed-width mono score columns
-- (digits never drift) + live quarter/clock chip. My side reads flag-tinted; winnerSide
-- snaps a gold stroke onto that row at the final gun.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local AnimatedNumber = require(script.Parent.AnimatedNumber)
local TeamCrest = require(script.Parent.TeamCrest)

local e = React.createElement

export type Side = {
	abbr: string,
	name: string,
	primary: Color3,
	secondary: Color3,
	score: number,
	mine: boolean,
}

export type Props = {
	home: Side,
	away: Side,
	quarterText: string, -- "Q3 · 8:42" | "FINAL"
	label: string, -- "Week 7" | "Semifinals" | "Championship"
	winnerSide: ("home" | "away")?,
	snapScores: boolean?, -- skip mode: scores land instantly
}

local ROW_H = 36

local function sideRow(side: Side, y: number, won: boolean, snap: boolean?): any
	return e("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(Theme.space.lg, y),
		Size = UDim2.new(1, -Theme.space.lg * 2, 0, ROW_H),
	}, {
		_stroke = if won
			then e("UIStroke", { Color = Theme.gold, Transparency = 0.35, Thickness = 1.5 })
			else nil,
		_crest = e(TeamCrest, {
			abbr = side.abbr,
			primary = side.primary,
			secondary = side.secondary,
			size = 28,
		}),
		_name = e("TextLabel", {
			Text = string.upper(side.name),
			Font = Theme.font.display,
			TextSize = Theme.type.h2.size,
			TextColor3 = if side.mine then Theme.flag else Theme.chalk,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(36, 0),
			Size = UDim2.new(1, -36 - 56, 1, 0),
		}),
		_score = e(AnimatedNumber, {
			value = side.score,
			snap = snap,
			textSize = 26,
			textColor3 = if won then Theme.gold else Theme.chalk,
			size = UDim2.new(0, 48, 1, 0),
			position = UDim2.new(1, -48, 0, 0),
		}),
	})
end

local function ScoreBug(props: Props)
	return e("Frame", {
		BackgroundColor3 = Theme.bg.base,
		Size = UDim2.new(1, 0, 0, 100),
		BorderSizePixel = 0,
	}, {
		_grad = e("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Theme.bg.high, Theme.bg.base),
		}),
		_home = sideRow(props.home, 10, props.winnerSide == "home", props.snapScores),
		_away = sideRow(props.away, 10 + ROW_H + 4, props.winnerSide == "away", props.snapScores),
		_chip = e("Frame", {
			BackgroundColor3 = Theme.alpha(Theme.chalk, 0.06, Theme.field2),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -Theme.space.lg - 56, 0, 12),
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 20),
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			pad = e("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
			label = e("TextLabel", {
				Text = props.quarterText,
				Font = Theme.font.mono,
				TextSize = Theme.type.monoSm.size,
				TextColor3 = Theme.text.secondary,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromScale(0, 1),
			}),
		}),
		_label = e("TextLabel", {
			Text = string.upper(props.label),
			Font = Theme.type.eyebrow.font,
			TextSize = Theme.type.eyebrow.size,
			TextColor3 = Theme.text.tertiary,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -Theme.space.lg, 1, -8),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(160, 12),
		}),
		_rule = e("Frame", {
			BackgroundColor3 = Theme.border.strong,
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BorderSizePixel = 0,
		}),
	})
end

return ScoreBug
