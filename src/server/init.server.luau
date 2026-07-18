--!strict
-- GRIDIRON GM — server bootstrapper. Registers services and runs the two-phase
-- Init -> Start loop (see Shared/Modules/core/ServiceLoader). All authoritative logic
-- lives in these services; the client only requests and displays.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- This is a UI-only management game — no 3D avatar. Stop spawning characters so the
-- player doesn't fall through the empty world and die on a loop.
Players.CharacterAutoLoads = false

local ServiceLoader = require(ReplicatedStorage.Shared.Modules.core.ServiceLoader)

-- Casts: each module defines only the lifecycle methods it needs (Init or Start), and
-- Luau won't unify a sealed table missing an optional field with the Service shape.
local loader = ServiceLoader.new()
loader:add(require(script.Services.SaveService) :: any) -- must init first (others read saves)
loader:add(require(script.Services.FranchiseService) :: any)
loader:add(require(script.Services.SeasonService) :: any)
loader:add(require(script.Services.DraftService) :: any)
loader:start()

print("[GRIDIRON] Server up.")
