--!strict
-- The war room: fog-of-war prospect board with SCOUT/PICK actions, an ON THE CLOCK
-- status banner, and the my-picks ticker strip. Terminal state when the draft is done
-- (spec: IXD-36, master A13). Row tap opens ProspectDetailModal via the overlay.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)
local Theme = require(script.Parent.Parent.Theme)
local Sound = require(script.Parent.Parent.Sound)
local SafeArea = require(script.Parent.Parent.SafeArea)
local motion = require(script.Parent.Parent.motion)
local Overlay = require(script.Parent.Parent.overlay.OverlayProvider)
local Button = require(script.Parent.Parent.components.Button)
local Badge = require(script.Parent.Parent.components.Badge)
local EmptyState = require(script.Parent.Parent.components.EmptyState)
local RangeBar = require(script.Parent.Parent.components.RangeBar)
local AnimatedNumber = require(script.Parent.Parent.components.AnimatedNumber)
local ProspectDetailModal = require(script.Parent.Parent.components.ProspectDetailModal)

local e = React.createElement

type Props = {
	draft: Franchise.DraftView,
	teams: { Franchise.TeamSummary },
	scouting: string?,
	picking: boolean?,
	onScout: (prospectId: string) -> (),
	onPick: (prospectId: string) -> (),
}

local HEADER_H = 96
local BANNER_H = 32
local STRIP_H = 36
local ROW_H = 68

-- Clears the screen's "modal is open" ref however the modal closes (X, scrim, replace).
local function ModalLifecycle(props: { onUnmount: () -> (), content: any })
	local onUnmountRef = React.useRef(props.onUnmount)
	onUnmountRef.current = props.onUnmount
	React.useEffect(function()
		return function()
			local fn = onUnmountRef.current
			if fn then
				fn()
			end
		end
	end, {})
	return props.content
end

local function abbrFor(teams: { Franchise.TeamSummary }, teamId: string): string
	for _, t in teams do
		if t.id == teamId then
			return t.abbr
		end
	end
	return "???"
end

-- ---- one prospect row ----

type RowProps = {
	prospect: Franchise.ScoutedProspect,
	index: number,
	entrance: React.Binding<number>,
	isMyPick: boolean,
	picking: boolean,
	scoutingId: string?,
	scoutPoints: number,
	onScout: (id: string) -> (),
	onPick: (id: string) -> (),
	onOpen: (prospect: Franchise.ScoutedProspect) -> (),
}

local function ProspectRow(props: RowProps)
	local p = props.prospect
	local entrance = props.entrance
	local collapsed = (p.ovrMax - p.ovrMin) <= 2
	local canScout = props.scoutPoints > 0 and not collapsed and props.scoutingId == nil
	local isScoutingMe = props.scoutingId == p.id

	local actionsW = if props.isMyPick then 160 else 84
	local flexW = -(60 + actionsW + Theme.space.md)

	local inner: { [string]: any } = {
		_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
		_stroke = e("UIStroke", {
			Color = Theme.strokes.edge.color,
			Thickness = 1,
			Transparency = entrance:map(function(v: number): number
				return motion.Motion.alpha(v, Theme.strokes.edge.transparency)
			end),
		}),
		_pos = e("TextLabel", {
			Text = p.position,
			Font = Theme.font.display,
			TextSize = Theme.type.caption.size,
			TextColor3 = Theme.flag,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(Theme.space.md, 0),
			Size = UDim2.new(0, 40, 1, 0),
		}),
		_name = e("TextLabel", {
			Text = p.name,
			Font = Theme.type.h2.font,
			TextSize = Theme.type.h2.size,
			TextColor3 = Theme.text.primary,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(60, 8),
			Size = UDim2.new(1, flexW, 0, 20),
		}),
		_age = e("TextLabel", {
			Text = string.format("AGE %d", p.age),
			Font = Theme.type.caption.font,
			TextSize = Theme.type.caption.size,
			TextColor3 = Theme.text.secondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(60, 28),
			Size = UDim2.new(0, 64, 0, 14),
		}),
		_range = e("TextLabel", {
			Text = if collapsed
				then tostring(p.ovrMax)
				else string.format("%d–%d", p.ovrMin, p.ovrMax),
			Font = Theme.font.mono,
			TextSize = Theme.type.monoSm.size,
			TextColor3 = if collapsed then Theme.ovrColor(p.ovrMax) else Theme.text.secondary,
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -actionsW - Theme.space.md, 0, 28),
			Size = UDim2.fromOffset(64, 14),
		}),
		_bar = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(60, 48),
			Size = UDim2.new(1, flexW, 0, Theme.size.barH),
		}, {
			bar = e(RangeBar, { min = p.ovrMin, max = p.ovrMax }),
		}),
		_scout = e("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(
				1,
				if props.isMyPick then -84 - Theme.space.sm * 2 else -Theme.space.sm,
				0.5,
				0
			),
			Size = UDim2.fromOffset(72, 40),
			ZIndex = 2,
		}, {
			btn = e(Button, {
				text = "SCOUT",
				variant = "ghost" :: Button.Variant,
				onActivated = function()
					props.onScout(p.id)
				end,
				disabled = not canScout and not isScoutingMe,
				loading = isScoutingMe,
				size = UDim2.fromScale(1, 1),
			}),
		}),
	}
	if props.isMyPick then
		inner._pick = e("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -Theme.space.sm, 0.5, 0),
			Size = UDim2.fromOffset(72, 40),
			ZIndex = 2,
		}, {
			btn = e(Button, {
				text = "PICK",
				variant = "primary" :: Button.Variant,
				onActivated = function()
					props.onPick(p.id)
				end,
				disabled = props.picking,
				sfx = "pick",
				size = UDim2.fromScale(1, 1),
			}),
		})
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, ROW_H),
		LayoutOrder = props.index,
	}, {
		inner = e(
			"TextButton",
			{
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = Theme.surface.base,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, -6),
				Position = entrance:map(function(v: number): UDim2
					return UDim2.fromOffset(
						math.floor(-motion.Motion.dist.slide * 0.75 * (1 - v)),
						0
					)
				end),
				BackgroundTransparency = entrance:map(function(v: number): number
					return motion.Motion.alpha(v)
				end),
				[React.Event.Activated] = function()
					props.onOpen(p)
				end,
			} :: { [any]: any },
			inner
		),
	})
