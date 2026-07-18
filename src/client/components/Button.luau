--!strict
-- Button v2: four skinned variants with spring press/hover/disabled states, loading
-- spinner, optional heartbeat pulse for the screen's main verb, and wired click sfx.
-- AutoButtonColor is off — we own every state (spec: ui-v2-visual §8.1, ui-v2-motion §7.1).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Sound = require(script.Parent.Parent.Sound)
local motion = require(script.Parent.Parent.motion)
local Spinner = require(script.Parent.Spinner)

local e = React.createElement

export type Variant = "primary" | "secondary" | "ghost" | "danger"

export type Props = {
	text: string,
	onActivated: () -> (),
	variant: Variant?, -- default "primary"
	size: UDim2?,
	layoutOrder: number?,
	disabled: boolean?,
	loading: boolean?, -- swaps label for a spinner, blocks input
	pulse: boolean?, -- heartbeat stroke for the screen's main verb
	sfx: string?, -- default "click"; "" silences
	textColor: Color3?,
	zIndex: number?,
}

type Skin = {
	fill: Color3,
	grad: ColorSequence?,
	hoverGrad: ColorSequence?,
	pressGrad: ColorSequence?,
	hoverFill: Color3?,
	pressFill: Color3?,
	ink: Color3,
	strokeColor: Color3,
	strokeT: number,
	transparentFill: boolean?,
}

local WHITE = Color3.fromRGB(255, 255, 255)

local SKINS: { [Variant]: Skin } = {
	primary = {
		fill = WHITE,
		grad = Theme.grad.primaryBtn,
		hoverGrad = ColorSequence.new(Theme.brand.glow, Theme.flag),
		pressGrad = ColorSequence.new(Theme.flagDeep, Color3.fromRGB(146, 51, 15)),
		ink = Theme.chalk,
		strokeColor = Theme.stroke,
		strokeT = 0.82,
	},
	secondary = {
		fill = Theme.surface.raised,
		hoverFill = Theme.alpha(Theme.chalk, 0.06, Theme.panel),
		pressFill = Theme.darken(Theme.panel, 0.18),
		ink = Theme.chalk,
		strokeColor = Theme.stroke,
		strokeT = 0.82,
	},
	ghost = {
		fill = WHITE,
		transparentFill = true,
		ink = Theme.text.secondary,
		strokeColor = Theme.stroke,
		strokeT = 0.86,
	},
	danger = {
		fill = WHITE,
		grad = Theme.grad.dangerBtn,
		hoverGrad = ColorSequence.new(Color3.fromRGB(227, 98, 98), Theme.semantic.danger),
		pressGrad = ColorSequence.new(Color3.fromRGB(182, 57, 57), Color3.fromRGB(123, 34, 34)),
		ink = Theme.chalk,
		strokeColor = Theme.semantic.danger,
		strokeT = 0.5,
	},
}

local function Button(props: Props)
	local variant: Variant = props.variant or "primary"
	local skin = SKINS[variant]
	local disabled = props.disabled == true or props.loading == true

	local scale, scaleApi = motion.useMotor(1)
	local hover, hoverApi = motion.useMotor(0)
	local press, pressApi = motion.useMotor(0)
	local heartbeat =
		motion.usePulse({ period = 2.6, enabled = props.pulse == true and not disabled })

	local pressedRef = React.useRef(false)

	local function setPressed(down: boolean)
		pressedRef.current = down
		if down then
			scaleApi.setTarget(motion.Motion.scale.press, motion.Motion.spring.snappy)
			pressApi.setTarget(1, motion.Motion.spring.snappy)
		else
			scaleApi.setTarget(1, motion.Motion.spring.pop)
			pressApi.setTarget(0, motion.Motion.spring.gentle)
		end
	end

	-- Gradient variants swap ColorSequence by state (cheap: state changes, not frames).
	local gradColor = if skin.grad
		then press:map(function(p: number): ColorSequence
			if p > 0.5 and skin.pressGrad then
				return skin.pressGrad
			end
			return skin.grad :: ColorSequence
		end)
		else nil

	local fillColor: Color3 | React.Binding<Color3>
	if skin.grad then
		fillColor = WHITE
	else
		local rest = skin.fill
		local hoverFill = skin.hoverFill or rest
		local pressFill = skin.pressFill or rest
		fillColor = React.joinBindings({ h = hover, p = press } :: { [string]: any })
			:map(function(v: any): Color3
				local c = Theme.mix(rest, hoverFill, math.clamp(v.h, 0, 1))
				return Theme.mix(c, pressFill, math.clamp(v.p, 0, 1))
			end)
	end

	local baseFillT = if skin.transparentFill then 1 else 0
	local ink = if disabled then Theme.text.disabled else (props.textColor or skin.ink)

	local children: { [string]: any } = {
		_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
		_stroke = e("UIStroke", {
			Color = skin.strokeColor,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Transparency = React.joinBindings({ h = hover, b = heartbeat } :: { [string]: any })
				:map(function(v: any): number
					if disabled then
						return 0.94
					end
					local base = skin.strokeT - 0.37 * math.clamp(v.h, 0, 1)
					local beat = 0.32 * math.clamp(v.b, 0, 1)
					return math.clamp(base - beat, 0.3, 1)
				end),
		}),
		_pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, Theme.space.lg),
			PaddingRight = UDim.new(0, Theme.space.lg),
		}),
		_scale = e("UIScale", { Scale = scale }),
	}
	if gradColor and not disabled then
		children._grad = e("UIGradient", { Rotation = 90, Color = gradColor })
	end
	if props.loading then
		children._spinner = e(Spinner, { color = ink })
	else
		children._label = e("TextLabel", {
			Text = props.text,
			Font = Theme.type.h2.font,
			TextSize = Theme.type.h2.size,
			TextColor3 = ink,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		})
	end

	return e("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Active = not disabled,
		BackgroundColor3 = if disabled then Theme.field3 else fillColor,
		BackgroundTransparency = if disabled then 0 else baseFillT,
		Size = props.size or UDim2.new(1, 0, 0, Theme.size.buttonH),
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		BorderSizePixel = 0,
		[React.Event.InputBegan] = function(_rbx, input: InputObject)
			if disabled then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				setPressed(true)
			end
		end,
		[React.Event.InputEnded] = function(_rbx, input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				if pressedRef.current then
					setPressed(false)
				end
			end
		end,
		[React.Event.MouseEnter] = function()
			if not disabled then
				hoverApi.setTarget(1, motion.Motion.spring.gentle)
			end
		end,
		[React.Event.MouseLeave] = function()
			hoverApi.setTarget(0, motion.Motion.spring.gentle)
			if pressedRef.current then
				setPressed(false)
			end
		end,
		[React.Event.Activated] = function()
			if disabled then
				return
			end
			local sfx = props.sfx or "click"
			if sfx ~= "" then
				Sound.play(sfx)
			end
			props.onActivated()
		end,
	}, children)
end

return Button
