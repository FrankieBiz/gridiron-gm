--!strict
-- Ambient looping driver for idle life (breathing strokes, sheen sweeps, on-the-clock
-- pulses). One ticker task per pulse; `enabled = false` (or reduced motion) parks the
-- binding at 0 and frees the task — idle screens must return Ticker.count() to 0.
--
--   "sine":  0 -> 1 -> 0 per period (starts at 0, peaks mid-period)
--   "sweep": one 0->1 wipe over `active` seconds, then holds 0 for the rest of the period

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Motion = require(script.Parent.Motion)
local Ticker = require(script.Parent.Ticker)

local function usePulse(config: Motion.PulseConfig): React.Binding<number>
	local binding, setBinding = React.useBinding(0)

	local enabled = config.enabled ~= false
	local period = config.period
	local waveform = config.waveform or "sine"
	local active = config.active or period

	React.useEffect(function()
		if not enabled or Motion.reducedMotion() then
			setBinding(0)
			return
		end
		local elapsed = 0
		local cancel = Ticker.add(function(dt: number): boolean
			elapsed = (elapsed + dt) % period
			if waveform == "sweep" then
				setBinding(if elapsed < active then elapsed / active else 0)
			else
				setBinding(0.5 - 0.5 * math.cos(2 * math.pi * elapsed / period))
			end
			return false
		end)
		return function()
			cancel()
			setBinding(0)
		end
	end, { enabled, period, waveform, active } :: { any })

	return binding
end

return usePulse
