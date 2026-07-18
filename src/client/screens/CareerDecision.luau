--!strict
-- CareerDecision (IXD-34): the season verdict. Fixed hero (FIRED / CHAMPIONS! / SEASON
-- REVIEW) on a 1.6s master clock, league honors, then selectable job offers with a
-- deliberate select-then-confirm ceremony. App owns the ChooseJob remote via onChoose.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)

local Theme = require(script.Parent.Parent.Theme)
local SafeArea = require(script.Parent.Parent.SafeArea)
local motion = require(script.Parent.Parent.motion)
local Badge = require(script.Parent.Parent.components.Badge)
local Card = require(script.Parent.Parent.components.Card)
local ConfirmBar = require(script.Parent.Parent.components.ConfirmBar)
local SectionHeader = require(script.Parent.Parent.components.SectionHeader)
local TeamCrest = require(script.Parent.Parent.components.TeamCrest)

local e = React.createElement

local Motion = motion.Motion
local Solver = motion.Solver

export type Props = {
	report: Franchise.CareerReport,
	offers: { Franchise.JobOffer },
	awards: Franchise.SeasonAwards,
	team: Franchise.LeagueTeam,
	teams: { Franchise.TeamSummary },
	prestige: number,
	choosing: boolean?,
	onChoose: (teamId: string) -> (),
}

local HERO_H = 140
local OFFER_START = 0.8
local OFFER_STEP = 0.12

local function tagVariant(tag: string): Badge.Variant
	if tag == "WIN NOW" then
		return "brand"
	elseif tag == "PLAYOFF PUSH" then
		return "gold"
	end
	return "neutral"
end

-- Crest identity for an offer: real team summary if we can resolve it, otherwise a
-- first-letter monogram in Theme colors.
local function crestFor(
	teamId: string?,
	fallbackName: string,
	teams: { Franchise.TeamSummary }
): (string, Color3, Color3)
	if teamId then
		for _, t in teams do
			if t.id == teamId then
				local pal = Theme.withTeam(t.primary, t.secondary)
				return t.abbr, pal.primary, pal.secondary
			end
		end
	end
	return string.upper(string.sub(fallbackName, 1, 1)), Theme.surface.raised, Theme.flag
end

type OfferCardProps = {
	layoutOrder: number,
	clock: React.Binding<number>,
	start: number,
	abbr: string,
	crestPrimary: Color3,
	crestSecondary: Color3,
	title: string,
	sub: string,
	prestige: number,
	tagText: string,
	tagVariant: Badge.Variant,
	selected: boolean,
	dimmed: boolean,
	onTap: () -> (),
}

local function OfferCard(props: OfferCardProps)
	-- Selection ceremony: non-selected cards ease behind a dim veil.
	local dim = motion.useSpring(if props.dimmed then 1 else 0, Motion.spring.gentle)
	local start = props.start

	local stars: { [string]: any } = {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for i = 1, 5 do
		stars["s" .. i] = e("TextLabel", {
			Text = "★",
			Font = Theme.font.bold,
			TextSize = 13,
			TextColor3 = if i <= props.prestige then Theme.gold else Theme.text.disabled,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(14, 14),
			LayoutOrder = i,
		})
	end

	return e(Card, {
		size = UDim2.new(1, 0, 0, 96),
		layoutOrder = props.layoutOrder,
		selectable = true,
		selected = props.selected,
		onActivated = props.onTap,
		children = {
			crestWrap = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 16),
				Size = UDim2.fromOffset(32, 32),
			}, {
				crest = e(TeamCrest, {
					abbr = props.abbr,
					primary = props.crestPrimary,
					secondary = props.crestSecondary,
					size = 32,
				}),
			}),
			title = e("TextLabel", {
				Text = props.title,
				Font = Theme.type.h2.font,
				TextSize = Theme.type.h2.size,
				TextColor3 = Theme.text.primary,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(58, 14),
				Size = UDim2.new(1, -58 - 160, 0, 20),
			}),
			stars = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(58, 38),
				Size = UDim2.fromOffset(80, 14),
			}, stars),
			tagWrap = e("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -14, 0, 14),
				Size = UDim2.fromOffset(150, 24),
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				tag = e(Badge, { text = props.tagText, variant = props.tagVariant }),
			}),
			sub = e("TextLabel", {
				Text = props.sub,
				Font = Theme.type.caption.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = Theme.text.secondary,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(58, 62),
				Size = UDim2.new(1, -58 - 14, 0, 16),
			}),
			dimVeil = e("Frame", {
				BackgroundColor3 = Theme.bg.base,
				BackgroundTransparency = dim:map(function(p: number): number
					return 1 - 0.45 * p
				end),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 8,
				BorderSizePixel = 0,
			}, { corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.lg) }) }),
			-- Entrance: card fades in from the page background on the master clock.
			enterVeil = e("Frame", {
				BackgroundColor3 = Theme.field,
				BackgroundTransparency = props.clock:map(function(t: number): number
					return Motion.window(t, start, 0.3)
				end),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 10,
				BorderSizePixel = 0,
			}, { corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.lg) }) }),
		},
	})
