--!strict
-- Screen-level enter transition (Fade's replacement). Enter-only choreography keyed by
-- `trigger`: content mounts at progress 0 (invisible — no one-frame flash) and fades +
-- slides in. This is the app's ONE persistent CanvasGroup; tab panes and list rows use
-- cheap per-element bindings instead (see design/ui-v2-master.md R4/R5).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local motion = require(script.Parent.Parent.motion)

local e = React.createElement

export type Props = {
	trigger: string, -- replay entrance on change
	dir: number?, -- 1 = slide in from right, -1 = from left, nil/0 = rise from below
	duration: number?, -- default Motion.dur.base
	distance: number?, -- default dist.rise (vertical) / dist.slide (horizontal)
	onComplete: (() -> ())?,
	children: { [string]: any }?,
}

local function Transition(props: Props)
	local dir = props.dir or 0
	local duration = props.duration or motion.Motion.dur.base
	local distance = props.distance
		or (if dir == 0 then motion.Motion.dist.rise else motion.Motion.dist.slide)

	local progress = (
		motion.useProgress(props.trigger, {
			duration = duration,
			easing = motion.Solver.easeOutQuint,
			onComplete = props.onComplete,
		})
	)

	return e("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = progress:map(function(v: number): number
			return 1 - v
		end),
		Position = progress:map(function(v: number): UDim2
			local d = math.floor(distance * (1 - v))
			if dir == 1 then
				return UDim2.fromOffset(d, 0)
			elseif dir == -1 then
				return UDim2.fromOffset(-d, 0)
			end
			return UDim2.fromOffset(0, d)
		end),
	}, props.children)
end

return Transition
