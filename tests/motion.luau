--!nocheck
-- Headless motion-math verification. Run: `lune run tests/motion.luau`
-- Proves the analytic spring converges correctly in every damping regime and that the
-- easing curves satisfy their boundary/shape contracts, so UI motion can't misbehave.

local Solver = require("../src/client/motion/Solver")

local function assertNear(actual, expected, tol, label)
	if math.abs(actual - expected) > tol then
		error(string.format("%s: expected %.6f, got %.6f (tol %.6f)", label, expected, actual, tol))
	end
end

-- 1. Convergence: from many starts, every damping regime settles on the target.
for _, zeta in { 0.3, 0.6, 1, 1.5 } do
	for _, start in { -100, 0, 42, 1000 } do
		local s = { x = start, v = 0 }
		local target = 250
		for _ = 1, 600 do -- 10s at 60fps
			s = Solver.springStep(s, target, 1 / 60, { frequency = 4, damping = zeta })
		end
		assertNear(s.x, target, 1e-2, string.format("converge zeta=%.1f start=%d", zeta, start))
		assertNear(s.v, 0, 1e-2, string.format("velocity zeta=%.1f start=%d", zeta, start))
	end
end
print("Spring convergence (under/critical/over-damped) ✓")

-- 2. Critical damping never overshoots (starting from rest).
local s = { x = 0, v = 0 }
for _ = 1, 600 do
	s = Solver.springStep(s, 1, 1 / 60, { frequency = 4, damping = 1 })
	if s.x > 1 + 1e-6 then
		error(string.format("critically damped spring overshot: x=%.8f", s.x))
	end
end
print("Critical damping: no overshoot ✓")

-- 3. Underdamped DOES overshoot (that's the bounce — verify it exists).
local bounced = false
s = { x = 0, v = 0 }
for _ = 1, 600 do
	s = Solver.springStep(s, 1, 1 / 60, { frequency = 4, damping = 0.4 })
	if s.x > 1 + 1e-3 then
		bounced = true
	end
end
assertNear(s.x, 1, 1e-2, "underdamped settle")
if not bounced then
	error("underdamped spring never overshot — bounce is broken")
end
print("Underdamping: overshoots then settles ✓")

-- 4. Step-size independence: one 0.5s step == thirty 1/60s steps (analytic exactness).
local big = Solver.springStep({ x = 0, v = 0 }, 1, 0.5, { frequency = 3, damping = 0.7 })
local small = { x = 0, v = 0 }
for _ = 1, 30 do
	small = Solver.springStep(small, 1, 0.5 / 30, { frequency = 3, damping = 0.7 })
end
assertNear(big.x, small.x, 1e-9, "dt-independence x")
assertNear(big.v, small.v, 1e-9, "dt-independence v")
print("Analytic exactness: big step == many small steps ✓")

-- 5. springDone: false while moving, true at rest.
if Solver.springDone({ x = 0, v = 0 }, 1) then
	error("springDone true while 1.0 away from target")
end
if not Solver.springDone({ x = 1.0000001, v = 0.0000001 }, 1) then
	error("springDone false at rest on target")
end
print("springDone thresholds ✓")

-- 6. Easings: boundaries and shape.
local easings = {
	easeOutCubic = Solver.easeOutCubic,
	easeOutQuint = Solver.easeOutQuint,
	easeInOutCubic = Solver.easeInOutCubic,
	easeOutExpo = Solver.easeOutExpo,
	easeOutBack = Solver.easeOutBack,
}
for name, fn in easings do
	assertNear(fn(0), 0, 1e-6, name .. "(0)")
	assertNear(fn(1), 1, 1e-6, name .. "(1)")
end
-- Monotonic (except easeOutBack which intentionally overshoots).
for name, fn in easings do
	if name ~= "easeOutBack" then
		local prev = fn(0)
		for i = 1, 100 do
			local cur = fn(i / 100)
			if cur < prev - 1e-9 then
				error(string.format("%s not monotonic at %d%%", name, i))
			end
			prev = cur
		end
	end
end
-- easeOutBack must exceed 1 somewhere (the "pop").
local popped = false
for i = 1, 99 do
	if Solver.easeOutBack(i / 100) > 1 then
		popped = true
	end
end
if not popped then
	error("easeOutBack never overshoots — pop is gone")
end
print("Easing boundaries, monotonicity, and back-overshoot ✓")

-- 7. Stagger windows: item 1 starts immediately, later items are delayed and clamped.
assertNear(Solver.staggerProgress(0, 1, 0.1, 0.5), 0, 1e-9, "stagger t0 item1")
assertNear(Solver.staggerProgress(0.5, 1, 0.1, 0.5), 1, 1e-9, "stagger item1 done")
assertNear(Solver.staggerProgress(0.1, 2, 0.1, 0.5), 0, 1e-9, "stagger item2 starts at its offset")
assertNear(Solver.staggerProgress(0.35, 2, 0.1, 0.5), 0.5, 1e-9, "stagger item2 halfway")
assertNear(Solver.staggerProgress(2, 5, 0.1, 0.5), 1, 1e-9, "stagger clamps at 1")
print("Stagger timing ✓")

print("")
print("Motion math verified. ✓")
