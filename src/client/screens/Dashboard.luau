--!strict
-- The season hub: your next game, the big SIM button, and a live standings snapshot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Parent.components.Button)

local e = React.createElement

type Props = {
	teamId: string,
	teams: { any },
	season: { year: number, week: number, phase: string, totalWeeks: number },
	standings: { any },
	schedule: any,
	onSim: () -> (),
}

local function lookup(teams: { any }): { [string]: any }
	local byId = {}
	for _, t in teams do
		byId[t.id] = t
	end
	return byId
end

local function Dashboard(props: Props)
	local byId = lookup(props.teams)

	-- Figure out the next matchup / phase headline + button label.
	local headline, subline, buttonText
	if props.season.phase == "regular" then
		local opp, home = nil, true
		local wk = props.schedule and props.schedule[props.season.week]
		if wk then
			for _, g in wk do
				if g.home == props.teamId then
					opp, home = g.away, true
					break
				elseif g.away == props.teamId then
					opp, home = g.home, false
					break
				end
			end
		end
		local oppTeam = opp and byId[opp]
		headline = oppTeam
				and ((if home then "vs " else "@ ") .. oppTeam.city .. " " .. oppTeam.name)
			or "Next game"
		subline = string.format("Week %d of %d", props.season.week, props.season.totalWeeks)
		buttonText = "▶  SIM WEEK"
	elseif props.season.phase == "playoffs" then
		headline = "PLAYOFFS"
		subline = "Win three games to take the title"
		buttonText = "▶  SIM PLAYOFF GAME"
	else
		headline = "SEASON COMPLETE"
		subline = "Age, retire, and draft — then kick off next year"
		buttonText = "▶  START NEXT SEASON"
	end

	-- Standings rows.
	local rows: { [string]: any } = {
		layout = e(
			"UIListLayout",
			{ Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }
		),
	}
	for i, row in props.standings do
		local t = byId[row.teamId]
		local mine = row.teamId == props.teamId
		rows["s_" .. row.teamId] = e("Frame", {
			BackgroundColor3 = if mine then Theme.field2 else Theme.field3,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = i,
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
			rank = e("TextLabel", {
				Text = tostring(i),
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(8, 6),
				Size = UDim2.fromOffset(22, 18),
			}),
			name = e("TextLabel", {
				Text = t and (t.abbr .. "  " .. t.name) or row.teamId,
				Font = if mine then Enum.Font.GothamBlack else Enum.Font.Gotham,
				TextScaled = true,
				TextColor3 = if mine then Theme.flag else Theme.chalk,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(36, 6),
				Size = UDim2.new(1, -140, 0, 18),
			}),
			rec = e("TextLabel", {
				Text = string.format("%d-%d  (%+d)", row.w, row.l, row.diff),
				Font = Enum.Font.GothamMedium,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -108, 0, 6),
				Size = UDim2.fromOffset(100, 18),
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		card = e("Frame", {
			BackgroundColor3 = Theme.field2,
			Size = UDim2.new(1, -24, 0, 132),
			Position = UDim2.fromOffset(12, 12),
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
			eyebrow = e("TextLabel", {
				Text = "NEXT UP",
				Font = Enum.Font.GothamBold,
				TextColor3 = Theme.flag,
				TextScaled = true,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(16, 12),
				Size = UDim2.fromOffset(120, 14),
			}),
			headline = e("TextLabel", {
				Text = headline,
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextColor3 = Theme.chalk,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(16, 30),
				Size = UDim2.new(1, -32, 0, 40),
			}),
			subline = e("TextLabel", {
				Text = subline,
				Font = Enum.Font.GothamMedium,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(16, 74),
				Size = UDim2.new(1, -32, 0, 18),
			}),
			sim = e("Frame", {
				Size = UDim2.new(1, -32, 0, 34),
				Position = UDim2.fromOffset(16, 92),
				BackgroundTransparency = 1,
			}, {
				btn = e(Button, {
					text = buttonText,
					onActivated = props.onSim,
					size = UDim2.fromScale(1, 1),
				}),
			}),
		}),
		standingsTitle = e("TextLabel", {
			Text = "LEAGUE STANDINGS",
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = Theme.chalkSoft,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(14, 156),
			Size = UDim2.fromOffset(220, 16),
		}),
		list = e("ScrollingFrame", {
			Size = UDim2.new(1, -24, 1, -186),
			Position = UDim2.fromOffset(12, 178),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, rows),
	})
end

return Dashboard
