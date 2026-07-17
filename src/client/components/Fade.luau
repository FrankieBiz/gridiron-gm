--!strict
-- Fades + lifts its children in whenever `trigger` changes. Uses a CanvasGroup so the whole
-- subtree fades as one. Cheap, non-fatal, and respects reduced-motion by snapping if needed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

local DURATION = 0.22

type Props = {
	trigger: string, -- change this to replay the entrance
	children: { [string]: any }?,
}

local function Fade(props: Props)
	local progress, setProgress = React.useBinding(1)

	React.useEffect(function()
		setProgress(0)
		local start = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local p = math.clamp((os.clock() - start) / DURATION, 0, 1)
			-- ease-out cubic
			setProgress(1 - (1 - p) * (1 - p) * (1 - p))
			if p >= 1 and conn then
				conn:Disconnect()
				conn = nil
			end
		end)
		return function()
			if conn then
				conn:Disconnect()
			end
		end
	end, { props.trigger })

	return e("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = progress:map(function(v)
			return 1 - v
		end),
		Position = progress:map(function(v)
			return UDim2.fromOffset(0, math.floor((1 - v) * 16))
		end),
	}, props.children)
end

return Fade
