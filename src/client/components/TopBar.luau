--!strict
-- Persistent header: team identity, record, year/week, coaching credits.

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

local function TopBar(props: Props)
	local team = props.team
	local phaseLabel
	if props.season.phase == "regular" then
		phaseLabel = string.format("Y%d · Week %d", props.season.year, props.season.week)
	elseif props.season.phase == "playoffs" then
		phaseLabel = string.format("Y%d · Playoffs", props.season.year)
	else
		phaseLabel = string.format("Y%d · Offseason", props.season.year)
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 74),
		BackgroundColor3 = Theme.hex(team.primary),
		BorderSizePixel = 0,
	}, {
		accent = e("Frame", {
			BackgroundColor3 = Theme.hex(team.secondary),
			Size = UDim2.new(1, 0, 0, 4),
			Position = UDim2.new(0, 0, 1, -4),
			BorderSizePixel = 0,
		}),
		name = e("TextLabel", {
			Text = string.upper(team.city) .. " " .. team.name,
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			TextColor3 = Theme.chalk,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.04, 0.14),
			Size = UDim2.fromScale(0.62, 0.4),
		}),
		sub = e("TextLabel", {
			Text = string.format(
				"%s   ·   %d-%d",
				phaseLabel,
				props.record.wins,
				props.record.losses
			),
			Font = Enum.Font.GothamMedium,
			TextScaled = true,
			TextColor3 = Theme.hex(team.secondary),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.04, 0.58),
			Size = UDim2.fromScale(0.62, 0.28),
		}),
		credits = e("TextLabel", {
			Text = "🪙 " .. props.credits,
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			TextColor3 = Theme.gold,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.fromScale(0.66, 0.28),
			Size = UDim2.fromScale(0.3, 0.44),
		}),
	})
end

return TopBar
