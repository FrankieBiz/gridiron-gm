--!strict
-- The flagship cinematic: matchup intro cover, beat-walked play-by-play with a rolling
-- ticker, asymmetric VICTORY/DEFEAT verdict, then the box-score reveal. The director is
-- a cancelable task.spawn beat-walk (generation counter); setState happens at beat
-- cadence only — per-frame work stays in bindings (spec: ui-v2-motion §8, IXD-28).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)
local Theme = require(script.Parent.Parent.Theme)
local Sound = require(script.Parent.Parent.Sound)
local SafeArea = require(script.Parent.Parent.SafeArea)
local motion = require(script.Parent.Parent.motion)
local Button = require(script.Parent.Parent.components.Button)
local ScoreBug = require(script.Parent.Parent.components.ScoreBug)
local Confetti = require(script.Parent.Parent.components.Confetti)
local AnimatedNumber = require(script.Parent.Parent.components.AnimatedNumber)
local TeamCrest = require(script.Parent.Parent.components.TeamCrest)

local e = React.createElement

type Props = {
	game: Franchise.SimGameResponse,
	teamId: string?,
	teams: { Franchise.TeamSummary },
	onDone: () -> (),
}

type Phase = "intro" | "plays" | "verdict" | "stats"
type Outcome = "win" | "loss" | "spectator"

type SideInfo = { abbr: string, name: string, primary: Color3, secondary: Color3 }

local CADENCE = {
	normal = 0.42, -- per routine play
	fastNormal = 0.34, -- used when #plays > 26
	bigPre = 0.50, -- held breath BEFORE a big play reveals
	bigHold = 1.0, -- dwell after a big play
	scoreHold = 0.9, -- dwell after any score change
	quarterBreak = 0.6, -- interstitial when the quarter increments
	finalPre = 0.8, -- held breath before the last play
	doneHold = 0.7, -- silence between the final play and the verdict
}

local BUG_H = 100
local BANNER_H = 72
local STATS_H = 168
local BOTTOM_H = 64

local function resolveSide(
	teams: { Franchise.TeamSummary },
	id: string,
	fallbackName: string
): SideInfo
	for _, t in teams do
		if t.id == id then
			return {
				abbr = t.abbr,
				name = t.name,
				primary = Theme.hex(t.primary),
				secondary = Theme.hex(t.secondary),
			}
		end
	end
	return {
		abbr = string.upper(string.sub(fallbackName, 1, 3)),
		name = fallbackName,
		primary = Theme.field2,
		secondary = Theme.chalk,
	}
end

-- ---- Phase A: the matchup cover (this screen's ONE CanvasGroup; unmounts at complete) ----

type CoverProps = {
	away: SideInfo,
	home: SideInfo,
	label: string,
	onComplete: () -> (),
}

local function coverBlock(side: SideInfo, clock: React.Binding<number>, fromLeft: boolean): any
	local start = if fromLeft then 0.05 else 0.20
	local y = if fromLeft then 0.26 else 0.56
	return e("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = clock:map(function(t: number): UDim2
			local p = motion.Motion.window(t, start, 0.45, motion.Solver.easeOutQuint)
			local from = if fromLeft then -0.4 else 1.4
			return UDim2.new(motion.Solver.lerp(from, 0.5, p), 0, y, 0)
		end),
		Size = UDim2.fromOffset(260, 96),
	}, {
		_crest = e("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromOffset(56, 56),
		}, {
			crest = e(TeamCrest, {
				abbr = side.abbr,
				primary = side.primary,
				secondary = side.secondary,
				size = 56,
			}),
		}),
		_name = e("TextLabel", {
			Text = string.upper(side.name),
			Font = Theme.font.display,
			TextSize = 24,
			TextColor3 = Theme.chalk,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextTransparency = clock:map(function(t: number): number
				return motion.Motion.alpha(motion.Motion.window(t, start, 0.2))
			end),
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 64),
			Size = UDim2.new(1, 0, 0, 28),
		}),
	})
end

