--!strict
-- Convenience motor that tracks a prop: the binding springs to `target` whenever it
-- changes. First render mounts AT target (no entrance animation). `config` is captured
-- at mount; later config changes are ignored (pass per-call overrides via useMotor if
-- that matters).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Motion = require(script.Parent.Motion)
local useMotor = require(script.Parent.useMotor)

local function useSpring(target: number, config: Motion.MotorConfig?): React.Binding<number>
	local binding, api = useMotor(target, config)

	React.useEffect(function()
		api.setTarget(target)
	end, { target } :: { any })

	return binding
end

return useSpring
