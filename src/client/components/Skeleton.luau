--!strict
-- Loading bone with a shared shimmer sweep: every mounted Skeleton rides ONE module-
-- level clock (refcounted Ticker task) — no per-bone connections, no CanvasGroups.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)
local Ticker = require(script.Parent.Parent.motion.Ticker)

local e = React.createElement

export type Props = {
	height: number?, -- default 14
	width: UDim?, -- default full width
	layoutOrder: number?,
}

-- Module-level shared shimmer clock (period 1.6s: 1.2s sweep + 0.4s rest).
local sharedBinding, setShared = React.createBinding(0)
local refs = 0
local cancel: Ticker.CancelFn? = nil

local function retain()
	refs += 1
	if refs == 1 and not motion.Motion.reducedMotion() then
		local elapsed = 0
		cancel = Ticker.add(function(dt: number): boolean
			elapsed = (elapsed + dt) % 1.6
			setShared(if elapsed < 1.2 then elapsed / 1.2 else 0)
			return false
		end)
	end
end

local function release()
	refs = math.max(refs - 1, 0)
	if refs == 0 and cancel then
		cancel()
		cancel = nil
		setShared(0)
	end
end

local function Skeleton(props: Props)
	React.useEffect(function()
		retain()
		return release
	end, {})

	return e("Frame", {
		BackgroundColor3 = Theme.alpha(Theme.chalk, 0.04, Theme.field2),
		Size = UDim2.new(props.width or UDim.new(1, 0), UDim.new(0, props.height or 14)),
		LayoutOrder = props.layoutOrder,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, {
		_corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.sm) }),
		_sweep = e("Frame", {
			BackgroundColor3 = Theme.chalk,
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.sm) }),
			grad = e("UIGradient", {
				Rotation = 15,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.42, 1),
					NumberSequenceKeypoint.new(0.5, 0.85),
					NumberSequenceKeypoint.new(0.58, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
				Offset = sharedBinding:map(function(p: number): Vector2
					return Vector2.new(-1 + 2 * p, 0)
				end),
			}),
		}),
	})
end

return Skeleton
