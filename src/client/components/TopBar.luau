--!strict
-- Persistent header: team-gradient bar (safe-area aware — background bleeds behind the
-- Roblox topbar, content sits below it), crest + identity, phase badge, record badge,
-- credits pill with count-up + gold flash, and the refresh hairline.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local SafeArea = require(script.Parent.Parent.SafeArea)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)
local motion = require(script.Parent.Parent.motion)
local TeamCrest = require(script.Parent.TeamCrest)
local PhaseBadge = require(script.Parent.PhaseBadge)
local AnimatedNumber = require(script.Parent.AnimatedNumber)

local e = React.createElement

export type Props = {
	team: Franchise.LeagueTeam,
	record: Franchise.TeamRecord,
	season: Franchise.SeasonInfo,
	credits: number,
	refreshing: boolean?,
}

local function usePrevious(value: number): number?
	local ref = React.useRef(nil :: number?)
	React.useEffect(function()
		ref.current = value
	end, { value } :: { any })
	return ref.current
end

local function TopBar(props: Props)
	local insets = SafeArea.useInsets()
	local tp = Theme.withTeam(props.team.primary, props.team.secondary)
	local totalH = insets.top + Theme.chrome.topBarH

	-- Credits pill pulse + gold flash on change.
	local pillScale, pillApi = motion.useMotor(1)
	local flash, flashApi = motion.useMotor(0)
	local prevCredits = usePrevious(props.credits)
	React.useEffect(function()
		if prevCredits ~= nil and prevCredits ~= props.credits then
			pillApi.snap(1)
			pillApi.impulse(3.5)
			flashApi.snap(1)
			flashApi.setTarget(0, motion.Motion.spring.gentle)
		end
	end, { props.credits } :: { any })

	-- Refresh hairline sweep (alive only while refreshing).
	local sweep = motion.usePulse({
		period = 1.1,
		waveform = "sweep",
		active = 1.1,
		enabled = props.refreshing == true,
	})

	local phaseText: string
	if props.season.phase == "regular" then
		phaseText = string.format("WEEK %d", props.season.week)
	elseif props.season.phase == "playoffs" then
		phaseText = "PLAYOFFS"
	else
		phaseText = "OFFSEASON"
	end

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, totalH),
		BorderSizePixel = 0,
		ZIndex = Theme.z.chrome,
	}, {
		_grad = e("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(tp.barTop, tp.barBottom),
		}),
		_accent = e("Frame", {
			BackgroundColor3 = tp.accent,
			Size = UDim2.new(1, 0, 0, 3),
			Position = UDim2.new(0, 0, 1, -3),
			BorderSizePixel = 0,
			ZIndex = Theme.z.chrome + 1,
		}),
		_hairline = if props.refreshing
			then e("Frame", {
				BackgroundColor3 = Theme.flag,
				AnchorPoint = Vector2.new(0, 0),
				Position = sweep:map(function(p: number): UDim2
					return UDim2.new(-0.3 + 1.3 * p, 0, 1, 0)
				end),
				Size = UDim2.new(0.3, 0, 0, 2),
				BorderSizePixel = 0,
				ZIndex = Theme.z.chrome + 2,
			})
			else nil,
		_content = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, insets.top),
			Size = UDim2.new(1, 0, 0, Theme.chrome.topBarH),
			ZIndex = Theme.z.chrome + 1,
		}, {
			crest = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(Theme.chrome.padX, (Theme.chrome.topBarH - 40) // 2),
				Size = UDim2.fromOffset(40, 40),
			}, {
				c = e(TeamCrest, {
					abbr = props.team.abbr,
					primary = tp.primary,
					secondary = tp.secondary,
					size = 40,
				}),
			}),
			name = e("TextLabel", {
				Text = string.upper(props.team.city .. " " .. props.team.name),
				Font = Theme.type.h1.font,
				TextSize = Theme.type.h2.size,
				TextColor3 = tp.barInk,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(Theme.chrome.padX + 48, 12),
				Size = UDim2.new(1, -(Theme.chrome.padX + 48) - 130, 0, 20),
			}),
			sub = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(Theme.chrome.padX + 48, 36),
				Size = UDim2.new(1, -(Theme.chrome.padX + 48) - 130, 0, 20),
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, Theme.space.sm),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				phase = e(PhaseBadge, {
					phase = props.season.phase :: string,
					text = string.format("Y%d · %s", props.season.year, phaseText),
					layoutOrder = 1,
				}),
				record = e("TextLabel", {
					Text = string.format("%d–%d", props.record.wins, props.record.losses),
					Font = Theme.font.mono,
					TextSize = Theme.type.monoSm.size,
					TextColor3 = tp.barInk,
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 20),
					LayoutOrder = 2,
				}),
			}),
			pill = e("Frame", {
				BackgroundColor3 = Theme.darken(tp.primary, 0.6),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -Theme.chrome.padX, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 36),
				BorderSizePixel = 0,
			}, {
				scale = e("UIScale", { Scale = pillScale }),
				corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				stroke = e("UIStroke", {
					Color = Theme.gold,
					Thickness = 1,
					Transparency = flash:map(function(f: number): number
						return 0.55 - 0.45 * f
					end),
				}),
				pad = e("UIPadding", {
					PaddingLeft = UDim.new(0, 12),
					PaddingRight = UDim.new(0, 12),
				}),
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				coin = e("TextLabel", {
					Text = "🪙",
					Font = Theme.font.body,
					TextSize = 14,
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(18, 36),
					LayoutOrder = 1,
				}),
				amount = e(AnimatedNumber, {
					value = props.credits,
					textColor3 = Theme.gold,
					textSize = Theme.type.mono.size,
					textXAlignment = Enum.TextXAlignment.Left,
					size = UDim2.fromOffset(44, 36),
					layoutOrder = 2,
				}),
			}),
		}),
	})
end

return TopBar
