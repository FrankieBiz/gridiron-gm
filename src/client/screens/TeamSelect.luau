--!strict
-- Team selection — "TAKE THE PODIUM". Responsive team-card grid over static league data
-- (ui-v2-ixd §4.2): diagonal team-gradient cards with ghost monograms, a cascade
-- entrance (one stagger clock, §5 cheap recipe — no CanvasGroups), a selection ceremony
-- (focus stroke + scale spring, others dim), and a ConfirmBar. Team hex strings enter
-- ONLY through Theme.hex/Theme.contrastOn. Screens never call remotes: the pick bubbles
-- up through onPick.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Sound = require(script.Parent.Parent.Sound)
local SafeArea = require(script.Parent.Parent.SafeArea)
local motion = require(script.Parent.Parent.motion)
local ConfirmBar = require(script.Parent.Parent.components.ConfirmBar)
local Teams = require(ReplicatedStorage.Shared.Data.Teams)

local Motion = motion.Motion

local e = React.createElement

type Props = {
	pending: boolean?,
	onPick: (teamId: string) -> (),
	onBack: () -> (),
}

local CARD_H = 92
local HEADER_H = 56
local CONFIRM_H = 72
local GHOST_W = 96
local GHOST_REST_T = 0.82
local CITY_REST_T = 0.35
local DIM_STRENGTH = 0.5

-- Viewport width for the responsive grid (re-renders on rotation/resize).
local function useViewportWidth(): number
	local width, setWidth = React.useState(function(): number
		local camera = Workspace.CurrentCamera
		return if camera then camera.ViewportSize.X else 1024
	end)

	React.useEffect(function(): (() -> ())?
		local camera = Workspace.CurrentCamera
		if not camera then
			return nil
		end
		local conn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			setWidth(camera.ViewportSize.X)
		end)
		return function()
			conn:Disconnect()
		end
	end, {})

	return width
end

local function cellSize(viewportW: number): UDim2
	if viewportW < 480 then
		return UDim2.new(1, 0, 0, CARD_H)
	elseif viewportW < 768 then
		return UDim2.new(0.5, -8, 0, CARD_H)
	end
	return UDim2.new(1 / 3, -12, 0, CARD_H)
end

-- ---- one team card (own component: hooks per card for the selection ceremony) ----

type CardProps = {
	team: Teams.TeamIdentity,
	entrance: React.Binding<number>,
	selected: boolean,
	dimmed: boolean,
	locked: boolean,
	layoutOrder: number,
	onTap: (teamId: string) -> (),
}

local function TeamCard(props: CardProps)
	local team = props.team
	local primary = Theme.hex(team.primary)
	local secondary = Theme.hex(team.secondary)
	local ink = Theme.contrastOn(primary)
	local entrance = props.entrance

	local scale, scaleApi = motion.useMotor(1)
	React.useEffect(function()
		scaleApi.setTarget(if props.selected then 1.03 else 1, Motion.spring.pop)
	end, { props.selected } :: { any })

	local dim, dimApi = motion.useMotor(0)
	React.useEffect(function()
		dimApi.setTarget(if props.dimmed then 1 else 0, Motion.spring.gentle)
	end, { props.dimmed } :: { any })

	local strokeSpec: Theme.StrokeSpec = if props.selected
		then Theme.strokes.focus
		else Theme.strokes.edge

	local hostProps: { [any]: any } = {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
		BorderSizePixel = 0,
		[React.Event.Activated] = function()
			if props.locked then
				return
			end
			Sound.play("tick", { volume = 0.18 })
			props.onTap(team.id)
		end,
	}

	-- §5 cheap entrance recipe: grid owns the outer button; the inner frame animates.
	return e("TextButton", hostProps, {
		inner = e("Frame", {
			BackgroundColor3 = primary,
			BackgroundTransparency = entrance:map(function(p: number): number
				return Motion.alpha(p)
			end),
			Position = entrance:map(function(p: number): UDim2
				return UDim2.fromOffset(0, math.floor(16 * (1 - p)))
			end),
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
		}, {
			_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.lg) }),
			_grad = e("UIGradient", {
				Rotation = 115,
				Color = ColorSequence.new(primary, Theme.darken(primary, 0.55)),
			}),
			_stroke = e("UIStroke", {
				Color = strokeSpec.color,
				Thickness = strokeSpec.thickness,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Transparency = entrance:map(function(p: number): number
					return Motion.alpha(p, strokeSpec.transparency)
				end),
			}),
			_scale = e("UIScale", { Scale = scale }),
			-- Giant ghost monogram: right-anchored, clipping-safe (no rotation).
			ghost = e("TextLabel", {
				Text = string.upper(team.abbr),
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = secondary,
				TextTransparency = entrance:map(function(p: number): number
					return Motion.alpha(p, GHOST_REST_T)
				end),
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, GHOST_W, 1, 0),
			}, {
				_max = e("UITextSizeConstraint", { MaxTextSize = 72 }),
			}),
			city = e("TextLabel", {
				Text = string.upper(team.city),
				Font = Theme.type.caption.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = ink,
				TextTransparency = entrance:map(function(p: number): number
					return Motion.alpha(p, CITY_REST_T)
				end),
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(Theme.space.lg, 20),
				Size = UDim2.new(1, -(GHOST_W + Theme.space.lg + Theme.space.sm), 0, 14),
			}),
			name = e("TextLabel", {
				Text = team.name,
				Font = Theme.type.h1.font,
				TextSize = Theme.type.h1.size,
				TextColor3 = ink,
				TextTransparency = entrance:map(function(p: number): number
					return Motion.alpha(p)
				end),
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(Theme.space.lg, 36),
				Size = UDim2.new(1, -(GHOST_W + Theme.space.lg + Theme.space.sm), 0, 26),
			}),
			underline = e("Frame", {
				BackgroundColor3 = secondary,
				BackgroundTransparency = entrance:map(function(p: number): number
					return Motion.alpha(p)
				end),
				Position = UDim2.new(0, Theme.space.lg, 1, -(Theme.space.lg - 1)),
				Size = UDim2.fromOffset(40, 3),
				BorderSizePixel = 0,
			}),
			-- Unselected-dim scrim (bindings only; invisible until a selection exists).
			scrim = e("Frame", {
				BackgroundColor3 = Theme.scrim.color,
				BackgroundTransparency = dim:map(function(d: number): number
					return 1 - DIM_STRENGTH * math.clamp(d, 0, 1)
				end),
				Size = UDim2.fromScale(1, 1),
				BorderSizePixel = 0,
				ZIndex = 3,
			}, {
				_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.lg) }),
			}),
		}),
	})
