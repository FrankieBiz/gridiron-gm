--!strict
-- Celebration burst: ≤32 rotated card-stock frames inside ONE ClipsDescendants
-- CanvasGroup (the only legal home for rotated frames). One elapsed-seconds binding
-- drives every particle via mapped closures; the group unmounts itself when done.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)

local e = React.createElement

export type Props = {
	play: boolean,
	origin: UDim2?, -- default centre-upper
	count: number?, -- default 24, clamped ≤32
	onDone: (() -> ())?,
}

type Particle = {
	color: Color3,
	x0: number, -- px offset from origin
	y0: number,
	vx: number,
	vy: number,
	rot0: number,
	vr: number,
}

local LIFETIME = 1.6
local GRAVITY = 620

local function makeParticles(count: number): { Particle }
	local colors = { Theme.gold, Theme.flag, Theme.chalk, Theme.green }
	local weights = { 8, 8, 5, 3 }
	local particles = {}
	local ci, used = 1, 0
	for _ = 1, count do
		-- proportional color allocation
		used += 1
		if used > math.ceil(weights[ci] * count / 24) then
			ci = math.min(ci + 1, #colors)
			used = 1
		end
		table.insert(particles, {
			color = colors[ci],
			x0 = (math.random() - 0.5) * 60,
			y0 = (math.random() - 0.5) * 20,
			vx = (math.random() - 0.5) * 360,
			vy = -260 - math.random() * 170,
			rot0 = math.random() * 360,
			vr = (if math.random() < 0.5 then -1 else 1) * (240 + math.random() * 280),
		})
	end
	return particles
end

local function Confetti(props: Props)
	local origin = props.origin or UDim2.fromScale(0.5, 0.42)
	local count = math.min(props.count or 24, 32)

	local clock, setClock = React.useBinding(0)
	local particlesRef = React.useRef(nil :: { Particle }?)
	if particlesRef.current == nil then
		particlesRef.current = makeParticles(count)
	end

	React.useEffect(function()
		if not props.play then
			return
		end
		if motion.Motion.reducedMotion() then
			if props.onDone then
				props.onDone()
			end
			return
		end
		local elapsed = 0
		local cancel = motion.Ticker.add(function(dt: number): boolean
			elapsed += dt
			setClock(elapsed)
			if elapsed >= LIFETIME then
				if props.onDone then
					props.onDone()
				end
				return true
			end
			return false
		end)
		return function()
			cancel()
		end
	end, { props.play } :: { any })

	if not props.play then
		return nil :: any
	end

	local children: { [string]: any } = {}
	for i, particle in particlesRef.current :: { Particle } do
		children["p" .. i] = e("Frame", {
			BackgroundColor3 = particle.color,
			Size = UDim2.fromOffset(6, 10),
			BorderSizePixel = 0,
			Position = clock:map(function(t: number): UDim2
				local x = particle.x0 + particle.vx * t
				local y = particle.y0 + particle.vy * t + 0.5 * GRAVITY * t * t
				return UDim2.new(
					origin.X.Scale,
					origin.X.Offset + math.floor(x),
					origin.Y.Scale,
					origin.Y.Offset + math.floor(y)
				)
			end),
			Rotation = clock:map(function(t: number): number
				return particle.rot0 + particle.vr * t
			end),
			BackgroundTransparency = clock:map(function(t: number): number
				return math.clamp((t - (LIFETIME - 0.4)) / 0.4, 0, 1)
			end),
		})
	end

	return e("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = Theme.z.raised,
	}, children)
end

return Confetti
