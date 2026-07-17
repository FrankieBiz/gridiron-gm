--!strict
-- Persistent header: team identity, record, year/week, and a coaching-credits pill.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

type Props = {
	team: any,
	record: { wins: number, losses: number },
	season: { year: number, week: number, phase: string, totalWeeks: number },
	credits: number,
}

local function darken(c: Color3, f: number): Color3
	return Color3.new(c.R * f, c.G * f, c.B * f)
end

local function TopBar(props: Props)
	local team = props.team
	local primary = Theme.hex(team.primary)
	local secondary = Theme.hex(team.secondary)

	local phaseLabel
	if props.season.phase == "regular" then
		phaseLabel = string.format("YEAR %d  ·  WEEK %d", props.season.year, props.season.week)
	elseif props.season.phase == "playoffs" then
		phaseLabel = string.format("YEAR %d  ·  PLAYOFFS", props.season.year)
	else
		phaseLabel = string.format("YEAR %d  ·  OFFSEASON", props.season.year)
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 82),
		BackgroundColor3 = primary,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, {
		grad = e("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(primary, darken(primary, 0.72)),
		}),
		accent = e("Frame", {
			BackgroundColor3 = secondary,
			Size = UDim2.new(1, 0, 0, 4),
			Position = UDim2.new(0, 0, 1, -4),
			BorderSizePixel = 0,
		}),
		name = e("TextLabel", {
			Text = string.upper(team.city .. " " .. team.name),
			Font = Theme.font.display,
			TextScaled = true,
			TextColor3 = Theme.chalk,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(18, 14),
			Size = UDim2.new(0.62, 0, 0, 26),
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 26 }) }),
		sub = e("TextLabel", {
			Text = phaseLabel .. "   ·   " .. props.record.wins .. "-" .. props.record.losses,
			Font = Theme.font.bold,
			TextScaled = true,
			TextColor3 = secondary,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(18, 46),
			Size = UDim2.new(0.62, 0, 0, 16),
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 15 }) }),
		creditPill = e("Frame", {
			BackgroundColor3 = darken(primary, 0.6),
			Position = UDim2.new(1, -128, 0.5, -18),
			Size = UDim2.fromOffset(110, 36),
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			stroke = e("UIStroke", { Color = Theme.gold, Transparency = 0.4, Thickness = 1 }),
			label = e("TextLabel", {
				Text = "🪙 " .. props.credits,
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = Theme.gold,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.1, 0.24),
				Size = UDim2.fromScale(0.8, 0.52),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 20 }) }),
		}),
	})
end

return TopBar