end

-- ---- the screen ----

local function TeamSelect(props: Props)
	local insets = SafeArea.useInsets()
	local viewportW = useViewportWidth()
	local pending = props.pending == true

	local selectedId, setSelectedId = React.useState(nil :: string?)
	local stagger = motion.useStagger("select", { count = #Teams, step = 0.05, span = 0.3 })

	local onTap = React.useCallback(function(teamId: string)
		if pending then
			return -- grid locked while the franchise builds (IXD-14 #1)
		end
		setSelectedId(function(prev: string?): string?
			return if prev == teamId then nil else teamId -- tap again = deselect
		end)
	end, { pending } :: { any })

	local selectedTeam: Teams.TeamIdentity? = nil
	for _, team in Teams do
		if team.id == selectedId then
			selectedTeam = team
			break
		end
	end

	-- Keep the last selection so the ConfirmBar's content survives its slide-out.
	local lastTeamRef = React.useRef(nil :: Teams.TeamIdentity?)
	if selectedTeam then
		lastTeamRef.current = selectedTeam
	end
	local barTeam = selectedTeam or lastTeamRef.current

	local headerH = insets.top + HEADER_H

	local gridChildren: { [string]: any } = {
		_layout = e("UIGridLayout", {
			CellSize = cellSize(viewportW),
			CellPadding = UDim2.fromOffset(Theme.space.lg, Theme.space.md),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		_pad = e("UIPadding", {
			PaddingTop = UDim.new(0, Theme.space.md),
			PaddingLeft = UDim.new(0, Theme.chrome.padX),
			PaddingRight = UDim.new(0, Theme.chrome.padX),
			PaddingBottom = UDim.new(0, Theme.space.xl + CONFIRM_H + insets.bottom),
		}),
	}
	for i, team in Teams do
		gridChildren["team_" .. team.id] = e(TeamCard, {
			team = team,
			entrance = stagger.item(i),
			selected = selectedId == team.id,
			dimmed = selectedId ~= nil and selectedId ~= team.id,
			locked = pending,
			layoutOrder = i,
			onTap = onTap,
		})
	end

	local backProps: { [any]: any } = {
		Text = "‹",
		Font = Theme.type.h1.font,
		TextSize = Theme.type.h1.size,
		TextColor3 = Theme.chalk,
		AutoButtonColor = false,
		BackgroundColor3 = Theme.surface.base,
		Size = UDim2.fromOffset(Theme.size.touchMin, Theme.size.touchMin),
		Position = UDim2.new(
			0,
			Theme.chrome.padX,
			0,
			insets.top + (HEADER_H - Theme.size.touchMin) / 2
		),
		BorderSizePixel = 0,
		[React.Event.Activated] = function()
			Sound.play("tick")
			props.onBack()
		end,
	}

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		header = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, headerH),
			ZIndex = 2,
		}, {
			back = e("TextButton", backProps, {
				_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
				_stroke = e("UIStroke", {
					Color = Theme.strokes.edge.color,
					Transparency = Theme.strokes.edge.transparency,
					Thickness = Theme.strokes.edge.thickness,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			}),
			title = e("TextLabel", {
				Text = "TAKE THE PODIUM",
				Font = Theme.type.h1.font,
				TextSize = Theme.type.h1.size,
				TextColor3 = Theme.chalk,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.new(
					0,
					Theme.chrome.padX + Theme.size.touchMin + Theme.space.md,
					0,
					insets.top
				),
				Size = UDim2.new(
					1,
					-(Theme.chrome.padX * 2 + Theme.size.touchMin + Theme.space.md),
					0,
					HEADER_H
				),
			}),
		}),
		grid = e("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, headerH),
			Size = UDim2.new(1, 0, 1, -headerH),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.line,
			ScrollingDirection = Enum.ScrollingDirection.Y,
		}, gridChildren),
		confirm = e(ConfirmBar, {
			text = if barTeam then "BUILD THE " .. string.upper(barTeam.name) .. " DYNASTY" else "",
			visible = selectedTeam ~= nil,
			pending = pending,
			crest = if barTeam
				then {
					abbr = barTeam.abbr,
					primary = Theme.hex(barTeam.primary),
					secondary = Theme.hex(barTeam.secondary),
				}
				else nil,
			onConfirm = function()
				if selectedId then
					props.onPick(selectedId)
				end
			end,
		}),
	})
end

return TeamSelect
