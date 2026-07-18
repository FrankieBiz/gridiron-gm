--!strict
-- Facilities — the HQ tab: gold-stroked credits banner, then three facility cards with
-- segmented level pips and an UPGRADE verb that beckons when affordable
-- (spec: ui-v2-ixd §4.7 IXD-31; metadata from Shared.Data.Facilities).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)
local FacilitiesData = require(ReplicatedStorage.Shared.Data.Facilities)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)
local Card = require(script.Parent.Parent.components.Card)
local Button = require(script.Parent.Parent.components.Button)
local Badge = require(script.Parent.Parent.components.Badge)
local ProgressBar = require(script.Parent.Parent.components.ProgressBar)
local AnimatedNumber = require(script.Parent.Parent.components.AnimatedNumber)

local e = React.createElement

export type Props = {
	facilities: Franchise.FacilityLevels,
	credits: number,
	upgrading: string?,
	onUpgrade: (key: string) -> (),
}

local BANNER_H = 48
local CARD_H = 148

local function Facilities(props: Props)
	-- Static record → dynamic-key map, so the metadata loop can index by facility key.
	local levels: { [string]: number } = {
		training = props.facilities.training,
		rehab = props.facilities.rehab,
		stadium = props.facilities.stadium,
	}

	local stagger = motion.useStagger("hq", {
		count = #FacilitiesData.list,
		step = 0.06,
		span = 0.3,
		easing = motion.Solver.easeOutBack,
	})

	local cards: { [string]: any } = {
		_layout = e("UIListLayout", {
			Padding = UDim.new(0, Theme.space.md),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		_pad = e("UIPadding", { PaddingBottom = UDim.new(0, Theme.space.xl) }),
	}

	for i, f in FacilitiesData.list do
		local level = levels[f.key] or 1
		local maxed = level >= FacilitiesData.MAX_LEVEL
		local cost = FacilitiesData.costForNext(level)
		local affordable = not maxed and props.credits >= cost
		local entrance = stagger.item(i)

		local body: { [string]: any } = {
			pad = e("UIPadding", {
				PaddingTop = UDim.new(0, Theme.space.md),
				PaddingBottom = UDim.new(0, Theme.space.md),
				PaddingLeft = UDim.new(0, Theme.space.md),
				PaddingRight = UDim.new(0, Theme.space.md),
			}),
			icon = e("TextLabel", {
				Text = f.icon,
				Font = Theme.font.body,
				TextSize = 24,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(32, 26),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			name = e("TextLabel", {
				Text = string.upper(f.name),
				Font = Theme.type.h2.font,
				TextSize = Theme.type.h2.size,
				TextColor3 = Theme.text.primary,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(40, 2),
				Size = UDim2.new(1, -140, 0, 22),
			}),
			lv = e("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Position = UDim2.new(1, 0, 0, 2),
				Size = UDim2.fromOffset(0, Theme.size.chipH),
			}, {
				badge = e(Badge, {
					text = `LV {level}`,
					variant = (if maxed then "gold" else "neutral") :: Badge.Variant,
				}),
			}),
			effect = e("TextLabel", {
				Text = f.effect,
				Font = Theme.type.caption.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = Theme.text.secondary,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 30),
				Size = UDim2.new(1, 0, 0, 26),
			}),
			pips = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 62),
				Size = UDim2.new(1, 0, 0, 10),
			}, {
				bar = e(ProgressBar, {
					value = level,
					max = FacilitiesData.MAX_LEVEL,
					segments = FacilitiesData.MAX_LEVEL,
					height = 10,
				}),
			}),
		}

		if maxed then
			body.maxedBadge = e("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 1),
				AutomaticSize = Enum.AutomaticSize.X,
				Position = UDim2.new(1, 0, 1, -8),
				Size = UDim2.fromOffset(0, Theme.size.chipH),
			}, {
				badge = e(Badge, { text = "MAXED OUT", variant = "gold" :: Badge.Variant }),
			})
		else
			body.cost = e("TextLabel", {
				Text = if affordable
					then string.format("COST %d 🪙", cost)
					else string.format("NEED %d MORE", cost - props.credits),
				Font = Theme.font.mono,
				TextSize = Theme.type.monoSm.size,
				TextColor3 = if affordable then Theme.text.secondary else Theme.gold,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 0, 1, -12),
				Size = UDim2.new(1, -152, 0, 16),
			})
			body.upgrade = e("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, 0, 1, 0),
				Size = UDim2.fromOffset(140, 40),
			}, {
				btn = e(Button, {
					text = "UPGRADE",
					onActivated = function()
						props.onUpgrade(f.key)
					end,
					disabled = not affordable,
					loading = props.upgrading == f.key,
					pulse = affordable,
					size = UDim2.fromScale(1, 1),
				}),
			})
		end

		cards["f_" .. f.key] = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, CARD_H),
			LayoutOrder = i,
		}, {
			slide = e("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Position = entrance:map(function(p: number): UDim2
					return UDim2.fromOffset(0, math.floor(16 * (1 - p)))
				end),
			}, {
				card = e(Card, {
					variant = "raised" :: Card.Variant,
					size = UDim2.fromScale(1, 1),
					children = body,
				}),
			}),
		})
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
		banner = e("Frame", {
			BackgroundColor3 = Theme.surface.raised,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, BANNER_H),
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
			grad = e("UIGradient", { Rotation = 90, Color = Theme.grad.raised }),
			stroke = e("UIStroke", {
				Color = Theme.gold,
				Transparency = 0.45,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			coin = e("TextLabel", {
				Text = "🪙",
				Font = Theme.font.body,
				TextSize = 20,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(Theme.space.md, 0),
				Size = UDim2.new(0, 24, 1, 0),
			}),
			amount = e(AnimatedNumber, {
				value = props.credits,
				textColor3 = Theme.gold,
				textSize = Theme.type.h1.size,
				textXAlignment = Enum.TextXAlignment.Left,
				position = UDim2.fromOffset(Theme.space.md + 30, 0),
				size = UDim2.new(0, 110, 1, 0),
			}),
			caption = e("TextLabel", {
				Text = "COACHING CREDITS",
				Font = Theme.type.eyebrow.font,
				TextSize = Theme.type.eyebrow.size,
				TextColor3 = Theme.text.tertiary,
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -Theme.space.md, 0, 0),
				Size = UDim2.new(0, 140, 1, 0),
			}),
		}),
		scroll = e("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, BANNER_H + Theme.space.md),
			Size = UDim2.new(1, 0, 1, -BANNER_H - Theme.space.md),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.line,
		}, cards),
	})
end

return Facilities