local function MatchupCover(props: CoverProps)
	local clock = motion.useChoreo(nil, 1.75, props.onComplete)
	local championship = string.lower(props.label) == "championship"

	-- Beat-synced sounds (skipped under reduced motion — the choreo finishes instantly).
	React.useEffect(function()
		if motion.Motion.reducedMotion() then
			return
		end
		local live = { true }
		task.delay(0.05, function()
			if live[1] then
				Sound.play("swoosh")
			end
		end)
		task.delay(0.20, function()
			if live[1] then
				Sound.play("swoosh", { speed = 0.94 })
			end
		end)
		task.delay(0.42, function()
			if live[1] then
				Sound.play("pop")
			end
		end)
		task.delay(0.90, function()
			if live[1] then
				Sound.play("drumroll", { volume = 0.3 })
			end
		end)
		return function()
			live[1] = false
		end
	end, {})

	return e("CanvasGroup", {
		BackgroundColor3 = Theme.field3,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 8,
		GroupTransparency = clock:map(function(t: number): number
			return motion.Motion.window(t, 1.4, 0.3, motion.Solver.easeInOutCubic)
		end),
	}, {
		_grad = e("UIGradient", { Rotation = 90, Color = Theme.grad.hero }),
		_away = coverBlock(props.away, clock, true),
		_home = coverBlock(props.home, clock, false),
		_chip = e("Frame", {
			BackgroundColor3 = Theme.surface.raised,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42),
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 32),
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			stroke = e("UIStroke", {
				Color = if championship then Theme.gold else Theme.stroke,
				Transparency = if championship then 0.2 else 0.8,
				Thickness = if championship then 1.5 else 1,
			}),
			pad = e("UIPadding", {
				PaddingLeft = UDim.new(0, Theme.space.lg),
				PaddingRight = UDim.new(0, Theme.space.lg),
			}),
			scale = e("UIScale", {
				Scale = clock:map(function(t: number): number
					return motion.Motion.window(t, 0.42, 0.3, motion.Solver.easeOutBack)
				end),
			}),
			label = e("TextLabel", {
				Text = string.upper(props.label),
				Font = Theme.font.display,
				TextSize = Theme.type.h2.size,
				TextColor3 = if championship then Theme.gold else Theme.chalk,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromScale(0, 1),
			}),
		}),
		_kickoff = e("TextLabel", {
			Text = "K I C K O F F",
			Font = Theme.type.eyebrow.font,
			TextSize = Theme.type.eyebrow.size,
			TextColor3 = Theme.text.secondary,
			TextTransparency = clock:map(function(t: number): number
				return motion.Motion.alpha(motion.Motion.window(t, 0.9, 0.2))
			end),
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.76),
			Size = UDim2.fromOffset(200, 16),
		}),
	})
end

-- ---- Phase B: ticker rows (each enters with its own tiny fade+rise; no CanvasGroup) ----

type TickerRowProps = {
	play: Franchise.PlayEvent,
	layoutOrder: number,
}

local function TickerRow(props: TickerRowProps)
	local play = props.play
	local entrance = motion.useProgress(nil, { duration = 0.22 })
	local big = play.big
	local height = if big then 52 else 44

	local fade = entrance:map(function(p: number): number
		return motion.Motion.alpha(p)
	end)

	local inner: { [string]: any } = {
		_text = e("TextLabel", {
			Text = string.format("Q%d %s  %s", play.quarter, play.clock, play.text),
			Font = if big then Theme.font.bold else Theme.type.body.font,
			TextSize = if big then 15 else Theme.type.body.size,
			TextColor3 = if big then Theme.flag else Theme.text.secondary,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = fade,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(if big then 12 else 4, 0),
			Size = UDim2.new(1, if big then -16 else -8, 1, 0),
		}),
	}
	if big then
		inner._rail = e("Frame", {
			BackgroundColor3 = Theme.flag,
			BackgroundTransparency = fade,
			Size = UDim2.new(0, 3, 1, -12),
			Position = UDim2.fromOffset(0, 6),
			BorderSizePixel = 0,
		})
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = props.layoutOrder,
	}, {
		inner = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = entrance:map(function(p: number): UDim2
				return UDim2.fromOffset(0, math.floor(-8 * (1 - p)))
			end),
		}, inner),
	})
end

-- ---- Phase D: one comparison stat row ----

type StatRowProps = {
	label: string,
	left: number,
	right: number,
	entrance: React.Binding<number>,
	layoutOrder: number,
}

