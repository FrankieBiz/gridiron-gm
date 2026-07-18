--!strict
-- The open market: sortable veteran list with SIGN actions priced in coaching credits,
-- a counting credits chip, signed-row send-offs, and the KICK OFF THE SEASON footer
-- (spec: IXD-37). Row tap opens PlayerDetailModal with a SIGN action.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)
local Theme = require(script.Parent.Parent.Theme)
local SafeArea = require(script.Parent.Parent.SafeArea)
local motion = require(script.Parent.Parent.motion)
local Overlay = require(script.Parent.Parent.overlay.OverlayProvider)
local Button = require(script.Parent.Parent.components.Button)
local EmptyState = require(script.Parent.Parent.components.EmptyState)
local SortChips = require(script.Parent.Parent.components.SortChips)
local PlayerRow = require(script.Parent.Parent.components.PlayerRow)
local AnimatedNumber = require(script.Parent.Parent.components.AnimatedNumber)
local PlayerDetailModal = require(script.Parent.Parent.components.PlayerDetailModal)

local e = React.createElement

type Props = {
	freeAgents: { Franchise.FreeAgent },
	credits: number,
	signing: string?,
	finishing: boolean?,
	onSign: (id: string) -> (),
	onFinish: () -> (),
}

type SortKey = "ovr" | "cost" | "pos"

local HEADER_H = 64
local CHIPS_H = 36
local FOOTER_H = 64
local GHOST_SECONDS = 0.4

local SORT_OPTIONS: { SortChips.Option } = {
	{ id = "ovr", label = "OVR" },
	{ id = "cost", label = "COST" },
	{ id = "pos", label = "POS" },
}

-- Default direction when a key is first selected (OVR wants best-first).
local DEFAULT_ASC: { [string]: boolean } = { ovr = false, cost = true, pos = true }

local function less(a: Franchise.FreeAgent, b: Franchise.FreeAgent, key: SortKey): boolean
	if key == "pos" then
		if a.position ~= b.position then
			return a.position < b.position
		end
		return a.overall > b.overall
	end
	local av = if key == "cost" then a.cost else a.overall
	local bv = if key == "cost" then b.cost else b.overall
	if av ~= bv then
		return av < bv
	end
	return a.id < b.id
end

-- ---- signed-row send-off ghost ----

local function GhostRow(props: { agent: Franchise.FreeAgent, layoutOrder: number })
	local fa = props.agent
	local p =
		motion.useProgress(nil, { duration = GHOST_SECONDS, easing = motion.Solver.easeOutCubic })

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Theme.size.rowH),
		LayoutOrder = props.layoutOrder,
	}, {
		inner = e("Frame", {
			BackgroundColor3 = Theme.surface.base,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Position = p:map(function(v: number): UDim2
				return UDim2.fromOffset(math.floor(40 * v), 0)
			end),
			BackgroundTransparency = p:map(function(v: number): number
				return 0.2 + 0.8 * v
			end),
		}, {
			_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
			_name = e("TextLabel", {
				Text = fa.name,
				Font = Theme.type.h2.font,
				TextSize = Theme.type.h2.size,
				TextColor3 = Theme.text.secondary,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTransparency = p,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(Theme.space.md, 0),
				Size = UDim2.new(0.6, -Theme.space.md, 1, 0),
			}),
			_signed = e("TextLabel", {
				Text = "SIGNED ✓",
				Font = Theme.font.bold,
				TextSize = Theme.type.h2.size,
				TextColor3 = Theme.semantic.success,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTransparency = p,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -Theme.space.lg, 0, 0),
				Size = UDim2.new(0.4, 0, 1, 0),
			}),
		}),
	})
end

-- ---- the screen ----

