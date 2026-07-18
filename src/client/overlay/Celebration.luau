--!strict
-- Full-screen celebration effects behind modals/toasts: confetti burst or gold bloom.
-- One celebration live at a time; new calls replace the current one.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)
local Confetti = require(script.Parent.Parent.components.Confetti)

local e = React.createElement

export type Props = {
	kind: ("confetti" | "goldBloom")?,
	onDone: () -> (),
}

local function GoldBloom(props: { onDone: () -> () })
	local progress = motion.useProgress(nil, {
		duration = 0.5,
		onComplete = props.onDone,
	})
	return e("Frame", {
		BackgroundColor3 = Theme.goldGlow,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		BackgroundTransparency = progress:map(function(p: number): number
			return 0.85 + 0.15 * p
		end),
	})
end

local function Celebration(props: Props): any
	if props.kind == "confetti" then
		return e(Confetti, { play = true, onDone = props.onDone }) :: any
	elseif props.kind == "goldBloom" then
		return e(GoldBloom, { onDone = props.onDone }) :: any
	end
	return nil
end

return Celebration
