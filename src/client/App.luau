--!strict
-- Root component: owns screen + franchise state, talks to the server via Remotes,
-- and renders the current screen. State is small enough for useState here; Reflex
-- comes in Slice 2 when season state grows.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(script.Parent.Theme)

local Menu = require(script.Parent.screens.Menu)
local TeamSelect = require(script.Parent.screens.TeamSelect)
local TeamOverview = require(script.Parent.screens.TeamOverview)
local GameResult = require(script.Parent.screens.GameResult)

local e = React.createElement

type Record = { wins: number, losses: number, gamesPlayed: number }

local function App()
	local screen, setScreen = React.useState("loading")
	local franchise, setFranchise = React.useState(nil :: any) -- { teamId, team, teams }
	local record, setRecord = React.useState({ wins = 0, losses = 0, gamesPlayed = 0 } :: Record)
	local lastGame, setLastGame = React.useState(nil :: any)

	-- Initial load: resume an existing franchise if the save has one.
	React.useEffect(function()
		task.spawn(function()
			local res = Remotes.GetState:InvokeServer()
			if res and res.ok and res.hasFranchise then
				setFranchise({ teamId = res.teamId, team = res.team, teams = res.teams })
				setRecord(res.record)
			end
			setScreen("menu")
		end)
	end, {})

	local onNew = React.useCallback(function()
		setScreen("select")
	end, {})

	local onContinue = React.useCallback(function()
		setScreen("overview")
	end, {})

	local onPick = React.useCallback(function(teamId: string)
		task.spawn(function()
			local res = Remotes.NewFranchise:InvokeServer(teamId)
			if res and res.ok then
				setFranchise({ teamId = res.teamId, team = res.team, teams = res.teams })
				setRecord(res.record)
				setScreen("overview")
			end
		end)
	end, {})

	local onSim = React.useCallback(function()
		task.spawn(function()
			local res = Remotes.SimGame:InvokeServer()
			if res and res.ok then
				setLastGame(res)
				setRecord(res.record)
				setScreen("result")
			end
		end)
	end, {})

	local onDone = React.useCallback(function()
		setScreen("overview")
	end, {})

	local onBackToMenu = React.useCallback(function()
		setScreen("menu")
	end, {})

	local body
	if screen == "loading" then
		body = e("TextLabel", {
			Text = "LOADING…",
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			TextColor3 = Theme.chalkSoft,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.4, 0.1),
			Position = UDim2.fromScale(0.3, 0.45),
		})
	elseif screen == "menu" then
		body = e(Menu, { hasFranchise = franchise ~= nil, onNew = onNew, onContinue = onContinue })
	elseif screen == "select" then
		body = e(TeamSelect, { onPick = onPick, onBack = onBackToMenu })
	elseif screen == "overview" and franchise then
		body = e(
			TeamOverview,
			{ team = franchise.team, record = record, onSim = onSim, onBack = onBackToMenu }
		)
	elseif screen == "result" and lastGame then
		body = e(
			GameResult,
			{ game = lastGame, teamId = franchise and franchise.teamId, onDone = onDone }
		)
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.field,
		BorderSizePixel = 0,
	}, {
		body = body,
	})
end

return App
