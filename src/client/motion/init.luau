--!strict
-- Aggregator: `local motion = require(...client.motion)` gives screens the whole motion
-- system through one require. Solver is pure math (lune-tested); everything else is
-- client wiring on top of it.

local motion = {
	Solver = require(script.Solver),
	Ticker = require(script.Ticker),
	Motion = require(script.Motion),
	useMotor = require(script.useMotor),
	useSpring = require(script.useSpring),
	useProgress = require(script.useProgress),
	useChoreo = require(script.useChoreo),
	useStagger = require(script.useStagger),
	usePulse = require(script.usePulse),
}

return motion