end

local function CareerDecision(props: Props)
	local insets = SafeArea.useInsets()
	local r = props.report
	local clock = motion.useChoreo("career", 1.6)

	local selected, setSelected = React.useState(nil :: string?)
	local stayId = props.team.id

	local headline: string
	local headlineColor: Color3
	if r.fired then
		headline = "YOU'VE BEEN FIRED"
		headlineColor = Theme.semantic.danger
	elseif r.champion then
		headline = "CHAMPIONS!"
		headlineColor = Theme.gold
	else
		headline = "SEASON REVIEW"
		headlineColor = Theme.text.primary
	end

	local function toggle(teamId: string)
		setSelected(function(prev: string?): string?
			return if prev == teamId then nil else teamId
		end)
	end

	local heroTop = insets.top + Theme.space.md
	local dimOthers = selected ~= nil

	-- ---- scroll content ----
	local content: { [string]: any } = {
		layout = e("UIListLayout", {
			Padding = UDim.new(0, Theme.space.md),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, Theme.chrome.padX),
			PaddingRight = UDim.new(0, Theme.chrome.padX),
			PaddingBottom = UDim.new(0, Theme.space.xl + 96),
		}),
	}

	if #props.awards.majors > 0 then
		local honorRows: { [string]: any } = {
			layout = e("UIListLayout", {
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			pad = e("UIPadding", {
				PaddingTop = UDim.new(0, Theme.space.sm),
				PaddingLeft = UDim.new(0, Theme.space.md),
				PaddingRight = UDim.new(0, Theme.space.md),
			}),
			header = e(
				SectionHeader,
				{ text = "LEAGUE HONORS", accent = Theme.gold, layoutOrder = 1 }
			),
		}
		for i, a in props.awards.majors do
			honorRows["aw_" .. a.title] = e("TextLabel", {
				Text = string.format(
					"%s · %s · %s · %s",
					a.title,
					a.name,
					a.position,
					a.teamName
				),
				Font = Theme.type.caption.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = Theme.text.secondary,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = 1 + i,
			})
		end
		content.honors = e(Card, {
			size = UDim2.new(1, 0, 0, 44 + #props.awards.majors * 22),
			layoutOrder = 1,
			children = {
				rows = e("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
				}, honorRows),
				enterVeil = e("Frame", {
					BackgroundColor3 = Theme.field,
					BackgroundTransparency = clock:map(function(t: number): number
						return Motion.window(t, 0.9, 0.3)
					end),
					Size = UDim2.fromScale(1, 1),
					ZIndex = 10,
					BorderSizePixel = 0,
				}, { corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.lg) }) }),
			},
		})
	end

	content.tableHeader = e(SectionHeader, { text = "ON THE TABLE", layoutOrder = 2 })

	for i, offer in props.offers do
		local abbr, cPrimary, cSecondary = crestFor(offer.teamId, offer.name, props.teams)
		content["offer_" .. offer.teamId] = e(OfferCard, {
			layoutOrder = 2 + i,
			clock = clock,
			start = OFFER_START + (i - 1) * OFFER_STEP,
			abbr = abbr,
			crestPrimary = cPrimary,
			crestSecondary = cSecondary,
			title = offer.city .. " " .. offer.name,
			sub = string.format("Owner wants %d+ wins", offer.expectedWins),
			prestige = offer.prestige,
			tagText = offer.tag,
			tagVariant = tagVariant(offer.tag),
			selected = selected == offer.teamId,
			dimmed = dimOthers and selected ~= offer.teamId,
			onTap = function()
				toggle(offer.teamId)
			end,
		})
	end

	local teamPal = Theme.withTeam(props.team.primary, props.team.secondary)
	local stayStart = OFFER_START + #props.offers * OFFER_STEP
	if not r.fired then
		content.stay = e(OfferCard, {
			layoutOrder = 40,
			clock = clock,
			start = stayStart,
			abbr = props.team.abbr,
			crestPrimary = teamPal.primary,
			crestSecondary = teamPal.secondary,
			title = props.team.city .. " " .. props.team.name,
			sub = string.format("Owner wants %d+ wins", r.expectedWins),
			prestige = props.prestige,
			tagText = "STAY",
			tagVariant = "success" :: Badge.Variant,
			selected = selected == stayId,
			dimmed = dimOthers and selected ~= stayId,
			onTap = function()
				toggle(stayId)
			end,
		})
	elseif #props.offers == 0 then
		-- Safety net: fired with nowhere to go — the owner grudgingly keeps you.
		content.reconsider = e(OfferCard, {
			layoutOrder = 40,
			clock = clock,
			start = stayStart,
			abbr = props.team.abbr,
			crestPrimary = teamPal.primary,
			crestSecondary = teamPal.secondary,
			title = "OWNER RECONSIDERS",
			sub = "One more year. Don't waste it.",
			prestige = props.prestige,
			tagText = "STAY",
			tagVariant = "success" :: Badge.Variant,
			selected = selected == stayId,
			dimmed = dimOthers and selected ~= stayId,
			onTap = function()
				toggle(stayId)
			end,
		})
	end

	-- ---- confirm bar ----
	local confirmText = ""
	local crest: ConfirmBar.CrestSpec? = nil
	if selected == stayId then
		confirmText = "RUN IT BACK"
		crest = { abbr = props.team.abbr, primary = teamPal.primary, secondary = teamPal.secondary }
	elseif selected ~= nil then
		for _, offer in props.offers do
			if offer.teamId == selected then
				confirmText = string.format("TAKE THE %s JOB", string.upper(offer.name))
				local abbr, cPrimary, cSecondary = crestFor(offer.teamId, offer.name, props.teams)
				crest = { abbr = abbr, primary = cPrimary, secondary = cSecondary }
				break
			end
		end
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		-- FIRED treatment: the whole screen tints flagDeep before you read a word.
		tint = if r.fired
			then e("Frame", {
				BackgroundColor3 = Theme.flagDeep,
				BackgroundTransparency = clock:map(function(t: number): number
					return 1 - 0.3 * Motion.window(t, 0, 0.5)
				end),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 1,
				BorderSizePixel = 0,
			}, {
				grad = e("UIGradient", {
					Rotation = 90,
					Transparency = NumberSequence.new(0.2, 1),
				}),
			})
			else nil,
		hero = e(Card, {
			variant = if r.champion then "highlight" :: Card.Variant else nil,
			size = UDim2.new(1, -Theme.chrome.padX * 2, 0, HERO_H),
			position = UDim2.fromOffset(Theme.chrome.padX, heroTop),
			zIndex = 2,
			children = {
				scaleFx = e("UIScale", {
					Scale = clock:map(function(t: number): number
						local p = Motion.window(t, 0, 0.35, Solver.easeOutQuint)
						return 1.06 - 0.06 * p
					end),
				}),
				headline = e("TextLabel", {
					Text = headline,
					Font = Theme.type.display.font,
					TextScaled = true,
					TextColor3 = headlineColor,
					TextTransparency = clock:map(function(t: number): number
						return Motion.alpha(Motion.window(t, 0, 0.35))
					end),
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(0, 14),
					Size = UDim2.new(1, 0, 0, 36),
				}, {
					max = e("UITextSizeConstraint", {
						MaxTextSize = Theme.type.display.maxSize :: number,
					}),
				}),
				subline = e("TextLabel", {
					Text = string.format(
						"Owner wanted %d+. You won %d.",
						r.expectedWins,
						r.actualWins
					),
					Font = Theme.type.body.font,
					TextSize = Theme.type.body.size,
					TextColor3 = Theme.text.primary,
					TextTransparency = clock:map(function(t: number): number
						return Motion.alpha(Motion.window(t, 0.35, 0.3))
					end),
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(0, 56),
					Size = UDim2.new(1, 0, 0, 18),
				}),
				verdict = e("TextLabel", {
					Text = if r.met then "Expectations met." else "Fell short.",
					Font = Theme.type.caption.font,
					TextSize = Theme.type.caption.size,
					TextColor3 = Theme.text.secondary,
					TextTransparency = clock:map(function(t: number): number
						return Motion.alpha(Motion.window(t, 0.45, 0.3))
					end),
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(0, 76),
					Size = UDim2.new(1, 0, 0, 16),
				}),
				-- Rep-delta chip pops at ~0.7s.
				repWrap = e("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 100),
					Size = UDim2.fromOffset(140, 24),
				}, {
					scale = e("UIScale", {
						Scale = clock:map(function(t: number): number
							return Motion.window(t, 0.7, 0.25, Solver.easeOutBack)
						end),
					}),
					layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					badge = e(Badge, {
						text = string.format("%+d REP", r.repDelta),
						variant = "outline" :: Badge.Variant,
						color = Theme.deltaColor(r.repDelta),
					}),
				}),
			},
		}),
		scroll = e("ScrollingFrame", {
			Position = UDim2.fromOffset(0, heroTop + HERO_H + Theme.space.md),
			Size = UDim2.new(1, 0, 1, -(heroTop + HERO_H + Theme.space.md)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.line,
			ZIndex = 2,
		}, content),
		confirm = e(ConfirmBar, {
			text = confirmText,
			visible = selected ~= nil,
			pending = props.choosing,
			crest = crest,
			onConfirm = function()
				if selected then
					props.onChoose(selected)
				end
			end,
		}),
	})
end

return CareerDecision
