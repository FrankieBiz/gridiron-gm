--!strict
-- Dashboard — the Season tab: matchup card with this week's opponent, the 52px SIM verb,
-- season progress, a standings snapshot, and the news wire (spec: ui-v2-ixd §4.3 IXD-27).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)
local Theme = require(script.Parent.Parent.Theme)
local Sound = require(script.Parent.Parent.Sound)
local motion = require(script.Parent.Parent.motion)
local Card = require(script.Parent.Parent.components.Card)
local Button = require(script.Parent.Parent.components.Button)
local PhaseBadge = require(script.Parent.Parent.components.PhaseBadge)
local ProgressBar = require(script.Parent.Parent.components.ProgressBar)
local SectionHeader = require(script.Parent.Parent.components.SectionHeader)
local EmptyState = require(script.Parent.Parent.components.EmptyState)
local TeamCrest = require(script.Parent.Parent.components.TeamCrest)

local e = React.createElement

export type Props = {
	teamId: string,
	teams: { Franchise.TeamSummary },
	season: Franchise.SeasonInfo,
	standings: { Franchise.StandingsRow },
	schedule: { Franchise.ScheduleWeek },
	news: { Franchise.NewsItem },
	simming: boolean?,
	onSim: () -> (),
	onOpenLeague: () -> (),
}

local CARD_H = 148
local PROGRESS_H = Theme.size.barH + Theme.space.xs + 16
local HEADER_H = CARD_H + Theme.space.md + PROGRESS_H + Theme.space.md

local function summaryOf(teams: { Franchise.TeamSummary }, id: string?): Franchise.TeamSummary?
	if id == nil then
		return nil
	end
	for _, t in teams do
		if t.id == id then
			return t
		end
	end
	return nil
end

local function standingOf(
	standings: { Franchise.StandingsRow },
	id: string
): (Franchise.StandingsRow?, number)
	for i, row in standings do
		if row.teamId == id then
			return row, i
		end
	end
	return nil, 0
end

local function recordText(standings: { Franchise.StandingsRow }, id: string): string
	local row = standingOf(standings, id)
	if row then
		return string.format("%d–%d", row.w, row.l)
	end
	return "0–0"
end

-- One side of the matchup: crest + abbr + city/record, stacked next to the mark.
local function teamBlock(summary: Franchise.TeamSummary, record: string, position: UDim2): any
	return e("Frame", {
		BackgroundTransparency = 1,
		Position = position,
		Size = UDim2.new(0.5, -28, 1, 0),
	}, {
		crest = e(TeamCrest, {
			abbr = summary.abbr,
			primary = Theme.hex(summary.primary),
			secondary = Theme.hex(summary.secondary),
			size = 40,
		}),
		abbr = e("TextLabel", {
			Text = summary.abbr,
			Font = Theme.type.h2.font,
			TextSize = Theme.type.h2.size,
			TextColor3 = Theme.text.primary,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(48, 2),
			Size = UDim2.new(1, -48, 0, 20),
		}),
		meta = e("TextLabel", {
			Text = string.format("%s · %s", summary.city, record),
			Font = Theme.type.caption.font,
			TextSize = Theme.type.caption.size,
			TextColor3 = Theme.text.secondary,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(48, 24),
			Size = UDim2.new(1, -48, 0, 14),
		}),
	})
end

-- Compact standings-snapshot row: rank, crest, abbr, W–L.
local function miniRow(
	row: Franchise.StandingsRow,
	rank: number,
	summary: Franchise.TeamSummary?,
	mine: boolean,
	order: number
): any
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = order,
	}, {
		rank = e("TextLabel", {
			Text = tostring(rank),
			Font = Theme.font.mono,
			TextSize = Theme.type.monoSm.size,
			TextColor3 = if rank <= 4 then Theme.gold else Theme.text.tertiary,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 20, 1, 0),
		}),
		crest = if summary
			then e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 24, 0.5, -8),
				Size = UDim2.fromOffset(16, 16),
			}, {
				mark = e(TeamCrest, {
					abbr = summary.abbr,
					primary = Theme.hex(summary.primary),
					secondary = Theme.hex(summary.secondary),
					size = 16,
				}),
			})
			else nil,
		abbr = e("TextLabel", {
			Text = if summary then summary.abbr else row.teamId,
			Font = if mine then Theme.type.bodyBold.font else Theme.type.body.font,
			TextSize = Theme.type.body.size,
			TextColor3 = if mine then Theme.flag else Theme.text.primary,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(48, 0),
			Size = UDim2.new(1, -48 - 64, 1, 0),
		}),
		rec = e("TextLabel", {
			Text = string.format("%d–%d", row.w, row.l),
			Font = Theme.font.mono,
			TextSize = Theme.type.monoSm.size,
			TextColor3 = Theme.text.secondary,
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(60, 24),
		}),
	})
end