local function FreeAgency(props: Props)
	local insets = SafeArea.useInsets()
	local overlay = Overlay.useOverlay()

	local sortKey, setSortKey = React.useState("ovr" :: SortKey)
	local ascending, setAscending = React.useState(false)
	local ghosts, setGhosts = React.useState({} :: { Franchise.FreeAgent })

	local mountedRef = React.useRef(true)
	React.useEffect(function()
		mountedRef.current = true
		return function()
			mountedRef.current = false
		end
	end, {})

	-- Signed-row send-off: hold rows removed from props for GHOST_SECONDS, overlaid
	-- with SIGNED ✓ sliding right + fading, then release (identity by fa.id).
	local prevAgentsRef = React.useRef(props.freeAgents)
	React.useEffect(function()
		local prev = prevAgentsRef.current :: { Franchise.FreeAgent }
		prevAgentsRef.current = props.freeAgents
		local currentIds: { [string]: boolean } = {}
		for _, fa in props.freeAgents do
			currentIds[fa.id] = true
		end
		local removed: { Franchise.FreeAgent } = {}
		for _, fa in prev do
			if not currentIds[fa.id] then
				table.insert(removed, fa)
			end
		end
		if #removed == 0 then
			return
		end
		setGhosts(function(g: { Franchise.FreeAgent }): { Franchise.FreeAgent }
			local out = table.clone(g)
			for _, fa in removed do
				table.insert(out, fa)
			end
			return out
		end)
		task.delay(GHOST_SECONDS, function()
			if not mountedRef.current then
				return
			end
			setGhosts(function(g: { Franchise.FreeAgent }): { Franchise.FreeAgent }
				local out = {}
				for _, fa in g do
					local drop = false
					for _, r in removed do
						if r.id == fa.id then
							drop = true
						end
					end
					if not drop then
						table.insert(out, fa)
					end
				end
				return out
			end)
		end)
	end, { props.freeAgents } :: { any })

	local stagger = motion.useStagger((sortKey :: string) .. (if ascending then "_a" else "_d"), {
		count = #props.freeAgents,
		step = 0.035,
		span = 0.24,
		maxTotal = 0.8,
	})

	local function openAgent(fa: Franchise.FreeAgent)
		local afford = props.credits >= fa.cost
		overlay.open("freeagent", function(close: () -> ()): any
			return e(PlayerDetailModal, {
				player = fa,
				action = {
					text = string.format("SIGN · %d 🪙", fa.cost),
					onActivated = function()
						close()
						props.onSign(fa.id)
					end,
					disabled = not afford or props.signing ~= nil,
				} :: PlayerDetailModal.Action,
				onClose = close,
			})
		end)
	end

	-- ---- sorted display list (live agents + ghosts held in place) ----
	local sorted: { { agent: Franchise.FreeAgent, ghost: boolean } } = {}
	for _, fa in props.freeAgents do
		table.insert(sorted, { agent = fa, ghost = false })
	end
	for _, fa in ghosts do
		table.insert(sorted, { agent = fa, ghost = true })
	end
	table.sort(sorted, function(a, b): boolean
		if ascending then
			return less(a.agent, b.agent, sortKey)
		end
		return less(b.agent, a.agent, sortKey)
	end)

	local topY = insets.top
	local padX = Theme.chrome.padX
	local listTop = topY + HEADER_H + CHIPS_H + Theme.space.sm
	local footerH = FOOTER_H + insets.bottom
	local marketOpen = #props.freeAgents > 0 or #ghosts > 0

	local children: { [string]: any } = {
		_header = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(padX, topY),
			Size = UDim2.new(1, -padX * 2, 0, HEADER_H),
		}, {
			_kicker = e("TextLabel", {
				Text = "FREE AGENCY",
				Font = Theme.type.eyebrow.font,
				TextSize = Theme.type.eyebrow.size,
				TextColor3 = Theme.text.tertiary,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 8),
				Size = UDim2.new(1, -130, 0, 14),
			}),
			_title = e("TextLabel", {
				Text = "OPEN MARKET",
				Font = Theme.type.h1.font,
				TextSize = Theme.type.h1.size,
				TextColor3 = Theme.text.primary,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 26),
				Size = UDim2.new(1, -130, 0, 26),
			}),
			_credits = e("Frame", {
				BackgroundColor3 = Theme.gold,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 18),
				Size = UDim2.fromOffset(110, 28),
				BorderSizePixel = 0,
			}, {
				corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				glyph = e("TextLabel", {
					Text = "🪙",
					Font = Theme.type.body.font,
					TextSize = 14,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(10, 0),
					Size = UDim2.fromOffset(20, 28),
				}),
				num = e(AnimatedNumber, {
					value = props.credits,
					textColor3 = Theme.text.inverse,
					textSize = Theme.type.mono.size,
					size = UDim2.fromOffset(60, 28),
					position = UDim2.new(1, -70, 0, 0),
				}),
			}),
		}),
		_chips = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(padX, topY + HEADER_H),
			Size = UDim2.new(1, -padX * 2, 0, CHIPS_H),
		}, {
			chips = e(SortChips, {
				options = SORT_OPTIONS,
				active = sortKey :: string,
				ascending = ascending,
				onSelect = function(id: string)
					if id == sortKey then
						setAscending(not ascending)
					else
						setSortKey(id :: SortKey)
						setAscending(DEFAULT_ASC[id] == true)
					end
				end,
			}),
		}),
	}

	if marketOpen then
		local rows: { [string]: any } = {
			_layout = e("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			_pad = e("UIPadding", { PaddingBottom = UDim.new(0, Theme.space.xl) }),
		}
		for i, entry in sorted do
			local fa = entry.agent
			if entry.ghost then
				rows["fa_" .. fa.id] = e(GhostRow, { agent = fa, layoutOrder = i })
			else
				local afford = props.credits >= fa.cost
				rows["fa_" .. fa.id] = e(PlayerRow, {
					player = fa,
					index = i,
					entrance = stagger.item(i),
					right = "cost" :: "cost",
					disabled = not afford,
					onTap = function()
						openAgent(fa)
					end,
					actionButton = e(Button, {
						text = string.format("SIGN · %d 🪙", fa.cost),
						variant = (if afford then "primary" else "ghost") :: Button.Variant,
						onActivated = function()
							props.onSign(fa.id)
						end,
						disabled = not afford,
						loading = props.signing == fa.id,
						size = UDim2.fromScale(1, 1),
					}),
					layoutOrder = i,
				})
			end
		end
		children._list = e("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(padX, listTop),
			Size = UDim2.new(1, -padX * 2, 1, -(listTop + footerH + Theme.space.sm)),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.line,
		}, rows)
		children._footer = e("Frame", {
			BackgroundColor3 = Theme.bg.base,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, footerH),
			ZIndex = 5,
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
			_btn = e(Button, {
				text = "KICK OFF THE SEASON ▸",
				variant = "primary" :: Button.Variant,
				onActivated = props.onFinish,
				loading = props.finishing,
				size = UDim2.new(1, 0, 0, 48),
			}),
		})
	else
		children._empty = e(EmptyState, {
			icon = "🖊",
			title = "MARKET'S CLOSED",
			body = "Every veteran found a home. Kick off the season!",
			actionText = "KICK OFF THE SEASON ▸",
			onAction = props.onFinish,
		})
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, children)
end

return FreeAgency
