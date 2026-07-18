--!strict
-- History tab (IXD-33): the banner wall — trophy row popping in, coach-authoritative
-- title/season counters, and a season-by-season log newest-first with champion colors
-- resolved from the team summaries. New title while alive -> gold-bloom celebration.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)

local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)
local Overlay = require(script.Parent.Parent.overlay.OverlayProvider)
local AnimatedNumber = require(script.Parent.Parent.components.AnimatedNumber)
local Badge = require(script.Parent.Parent.components.Badge)
local Card = require(script.Parent.Parent.components.Card)
local EmptyState = require(script.Parent.Parent.components.EmptyState)

local e = React.createElement

local Motion = motion.Motion

export type Props = {
	history: { Franchise.HistoryEntry },
	teams: { Franchise.TeamSummary },
	coach: Franchise.Coach,
}

local MAX_TROPHIES = 8

local function recordVariant(entry: Franchise.HistoryEntry): Badge.Variant
	if entry.wins > entry.losses then
		return "success"
	elseif entry.losses > entry.wins then
		return "danger"
	end
	return "neutral"
end

-- §5 per-row entrance: transparent outer (list-owned), animated inner surface.
local function seasonRow(
	entry: Franchise.HistoryEntry,
	order: number,
	b: React.Binding<number>,
	champ: Franchise.TeamSummary?
): any
	local inner: { [string]: any } = {
		corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
		stroke = e("UIStroke", {
			Color = Theme.strokes.edge.color,
			Transparency = b:map(function(p: number): number
				return Motion.alpha(p, Theme.strokes.edge.transparency)
			end),
			Thickness = Theme.strokes.edge.thickness,
		}),
		year = e("TextLabel", {
			Text = tostring(entry.year),
			Font = Theme.font.display,
			TextSize = Theme.type.h2.size,
			TextColor3 = Theme.text.primary,
			TextTransparency = b:map(function(p: number): number
				return Motion.alpha(p)
			end),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.fromOffset(56, 56),
		}),
		badgeWrap = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(76, 16),
			Size = UDim2.fromOffset(70, 24),
		}, {
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			wl = e(Badge, {
				text = string.format("%d–%d", entry.wins, entry.losses),
				variant = recordVariant(entry),
			}),
		}),
	}

	if entry.wonIt then
		inner.rail = e("Frame", {
			BackgroundColor3 = Theme.gold,
			Size = UDim2.new(0, 3, 1, -8),
			Position = UDim2.fromOffset(1, 4),
			BorderSizePixel = 0,
		}, { corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.xs) }) })
		inner.result = e("TextLabel", {
			Text = "🏆 CHAMPIONS",
			Font = Theme.type.bodyBold.font,
			TextSize = Theme.type.bodyBold.size,
			TextColor3 = Theme.gold,
			TextTransparency = b:map(function(p: number): number
				return Motion.alpha(p)
			end),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(150, 0),
			Size = UDim2.new(1, -150 - 14, 1, 0),
		})
	else
		inner.dot = e("Frame", {
			BackgroundColor3 = if champ then Theme.hex(champ.primary) else Theme.chalkSoft,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(1, -14 - 140, 0.5, 0),
			Size = UDim2.fromOffset(8, 8),
			BorderSizePixel = 0,
		}, { corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		inner.result = e("TextLabel", {
			Text = "Champion: " .. (if champ then champ.city .. " " .. champ.name else "Unknown"),
			Font = Theme.type.caption.font,
			TextSize = Theme.type.caption.size,
			TextColor3 = Theme.text.secondary,
			TextTransparency = b:map(function(p: number): number
				return Motion.alpha(p)
			end),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -14 - 128, 0, 0),
			Size = UDim2.fromOffset(128, 56),
		})
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 56),
		LayoutOrder = order,
	}, {
		inner = e("Frame", {
			BackgroundColor3 = Theme.surface.base,
			BackgroundTransparency = b:map(function(p: number): number
				return Motion.alpha(p)
			end),
			Position = b:map(function(p: number): UDim2
				return UDim2.fromOffset(math.floor(-18 * (1 - p)), 0)
			end),
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
		}, inner),
	})
end

