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
	news: { any }?,
	onSim: () -> (),
}

local NEWS_COLOR = {
	title = Color3.fromRGB(233, 182, 62),
	career = Color3.fromRGB(232, 92, 34),
	draft = Color3.fromRGB(74, 168, 120),
	retire = Color3.fromRGB(150, 172, 162),
	credits = Color3.fromRGB(233, 182, 62),
	league = Color3.fromRGB(150, 172, 162),
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

	-- News feed rows (auto-sized wrapped text cards).
	local news = props.news or {}
	local rows: { [string]: any } = {
		layout = e(
			"UIListLayout",
			{ Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }
		),
	}
	if #news == 0 then
		rows.empty = e("TextLabel", {
			Text = "Sim your season — headlines will appear here.",
			Font = Theme.font.body,
			TextColor3 = Theme.chalkSoft,
			TextSize = 14,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = 1,
		})
	end
	for i, item in news do
		rows["n_" .. i] = e("Frame", {
			BackgroundColor3 = Theme.field2,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = i,
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			stripe = e("Frame", {
				BackgroundColor3 = NEWS_COLOR[item.kind] or Theme.chalkSoft,
				Size = UDim2.new(0, 4, 1, 0),
				BorderSizePixel = 0,
			}),
			pad = e("UIPadding", {
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),
			text = e("TextLabel", {
				Text = item.text,
				Font = Theme.font.medium,
				TextColor3 = Theme.chalk,
				TextSize = 14,
				TextWrapped = true,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
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
		newsTitle = e("TextLabel", {
			Text = "📰 LATEST NEWS",
			Font = Theme.font.bold,
			TextScaled = true,
			TextColor3 = Theme.chalkSoft,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(14, 156),
			Size = UDim2.fromOffset(220, 16),
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 14 }) }),
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
