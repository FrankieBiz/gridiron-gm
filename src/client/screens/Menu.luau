--!strict
-- Title screen — the first impression. Centered wordmark column over a yard-lined field
-- gradient, hero entrance choreography (ui-v2-ixd §4.1 / ui-v2-motion §6 Menu row), and
-- the primary CTA heartbeat. Screens never call remotes: NEW/CONTINUE bubble up to App
-- (the START OVER? confirm modal is App's job, per R20).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local SafeArea = require(script.Parent.Parent.SafeArea)
local motion = require(script.Parent.Parent.motion)
local Button = require(script.Parent.Parent.components.Button)

local Motion = motion.Motion
local Solver = motion.Solver

local e = React.createElement

type Props = {
	hasFranchise: boolean,
	continueContext: { teamName: string, year: number, wins: number, losses: number }?,
	resuming: boolean?,
	onNew: () -> (),
	onContinue: () -> (),
}

local YARD_LINE_COUNT = 5
local WORDMARK_MAX = 64 -- sanctioned TextScaled exception (ui-v2-master non-negotiables)
local ACCENT_W = 88
local CTA_MAX_W = 320
local BTN_H = 52

-- "A FRONT OFFICE DYNASTY" letter-spaced via spaces (IXD-25 kicker treatment).
local function letterSpace(s: string): string
	local out = s:gsub("(.)", "%1 ")
	return (out:gsub("%s+$", ""))
end

-- Static loop-generated yard lines (M2 recipe, Menu brightness override).
local function yardLines(): { [string]: any }
	local lines: { [string]: any } = {}
	for i = 1, YARD_LINE_COUNT do
		lines["line_" .. i] = e("Frame", {
			BackgroundColor3 = Theme.line,
			BackgroundTransparency = 0.35,
			Size = UDim2.new(0, 2, 1, 0),
			Position = UDim2.fromScale(i / (YARD_LINE_COUNT + 1), 0),
			BorderSizePixel = 0,
		})
	end
	return lines
end

local function Menu(props: Props)
	local insets = SafeArea.useInsets()
	local clock = motion.useChoreo("menu", 0.9)

	-- Windowed entrance maps (one seconds clock drives every element — no setState).
	local kickerFade = clock:map(function(t: number): number
		return Motion.alpha(Motion.window(t, 0, 0.18))
	end)
	local accentSize = clock:map(function(t: number): UDim2
		local p = Motion.window(t, 0.08, 0.22, Solver.easeOutQuint)
		return UDim2.fromOffset(math.floor(ACCENT_W * p), 3)
	end)
	local gridironOffset = clock:map(function(t: number): UDim2
		local p = Motion.window(t, 0.14, 0.28, Solver.easeOutQuint)
		return UDim2.fromOffset(math.floor(-30 * (1 - p)), 0)
	end)
	local gridironFade = clock:map(function(t: number): number
		return Motion.alpha(Motion.window(t, 0.14, 0.28, Solver.easeOutQuint))
	end)
	local gmOffset = clock:map(function(t: number): UDim2
		local p = Motion.window(t, 0.22, 0.28, Solver.easeOutQuint)
		return UDim2.fromOffset(math.floor(-30 * (1 - p)), 0)
	end)
	local gmFade = clock:map(function(t: number): number
		return Motion.alpha(Motion.window(t, 0.22, 0.28, Solver.easeOutQuint))
	end)
	local taglineFade = clock:map(function(t: number): number
		return Motion.alpha(Motion.window(t, 0.30, 0.25))
	end)
	local ctaPosition = clock:map(function(t: number): UDim2
		local p = Motion.window(t, 0.38, 0.37, Solver.easeOutBack)
		return UDim2.new(0.5, 0, 0, math.floor(18 * (1 - p)))
	end)
	local footerFade = clock:map(function(t: number): number
		return Motion.alpha(Motion.window(t, 0.5, 0.3), 0.4)
	end)

	-- CTA stack (conditional children built imperatively — house style).
	local ctaChildren: { [string]: any } = {
		_layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, Theme.space.sm),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		_max = e("UISizeConstraint", { MaxSize = Vector2.new(CTA_MAX_W, math.huge) }),
	}
	local ctaH: number
	if props.hasFranchise then
		ctaChildren.continueBtn = e(Button, {
			text = "CONTINUE DYNASTY",
			onActivated = props.onContinue,
			variant = "primary",
			pulse = true,
			loading = props.resuming,
			size = UDim2.new(1, 0, 0, BTN_H),
			layoutOrder = 1,
		})
		local ctx = props.continueContext
		if ctx then
			-- Text-only context chip (Menu carries no team colors — no crest here).
			ctaChildren.contextChip = e("TextLabel", {
				Text = string.format(
					"%s · SEASON %d · %d–%d",
					ctx.teamName,
					ctx.year,
					ctx.wins,
					ctx.losses
				),
				Font = Theme.type.caption.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = Theme.chalkSoft,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				LayoutOrder = 2,
			})
		end
		ctaChildren.newBtn = e(Button, {
			text = "NEW FRANCHISE",
			onActivated = props.onNew,
			variant = "ghost",
			size = UDim2.new(1, 0, 0, BTN_H),
			layoutOrder = 3,
		})
		ctaH = BTN_H * 2 + 18 + Theme.space.sm * 2
	else
		ctaChildren.startBtn = e(Button, {
			text = "START YOUR DYNASTY",
			onActivated = props.onNew,
			variant = "primary",
			pulse = true,
			size = UDim2.new(1, 0, 0, BTN_H),
			layoutOrder = 1,
		})
		ctaH = BTN_H
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.field,
		BorderSizePixel = 0,
	}, {
		_grad = e("UIGradient", { Rotation = 90, Color = Theme.grad.hero }),
		stripes = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ClipsDescendants = true,
			ZIndex = 1,
		}, yardLines()),
		column = e("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.44),
			Size = UDim2.new(1, -Theme.chrome.padX * 2, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 2,
		}, {
			_max = e("UISizeConstraint", { MaxSize = Vector2.new(560, math.huge) }),
			_layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, Theme.space.sm),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			kicker = e("TextLabel", {
				Text = letterSpace("A FRONT OFFICE DYNASTY"),
				Font = Theme.type.caption.font,
				TextSize = Theme.type.caption.size,
				TextColor3 = Theme.chalkSoft,
				TextTransparency = kickerFade,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				LayoutOrder = 1,
			}),
			accentBar = e("Frame", {
				BackgroundColor3 = Theme.flag,
				Size = accentSize,
				BorderSizePixel = 0,
				LayoutOrder = 2,
			}),
			gridironRow = e("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 56),
				LayoutOrder = 3,
			}, {
				label = e("TextLabel", {
					Text = "GRIDIRON",
					Font = Theme.font.display,
					TextScaled = true,
					TextColor3 = Theme.chalk,
					TextTransparency = gridironFade,
					BackgroundTransparency = 1,
					Position = gridironOffset,
					Size = UDim2.fromScale(1, 1),
				}, {
					_max = e("UITextSizeConstraint", { MaxTextSize = WORDMARK_MAX }),
				}),
			}),
			gmRow = e("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 56),
				LayoutOrder = 4,
			}, {
				label = e("TextLabel", {
					Text = "GM",
					Font = Theme.font.display,
					TextScaled = true,
					TextColor3 = Theme.flag,
					TextTransparency = gmFade,
					BackgroundTransparency = 1,
					Position = gmOffset,
					Size = UDim2.fromScale(1, 1),
				}, {
					_max = e("UITextSizeConstraint", { MaxTextSize = WORDMARK_MAX }),
				}),
			}),
			tagline = e("TextLabel", {
				Text = "Call the shots. Build the dynasty.",
				Font = Theme.type.body.font,
				TextSize = Theme.type.body.size,
				TextColor3 = Theme.chalkSoft,
				TextTransparency = taglineFade,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				LayoutOrder = 5,
			}),
			spacer = e("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20),
				LayoutOrder = 6,
			}),
			ctaRow = e("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, ctaH),
				LayoutOrder = 7,
			}, {
				inner = e("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = ctaPosition,
					Size = UDim2.fromScale(1, 1),
				}, ctaChildren),
			}),
		}),
		footer = e("TextLabel", {
			Text = "v1 · a two-person studio game",
			Font = Theme.type.caption.font,
			TextSize = Theme.type.caption.size,
			TextColor3 = Theme.chalkSoft,
			TextTransparency = footerFade,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -(insets.bottom + 12)),
			Size = UDim2.new(1, -Theme.chrome.padX * 2, 0, 14),
			ZIndex = 2,
		}),
	})
end

return Menu
