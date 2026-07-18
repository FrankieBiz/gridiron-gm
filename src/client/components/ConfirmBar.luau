--!strict
-- Bottom-anchored confirmation bar (TeamSelect, CareerDecision): slides up when a
-- selection exists, giving big decisions a deliberate confirm step.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local SafeArea = require(script.Parent.Parent.SafeArea)
local motion = require(script.Parent.Parent.motion)
local Button = require(script.Parent.Button)
local TeamCrest = require(script.Parent.TeamCrest)

local e = React.createElement

export type CrestSpec = { abbr: string, primary: Color3, secondary: Color3 }

export type Props = {
	text: string,
	visible: boolean,
	onConfirm: () -> (),
	crest: CrestSpec?,
	pending: boolean?,
	variant: Button.Variant?,
}

local function ConfirmBar(props: Props)
	local insets = SafeArea.useInsets()
	local height = 72 + math.max(insets.bottom, Theme.space.sm)

	local slide, slideApi = motion.useMotor(if props.visible then 0 else 1)
	React.useEffect(function()
		slideApi.setTarget(if props.visible then 0 else 1, motion.Motion.spring.slide)
	end, { props.visible } :: { any })

	return e("Frame", {
		BackgroundColor3 = Theme.bg.base,
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.new(1, 0, 0, height),
		Position = slide:map(function(p: number): UDim2
			return UDim2.new(0, 0, 1, math.floor(p * (height + 8)))
		end),
		BorderSizePixel = 0,
		ZIndex = Theme.z.chrome,
	}, {
		_topline = e("Frame", {
			BackgroundColor3 = Theme.border.base,
			Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0,
		}),
		_pad = e("UIPadding", {
			PaddingTop = UDim.new(0, Theme.space.md),
			PaddingLeft = UDim.new(0, Theme.chrome.padX),
			PaddingRight = UDim.new(0, Theme.chrome.padX),
			PaddingBottom = UDim.new(0, math.max(insets.bottom, Theme.space.sm)),
		}),
		_layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, Theme.space.md),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		_crest = if props.crest
			then e(TeamCrest, {
				abbr = props.crest.abbr,
				primary = props.crest.primary,
				secondary = props.crest.secondary,
				size = 48,
				layoutOrder = 1,
			})
			else nil,
		_btnWrap = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(
				1,
				if props.crest then -48 - Theme.space.md else 0,
				0,
				Theme.size.buttonH
			),
			LayoutOrder = 2,
		}, {
			_max = e("UISizeConstraint", {
				MaxSize = Vector2.new(Theme.chrome.contentMaxW, math.huge),
			}),
			btn = e(Button, {
				text = props.text,
				variant = props.variant,
				onActivated = props.onConfirm,
				loading = props.pending,
				size = UDim2.new(1, 0, 0, Theme.size.buttonH),
			}),
		}),
	})
end

return ConfirmBar
