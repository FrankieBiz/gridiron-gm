--!strict
-- Offseason (IXD-35): the between-seasons ceremony on one 2.2s clock — champion hero,
-- credits earned, retirements, your draft class, then START YEAR. SKIP snaps every beat
-- to rest. My team winning it all fires the confetti celebration.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)

local Theme = require(script.Parent.Parent.Theme)
local SafeArea = require(script.Parent.Parent.SafeArea)
local motion = require(script.Parent.Parent.motion)
local Overlay = require(script.Parent.Parent.overlay.OverlayProvider)
local AnimatedNumber = require(script.Parent.Parent.components.AnimatedNumber)
local Badge = require(script.Parent.Parent.components.Badge)
local Button = require(script.Parent.Parent.components.Button)
local SectionHeader = require(script.Parent.Parent.components.SectionHeader)

local e = React.createElement

local Motion = motion.Motion
local Solver = motion.Solver

export type Props = {
	summary: Franchise.OffseasonSummary,
	teams: { Franchise.TeamSummary },
	myTeamId: string,
	starting: boolean?,
	onDone: () -> (),
}

-- Beat timeline (seconds on the choreo clock).
local BEAT = { hero = 0, credits = 0.5, retire = 1.0, rookies = 1.4, footer = 1.9 }
local TOTAL = 2.2

type Clock = React.Binding<number>

local function fadeText(clock: Clock, start: number): React.Binding<number>
	return clock:map(function(t: number): number
		return Motion.alpha(Motion.window(t, start, 0.35))
	end)
end

local function fadeBg(clock: Clock, start: number, rest: number): React.Binding<number>
	return clock:map(function(t: number): number
		return Motion.alpha(Motion.window(t, start, 0.35), rest)
	end)
end

-- SectionHeader can't take bindings, so beats reveal it from behind a bg-colored veil.
local function headerBeat(text: string, clock: Clock, start: number, order: number): any
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = order,
	}, {
		header = e(SectionHeader, { text = text }),
		veil = e("Frame", {
			BackgroundColor3 = Theme.field,
			BackgroundTransparency = clock:map(function(t: number): number
				return Motion.window(t, start, 0.3)
			end),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 10,
			BorderSizePixel = 0,
		}),
	})
end

local function noteRow(text: string, clock: Clock, start: number, order: number): any
	return e("TextLabel", {
		Text = text,
		Font = Theme.type.body.font,
		TextSize = Theme.type.body.size,
		TextColor3 = Theme.text.secondary,
		TextTransparency = fadeText(clock, start),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = order,
	})
end

