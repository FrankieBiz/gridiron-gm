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
local CareerDecision = require(script.Parent.screens.CareerDecision)
local CareerProfile = require(script.Parent.screens.CareerProfile)
local History = require(script.Parent.screens.History)
local DraftRoom = require(script.Parent.screens.DraftRoom)
local FreeAgency = require(script.Parent.screens.FreeAgency)
local Fade = require(script.Parent.components.Fade)
local Sound = require(script.Parent.Sound)

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
		coach = st.coach,
		prestige = st.prestige or 3,
		expectedWins = st.expectedWins or 8,
		pendingCareer = st.pendingCareer or false,
		news = st.news or {},
		history = st.history or {},
		achievements = st.achievements or {},
		achievementDefs = st.achievementDefs or {},
		dynastyScore = st.dynastyScore or 0,
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
	local career, setCareer = React.useState(nil :: any)
	local draft, setDraft = React.useState(nil :: any)
	local freeAgents, setFreeAgents = React.useState(nil :: any)

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
		Sound.play("whistle")
		task.spawn(function()
			local res = Remotes.SimGame:InvokeServer()
			if res and res.ok then
				setLastGame(res)
				setScreen("result")
			end
		end)
	end, {})

	local refreshToApp = React.useCallback(function()
		task.spawn(function()
			local d = fetchAll()
			if d then
				setData(d)
			end
			setPendingOffseason(nil)
			setScreen("app")
		end)
	end, {})

	-- After the game result: if the season just ended, go to the career decision.
	local resultDone = React.useCallback(function()
		if lastGame and lastGame.careerReport then
			setCareer(lastGame.careerReport)
			setScreen("career")
			return
		end
		refreshToApp()
	end, { lastGame, refreshToApp })

	-- Stay or take a job -> begin the interactive draft.
	local chooseJob = React.useCallback(function(teamId: string)
		task.spawn(function()
			local res = Remotes.ChooseJob:InvokeServer(teamId)
			if res and res.ok and res.enteringDraft then
				setCareer(nil)
				setDraft(res.draft)
				setScreen("draft")
			end
		end)
	end, {})

	local scoutProspect = React.useCallback(function(prospectId: string)
		task.spawn(function()
			local res = Remotes.ScoutProspect:InvokeServer(prospectId)
			if res and res.ok then
				setDraft(res.draft)
			end
		end)
	end, {})

	local makePick = React.useCallback(function(prospectId: string)
		Sound.play("pick")
		task.spawn(function()
			local res = Remotes.MakePick:InvokeServer(prospectId)
			if res and res.ok then
				if res.done then
					setDraft(nil)
					setPendingOffseason(res.offseason)
					setScreen("offseason")
				else
					setDraft(res.draft)
				end
			end
		end)
	end, {})

	-- After the offseason recap, open free agency (credits were just awarded).
	local offseasonDone = React.useCallback(function()
		task.spawn(function()
			local d = fetchAll()
			if d then
				setData(d)
				if d.freeAgents and #d.freeAgents > 0 then
					setFreeAgents(d.freeAgents)
					setScreen("freeagency")
					return
				end
			end
			setPendingOffseason(nil)
			setScreen("app")
		end)
	end, {})

	local signFreeAgent = React.useCallback(function(faId: string)
		Sound.play("cash")
		task.spawn(function()
			local res = Remotes.SignFreeAgent:InvokeServer(faId)
			if res and res.ok then
				setFreeAgents(res.freeAgents)
				setData(function(prev: any)
					if not prev then
						return prev
					end
					local updated = table.clone(prev)
					updated.credits = res.credits
					updated.freeAgents = res.freeAgents
					return updated
				end)
			end
		end)
	end, {})

	local finishOffseason = React.useCallback(function()
		task.spawn(function()
			Remotes.FinishOffseason:InvokeServer()
			setFreeAgents(nil)
			refreshToApp()
		end)
	end, { refreshToApp })

	local backToMenu = React.useCallback(function()
		setScreen("menu")
	end, {})

	local upgradeFacility = React.useCallback(function(key: string)
		Sound.play("cash")
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
				if data and data.pendingCareer then
					setCareer(data.pendingCareer)
					setScreen("career")
				elseif data and data.inDraft then
					task.spawn(function()
						local res = Remotes.GetDraft:InvokeServer()
						if res and res.ok then
							setDraft(res.draft)
							setScreen("draft")
						else
							setScreen("app")
						end
					end)
				elseif data and data.freeAgents and #data.freeAgents > 0 then
					setFreeAgents(data.freeAgents)
					setScreen("freeagency")
				else
					setScreen("app")
				end
			end,
		})
	elseif screen == "select" then
		body = e(TeamSelect, { onPick = pickTeam, onBack = backToMenu })
	elseif screen == "draft" and draft then
		body = e(DraftRoom, { draft = draft, onScout = scoutProspect, onPick = makePick })
	elseif screen == "freeagency" and freeAgents and data then
		body = e(FreeAgency, {
			freeAgents = freeAgents,
			credits = data.credits,
			onSign = signFreeAgent,
			onFinish = finishOffseason,
		})
	elseif screen == "result" and lastGame then
		body =
			e(GameResult, { game = lastGame, teamId = data and data.teamId, onDone = resultDone })
	elseif screen == "career" and career and data then
		body = e(CareerDecision, {
			report = career.report,
			offers = career.offers,
			awards = career.awards,
			team = data.team,
			prestige = data.prestige,
			onChoose = chooseJob,
		})
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
				news = data.news,
				onSim = simWeek,
			})
		elseif tab == "Roster" then
			content = e(Roster, { team = data.team })
		elseif tab == "League" then
			content = e(
				LeagueTable,
				{ teamId = data.teamId, teams = data.teams, standings = data.standings }
			)
		elseif tab == "HQ" then
			content = e(Facilities, {
				facilities = data.facilities,
				credits = data.credits,
				onUpgrade = upgradeFacility,
			})
		elseif tab == "Career" then
			content = e(CareerProfile, {
				coach = data.coach,
				team = data.team,
				prestige = data.prestige,
				expectedWins = data.expectedWins,
				record = data.record,
				achievements = data.achievements,
				achievementDefs = data.achievementDefs,
				dynastyScore = data.dynastyScore,
			})
		else
			content = e(History, {
				history = data.history,
				teams = data.teams,
				coach = data.coach,
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
			}, { fade = e(Fade, { trigger = tab }, { screen = content }) }),
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
		body = e(Fade, { trigger = screen }, { body = body }),
	})
end

return App
