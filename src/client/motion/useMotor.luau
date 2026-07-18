--!strict
-- The spring primitive: a binding driven by the analytic spring solver through the
-- shared Ticker. One motor = one number; join motors for multi-axis motion:
--   React.joinBindings({ x = xB, y = yB }):map(function(v) return UDim2.fromOffset(v.x, v.y) end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Solver = require(script.Parent.Solver)
local Motion = require(script.Parent.Motion)
local Ticker = require(script.Parent.Ticker)

export type MotorApi = {
	setTarget: (target: number, config: Motion.MotorConfig?) -> (), -- spring toward target
	snap: (value: number) -> (), -- cancel motion, jump, zero velocity
	impulse: (velocity: number) -> (), -- add velocity (units/sec), keep current target
	stop: () -> (), -- freeze at current value (velocity zeroed)
	getValue: () -> number,
	getVelocity: () -> number,
}

type MotorState = {
	state: Solver.SpringState,
	target: number,
	base: Motion.MotorConfig?,
	override: Motion.MotorConfig?,
	cancel: Ticker.CancelFn?,
}

local function useMotor(
	initial: number,
	config: Motion.MotorConfig?
): (React.Binding<number>, MotorApi)
	local binding, setBinding = React.useBinding(initial)

	local ref = React.useRef(nil :: MotorState?)
	if ref.current == nil then
		ref.current = {
			state = { x = initial, v = 0 },
			target = initial,
			base = config,
			override = nil,
			cancel = nil,
		}
	end

	local apiRef = React.useRef(nil :: MotorApi?)
	if apiRef.current == nil then
		local function activeConfig(m: MotorState): Motion.MotorConfig?
			return m.override or m.base
		end

		local function ensureRunning(m: MotorState)
			if m.cancel then
				return
			end
			m.cancel = Ticker.add(function(dt: number): boolean
				m.state = Solver.springStep(m.state, m.target, dt, activeConfig(m))
				local cfg = activeConfig(m)
				if Solver.springDone(m.state, m.target, cfg and cfg.epsilon) then
					m.state = { x = m.target, v = 0 }
					setBinding(m.target)
					m.cancel = nil
					return true
				end
				setBinding(m.state.x)
				return false
			end)
		end

		local function snap(value: number)
			local m = ref.current :: MotorState
			if m.cancel then
				m.cancel()
				m.cancel = nil
			end
			m.state = { x = value, v = 0 }
			m.target = value
			setBinding(value)
		end

		apiRef.current = {
			setTarget = function(target: number, override: Motion.MotorConfig?)
				local m = ref.current :: MotorState
				m.target = target
				m.override = override
				if Motion.reducedMotion() then
					snap(target)
					return
				end
				ensureRunning(m)
			end,
			snap = snap,
			impulse = function(velocity: number)
				if Motion.reducedMotion() then
					return
				end
				local m = ref.current :: MotorState
				m.state = { x = m.state.x, v = m.state.v + velocity }
				ensureRunning(m)
			end,
			stop = function()
				local m = ref.current :: MotorState
				if m.cancel then
					m.cancel()
					m.cancel = nil
				end
				m.state = { x = m.state.x, v = 0 }
				m.target = m.state.x
			end,
			getValue = function()
				local m = ref.current :: MotorState
				return m.state.x
			end,
			getVelocity = function()
				local m = ref.current :: MotorState
				return m.state.v
			end,
		}
	end

	React.useEffect(function()
		return function()
			local m = ref.current
			if m and m.cancel then
				m.cancel()
				m.cancel = nil
			end
		end
	end, {})

	return binding, apiRef.current :: MotorApi
end

return useMotor