local function Dashboard(props: Props)
	local season = props.season
	local standings: { Franchise.StandingsRow } = props.standings or {}
	local news: { Franchise.NewsItem } = props.news or {}

	-- Entrance: the matchup card rises 12px while the news wire staggers in.
	local headerIn = motion.useProgress("dashboard", {
		duration = motion.Motion.dur.slow,
		easing = motion.Solver.easeOutQuint,
	})
	local stagger = motion.useStagger("wire", {
		count = math.min(#news, 20),
		step = 0.04,
		span = 0.24,
	})

	-- Phase copy: badge label + the SIM verb.
	local phaseText: string
	local simText: string
	if season.phase == "regular" then
		phaseText = `WEEK {season.week} · NEXT UP`
		simText = `SIM WEEK {season.week} ▸`
	elseif season.phase == "playoffs" then
		local champ = season.week > season.totalWeeks + 1
		phaseText = if champ then "PLAYOFFS · CHAMPIONSHIP" else "PLAYOFFS · SEMIFINALS"
		simText = if champ then "SIM CHAMPIONSHIP ▸" else "SIM SEMIFINAL ▸"
	else
		phaseText = `OFFSEASON · YEAR {season.year}`
		simText = "RUN THE OFFSEASON ▸"
	end

	-- Find my game this week (regular-season schedule only).
	local myGame: Franchise.ScheduledGame? = nil
	local weekGames = props.schedule[season.week]
	if season.phase ~= "offseason" and weekGames then
		for _, g in weekGames do
			if g.home == props.teamId or g.away == props.teamId then
				myGame = g
				break
			end
		end
	end

	local mySummary = summaryOf(props.teams, props.teamId)
	local matchup: { [string]: any } = {}
	local g = myGame
	if g ~= nil and mySummary ~= nil then
		local home = g.home == props.teamId
		local oppSummary = summaryOf(props.teams, if home then g.away else g.home)
		if oppSummary then
			matchup.mine =
				teamBlock(mySummary, recordText(standings, props.teamId), UDim2.fromOffset(0, 0))
			matchup.divider = e("TextLabel", {
				Text = if home then "VS" else "@",
				Font = Theme.font.display,
				TextSize = Theme.type.h2.size,
				TextColor3 = Theme.text.tertiary,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.fromOffset(40, 20),
			})
			matchup.opp = teamBlock(
				oppSummary,
				recordText(standings, oppSummary.id),
				UDim2.new(0.5, 28, 0, 0)
			)
		end
	end
	if matchup.mine == nil then
		-- Offseason / no scheduled opponent: keep the card alive with the club mark.
		matchup.crest = if mySummary
			then e(TeamCrest, {
				abbr = mySummary.abbr,
				primary = Theme.hex(mySummary.primary),
				secondary = Theme.hex(mySummary.secondary),
				size = 40,
			})
			else nil
		matchup.line = e("TextLabel", {
			Text = if season.phase == "offseason"
				then "The season's in the books. Build for next year."
				else "Win or go home.",
			Font = Theme.type.body.font,
			TextSize = Theme.type.body.size,
			TextColor3 = Theme.text.secondary,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(48, 12),
			Size = UDim2.new(1, -48, 0, 18),
		})
	end

	-- Region C content: standings snapshot + the wire.
	local scrollChildren: { [string]: any } = {
		_layout = e("UIListLayout", {
			Padding = UDim.new(0, Theme.space.sm),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		_pad = e("UIPadding", { PaddingBottom = UDim.new(0, Theme.space.xl) }),
	}

	if #standings > 0 then
		local snapshot: { [string]: any } = {
			pad = e("UIPadding", {
				PaddingTop = UDim.new(0, Theme.space.md),
				PaddingBottom = UDim.new(0, Theme.space.xs),
				PaddingLeft = UDim.new(0, Theme.space.md),
				PaddingRight = UDim.new(0, Theme.space.md),
			}),
			layout = e("UIListLayout", {
				Padding = UDim.new(0, Theme.space.xs),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			header = e(SectionHeader, { text = "DIVISION RACE", layoutOrder = 1 }),
		}
		local _, myRank = standingOf(standings, props.teamId)
		for i = 1, math.min(4, #standings) do
			local row = standings[i]
			snapshot["s_" .. row.teamId] = miniRow(
				row,
				i,
				summaryOf(props.teams, row.teamId),
				row.teamId == props.teamId,
				1 + i
			)
		end
		if myRank > 4 then
			local myRow = standings[myRank]
			snapshot["s_" .. myRow.teamId] = miniRow(myRow, myRank, mySummary, true, 6)
		end
		snapshot.fullTable = e(
			"TextButton",
			{
				Text = "FULL TABLE ▸",
				Font = Theme.type.eyebrow.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = Theme.flag,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 44),
				LayoutOrder = 7,
				[React.Event.Activated] = function()
					Sound.play("tick", { volume = 0.18 })
					props.onOpenLeague()
				end,
			} :: { [any]: any }
		)
		scrollChildren.snapshot = e(Card, {
			size = UDim2.new(1, 0, 0, 0),
			automaticSize = Enum.AutomaticSize.Y,
			layoutOrder = 1,
			children = snapshot,
		})
	end

	scrollChildren.wireHeader = e(SectionHeader, { text = "THE WIRE", layoutOrder = 2 })

	if #news == 0 then
		scrollChildren.empty = e(EmptyState, {
			icon = "🗞",
			title = "THE WIRE IS QUIET",
			body = "Sim your first week — headlines land here the moment the whistle blows.",
			layoutOrder = 3,
		})
	else
		for i, item in news do
			local entrance = stagger.item(math.min(i, 20))
			-- Stable-from-tail keys: the server prepends newest, so tail index is identity.
			scrollChildren["n_" .. (#news - i)] = e("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 44),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2 + i,
			}, {
				inner = e("Frame", {
					BackgroundColor3 = Theme.surface.base,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 44),
					AutomaticSize = Enum.AutomaticSize.Y,
					Position = entrance:map(function(p: number): UDim2
						return UDim2.fromOffset(math.floor(-12 * (1 - p)), 0)
					end),
					BackgroundTransparency = entrance:map(function(p: number): number
						return motion.Motion.alpha(p, 0)
					end),
				}, {
					corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
					rail = e("Frame", {
						BackgroundColor3 = Theme.newsColor(item.kind),
						Size = UDim2.new(0, 3, 1, -8),
						Position = UDim2.fromOffset(4, 4),
						BorderSizePixel = 0,
					}, {
						corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.xs) }),
					}),
					label = e("TextLabel", {
						Text = item.text,
						Font = Theme.type.body.font,
						TextSize = Theme.type.body.size,
						TextColor3 = Theme.text.primary,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(16, 0),
						Size = UDim2.new(1, -16 - Theme.space.md, 0, 44),
						AutomaticSize = Enum.AutomaticSize.Y,
						TextTransparency = entrance:map(function(p: number): number
							return motion.Motion.alpha(p, 0)
						end),
					}),
				}),
			})
		end
	end

	local progressValue = if season.phase == "offseason"
		then season.totalWeeks
		else math.clamp(season.week - 1, 0, season.totalWeeks)

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		_pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, Theme.chrome.padX),
			PaddingRight = UDim.new(0, Theme.chrome.padX),
			PaddingTop = UDim.new(0, Theme.space.md),
		}),
		matchupSlot = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, CARD_H),
			Position = headerIn:map(function(p: number): UDim2
				return UDim2.fromOffset(0, math.floor(12 * (1 - p)))
			end),
		}, {
			card = e(Card, {
				variant = "raised" :: Card.Variant,
				size = UDim2.fromScale(1, 1),
				children = {
					tint = e("Frame", {
						BackgroundColor3 = Theme.phaseColor(season.phase),
						BackgroundTransparency = 0.92,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1, 1),
					}, {
						corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.lg) }),
						grad = e("UIGradient", {
							Rotation = 90,
							Transparency = NumberSequence.new(0, 1),
						}),
					}),
					badge = e("Frame", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(Theme.space.md, 10),
						Size = UDim2.new(1, -Theme.space.md * 2, 0, Theme.size.chipH),
					}, {
						bug = e(PhaseBadge, { phase = season.phase :: string, text = phaseText }),
					}),
					blocks = e("Frame", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(Theme.space.md, 42),
						Size = UDim2.new(1, -Theme.space.md * 2, 0, 42),
					}, matchup),
					sim = e("Frame", {
						BackgroundTransparency = 1,
						Position = UDim2.new(0, Theme.space.md, 1, -52 - Theme.space.sm),
						Size = UDim2.new(1, -Theme.space.md * 2, 0, 52),
						ZIndex = 2,
					}, {
						btn = e(Button, {
							text = simText,
							onActivated = props.onSim,
							loading = props.simming,
							pulse = true,
							size = UDim2.fromScale(1, 1),
						}),
					}),
				},
			}),
		}),
		progress = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, CARD_H + Theme.space.md),
			Size = UDim2.new(1, 0, 0, PROGRESS_H),
		}, {
			bar = e(ProgressBar, {
				value = progressValue,
				max = season.totalWeeks,
				color = Theme.phaseColor(season.phase),
			}),
			caption = e("TextLabel", {
				Text = string.format(
					"WEEK %d / %d",
					math.min(season.week, season.totalWeeks),
					season.totalWeeks
				),
				Font = Theme.font.mono,
				TextSize = Theme.type.monoSm.size,
				TextColor3 = Theme.text.secondary,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, Theme.size.barH + Theme.space.xs),
				Size = UDim2.new(0.5, 0, 0, 16),
			}),
			phase = e("TextLabel", {
				Text = string.upper(season.phase),
				Font = Theme.type.eyebrow.font,
				TextSize = Theme.type.eyebrow.size,
				TextColor3 = Theme.text.tertiary,
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 0, Theme.size.barH + Theme.space.xs),
				Size = UDim2.new(0.5, 0, 0, 16),
			}),
		}),
		scroll = e("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, HEADER_H),
			Size = UDim2.new(1, 0, 1, -HEADER_H - Theme.space.md),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.line,
		}, scrollChildren),
	})
end

return Dashboard
