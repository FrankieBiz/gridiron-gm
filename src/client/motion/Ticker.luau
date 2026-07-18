--!strict
-- The one shared frame loop for every animation in the app. Tasks are (dt) -> boolean;
-- returning true (or erroring) removes the task. The RenderStepped connection is created
-- on the first add and disconnected when the registry empties — idle screens cost zero.

local RunService = game:GetService("RunService")

export type TickerTask = (dt: number) -> boolean
export type CancelFn = () -> ()

type Entry = { fn: TickerTask, dead: boolean }

local Ticker = {}

local tasks: { Entry } = {}
local conn: RBXScriptConnection? = nil

local function step(dt: number)
	-- Reverse iteration makes table.remove safe mid-loop; tasks added during the loop
	-- land at the end and run starting next frame.
	for i = #tasks, 1, -1 do
		local entry = tasks[i]
		local remove = entry.dead
		if not remove then
			local ok, done = pcall(entry.fn, dt)
			if not ok then
				if RunService:IsStudio() then
					warn("[Ticker] task error:", done)
				end
				remove = true
			else
				remove = done == true
			end
		end
		if remove then
			table.remove(tasks, i)
		end
	end
	if #tasks == 0 and conn then
		conn:Disconnect()
		conn = nil
	end
end

function Ticker.add(fn: TickerTask): CancelFn
	local entry: Entry = { fn = fn, dead = false }
	table.insert(tasks, entry)
	if conn == nil then
		conn = RunService.RenderStepped:Connect(step)
	end
	return function()
		entry.dead = true
	end
end

-- Active task count — perf assertions and debugging ("Ticker.count() == 0 at rest").
function Ticker.count(): number
	local n = 0
	for _, entry in tasks do
		if not entry.dead then
			n += 1
		end
	end
	return n
end

return Ticker
