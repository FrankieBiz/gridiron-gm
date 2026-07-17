--!strict
-- Your coaching career: reputation, job security, lifetime record, titles, and this
-- season's owner expectation. The persistent long-term progression track.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Card = require(script.Parent.Parent.components.Card)

local e = React.createElement

type Props = {
	coach: any,
	team: any,
	prestige: number,
	expectedWins: number,
	record: { wins: number, losses: number },
}

local function stars(n: number): string
	return string.rep("★", n) .. string.rep("☆", 5 - n)
end

local function bar(value: number, color: Color3, y: number, label: string): any
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -28, 0, 40),
		Position = UDim2.fromOffset(14, y),
	}, {
		label = e("TextLabel", {
			Text = label,
			Font = Theme.font.bold,
			TextScaled = true,
			TextColor3 = Theme.chalkSoft,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 14),
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 13 }) }),
		track = e("Frame", {
			BackgroundColor3 = Theme.field3,
			Position = UDim2.fromOffset(0, 18),
			Size = UDim2.new(1, 0, 0, 14),
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			fill = e("Frame", {
				BackgroundColor3 = color,
				Size = UDim2.fromScale(math.clamp(value / 100, 0, 1), 1),
				BorderSizePixel = 0,
			}, { corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
		}),
	})
end

local function CareerProfile(props: Props)
	local c = props.coach or {}
	local rep = c.reputation or 40
	local sec = c.jobSecurity or 55
	local secColor = if sec >= 55 then Theme.green elseif sec >= 25 then Theme.gold else Theme.flag
	local seatLabel = if sec >= 55 then "SECURE" elseif sec >= 25 then "ON NOTICE" else "HOT SEAT"

	return e("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, {
		pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 12),
		}),
		layout = e(
			"UIListLayout",
			{ Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }
		),

		status = e(Card, {
			size = UDim2.new(1, 0, 0, 128),
			layoutOrder = 1,
			children = {
				rep = bar(rep, Theme.gold, 12, "REPUTATION  " .. math.floor(rep)),
				sec = bar(sec, secColor, 62, "JOB SECURITY  ·  " .. seatLabel),
			},
		}),

		record = e(Card, {
			size = UDim2.new(1, 0, 0, 118),
			layoutOrder = 2,
			children = {
				title = e("TextLabel", {
					Text = "CAREER",
					Font = Theme.font.display,
					TextScaled = true,
					TextColor3 = Theme.chalk,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.fromOffset(14, 12),
					Size = UDim2.fromOffset(160, 20),
				}, { max = e("UITextSizeConstraint", { MaxTextSize = 18 }) }),
				stats = e("TextLabel", {
					Text = string.format(
						"Record  %d-%d\n🏆 Championships  %d\nSeasons coached  %d\nTeams coached  %d",
						c.careerWins or 0,
						c.careerLosses or 0,
						c.championships or 0,
						c.seasonsCoached or 0,
						c.teamsCoached and #c.teamsCoached or 1
					),
					Font = Theme.font.medium,
					TextColor3 = Theme.chalkSoft,
					TextScaled = false,
					TextSize = 15,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					Position = UDim2.fromOffset(14, 40),
					Size = UDim2.new(1, -28, 0, 70),
				}),
			},
		}),

		job = e(Card, {
			size = UDim2.new(1, 0, 0, 96),
			layoutOrder = 3,
			children = {
				title = e("TextLabel", {
					Text = "CURRENT JOB",
					Font = Theme.font.display,
					TextScaled = true,
					TextColor3 = Theme.chalk,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.fromOffset(14, 12),
					Size = UDim2.fromOffset(180, 20),
				}, { max = e("UITextSizeConstraint", { MaxTextSize = 18 }) }),
				info = e("TextLabel", {
					Text = string.format(
						"%s %s   %s\nOwner wants %d+ wins this year  ·  you're %d-%d",
						props.team.city,
						props.team.name,
						stars(props.prestige),
						props.expectedWins,
						props.record.wins,
						props.record.losses
					),
					Font = Theme.font.medium,
					TextColor3 = Theme.chalkSoft,
					TextScaled = false,
					TextSize = 14,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					Position = UDim2.fromOffset(14, 40),
					Size = UDim2.new(1, -28, 0, 44),
				}),
			},
		}),
	})
end

return CareerProfile