local function StatRow(props: StatRowProps)
	local bar, barApi = motion.useMotor(0.5)

	React.useEffect(function()
		local total = props.left + props.right
		local share = if total > 0 then props.left / total else 0.5
		barApi.setTarget(share, motion.Motion.spring.slide)
	end, {})

	local fade = props.entrance:map(function(p: number): number
		return motion.Motion.alpha(p)
	end)

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		LayoutOrder = props.layoutOrder,
	}, {
		inner = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = props.entrance:map(function(p: number): UDim2
				return UDim2.fromOffset(0, math.floor(motion.Motion.dist.drop * (1 - p)))
			end),
		}, {
			_left = e(AnimatedNumber, {
				value = props.left,
				animateOnMount = true,
				textSize = 20,
				textXAlignment = Enum.TextXAlignment.Left,
				size = UDim2.fromOffset(64, 24),
				position = UDim2.fromOffset(0, 10),
			}),
			_right = e(AnimatedNumber, {
				value = props.right,
				animateOnMount = true,
				textSize = 20,
				size = UDim2.fromOffset(64, 24),
				position = UDim2.new(1, -64, 0, 10),
			}),
			_label = e("TextLabel", {
				Text = props.label,
				Font = Theme.type.eyebrow.font,
				TextSize = Theme.type.eyebrow.size,
				TextColor3 = Theme.text.tertiary,
				TextTransparency = fade,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 72, 0, 4),
				Size = UDim2.new(1, -144, 0, 12),
			}),
			_track = e("Frame", {
				BackgroundColor3 = Theme.surface.sunken,
				BackgroundTransparency = fade,
				Position = UDim2.new(0, 72, 0, 22),
				Size = UDim2.new(1, -144, 0, 6),
				BorderSizePixel = 0,
			}, {
				corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				fill = e("Frame", {
					BackgroundColor3 = Theme.flag,
					BackgroundTransparency = fade,
					BorderSizePixel = 0,
					Size = bar:map(function(s: number): UDim2
						return UDim2.new(math.clamp(s, 0, 1), 0, 1, 0)
					end),
				}, { corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
			}),
		}),
	})
end

-- ---- the screen ----

