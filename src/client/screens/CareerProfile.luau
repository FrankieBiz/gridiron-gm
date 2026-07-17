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
	achievements: { [string]: boolean }?,
	achievementDefs: { any }?,
	dynastyScore: number?,
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

	-- Achievements grid: one row per achievement, unlocked ones lit gold.
	local owned = props.achievements or {}
	local defs = props.achievementDefs or {}
	local unlockedCount = 0
	for _, d in defs do
		if owned[d.id] then
			unlockedCount += 1
		end
	end
	local achRows: { [string]: any } = {
		layout = e(
			"UIListLayout",
			{ Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
		),
	}
	for i, d in defs do
		local got = owned[d.id] == true
		achRows["a_" .. d.id] = e("Frame", {
			BackgroundColor3 = if got then Theme.field2 else Theme.field3,
			Size = UDim2.new(1, 0, 0, 44),
			LayoutOrder = if got then i else 100 + i,
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			icon = e("TextLabel", {
				Text = if got then "🏅" else "🔒",
				TextScaled = true,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 10),
				Size = UDim2.fromOffset(24, 24),
			}),
			name = e("TextLabel", {
				Text = d.name,
				Font = Theme.font.bold,
				TextScaled = true,
				TextColor3 = if got then Theme.gold else Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(44, 7),
				Size = UDim2.new(1, -110, 0, 16),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 15 }) }),
			desc = e("TextLabel", {
				Text = d.desc,
				Font = Theme.font.body,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(44, 24),
				Size = UDim2.new(1, -110, 0, 13),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 12 }) }),
			pts = e("TextLabel", {
				Text = "+" .. d.points,
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = if got then Theme.gold else Theme.line,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -54, 0, 12),
				Size = UDim2.fromOffset(44, 20),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 16 }) }),
		})
	end

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

		dynasty = e(Card, {
			size = UDim2.new(1, 0, 0, 72),
			layoutOrder = 1,
			children = {
				label = e("TextLabel", {
					Text = "DYNASTY SCORE",
					Font = Theme.font.bold,
					TextScaled = true,
					TextColor3 = Theme.chalkSoft,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.fromOffset(16, 12),
					Size = UDim2.fromOffset(180, 14),
				}, { max = e("UITextSizeConstraint", { MaxTextSize = 13 }) }),
				value = e("TextLabel", {
					Text = tostring(props.dynastyScore or 0),
					Font = Theme.font.display,
					TextScaled = true,
					TextColor3 = Theme.gold,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.fromOffset(16, 28),
					Size = UDim2.fromOffset(160, 34),
				}, { max = e("UITextSizeConstraint", { MaxTextSize = 32 }) }),
				ach = e("TextLabel", {
					Text = string.format("🏅 %d / %d", unlockedCount, #defs),
					Font = Theme.font.bold,
					TextScaled = true,
					TextColor3 = Theme.chalk,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Right,
					Position = UDim2.new(1, -110, 0, 26),
					Size = UDim2.fromOffset(96, 24),
				}, { max = e("UITextSizeConstraint", { MaxTextSize = 20 }) }),
			},
		}),

		status = e(Card, {
			size = UDim2.new(1, 0, 0, 128),
			layoutOrder = 2,
			children = {
				rep = bar(rep, Theme.gold, 12, "REPUTATION  " .. math.floor(rep)),
				sec = bar(sec, secColor, 62, "JOB SECURITY  ·  " .. seatLabel),
			},
		}),

		record = e(Card, {
			size = UDim2.new(1, 0, 0, 118),
			layoutOrder = 3,
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
			layoutOrder = 4,
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

		achTitle = e("TextLabel", {
			Text = "🏅 ACHIEVEMENTS",
			Font = Theme.font.bold,
			TextScaled = true,
			TextColor3 = Theme.chalkSoft,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = 5,
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 15 }) }),
		achievements = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 6,
		}, achRows),
	})
end

return CareerProfile
