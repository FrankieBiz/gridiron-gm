--!strict
-- Router fallback: reachable when a screen's payload guard fails (e.g. screen=="draft"
-- with no draft). Replaces the old silent blank screen with a recovery path.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Parent.components.Button)
local EmptyState = require(script.Parent.Parent.components.EmptyState)

local e = React.createElement

export type Props = {
	recovering: boolean?,
	onRecover: () -> (),
}

local function Fallback(props: Props)
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		empty = e(EmptyState, {
			icon = "🏈",
			title = "WE LOST THE FEED",
			body = "The broadcast truck hit a snag. Tap below and we'll get you back to the booth.",
		}),
		btnWrap = e("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.62),
			Size = UDim2.fromOffset(280, Theme.size.buttonH),
		}, {
			btn = e(Button, {
				text = "BACK TO THE BOOTH",
				onActivated = props.onRecover,
				loading = props.recovering,
			}),
		}),
	})
end

return Fallback
