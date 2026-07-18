--!strict
-- Seconds clock for multi-element storyboards: the binding carries ELAPSED SECONDS
-- (linear, clamped to `total`). Elements subscribe with windows in real seconds:
--   TextTransparency = clock:map(function(t)
--       return Motion.alpha(Motion.window(t, 0.30, 0.25))
--   end)
-- finish() snaps the clock to `total`, landing every windowed map on its rest value in
-- one frame — the universal SKIP mechanism.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Motion = require(script.Parent.Motion)
local Ticker = require(script.Parent.Ticker)
local useProgress = require(script.Parent.useProgress)

type ClockState = {
	cancel: Ticker.CancelFn?,
	onComplete: (() -> ())?,
}

local function useChoreo(
	trigger: any,
	total: number,
	onComplete: (() -> ())?
): (React.Binding<number>, useProgress.ProgressApi)
	local binding, setBinding = React.useBinding(0)

	local ref = React.useRef(nil :: ClockState?)
	if ref.current == nil then
		ref.current = { cancel = nil, onComplete = onComplete }
	end
	(ref.current :: ClockState).onComplete = onComplete

	local apiRef = React.useRef(nil :: useProgress.ProgressApi?)
	if apiRef.current == nil then
		local function cancelTask()
			local s = ref.current :: ClockState
			if s.cancel then
				s.cancel()
				s.cancel = nil
			end
		end

		local function complete()
			local s = ref.current :: ClockState
			if s.onComplete then
				s.onComplete()
			end
		end

		apiRef.current = {
			replay = function()
				cancelTask()
				if Motion.reducedMotion() then
					setBinding(total)
					complete()
					return
				end
				local elapsed = 0
				setBinding(0)
				local s = ref.current :: ClockState
				s.cancel = Ticker.add(function(dt: number): boolean
					elapsed += dt
					if elapsed >= total then
						setBinding(total)
						s.cancel = nil
						complete()
						return true
					end
					setBinding(elapsed)
					return false
				end)
			end,
			finish = function()
				cancelTask()
				setBinding(total)
				complete()
			end,
			reset = function()
				cancelTask()
				setBinding(0)
			end,
		}
	end

	local api = apiRef.current :: useProgress.ProgressApi

	-- Reset synchronously during render on trigger change so the old rest value can't
	-- paint for one frame before the replay effect runs (binding writes are render-safe).
	local prevTriggerRef = React.useRef(trigger)
	if prevTriggerRef.current ~= trigger then
		prevTriggerRef.current = trigger
		if not Motion.reducedMotion() then
			setBinding(0)
		end
	end

	React.useEffect(function()
		api.replay()
	end, { trigger } :: { any })

	React.useEffect(function()
		return function()
			local s = ref.current
			if s and s.cancel then
				s.cancel()
				s.cancel = nil
			end
		end
	end, {})

	return binding, api
end

return useChoreo
