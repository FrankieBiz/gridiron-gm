--!strict
-- Count-up number label: binding-driven interpolation from the previous value on every
-- `value` change. TextScaled is hard-coded OFF (per-frame relayout of scaled text is
-- banned); numbers that animate render in fixed-size mono by default.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)
local Ticker = require(script.Parent.Parent.motion.Ticker)

local e = React.createElement

export type Props = {
	value: number,
	format: ((n: number) -> string)?, -- default: rounded tostring
	durationFor: ((delta: number) -> number)?, -- default Motion.countDuration
	easing: ((p: number) -> number)?, -- default easeOutExpo (lands softly)
	animateOnMount: boolean?, -- default false: mounts showing `value`
	snap: boolean?, -- true: changes apply instantly (skip mode)
	onSettled: (() -> ())?, -- fires when a count lands (e.g. play "cash")
	font: Enum.Font?, -- default mono
	textColor3: (Color3 | React.Binding<Color3>)?,
	textSize: number?, -- default Theme.type.mono.size
	textXAlignment: Enum.TextXAlignment?, -- default Right (digits grow leftward)
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	zIndex: number?,
}

local function defaultFormat(n: number): string
	return tostring(math.floor(n + 0.5))
end

local function AnimatedNumber(props: Props)
	local format = props.format or defaultFormat

	local shownRef = React.useRef(if props.animateOnMount then 0 else props.value)
	local binding, setBinding = React.useBinding(shownRef.current :: number)
	local cancelRef = React.useRef(nil :: Ticker.CancelFn?)

	React.useEffect(function()
		local from = shownRef.current :: number
		local to = props.value
		if cancelRef.current then
			cancelRef.current()
			cancelRef.current = nil
		end
		if from == to then
			return
		end
		if props.snap == true or motion.Motion.reducedMotion() then
			shownRef.current = to
			setBinding(to)
			return
		end
		local duration = (props.durationFor or motion.Motion.countDuration)(to - from)
		local easing = props.easing or motion.Solver.easeOutExpo
		local elapsed = 0
		cancelRef.current = Ticker.add(function(dt: number): boolean
			elapsed += dt
			local p = math.clamp(elapsed / duration, 0, 1)
			local shown = motion.Solver.lerp(from, to, easing(p))
			shownRef.current = shown
			setBinding(shown)
			if p >= 1 then
				shownRef.current = to
				cancelRef.current = nil
				if props.onSettled then
					props.onSettled()
				end
				return true
			end
			return false
		end)
	end, { props.value, props.snap } :: { any })

	React.useEffect(function()
		return function()
			if cancelRef.current then
				cancelRef.current()
				cancelRef.current = nil
			end
		end
	end, {})

	return e("TextLabel", {
		Text = binding:map(format),
		Font = props.font or Theme.font.mono,
		TextSize = props.textSize or Theme.type.mono.size,
		TextScaled = false,
		TextColor3 = props.textColor3 or Theme.text.primary,
		TextXAlignment = props.textXAlignment or Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
	})
end

return AnimatedNumber
