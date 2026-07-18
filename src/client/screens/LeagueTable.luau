--!strict
-- LeagueTable — the League tab: one shared column spec drives the header and every row,
-- gold seeds 1–4 above a dashed PLAYOFF LINE, and a team-tinted, stroke-pulsing my-row
-- (spec: ui-v2-ixd §4.6 IXD-30).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)
local TeamCrest = require(script.Parent.Parent.components.TeamCrest)
local EmptyState = require(script.Parent.Parent.components.EmptyState)

local e = React.createElement

export type Props = {
	teamId: string,
	teams: { Franchise.TeamSummary },
	standings: { Franchise.StandingsRow },
}

-- One shared column spec: x = left offset, xFromRight = right-anchored offset (px).
local COL = {
	rank = { x = 12, w = 24 },
	crest = { x = 40, w = 24 },
	team = { x = 72, wOffset = -(72 + 116 + 4) }, -- flexes between crest and the stat block
	wl = { xFromRight = 116, w = 60 },
	diff = { xFromRight = 52, w = 44 },
}

local ROW_H = 48
local HEADER_ROW_H = 32
local DIVIDER_H = 24
local SEED_CUT = 4

local function diffText(n: number): string
	if n > 0 then
		return string.format("+%d", n)
	end
	return tostring(n)
end

local function headerCell(text: string, position: UDim2, size: UDim2, right: boolean): any
	return e("TextLabel", {
		Text = text,
		Font = Theme.font.bold,
		TextSize = Theme.type.caption.size,
		TextColor3 = Theme.text.secondary,
		TextXAlignment = if right then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = position,
		Size = size,
	})
end

-- Dashed PLAYOFF LINE divider: caption above 9 short chalkSoft dashes.
local function playoffDivider(order: number): any
	local children: { [string]: any } = {
		caption = e("TextLabel", {
			Text = "PLAYOFF LINE",
			Font = Theme.type.eyebrow.font,
			TextSize = Theme.type.eyebrow.size,
			TextColor3 = Theme.gold,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 12),
		}),
	}
	for d = 1, 9 do
		children["dash" .. d] = e("Frame", {
			BackgroundColor3 = Theme.chalkSoft,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Position = UDim2.new(d / 10, -6, 0, 18),
			Size = UDim2.fromOffset(12, 1),
		})
	end
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, DIVIDER_H),
		LayoutOrder = order,
	}, children)
end

