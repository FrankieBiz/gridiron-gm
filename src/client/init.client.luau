--!strict
-- GRIDIRON GM — client entry point. Mounts the React-lua app into a full-screen ScreenGui.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local React = require(ReplicatedStorage.Packages.React)
local App = require(script.App)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local container = Instance.new("ScreenGui")
container.Name = "GridironGM"
container.ResetOnSpawn = false
container.IgnoreGuiInset = true
container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
container.Parent = playerGui

local root = ReactRoblox.createRoot(container)
root:render(React.createElement(App))
