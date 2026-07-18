--!strict
-- List entrances that scale to 30 rows for the cost of ONE ticker task: a hidden
-- seconds clock plus one memoized eased binding per row index. No CanvasGroups, no
-- per-row connections, no setState. Rows apply the §5 recipe: inner-frame position
-- offset + transparency maps driven by stagger.item(i).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Solver = require(script.Parent.Solver)
local Motion = require(script.Parent.Motion)
local Ticker = require(script.Parent.Ticker)

export type StaggerApi = {
	item: (index: number) -> React.Binding<number>, -- eased 0->1 for that row (memoized)
	skip: () -> (),
}

type StaggerState = {
	cancel: Ticker.CancelFn?,
	items: { [number]: React.Binding<number> },
	total: number,
	step: number,
	span: number,
	delay: number,
	easing: (number) -> number,
}

local function useStagger(trigger: any, config: Motion.StaggerConfig): StaggerApi
	local clock, setClock = React.useBinding(0)

	local ref = React.useRef(nil :: StaggerState?)
	if ref.current == nil then
		local step = config.step or Motion.stagger.step
		local span = config.span or Motion.stagger.span
		local delay = config.delay or 0
		local maxTotal = config.maxTotal or Motion.stagger.maxTotal
		-- Compress the per-row step so long lists still land inside maxTotal.
		local natural = delay + math.max(config.count - 1, 0) * step + span
		if natural > maxTotal then
			step = math.max(0.012, (maxTotal - span) / math.max(config.count - 1, 1))
		end
		ref.current = {
			cancel = nil,
			items = {},
			total = delay + math.max(config.count - 1, 0) * step + span,
			step = step,
			span = span,
			delay = delay,
			easing = config.easing or Solver.easeOutQuint,
		}
	end

	local apiRef = React.useRef(nil :: StaggerApi?)
	if apiRef.current == nil then
		local s = ref.current :: StaggerState

		apiRef.current = {
			item = function(index: number): React.Binding<number>
				local cached = s.items[index]
				if cached then
					return cached
				end
				local mapped = clock:map(function(t: number): number
					return s.easing(Solver.staggerProgress(t - s.delay, index, s.step, s.span))
				end)
				s.items[index] = mapped
				return mapped
			end,
			skip = function()
				if s.cancel then
					s.cancel()
					s.cancel = nil
				end
				setClock(s.total)
			end,
		}
	end

	local api = apiRef.current :: StaggerApi

	React.useEffect(function()
		local s = ref.current :: StaggerState
		if s.cancel then
			s.cancel()
			s.cancel = nil
		end
		if Motion.reducedMotion() then
			setClock(s.total)
			return
		end
		local elapsed = 0
		setClock(0)
		s.cancel = Ticker.add(function(dt: number): boolean
			elapsed += dt
			if elapsed >= s.total then
				setClock(s.total)
				s.cancel = nil
				return true
			end
			setClock(elapsed)
			return false
		end)
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

	return api
end

return useStagger