local function GameResult(props: Props)
	local game = props.game
	local result = game.result
	local plays = result.plays
	local insets = SafeArea.useInsets()

	local homeSide = resolveSide(props.teams, result.homeId, game.homeName)
	local awaySide = resolveSide(props.teams, result.awayId, game.awayName)

	local iAmHome = props.teamId == result.homeId
	local iAmAway = props.teamId == result.awayId
	local outcome: Outcome = if not (iAmHome or iAmAway)
		then "spectator"
		elseif result.winnerId == props.teamId then "win"
		else "loss"

	local phase, setPhase = React.useState((if #plays == 0 then "stats" else "intro") :: Phase)
	local revealed, setRevealed = React.useState(0)
	local skipped, setSkipped = React.useState(#plays == 0)
	local showConfetti, setShowConfetti = React.useState(false)

	local genRef = React.useRef(0)
	local startedRef = React.useRef(false)
	local mountedRef = React.useRef(true)
	React.useEffect(function()
		mountedRef.current = true
		return function()
			mountedRef.current = false
			genRef.current += 1
		end
	end, {})

	local finalPhase = phase == "verdict" or phase == "stats"

	-- Scoreboard flash strip (big plays / TDs): transparency motor, snap 0.75 -> ease 1.
	local flash, flashApi = motion.useMotor(1)
	-- LOSS full-screen somber tint.
	local tint, tintApi = motion.useMotor(1)

	-- SKIP: bump the generation (cancels the director), land the board, play the verdict.
	local function skipToVerdict()
		genRef.current += 1
		setSkipped(true)
		setRevealed(#plays)
		setPhase("verdict")
	end

	-- The director: beat-walks the plays at variable cadence. setState per BEAT only.
	local function startDirector()
		if startedRef.current then
			return
		end
		startedRef.current = true
		if motion.Motion.reducedMotion() then
			skipToVerdict()
			return
		end
		genRef.current += 1
		local gen = genRef.current
		task.spawn(function()
			local per = if #plays > 26 then CADENCE.fastNormal else CADENCE.normal
			local prevHome, prevAway = 0, 0
			local prevQuarter = if plays[1] then plays[1].quarter else 1
			for i = 1, #plays do
				local play = plays[i]
				if i == #plays and #plays > 1 then
					Sound.play("drumroll", { volume = 0.45 })
					task.wait(CADENCE.finalPre)
				elseif play.big then
					task.wait(CADENCE.bigPre)
				end
				if gen ~= genRef.current then
					return
				end
				setRevealed(i)

				local dwell = per
				if play.big then
					Sound.play("pop", { speed = 0.9, volume = 0.6 })
					dwell = math.max(dwell, CADENCE.bigHold)
				end
				local delta = (play.homeScore - prevHome) + (play.awayScore - prevAway)
				if delta > 0 then
					if delta >= 6 then
						Sound.play("pop", { speed = 0.85 })
					else
						Sound.play("tick", { speed = 1.15 })
					end
					dwell = math.max(dwell, CADENCE.scoreHold)
				end
				if play.quarter > prevQuarter then
					Sound.play("tick")
					dwell = math.max(dwell, CADENCE.quarterBreak)
				end
				if i == #plays then
					Sound.play("whistle", { speed = 1.1, volume = 0.3 })
				end
				prevHome, prevAway, prevQuarter = play.homeScore, play.awayScore, play.quarter

				task.wait(dwell)
				if gen ~= genRef.current then
					return
				end
			end
			task.wait(CADENCE.doneHold)
			if gen ~= genRef.current then
				return
			end
			setPhase("verdict")
		end)
	end

	-- Phase C sequencing: stinger, (confetti), then Phase D.
	React.useEffect(function()
		if phase ~= "verdict" then
			return
		end
		if outcome == "win" then
			Sound.play("stinger_win")
			task.delay(0.35, function()
				if mountedRef.current then
					setShowConfetti(true)
				end
			end)
		elseif outcome == "loss" then
			Sound.play("stinger_loss")
		end
		local toStats = if outcome == "loss" then 0.6 else 0.5
		task.delay(toStats, function()
			if mountedRef.current then
				setPhase("stats")
			end
		end)
	end, { phase } :: { any })

	React.useEffect(function()
		if finalPhase and outcome == "loss" then
			tintApi.setTarget(0.65, motion.Motion.spring.gentle)
		end
	end, { finalPhase } :: { any })

	-- Big-play / TD heat strip over the ScoreBug (effect runs at beat cadence).
	React.useEffect(function()
		if revealed == 0 or phase ~= "plays" then
			return
		end
		local play = plays[revealed]
		local prev = plays[revealed - 1]
		local ph = if prev then prev.homeScore else 0
		local pa = if prev then prev.awayScore else 0
		local delta = (play.homeScore - ph) + (play.awayScore - pa)
		if play.big or delta >= 6 then
			flashApi.snap(0.75)
			flashApi.setTarget(1, motion.Motion.spring.gentle)
		end
	end, { revealed } :: { any })

	-- Verdict letter stagger (VICTORY) — trigger is stable across verdict -> stats.
	local verdictTrigger = if finalPhase then "go" else "wait"
	local letters = motion.useStagger(verdictTrigger, {
		count = 7,
		step = 0.04,
		span = 0.22,
		easing = motion.Solver.easeOutBack,
	})
	local bannerP = motion.useProgress(verdictTrigger, {
		duration = 0.5,
		easing = motion.Solver.easeOutCubic,
	})
	local statsTrigger = if phase == "stats" then "go" else "wait"
	local statRows = motion.useStagger(statsTrigger, { count = 3, step = 0.07, span = 0.3 })

	-- ---- derived scores / chip text ----
	local hs, as = 0, 0
	if finalPhase then
		hs, as = result.home.score, result.away.score
	elseif revealed > 0 then
		hs, as = plays[revealed].homeScore, plays[revealed].awayScore
	end

	local quarterText = "Q1 · 15:00"
	if finalPhase or (revealed >= #plays and #plays > 0) then
		quarterText = "FINAL"
	elseif revealed > 0 then
		local p = plays[revealed]
		quarterText = string.format("Q%d · %s", p.quarter, p.clock)
	end

	local winnerSide: ("home" | "away")? = nil
	if finalPhase then
		winnerSide = if result.winnerId == result.homeId then "home" else "away"
	end

	local homeBug: ScoreBug.Side = {
		abbr = homeSide.abbr,
		name = homeSide.name,
		primary = homeSide.primary,
		secondary = homeSide.secondary,
		score = hs,
		mine = iAmHome,
	}
	local awayBug: ScoreBug.Side = {
		abbr = awaySide.abbr,
		name = awaySide.name,
		primary = awaySide.primary,
		secondary = awaySide.secondary,
		score = as,
		mine = iAmAway,
	}

	-- ---- layout math ----
	local topY = insets.top
	local contentTop = topY + BUG_H + Theme.space.sm
	local bottomH = BOTTOM_H + insets.bottom
	local padX = Theme.chrome.padX

	local tickerTop = contentTop
	if phase == "verdict" then
		tickerTop = contentTop + BANNER_H + Theme.space.sm
	elseif phase == "stats" then
		tickerTop = contentTop + BANNER_H + STATS_H + Theme.space.sm * 2
	end

	-- ---- ticker rows ----
	local tickerChildren: { [string]: any } = {
		_layout = e("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		_pad = e("UIPadding", { PaddingBottom = UDim.new(0, Theme.space.xl) }),
	}
	if #plays == 0 then
		tickerChildren.play_none = e("TextLabel", {
			Text = "Final — see the box score below.",
			Font = Theme.type.body.font,
			TextSize = Theme.type.body.size,
			TextColor3 = Theme.text.secondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 44),
			LayoutOrder = 1,
		})
	else
		local newest = math.min(revealed, #plays)
		local oldest = if phase == "stats" then 1 else math.max(1, newest - 11)
		for i = newest, oldest, -1 do
			tickerChildren["play_" .. i] = e(TickerRow, {
				play = plays[i],
				layoutOrder = -i,
			})
		end
	end

	-- ---- children ----
	local children: { [string]: any } = {
		_bug = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, topY),
			Size = UDim2.new(1, 0, 0, BUG_H),
			ZIndex = 2,
		}, {
			bug = e(ScoreBug, {
				home = homeBug,
				away = awayBug,
				quarterText = quarterText,
				label = game.label,
				winnerSide = winnerSide,
				snapScores = skipped,
			}),
		}),
		_flash = e("Frame", {
			BackgroundColor3 = Theme.flag,
			BackgroundTransparency = flash,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, topY),
			Size = UDim2.new(1, 0, 0, BUG_H),
			ZIndex = 3,
		}),
		_ticker = e("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(padX, tickerTop),
			Size = UDim2.new(1, -padX * 2, 1, -(tickerTop + bottomH + Theme.space.sm)),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.line,
			ZIndex = 1,
		}, tickerChildren),
		_bottom = e("Frame", {
			BackgroundColor3 = Theme.bg.base,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, bottomH),
			ZIndex = 9,
		}, {
			_rule = e("Frame", {
				BackgroundColor3 = Theme.border.base,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 1),
			}),
			_pad = e("UIPadding", {
				PaddingTop = UDim.new(0, Theme.space.sm),
				PaddingLeft = UDim.new(0, padX),
				PaddingRight = UDim.new(0, padX),
			}),
			_btn = if finalPhase
				then e(Button, {
					text = "CONTINUE",
					variant = "primary" :: Button.Variant,
					pulse = true,
					onActivated = props.onDone,
					size = UDim2.new(1, 0, 0, 48),
				})
				else e(Button, {
					text = "SKIP ▶▶",
					variant = "ghost" :: Button.Variant,
					onActivated = skipToVerdict,
					size = UDim2.new(1, 0, 0, 48),
				}),
		}),
	}

	-- LOSS tint (dims everything under the banner/stats/bottom layers).
	if finalPhase and outcome == "loss" then
		children._tint = e("Frame", {
			BackgroundColor3 = Theme.field3,
			BackgroundTransparency = tint,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 4,
		})
	end

	-- Phase C: the verdict banner (asymmetric by design).
	if finalPhase then
		local banner: { [string]: any } = {}
		if outcome == "win" then
			local word = "VICTORY"
			local letterChildren: { [string]: any } = {
				_layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}
			for i = 1, #word do
				local b = letters.item(i)
				letterChildren["l" .. i] = e("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(32, 56),
					LayoutOrder = i,
				}, {
					letter = e("TextLabel", {
						Text = string.sub(word, i, i),
						Font = Theme.font.display,
						TextSize = 40,
						TextColor3 = Theme.gold,
						TextTransparency = b:map(function(p: number): number
							return motion.Motion.alpha(p)
						end),
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						Position = b:map(function(p: number): UDim2
							return UDim2.fromOffset(0, math.floor(18 * (1 - p)))
						end),
					}, {
						stroke = e("UIStroke", {
							Color = Theme.chalk,
							Thickness = 1,
							Transparency = b:map(function(p: number): number
								return motion.Motion.alpha(p, 0.75)
							end),
						}),
					}),
				})
			end
			banner.letters = e("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, letterChildren)
		else
			banner.word = e("TextLabel", {
				Text = if outcome == "loss" then "DEFEAT" else "FINAL",
				Font = Theme.font.display,
				TextSize = 40,
				TextColor3 = if outcome == "loss" then Theme.chalkSoft else Theme.chalk,
				TextTransparency = bannerP:map(function(p: number): number
					return motion.Motion.alpha(p)
				end),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Position = bannerP:map(function(p: number): UDim2
					return UDim2.fromOffset(0, math.floor(-12 * (1 - p)))
				end),
			})
		end
		children._banner = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, contentTop),
			Size = UDim2.new(1, 0, 0, BANNER_H),
			ZIndex = 5,
		}, banner)
	end

	-- Phase D: three comparison rows over the full play log.
	if phase == "stats" then
		local myBox = if iAmAway then result.away else result.home
		local oppBox = if iAmAway then result.home else result.away
		local leftTag = if outcome == "spectator" then string.upper(homeSide.abbr) else "YOU"
		local rightTag = if outcome == "spectator"
			then string.upper(awaySide.abbr)
			else string.upper(if iAmAway then homeSide.abbr else awaySide.abbr)
		children._stats = e("Frame", {
			BackgroundColor3 = Theme.surface.base,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(padX, contentTop + BANNER_H + Theme.space.sm),
			Size = UDim2.new(1, -padX * 2, 0, STATS_H),
			ZIndex = 5,
		}, {
			_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
			_stroke = e("UIStroke", {
				Color = Theme.strokes.edge.color,
				Transparency = Theme.strokes.edge.transparency,
				Thickness = 1,
			}),
			_pad = e("UIPadding", {
				PaddingTop = UDim.new(0, Theme.space.sm),
				PaddingBottom = UDim.new(0, Theme.space.sm),
				PaddingLeft = UDim.new(0, Theme.space.md),
				PaddingRight = UDim.new(0, Theme.space.md),
			}),
			_layout = e("UIListLayout", {
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			_tags = e("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14),
				LayoutOrder = 1,
			}, {
				left = e("TextLabel", {
					Text = leftTag,
					Font = Theme.type.eyebrow.font,
					TextSize = Theme.type.eyebrow.size,
					TextColor3 = Theme.flag,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(80, 14),
				}),
				right = e("TextLabel", {
					Text = rightTag,
					Font = Theme.type.eyebrow.font,
					TextSize = Theme.type.eyebrow.size,
					TextColor3 = Theme.text.secondary,
					TextXAlignment = Enum.TextXAlignment.Right,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromOffset(80, 14),
				}),
			}),
			_pass = e(StatRow, {
				label = "PASS YDS",
				left = myBox.passYards,
				right = oppBox.passYards,
				entrance = statRows.item(1),
				layoutOrder = 2,
			}),
			_rush = e(StatRow, {
				label = "RUSH YDS",
				left = myBox.rushYards,
				right = oppBox.rushYards,
				entrance = statRows.item(2),
				layoutOrder = 3,
			}),
			_to = e(StatRow, {
				label = "TURNOVERS",
				left = myBox.turnovers,
				right = oppBox.turnovers,
				entrance = statRows.item(3),
				layoutOrder = 4,
			}),
		})
	end

	-- Confetti (win only): the transient CanvasGroup slot — the cover is long gone.
	if showConfetti then
		children._confetti = e(Confetti, {
			play = true,
			onDone = function()
				if mountedRef.current then
					setShowConfetti(false)
				end
			end,
		})
	end

	-- Phase A cover (the screen's ONE CanvasGroup; unmounts at choreo complete).
	if phase == "intro" then
		children._cover = e(MatchupCover, {
			away = awaySide,
			home = homeSide,
			label = game.label,
			onComplete = function()
				if not mountedRef.current then
					return
				end
				setPhase("plays")
				startDirector()
			end,
		})
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, children)
end

return GameResult
