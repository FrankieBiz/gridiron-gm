--!strict
-- Eased one-shot 0->1 (the screen-entrance engine). The binding initializes at 0, so
-- content mounts invisible — no one-frame flash. Plays on mount and on every `trigger`
-- change; `trigger = nil` means "once on mount". The returned binding is EASED; for
-- multi-element storyboards use useChoreo instead.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Solver = require(script.Parent.Solver)
local Motion = require(script.Parent.Motion)
local Ticker = require(script.Parent.Ticker)

export type ProgressApi = {
	replay: () -> (), -- restart from 0
	finish: () -> (), -- snap to 1, fire onComplete (SKIP / reduced-motion path)
	reset: () -> (), -- snap to 0 without playing
}

type ProgressState = {
	cancel: Ticker.CancelFn?,
	config: Motion.TimelineConfig?,
}

local function useProgress(
	trigger: any,
	config: Motion.TimelineConfig?
): (React.Binding<number>, ProgressApi)
	local binding, setBinding = React.useBinding(0)

	local ref = React.useRef(nil :: ProgressState?)
	if ref.current == nil then
		ref.current = { cancel = nil, config = config }
	end
	-- Keep the latest config/onComplete visible to the api without re-creating it.
	(ref.current :: ProgressState).config = config

	local apiRef = React.useRef(nil :: ProgressApi?)
	if apiRef.current == nil then
		local function cancelTask()
			local s = ref.current :: ProgressState
			if s.cancel then
				s.cancel()
				s.cancel = nil
			end
		end

		local function complete()
			local s = ref.current :: ProgressState
			local cfg = s.config
			if cfg and cfg.onComplete then
				cfg.onComplete()
			end
		end

		apiRef.current = {
			replay = function()
				cancelTask()
				local s = ref.current :: ProgressState
				local cfg = s.config
				if Motion.reducedMotion() then
					setBinding(1)
					complete()
					return
				end
				local duration = (cfg and cfg.duration) or Motion.dur.base
				local delay = (cfg and cfg.delay) or 0
				local easing = (cfg and cfg.easing) or Solver.easeOutCubic
				local elapsed = 0
				setBinding(0)
				s.cancel = Ticker.add(function(dt: number): boolean
					elapsed += dt
					local raw = math.clamp((elapsed - delay) / duration, 0, 1)
					setBinding(easing(raw))
					if raw >= 1 then
						s.cancel = nil
						complete()
						return true
					end
					return false
				end)
			end,
			finish = function()
				cancelTask()
				setBinding(1)
				complete()
			end,
			reset = function()
				cancelTask()
				setBinding(0)
			end,
		}
	end

	local api = apiRef.current :: ProgressApi

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

return useProgress