local function History(props: Props)
	local overlay = Overlay.useOverlay()
	local coach = props.coach
	local history = props.history

	local byId: { [string]: Franchise.TeamSummary } = {}
	for _, t in props.teams do
		byId[t.id] = t
	end

	local trophies = math.min(coach.championships, MAX_TROPHIES)
	local trophyStagger = motion.useStagger("trophies", {
		count = trophies,
		step = 0.08,
		span = 0.25,
	})
	local rowStagger = motion.useStagger("rows", {
		count = #history,
		step = 0.04,
		span = 0.24,
		delay = 0.2,
	})

	-- New-title celebration: title count held in a ref; increment -> gold bloom.
	local prevTitles = React.useRef(coach.championships)
	React.useEffect(function()
		if coach.championships > (prevTitles.current :: number) then
			overlay.celebrate("goldBloom")
		end
		prevTitles.current = coach.championships
	end, { coach.championships } :: { any })

	-- Trophy row: each 🏆 pops in on its own stagger binding (transparency + Y rise).
	local trophyChildren: { [string]: any } = {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, Theme.space.xs),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for i = 1, trophies do
		local b = trophyStagger.item(i)
		trophyChildren["t" .. i] = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(30, 36),
			LayoutOrder = i,
		}, {
			glyph = e("TextLabel", {
				Text = "🏆",
				Font = Theme.font.body,
				TextSize = 24,
				TextTransparency = b:map(function(p: number): number
					return Motion.alpha(p)
				end),
				Position = b:map(function(p: number): UDim2
					return UDim2.fromOffset(0, math.floor(8 * (1 - p)))
				end),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}),
		})
	end
	if trophies == 0 then
		trophyChildren.none = e("TextLabel", {
			Text = "—",
			Font = Theme.type.body.font,
			TextSize = Theme.type.body.size,
			TextColor3 = Theme.text.tertiary,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(30, 36),
			LayoutOrder = 1,
		})
	end

	local content: { [string]: any } = {
		layout = e("UIListLayout", {
			Padding = UDim.new(0, Theme.space.sm),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		pad = e("UIPadding", {
			PaddingTop = UDim.new(0, Theme.space.md),
			PaddingLeft = UDim.new(0, Theme.chrome.padX),
			PaddingRight = UDim.new(0, Theme.chrome.padX),
			PaddingBottom = UDim.new(0, Theme.space.xl),
		}),
	}

	-- Banner card: trophies + coach-authoritative counters.
	content.banner = e(Card, {
		size = UDim2.new(1, 0, 0, 112),
		layoutOrder = 1,
		children = {
			trophyRow = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 14),
				Size = UDim2.new(1, 0, 0, 36),
			}, trophyChildren),
			counters = e("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 62),
				Size = UDim2.fromOffset(280, 24),
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, Theme.space.sm),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				titles = e(AnimatedNumber, {
					value = coach.championships,
					animateOnMount = true,
					format = function(n: number): string
						return string.format("%d TITLES", math.floor(n + 0.5))
					end,
					textColor3 = Theme.gold,
					textXAlignment = Enum.TextXAlignment.Right,
					size = UDim2.fromOffset(110, 24),
					layoutOrder = 1,
				}),
				dotSep = e("TextLabel", {
					Text = "·",
					Font = Theme.type.body.font,
					TextSize = Theme.type.body.size,
					TextColor3 = Theme.text.tertiary,
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(10, 24),
					LayoutOrder = 2,
				}),
				seasons = e(AnimatedNumber, {
					value = coach.seasonsCoached,
					animateOnMount = true,
					format = function(n: number): string
						return string.format("%d SEASONS", math.floor(n + 0.5))
					end,
					textColor3 = Theme.text.secondary,
					textXAlignment = Enum.TextXAlignment.Left,
					size = UDim2.fromOffset(130, 24),
					layoutOrder = 3,
				}),
			}),
		},
	})

	if #history == 0 then
		content.empty = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 220),
			LayoutOrder = 2,
		}, {
			empty = e(EmptyState, {
				icon = "📜",
				title = "NO BANNERS YET",
				body = "Finish a season to start writing your history.",
			}),
		})
	else
		-- Newest first: iterate the array reversed, LayoutOrder = running counter.
		local order = 1
		for i = #history, 1, -1 do
			local entry = history[i]
			order += 1
			local champ: Franchise.TeamSummary? = if entry.champion ~= nil
				then byId[entry.champion :: string]
				else nil
			content["h_" .. entry.year] = seasonRow(entry, order, rowStagger.item(order - 1), champ)
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

return History
