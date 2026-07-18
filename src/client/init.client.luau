--!strict
-- GRIDIRON GM — client entry point. Two ScreenGuis (main app at DisplayOrder 10, an
-- overlay layer at 20 for toasts/modals/celebrations), camera locked with a re-lock
-- guard, sounds warmed during boot, and the tree wrapped in an ErrorBoundary so a
-- render crash can never strand the player on a black screen.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local React = require(ReplicatedStorage.Packages.React)
local App = require(script.App)
local ErrorBoundary = require(script.ErrorBoundary)
local Overlay = require(script.overlay.OverlayProvider)
local Sound = require(script.Sound)

local e = React.createElement

-- No character in this UI game — lock the camera (and re-lock if it gets replaced).
local function lockCamera()
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
	end
end
lockCamera()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(lockCamera)

-- Warm sound assets so the first whistle doesn't hitch.
task.spawn(function()
	local sounds = {}
	for _, id in Sound.assetIds() do
		local s = Instance.new("Sound")
		s.SoundId = id
		table.insert(sounds, s)
	end
	pcall(function()
		ContentProvider:PreloadAsync(sounds)
	end)
	for _, s in sounds do
		s:Destroy()
	end
end)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local mainGui = Instance.new("ScreenGui")
mainGui.Name = "GridironGM"
mainGui.ResetOnSpawn = false
mainGui.IgnoreGuiInset = true
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainGui.DisplayOrder = 10
mainGui.Parent = playerGui

local overlayGui = Instance.new("ScreenGui")
overlayGui.Name = "GridironGM_Overlay"
overlayGui.ResetOnSpawn = false
overlayGui.IgnoreGuiInset = true
overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
overlayGui.DisplayOrder = 20
overlayGui.Parent = playerGui

local root = ReactRoblox.createRoot(mainGui)
root:render(e(ErrorBoundary, {}, {
	provider = e(Overlay.Provider, { gui = overlayGui }, {
		app = e(App),
	}),
}))
