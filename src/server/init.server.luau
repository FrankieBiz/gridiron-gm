--!strict
-- GRIDIRON GM — server bootstrapper. Registers services and runs the two-phase
-- Init -> Start loop (see Shared/Modules/core/ServiceLoader). All authoritative logic
-- lives in these services; the client only requests and displays.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceLoader = require(ReplicatedStorage.Shared.Modules.core.ServiceLoader)

local loader = ServiceLoader.new()
loader:add(require(script.Services.SaveService)) -- must init first (others read saves)
loader:add(require(script.Services.FranchiseService))
loader:add(require(script.Services.SeasonService))
loader:start()

print("[GRIDIRON] Server up.")
