--!strict
-- Root controller: owns app state, talks to the server via Remotes, and routes between
-- the menu, the tabbed main app (Season / Roster / League), the game result, and the
-- offseason recap. State via React hooks passed down as props (simple + robust).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(script.Parent.Theme)

local TopBar = require(script.Parent.components.TopBar)
local TabBar = require(script.Parent.components.TabBar)
local Menu = require(script.Parent.screens.Menu)
local TeamSelect = require(script.Parent.screens.TeamSelect)
local Dashboard = require(script.Parent.screens.Dashboard)
local Roster = require(script.Parent.screens.Roster)
local LeagueTable = require(script.Parent.screens.LeagueTable)
local GameResult = require(script.Parent.screens.GameResult)
local Offseason = require(script.Parent.screens.Offseason)
local Facilities = require(script.Parent.screens.Facilities)

local e = React.createElement

local function fetchAll(): any?
	local st = Remotes.GetState:InvokeServer()
	if not (st and st.ok and st.hasFranchise) then
		return nil
	end
	local se = Remotes.GetSeason:InvokeServer()
	return {
		teamId = st.teamId,
		team = st.team,
		teams = st.teams,
		credits = st.coachingCredits or 0,
		record = st.record,
		season = st.season,
		facilities = st.facilities or { training = 1, rehab = 1, stadium = 1 },
		standings = (se and se.ok and se.standings) or {},
		schedule = (se and se.ok and se.schedule) or {},
	}
end

local function App()
	local screen, setScreen = React.useState("loading")
	local tab, setTab = React.useState("Season")
	local data, setData = React.useState(nil :: any)
	local lastGame, setLastGame = React.useState(nil :: any)
	local pendingOffseason, setPendingOffseason = React.useState(nil :: any)

	React.useEffect(function()
		task.spawn(function()
			local d = fetchAll()
			if d then
				setData(d)
			end
			setScreen("menu")
		end)
	end, {})

	local pickTeam = React.useCallback(function(teamId: string)
		task.spawn(function()
			local res = Remotes.NewFranchise:InvokeServer(teamId)
			if res and res.ok then
				local d = fetchAll()
				if d then
					setData(d)
					setTab("Season")
					setScreen("app")
				end
			end
		end)
	end, {})

	local simWeek = React.useCallback(function()
		task.spawn(function()
			local res = Remotes.SimGame:InvokeServer()
			if res and res.ok then
				setLastGame(res)
				if res.offseason then
					setPendingOffseason(res.offseason)
					setScreen("offseason") -- recap first, then play the opening game
				else
					setScreen("result")
				end
			end
		end)
	end, {})

	local offseasonDone = React.useCallback(function()
		setScreen("result")
	end, {})

	local resultDone = React.useCallback(function()
		task.spawn(function()
			local d = fetchAll()
			if d then
				setData(d)
			end
			setPendingOffseason(nil)
			setScreen("app")
		end)
	end, {})

	local backToMenu = React.useCallback(function()
		setScreen("menu")
	end, {})

	local upgradeFacility = React.useCallback(function(key: string)
		task.spawn(function()
			local res = Remotes.UpgradeFacility:InvokeServer(key)
			if res and res.ok then
				local d = fetchAll()
				if d then
					setData(d)
				end
			end
		end)
	end, {})

	-- ---- routing ----
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
		body = e(Menu, {
			hasFranchise = data ~= nil,
			onNew = function()
				setScreen("select")
			end,
			onContinue = function()
				setScreen("app")
			end,
		})
	elseif screen == "select" then
		body = e(TeamSelect, { onPick = pickTeam, onBack = backToMenu })
	elseif screen == "result" and lastGame then
		body =
			e(GameResult, { game = lastGame, teamId = data and data.teamId, onDone = resultDone })
	elseif screen == "offseason" and pendingOffseason and data then
		body =
			e(Offseason, { summary = pendingOffseason, teams = data.teams, onDone = offseasonDone })
	elseif screen == "app" and data then
		local content
		if tab == "Season" then
			content = e(Dashboard, {
				teamId = data.teamId,
				teams = data.teams,
				season = data.season,
				standings = data.standings,
				schedule = data.schedule,
				onSim = simWeek,
			})
		elseif tab == "Roster" then
			content = e(Roster, { team = data.team })
		elseif tab == "League" then
			content = e(
				LeagueTable,
				{ teamId = data.teamId, teams = data.teams, standings = data.standings }
			)
		else
			content = e(Facilities, {
				facilities = data.facilities,
				credits = data.credits,
				onUpgrade = upgradeFacility,
			})
		end

		body = e("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, {
			top = e(TopBar, {
				team = data.team,
				record = data.record,
				season = data.season,
				credits = data.credits,
			}),
			content = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 82),
				Size = UDim2.new(1, 0, 1, -146),
			}, { screen = content }),
			tabs = e(TabBar, { active = tab, onSelect = setTab }),
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.field,
		BorderSizePixel = 0,
	}, {
		bg = e("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Theme.bgTop, Theme.bgBottom),
		}),
		body = body,
	})
end

return App