local function LeagueTable(props: Props)
	local standings: { Franchise.StandingsRow } = props.standings or {}

	local stagger = motion.useStagger("league", {
		count = math.min(#standings, 14),
		step = 0.03,
		span = 0.24,
	})
	-- Ambient: my-row stroke breathes on a slow shared clock.
	local pulse = motion.usePulse({ period = 2.4 })

	if #standings == 0 then
		return e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			empty = e(EmptyState, {
				icon = "🏁",
				title = "NOTHING ON THE BOARD",
				body = "Standings post after Week 1 kicks off. Go sim the opener.",
			}),
		})
	end

	local byId: { [string]: Franchise.TeamSummary } = {}
	for _, t in props.teams do
		byId[t.id] = t
	end

	local rows: { [string]: any } = {
		_layout = e("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		_pad = e("UIPadding", { PaddingBottom = UDim.new(0, Theme.space.xl) }),
	}

	for i, row in standings do
		local summary = byId[row.teamId]
		local mine = row.teamId == props.teamId
		local seed = i <= SEED_CUT
		local entrance = stagger.item(math.min(i, 14))

		local restBgT = if mine then 0 else 1
		local palette: Theme.TeamPalette? = if mine and summary
			then Theme.withTeam(summary.primary, summary.secondary)
			else nil

		local inner: { [string]: any } = {
			corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
			rank = e("TextLabel", {
				Text = tostring(i),
				Font = Theme.font.mono,
				TextSize = Theme.type.mono.size,
				TextColor3 = if seed then Theme.gold else Theme.text.tertiary,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(COL.rank.x, 0),
				Size = UDim2.new(0, COL.rank.w, 1, 0),
				TextTransparency = entrance:map(function(p: number): number
					return motion.Motion.alpha(p, 0)
				end),
			}),
			team = e("TextLabel", {
				Text = if summary
					then string.format("%s %s", summary.abbr, summary.name)
					else row.teamId,
				Font = if mine then Theme.font.display else Theme.type.bodyBold.font,
				TextSize = Theme.type.body.size,
				TextColor3 = if mine then Theme.flag else Theme.text.primary,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(COL.team.x, 0),
				Size = UDim2.new(1, COL.team.wOffset, 1, 0),
				TextTransparency = entrance:map(function(p: number): number
					return motion.Motion.alpha(p, 0)
				end),
			}),
			wl = e("TextLabel", {
				Text = string.format("%d–%d", row.w, row.l),
				Font = Theme.font.mono,
				TextSize = Theme.type.mono.size,
				TextColor3 = Theme.text.primary,
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -COL.wl.xFromRight, 0, 0),
				Size = UDim2.new(0, COL.wl.w, 1, 0),
				TextTransparency = entrance:map(function(p: number): number
					return motion.Motion.alpha(p, 0)
				end),
			}),
			diff = e("TextLabel", {
				Text = diffText(row.diff),
				Font = Theme.font.mono,
				TextSize = Theme.type.monoSm.size,
				TextColor3 = Theme.deltaColor(row.diff),
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -COL.diff.xFromRight, 0, 0),
				Size = UDim2.new(0, COL.diff.w, 1, 0),
				TextTransparency = entrance:map(function(p: number): number
					return motion.Motion.alpha(p, 0)
				end),
			}),
		}
		if summary then
			inner.crest = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, COL.crest.x, 0.5, -10),
				Size = UDim2.fromOffset(20, 20),
			}, {
				mark = e(TeamCrest, {
					abbr = summary.abbr,
					primary = Theme.hex(summary.primary),
					secondary = Theme.hex(summary.secondary),
					size = 20,
				}),
			})
		end
		if seed then
			inner.rail = e("Frame", {
				BackgroundColor3 = Theme.gold,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(1, 1),
				Size = UDim2.new(0, 3, 1, -2),
			}, { corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.xs) }) })
		end
		if mine and palette then
			inner.stroke = e("UIStroke", {
				Color = palette.accent,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Transparency = pulse:map(function(p: number): number
					return 0.9 - 0.3 * p
				end),
			})
		end

		rows["r_" .. row.teamId] = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, ROW_H),
			LayoutOrder = if i <= SEED_CUT then i else i + 1,
		}, {
			inner = e("Frame", {
				BackgroundColor3 = if palette then palette.tint else Theme.surface.base,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				Position = entrance:map(function(p: number): UDim2
					return UDim2.fromOffset(math.floor(-14 * (1 - p)), 0)
				end),
				BackgroundTransparency = entrance:map(function(p: number): number
					return motion.Motion.alpha(p, restBgT)
				end),
			}, inner),
		})
	end

	if #standings > SEED_CUT then
		rows.divider = playoffDivider(SEED_CUT + 1)
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		_pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, Theme.chrome.padX),
			PaddingRight = UDim.new(0, Theme.chrome.padX),
			PaddingTop = UDim.new(0, Theme.space.md),
		}),
		header = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, HEADER_ROW_H),
		}, {
			rank = headerCell(
				"#",
				UDim2.fromOffset(COL.rank.x, 0),
				UDim2.new(0, COL.rank.w, 1, 0),
				false
			),
			team = headerCell(
				"TEAM",
				UDim2.fromOffset(COL.team.x, 0),
				UDim2.new(1, COL.team.wOffset, 1, 0),
				false
			),
			wl = headerCell(
				"W–L",
				UDim2.new(1, -COL.wl.xFromRight, 0, 0),
				UDim2.new(0, COL.wl.w, 1, 0),
				true
			),
			diff = headerCell(
				"DIFF",
				UDim2.new(1, -COL.diff.xFromRight, 0, 0),
				UDim2.new(0, COL.diff.w, 1, 0),
				true
			),
			underline = e("Frame", {
				BackgroundColor3 = Theme.border.strong,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 1, -1),
				Size = UDim2.new(1, 0, 0, 1),
			}),
		}),
		scroll = e("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, HEADER_ROW_H + Theme.space.xs),
			Size = UDim2.new(1, 0, 1, -HEADER_ROW_H - Theme.space.xs),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.line,
		}, rows),
	})
end

return LeagueTable
