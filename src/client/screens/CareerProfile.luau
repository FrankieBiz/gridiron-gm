--!strict
-- Career tab (IXD-32): dynasty-score hero, four career stat tiles, reputation /
-- job-security status with hot-seat drama, the current job card, and the trophy case.
-- Read-only — App passes data down; this screen never touches a remote.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)

local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)
local AnimatedNumber = require(script.Parent.Parent.components.AnimatedNumber)
local Badge = require(script.Parent.Parent.components.Badge)
local Card = require(script.Parent.Parent.components.Card)
local EmptyState = require(script.Parent.Parent.components.EmptyState)
local ProgressBar = require(script.Parent.Parent.components.ProgressBar)
local SectionHeader = require(script.Parent.Parent.components.SectionHeader)
local StatChip = require(script.Parent.Parent.components.StatChip)
local TeamCrest = require(script.Parent.Parent.components.TeamCrest)

local e = React.createElement

export type Props = {
	coach: Franchise.Coach,
	team: Franchise.LeagueTeam,
	prestige: number,
	expectedWins: number,
	record: Franchise.TeamRecord,
	achievements: { [string]: boolean },
	achievementDefs: { Franchise.AchievementDef },
	dynastyScore: number,
}

local HOT_SEAT_BELOW = 25

local function securityStatus(sec: number): (string, Badge.Variant)
	if sec >= 60 then
		return "SECURE", "success" :: Badge.Variant
	elseif sec >= 30 then
		return "ON NOTICE", "gold" :: Badge.Variant
	end
	return "HOT SEAT", "danger" :: Badge.Variant
end

-- Five prestige glyphs: gold up to `prestige`, dimmed past it.
local function starsRow(prestige: number, x: number, y: number): any
	local children: { [string]: any } = {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for i = 1, 5 do
		children["s" .. i] = e("TextLabel", {
			Text = "★",
			Font = Theme.font.bold,
			TextSize = 13,
			TextColor3 = if i <= prestige then Theme.gold else Theme.text.disabled,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(14, 14),
			LayoutOrder = i,
		})
	end
	return e("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(80, 14),
	}, children)
end

local function achievementRow(def: Franchise.AchievementDef, unlocked: boolean, order: number): any
	return e("Frame", {
		BackgroundColor3 = if unlocked then Theme.surface.base else Theme.field3,
		Size = UDim2.new(1, 0, 0, 52),
		LayoutOrder = order,
		BorderSizePixel = 0,
	}, {
		corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
		stroke = e("UIStroke", {
			Color = Theme.strokes.hairline.color,
			Transparency = Theme.strokes.hairline.transparency,
			Thickness = Theme.strokes.hairline.thickness,
		}),
		glyph = e("TextLabel", {
			Text = if unlocked then "🏅" else "🔒",
			Font = Theme.font.body,
			TextSize = 20,
			TextTransparency = if unlocked then 0 else 0.35,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 14),
			Size = UDim2.fromOffset(24, 24),
		}),
		name = e("TextLabel", {
			Text = def.name,
			Font = Theme.type.bodyBold.font,
			TextSize = Theme.type.bodyBold.size,
			TextColor3 = if unlocked then Theme.text.primary else Theme.text.disabled,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(48, 9),
			Size = UDim2.new(1, -48 - 92, 0, 16),
		}),
		desc = e("TextLabel", {
			Text = def.desc,
			Font = Theme.type.caption.font,
			TextSize = Theme.type.caption.size,
			TextColor3 = if unlocked then Theme.text.secondary else Theme.text.disabled,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(48, 28),
			Size = UDim2.new(1, -48 - 92, 0, 14),
		}),
		pointsWrap = e("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 14),
			Size = UDim2.fromOffset(80, 24),
		}, {
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			pts = e(Badge, {
				text = tostring(def.points) .. " PTS",
				variant = if unlocked then "gold" :: Badge.Variant else "neutral" :: Badge.Variant,
			}),
		}),
	})
end