local function Offseason(props: Props)
	local overlay = Overlay.useOverlay()
	local insets = SafeArea.useInsets()
	local s = props.summary

	local done, setDone = React.useState(false)
	local clock, choreo = motion.useChoreo("offseason", TOTAL, function()
		setDone(true)
	end)

	local byId: { [string]: Franchise.TeamSummary } = {}
	for _, t in props.teams do
		byId[t.id] = t
	end
	local champ: Franchise.TeamSummary? = if s.champion ~= nil
		then byId[s.champion :: string]
		else nil
	local myBanner = s.champion ~= nil and s.champion == props.myTeamId

	-- My banner -> confetti, once, on mount.
	React.useEffect(function()
		if myBanner then
			overlay.celebrate("confetti")
		end
	end, {})

	-- Defensive self-defaults: summary bypasses fetchAll normalization by design.
	local retirees: { Franchise.RosterPlayer } = s.retirees or ({} :: { Franchise.RosterPlayer })
	local rookies: { Franchise.DraftPick } = s.rookies or ({} :: { Franchise.DraftPick })

	local content: { [string]: any } = {
		layout = e("UIListLayout", {
			Padding = UDim.new(0, Theme.space.md),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, Theme.chrome.padX),
			PaddingRight = UDim.new(0, Theme.chrome.padX),
			PaddingBottom = UDim.new(0, Theme.space.xl),
		}),
	}

	-- Beat 1: champion hero.
	local champPal = if champ then Theme.withTeam(champ.primary, champ.secondary) else nil
	content.hero = e("Frame", {
		BackgroundColor3 = Theme.stroke, -- white base so the team gradient reads true
		BackgroundTransparency = fadeBg(clock, BEAT.hero, 0),
		Size = UDim2.new(1, 0, 0, 120),
		LayoutOrder = 1,
		BorderSizePixel = 0,
	}, {
		corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.lg) }),
		grad = e("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(
				if champPal then champPal.tint else Theme.surface.base,
				Theme.field3
			),
		}),
		stroke = e("UIStroke", {
			Color = Theme.gold,
			Transparency = if myBanner then 0.35 else 0.75,
			Thickness = if myBanner then 2 else 1,
		}),
		kicker = e("TextLabel", {
			Text = string.format("🏆 %d CHAMPIONS", s.year),
			Font = Theme.type.eyebrow.font,
			TextSize = Theme.type.eyebrow.size,
			TextColor3 = Theme.text.secondary,
			TextTransparency = fadeText(clock, BEAT.hero),
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 24),
			Size = UDim2.new(1, 0, 0, 14),
		}),
		name = e("TextLabel", {
			Text = if champ
				then champ.city .. " " .. champ.name
				else "Season " .. tostring(s.year) .. " complete",
			Font = Theme.type.h1.font,
			TextSize = Theme.type.h1.size,
			TextColor3 = Theme.gold,
			TextTransparency = fadeText(clock, BEAT.hero),
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 46),
			Size = UDim2.new(1, 0, 0, 26),
		}),
		mine = if myBanner
			then e("TextLabel", {
				Text = "THAT'S YOUR BANNER.",
				Font = Theme.type.caption.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = Theme.goldGlow,
				TextTransparency = fadeText(clock, BEAT.hero + 0.15),
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 80),
				Size = UDim2.new(1, 0, 0, 16),
			})
			else nil,
	})

	-- Beat 2: credits earned.
	content.credits = e("Frame", {
		BackgroundColor3 = Theme.surface.raised,
		BackgroundTransparency = fadeBg(clock, BEAT.credits, 0),
		Size = UDim2.new(1, 0, 0, 72),
		LayoutOrder = 2,
		BorderSizePixel = 0,
	}, {
		corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
		stroke = e("UIStroke", { Color = Theme.gold, Transparency = 0.6, Thickness = 1 }),
		pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, Theme.space.lg),
			PaddingRight = UDim.new(0, Theme.space.lg),
		}),
		amount = e(AnimatedNumber, {
			value = s.creditsEarned,
			animateOnMount = true,
			snap = done,
			format = function(n: number): string
				return string.format("+%d 🪙", math.floor(n + 0.5))
			end,
			textColor3 = Theme.gold,
			textSize = 24,
			textXAlignment = Enum.TextXAlignment.Left,
			size = UDim2.new(1, 0, 0, 30),
			position = UDim2.fromOffset(0, 12),
		}),
		caption = e("TextLabel", {
			Text = string.format("COACHING CREDITS EARNED · BANK: %d", s.totalCredits),
			Font = Theme.type.caption.font,
			TextSize = Theme.type.caption.size,
			TextColor3 = Theme.text.secondary,
			TextTransparency = fadeText(clock, BEAT.credits),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 46),
			Size = UDim2.new(1, 0, 0, 14),
		}),
	})

	-- Beat 3: retirements.
	content.retireHeader = headerBeat("RETIREMENTS", clock, BEAT.retire, 3)
	if #retirees == 0 then
		content.retireEmpty =
			noteRow("None this year. The locker room holds.", clock, BEAT.retire, 4)
	else
		for i, p in retirees do
			local start = BEAT.retire + 0.05 + (i - 1) * 0.04
			content["ret_" .. p.id] = e("Frame", {
				BackgroundColor3 = Theme.surface.base,
				BackgroundTransparency = fadeBg(clock, start, 0),
				Size = UDim2.new(1, 0, 0, 44),
				LayoutOrder = 4 + i,
				BorderSizePixel = 0,
			}, {
				corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.sm) }),
				pos = e("TextLabel", {
					Text = p.position,
					Font = Theme.font.display,
					TextSize = Theme.type.caption.size,
					TextColor3 = Theme.flag,
					TextTransparency = fadeText(clock, start),
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(12, 0),
					Size = UDim2.fromOffset(36, 44),
				}),
				name = e("TextLabel", {
					Text = p.name,
					Font = Theme.type.bodyBold.font,
					TextSize = Theme.type.bodyBold.size,
					TextColor3 = Theme.text.primary,
					TextTransparency = fadeText(clock, start),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(54, 0),
					Size = UDim2.new(1, -54 - 190, 1, 0),
				}),
				fate = e("TextLabel", {
					Text = string.format("hangs it up at %d · %d OVR", p.age, p.overall),
					Font = Theme.type.caption.font,
					TextSize = Theme.type.caption.size,
					TextColor3 = Theme.text.secondary,
					TextTransparency = fadeText(clock, start),
					TextXAlignment = Enum.TextXAlignment.Right,
					TextTruncate = Enum.TextTruncate.AtEnd,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -12, 0, 0),
					Size = UDim2.fromOffset(180, 44),
				}),
			})
		end
	end

	-- Beat 4: draft class.
	content.rookieHeader = headerBeat("YOUR DRAFT CLASS", clock, BEAT.rookies, 40)
	if #rookies == 0 then
		content.rookieEmpty =
			noteRow("No picks came in. Free agency is next.", clock, BEAT.rookies, 41)
	else
		for i, p in rookies do
			local start = BEAT.rookies + 0.05 + (i - 1) * 0.04
			content["rk_" .. p.name .. "_" .. p.round] = e("Frame", {
				BackgroundColor3 = Theme.surface.base,
				BackgroundTransparency = fadeBg(clock, start, 0),
				Size = UDim2.new(1, 0, 0, 56),
				LayoutOrder = 41 + i,
				BorderSizePixel = 0,
			}, {
				corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
				stroke = e("UIStroke", {
					Color = Theme.devColor(p.devTrait),
					Transparency = 0.55,
					Thickness = 1,
				}),
				roundWrap = e("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(12, 16),
					Size = UDim2.fromOffset(48, 24),
				}, {
					layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					round = e(Badge, { text = "R" .. p.round, variant = "brand" :: Badge.Variant }),
				}),
				pos = e("TextLabel", {
					Text = p.position,
					Font = Theme.font.display,
					TextSize = Theme.type.caption.size,
					TextColor3 = Theme.flag,
					TextTransparency = fadeText(clock, start),
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(66, 0),
					Size = UDim2.fromOffset(36, 56),
				}),
				name = e("TextLabel", {
					Text = p.name,
					Font = Theme.type.bodyBold.font,
					TextSize = Theme.type.bodyBold.size,
					TextColor3 = Theme.text.primary,
					TextTransparency = fadeText(clock, start),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(108, 0),
					Size = UDim2.new(1, -108 - 70, 1, 0),
				}),
				ovr = e("TextLabel", {
					Text = tostring(p.overall),
					Font = Theme.font.mono,
					TextSize = 20,
					TextColor3 = Theme.ovrColor(p.overall),
					TextTransparency = fadeText(clock, start),
					TextXAlignment = Enum.TextXAlignment.Right,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -14, 0, 0),
					Size = UDim2.fromOffset(56, 56),
				}),
			})
		end
	end

	-- Footer: START YEAR, revealed with the final beat.
	content.footer = e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 64),
		LayoutOrder = 90,
	}, {
		scale = e("UIScale", {
			Scale = clock:map(function(t: number): number
				return Motion.window(t, BEAT.footer, 0.3, Solver.easeOutBack)
			end),
		}),
		btn = e(Button, {
			text = string.format("START YEAR %d ▸", s.nextYear),
			loading = props.starting,
			onActivated = props.onDone,
			size = UDim2.new(1, 0, 0, 52),
		}),
	})

	local topPad = insets.top + Theme.space.md + 44

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		skipWrap = if not done
			then e("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -Theme.chrome.padX, 0, insets.top + Theme.space.sm),
				Size = UDim2.fromOffset(88, 44),
				ZIndex = Theme.z.raised,
			}, {
				btn = e(Button, {
					text = "SKIP ▸",
					variant = "ghost" :: Button.Variant,
					size = UDim2.fromScale(1, 1),
					onActivated = choreo.finish,
				}),
			})
			else nil,
		scroll = e("ScrollingFrame", {
			Position = UDim2.fromOffset(0, topPad),
			Size = UDim2.new(1, 0, 1, -topPad),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.line,
		}, content),
	})
end

return Offseason