end

-- ---- the screen ----

local function DraftRoom(props: Props)
	local draft = props.draft
	local insets = SafeArea.useInsets()
	local overlay = Overlay.useOverlay()

	local openIdRef = React.useRef(nil :: string?)

	-- ON THE CLOCK ambience + broadcast cut-in sound when it flips true.
	local clockPulse =
		motion.usePulse({ period = 1.1, enabled = draft.isMyPick and not draft.done })
	local wasMyPickRef = React.useRef(false)
	React.useEffect(function()
		if draft.isMyPick and not wasMyPickRef.current and not draft.done then
			Sound.play("drumroll", { volume = 0.4 })
		end
		wasMyPickRef.current = draft.isMyPick
	end, { draft.isMyPick } :: { any })

	local stagger = motion.useStagger("board", {
		count = #draft.prospects,
		step = 0.04,
		span = 0.26,
	})

	-- Open (or refresh) the prospect modal. overlay.open with the same id replaces the
	-- build in place, so scouting results live-update the open modal.
	local function openProspect(p: Franchise.ScoutedProspect)
		openIdRef.current = p.id
		overlay.open("prospect", function(close: () -> ()): any
			return e(ModalLifecycle, {
				onUnmount = function()
					openIdRef.current = nil
				end,
				content = e(ProspectDetailModal, {
					prospect = p,
					scoutPoints = draft.scoutPoints,
					scouting = props.scouting == p.id,
					isMyPick = draft.isMyPick and not draft.done,
					onScout = function()
						props.onScout(p.id)
					end,
					onPick = if draft.isMyPick and not draft.done
						then function()
							close()
							props.onPick(p.id)
						end
						else nil,
					onClose = close,
				}),
			})
		end)
	end

	-- Keep an open modal in sync with fresh draft data; close it if the prospect left
	-- the board (picked by someone).
	React.useEffect(function()
		local id = openIdRef.current
		if not id then
			return
		end
		for _, p in draft.prospects do
			if p.id == id then
				openProspect(p)
				return
			end
		end
		openIdRef.current = nil
		overlay.close("prospect")
	end, { props.draft, props.scouting } :: { any })

	local topY = insets.top
	local padX = Theme.chrome.padX
	local hasStrip = #draft.myPicks > 0
	local listTop = topY
		+ HEADER_H
		+ (if hasStrip then STRIP_H + Theme.space.sm else 0)
		+ Theme.space.sm

	-- ---- header ----
	local onClockText = if draft.isMyPick
		then "YOU'RE ON THE CLOCK"
		else string.format("%s ON THE CLOCK", abbrFor(props.teams, draft.onClock))
	if draft.done then
		onClockText = "DRAFT COMPLETE"
	end

	local header = e("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(padX, topY),
		Size = UDim2.new(1, -padX * 2, 0, HEADER_H),
	}, {
		_kicker = e("TextLabel", {
			Text = "WAR ROOM",
			Font = Theme.type.eyebrow.font,
			TextSize = Theme.type.eyebrow.size,
			TextColor3 = Theme.text.tertiary,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -120, 0, 14),
		}),
		_title = e("TextLabel", {
			Text = string.format("PICK %d OF %d", draft.pickNumber, draft.totalPicks),
			Font = Theme.type.h1.font,
			TextSize = Theme.type.h1.size,
			TextColor3 = Theme.text.primary,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 18),
			Size = UDim2.new(1, -120, 0, 26),
		}),
		_scoutChip = e("Frame", {
			BackgroundColor3 = Theme.gold,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(96, 28),
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			glyph = e("TextLabel", {
				Text = "🔭",
				Font = Theme.type.body.font,
				TextSize = 14,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.fromOffset(20, 28),
			}),
			num = e(AnimatedNumber, {
				value = draft.scoutPoints,
				textColor3 = Theme.text.inverse,
				textSize = Theme.type.mono.size,
				size = UDim2.fromOffset(50, 28),
				position = UDim2.new(1, -60, 0, 0),
			}),
		}),
		_banner = e("Frame", {
			BackgroundColor3 = if draft.isMyPick and not draft.done
				then Theme.flag
				else Theme.surface.base,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, HEADER_H - BANNER_H),
			Size = UDim2.new(1, 0, 0, BANNER_H),
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.sm) }),
			stroke = e("UIStroke", {
				Color = if draft.isMyPick and not draft.done
					then Theme.chalk
					else Theme.strokes.edge.color,
				Thickness = if draft.isMyPick and not draft.done then 1.5 else 1,
				Transparency = if draft.isMyPick and not draft.done
					then clockPulse:map(function(p: number): number
						return 0.8 - 0.45 * p
					end)
					else Theme.strokes.edge.transparency :: number | React.Binding<number>,
			}),
			label = e("TextLabel", {
				Text = onClockText,
				Font = Theme.font.display,
				TextSize = Theme.type.bodyBold.size,
				TextColor3 = if draft.isMyPick and not draft.done
					then Theme.chalk
					else Theme.text.secondary,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}),
		}),
	})

	-- ---- my-picks strip ----
	local strip: any = nil
	if hasStrip then
		local chips: { [string]: any } = {
			_layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, Theme.space.sm),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}
		for i, pick in draft.myPicks do
			chips["mp_" .. pick.round .. "_" .. pick.name] = e(Badge, {
				text = string.format("R%d · %s %s", pick.round, pick.position, pick.name),
				variant = "outline" :: Badge.Variant,
				color = Theme.gold,
				layoutOrder = i,
			})
		end
		strip = e("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(padX, topY + HEADER_H + Theme.space.sm),
			Size = UDim2.new(1, -padX * 2, 0, STRIP_H),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.X,
		}, chips)
	end

	-- ---- body: terminal / empty / board ----
	local body: any
	if draft.done then
		body = e(EmptyState, {
			icon = "🔭",
			title = "DRAFT COMPLETE",
			body = "Every pick is in. The league office is finalizing the offseason.",
		})
	elseif #draft.prospects == 0 then
		body = e(EmptyState, {
			icon = "🔭",
			title = "THE BOARD IS BARE",
			body = "Every name is off the board. Turn in your pick.",
		})
	else
		local rows: { [string]: any } = {
			_layout = e("UIListLayout", {
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			_pad = e("UIPadding", { PaddingBottom = UDim.new(0, Theme.space.xl) }),
		}
		for i, p in draft.prospects do
			rows["pr_" .. p.id] = e(ProspectRow, {
				prospect = p,
				index = i,
				entrance = stagger.item(i),
				isMyPick = draft.isMyPick,
				picking = props.picking == true,
				scoutingId = props.scouting,
				scoutPoints = draft.scoutPoints,
				onScout = props.onScout,
				onPick = props.onPick,
				onOpen = openProspect,
			})
		end
		body = e("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(padX, listTop),
			Size = UDim2.new(1, -padX * 2, 1, -(listTop + insets.bottom + Theme.space.sm)),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.line,
		}, rows)
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		_header = header,
		_strip = strip,
		_body = body,
	})
end

return DraftRoom