local function CareerProfile(props: Props)
	local coach = props.coach

	local total = #props.achievementDefs
	local unlockedCount = 0
	for _, def in props.achievementDefs do
		if props.achievements[def.id] then
			unlockedCount += 1
		end
	end

	-- Bars spring-fill on mount: values flip 0 -> real after first paint, the security
	-- bar 0.12s behind the reputation bar (ProgressBar's internal spring does the rest).
	local barsIn, setBarsIn = React.useState(0)
	React.useEffect(function()
		local alive = true
		setBarsIn(1)
		task.delay(0.12, function()
			if alive then
				setBarsIn(2)
			end
		end)
		return function()
			alive = false
		end
	end, {})

	local hotSeat = coach.jobSecurity < HOT_SEAT_BELOW
	local pulse = motion.usePulse({ period = 1.6, enabled = hotSeat })
	local secText, secVariant = securityStatus(coach.jobSecurity)
	local palette = Theme.withTeam(props.team.primary, props.team.secondary)

	local content: { [string]: any } = {
		layout = e("UIListLayout", {
			Padding = UDim.new(0, Theme.space.md),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		pad = e("UIPadding", {
			PaddingTop = UDim.new(0, Theme.space.md),
			PaddingLeft = UDim.new(0, Theme.chrome.padX),
			PaddingRight = UDim.new(0, Theme.chrome.padX),
			PaddingBottom = UDim.new(0, Theme.space.xl),
		}),
	}

	-- ① Dynasty-score hero.
	content.hero = e(Card, {
		size = UDim2.new(1, 0, 0, 96),
		layoutOrder = 1,
		children = {
			pad = e("UIPadding", {
				PaddingTop = UDim.new(0, Theme.space.lg),
				PaddingLeft = UDim.new(0, Theme.space.lg),
				PaddingRight = UDim.new(0, Theme.space.lg),
			}),
			eyebrow = e("TextLabel", {
				Text = "DYNASTY SCORE",
				Font = Theme.type.eyebrow.font,
				TextSize = Theme.type.eyebrow.size,
				TextColor3 = Theme.text.tertiary,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(0.6, 0, 0, 12),
			}),
			score = e(AnimatedNumber, {
				value = props.dynastyScore,
				animateOnMount = true,
				textColor3 = Theme.gold,
				textSize = Theme.type.display.size,
				textXAlignment = Enum.TextXAlignment.Left,
				size = UDim2.new(0.6, 0, 0, 36),
				position = UDim2.fromOffset(0, 22),
			}),
			medals = e("TextLabel", {
				Text = string.format("🏅 %d / %d", unlockedCount, total),
				Font = Theme.type.caption.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = Theme.text.secondary,
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				Position = UDim2.new(0.6, 0, 0, 0),
				Size = UDim2.new(0.4, 0, 0, 14),
			}),
		},
	})

	-- ② Career stat tiles.
	content.stats = e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 60),
		LayoutOrder = 2,
	}, {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, Theme.space.sm),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		wins = e(StatChip, {
			label = "WINS",
			value = coach.careerWins,
			animate = true,
			size = UDim2.new(0.25, -6, 1, 0),
			layoutOrder = 1,
		}),
		losses = e(StatChip, {
			label = "LOSSES",
			value = coach.careerLosses,
			animate = true,
			size = UDim2.new(0.25, -6, 1, 0),
			layoutOrder = 2,
		}),
		titles = e(StatChip, {
			label = "TITLES",
			value = coach.championships,
			accent = Theme.gold,
			animate = true,
			size = UDim2.new(0.25, -6, 1, 0),
			layoutOrder = 3,
		}),
		seasons = e(StatChip, {
			label = "SEASONS",
			value = coach.seasonsCoached,
			animate = true,
			size = UDim2.new(0.25, -6, 1, 0),
			layoutOrder = 4,
		}),
	})

	-- ③ Status card: reputation + job security.
	content.status = e(Card, {
		size = UDim2.new(1, 0, 0, 136),
		layoutOrder = 3,
		children = {
			pad = e("UIPadding", {
				PaddingTop = UDim.new(0, Theme.space.lg),
				PaddingLeft = UDim.new(0, Theme.space.lg),
				PaddingRight = UDim.new(0, Theme.space.lg),
			}),
			repLabel = e("TextLabel", {
				Text = "REPUTATION",
				Font = Theme.type.eyebrow.font,
				TextSize = Theme.type.eyebrow.size,
				TextColor3 = Theme.text.tertiary,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(0.5, 0, 0, 16),
			}),
			repValue = e("TextLabel", {
				Text = tostring(coach.reputation),
				Font = Theme.font.mono,
				TextSize = Theme.type.mono.size,
				TextColor3 = Theme.gold,
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.new(0.5, 0, 0, 16),
			}),
			repBar = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 24),
				Size = UDim2.new(1, 0, 0, Theme.size.barH),
			}, {
				bar = e(ProgressBar, {
					value = if barsIn >= 1 then coach.reputation else 0,
					max = 100,
					color = Theme.gold,
				}),
			}),
			secLabel = e("TextLabel", {
				Text = "JOB SECURITY",
				Font = Theme.type.eyebrow.font,
				TextSize = Theme.type.eyebrow.size,
				TextColor3 = Theme.text.tertiary,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 56),
				Size = UDim2.fromOffset(100, 24),
			}),
			secBadgeWrap = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(104, 56),
				Size = UDim2.fromOffset(130, 24),
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				badge = e(Badge, { text = secText, variant = secVariant :: Badge.Variant }),
			}),
			secValue = e("TextLabel", {
				Text = tostring(coach.jobSecurity),
				Font = Theme.font.mono,
				TextSize = Theme.type.mono.size,
				TextColor3 = Theme.securityColor(coach.jobSecurity),
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				Position = UDim2.new(0.7, 0, 0, 60),
				Size = UDim2.new(0.3, 0, 0, 16),
			}),
			secBar = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 92),
				Size = UDim2.new(1, 0, 0, Theme.size.barH),
			}, {
				-- HOT SEAT drama: a danger stroke breathing on the shared pulse clock.
				pulseStroke = if hotSeat
					then e("UIStroke", {
						Color = Theme.semantic.danger,
						Thickness = 2,
						Transparency = pulse:map(function(p: number): number
							return 0.8 - 0.5 * p
						end),
					})
					else nil,
				bar = e(ProgressBar, {
					value = if barsIn >= 2 then coach.jobSecurity else 0,
					max = 100,
					color = Theme.securityColor(coach.jobSecurity),
				}),
			}),
		},
	})

	-- ④ Current job card.
	content.job = e(Card, {
		size = UDim2.new(1, 0, 0, 88),
		layoutOrder = 4,
		children = {
			pad = e("UIPadding", {
				PaddingTop = UDim.new(0, Theme.space.md),
				PaddingLeft = UDim.new(0, Theme.space.lg),
				PaddingRight = UDim.new(0, Theme.space.lg),
			}),
			crestWrap = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 14),
				Size = UDim2.fromOffset(32, 32),
			}, {
				crest = e(TeamCrest, {
					abbr = props.team.abbr,
					primary = palette.primary,
					secondary = palette.secondary,
					size = 32,
				}),
			}),
			name = e("TextLabel", {
				Text = props.team.city .. " " .. props.team.name,
				Font = Theme.type.h2.font,
				TextSize = Theme.type.h2.size,
				TextColor3 = Theme.text.primary,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(44, 6),
				Size = UDim2.new(1, -44, 0, 20),
			}),
			stars = starsRow(props.prestige, 44, 30),
			expectation = e("TextLabel", {
				Text = string.format(
					"Owner wants %d+ wins · You're at %d–%d",
					props.expectedWins,
					props.record.wins,
					props.record.losses
				),
				Font = Theme.type.caption.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = Theme.text.secondary,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(44, 50),
				Size = UDim2.new(1, -44, 0, 14),
			}),
		},
	})

	-- ⑤ Trophy case: unlocked first, then locked (two-pass build, running LayoutOrder).
	content.caseHeader = e(SectionHeader, {
		text = "TROPHY CASE",
		right = string.format("%d / %d", unlockedCount, total),
		layoutOrder = 5,
	})

	if total == 0 then
		content.caseEmpty = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 130),
			LayoutOrder = 6,
		}, {
			empty = e(EmptyState, {
				title = "THE CASE IS EMPTY",
				body = "Win one game and the hardware starts arriving.",
				compact = true,
			}),
		})
	else
		local order = 6
		for _, def in props.achievementDefs do
			if props.achievements[def.id] then
				order += 1
				content["a_" .. def.id] = achievementRow(def, true, order)
			end
		end
		for _, def in props.achievementDefs do
			if not props.achievements[def.id] then
				order += 1
				content["a_" .. def.id] = achievementRow(def, false, order)
			end
		end
	end

	return e("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.line,
	}, content)
end

return CareerProfile
