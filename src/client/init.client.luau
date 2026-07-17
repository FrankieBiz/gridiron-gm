--!strict
-- GRIDIRON GM — client entry point.
-- Phase 0: a throwaway button that pings the server. Replace with the real
-- main menu in Phase 1 (React-lua). This just proves the client->server pipe.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screen = Instance.new("ScreenGui")
screen.Name = "GridironDebug"
screen.ResetOnSpawn = false
screen.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.fromScale(0.4, 0.12) -- scale, so it survives phone screens
button.Position = UDim2.fromScale(0.3, 0.44)
button.Text = "PING SERVER"
button.TextScaled = true
button.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

button.Activated:Connect(function()
	Remotes.Ping:FireServer()
end)
