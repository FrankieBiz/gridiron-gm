--!strict
-- Root controller: typed screen state machine, all remote traffic (with pending guards
-- and failure toasts on EVERY handler — no silent failures), safe-area chrome layout,
-- directional tab slide, and a Fallback else-branch so the router can never strand the
-- player on a blank screen. Screens are dumb: data + callbacks in, actions bubble up.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)

local Theme = require(script.Parent.Theme)
local Nav = require(script.Parent.Nav)
local SafeArea = require(script.Parent.SafeArea)
local Sound = require(script.Parent.Sound)
local Fetch = require(script.Parent.net.Fetch)
local Overlay = require(script.Parent.overlay.OverlayProvider)
local motion = require(script.Parent.motion)

local Transition = require(script.Parent.components.Transition)
local TopBar = require(script.Parent.components.TopBar)
local TabBar = require(script.Parent.components.TabBar)
local Button = require(script.Parent.components.Button)
local Modal = require(script.Parent.components.Modal)

local Loading = require(script.Parent.screens.Loading)
local Fallback = require(script.Parent.screens.Fallback)
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

local e = React.createElement

type PendingKey =
	"boot"
	| "resume"
	| "newFranchise"
	| "sim"
	| "refresh"
	| "chooseJob"
	| "pick"
	| "offseason"
	| "finish"
	| "recover"

local MIN_BOOT = 0.6

-- Tab pane slide: cheap directional entrance without a CanvasGroup (master spec A3).
local function TabPane(props: {
	tab: string,
	dir: number,
	topH: number,
	botH: number,
	children: { [string]: any }?,
})
	local progress = motion.useProgress(props.tab, {
		duration = 0.18,
		easing = motion.Solver.easeOutCubic,
	})
	local dir = props.dir

	return e("Frame", {
		BackgroundTransparency = 1,
		Position = progress:map(function(p: number): UDim2
			local offset =
				math.floor(motion.Motion.dist.slide * (1 - p) * (if dir ~= 0 then dir else 0))
			return UDim2.fromOffset(offset, props.topH)
		end),
		Size = UDim2.new(1, 0, 1, -(props.topH + props.botH)),
		ClipsDescendants = true,
	}, props.children)
end

local function App()
	local overlay = Overlay.useOverlay()
	local insets = SafeArea.useInsets()

	local screen, setScreen = React.useState("loading" :: Nav.Screen)
	local tab, setTab = React.useState("Season" :: Nav.Tab)
	local data, setData = React.useState(nil :: Franchise.FranchiseData?)
	local lastGame, setLastGame = React.useState(nil :: Franchise.SimGameResponse?)
	local pendingOffseason, setPendingOffseason = React.useState(nil :: Franchise.OffseasonSummary?)
	local career, setCareer = React.useState(nil :: Franchise.PendingCareer?)
	local draft, setDraft = React.useState(nil :: Franchise.DraftView?)
	local freeAgents, setFreeAgents = React.useState(nil :: { Franchise.FreeAgent }?)

	local pending, setPending = React.useState({} :: { [string]: boolean })
	local scouting, setScouting = React.useState(nil :: string?)
	local signing, setSigning = React.useState(nil :: string?)
	local upgrading, setUpgrading = React.useState(nil :: string?)

	-- Directional tab slide: remember where we came from.
	local prevTabRef = React.useRef(tab)
	local tabDir = math.sign(Nav.tabIndex(tab) - Nav.tabIndex(prevTabRef.current))
	React.useEffect(function()
		prevTabRef.current = tab
	end, { tab } :: { any })

	local pendingRef = React.useRef(pending)
	pendingRef.current = pending

	-- Re-entry-guarded async handler wrapper: every remote call goes through this.
	local function withPending(key: PendingKey, fn: () -> ())
		if pendingRef.current[key] then
			return
		end
		setPending(function(prev)
			local out = table.clone(prev)
			out[key] = true
			return out
		end)
		task.spawn(function()
			xpcall(fn, function(err)
				warn("[GRIDIRON] handler error:", err)
			end)
			setPending(function(prev)
				local out = table.clone(prev)
				out[key] = nil
				return out
			end)
		end)
	end

	-- ---- boot ----
	React.useEffect(function()
		withPending("boot", function()
			local started = os.clock()
			local result = Fetch.fetchAll()
			local elapsed = os.clock() - started
			if elapsed < MIN_BOOT then
				task.wait(MIN_BOOT - elapsed)
			end
			if result.err then
				overlay.toast({
					kind = "error",
					title = "STATS DESK OFFLINE",
					detail = "Couldn't reach your save. NEW FRANCHISE works; CONTINUE will retry.",
				})
			end
			setData(result.state)
			setScreen("menu")
		end)
	end, {})

	-- ---- handlers ----

	local refreshToApp = React.useCallback(function()
		withPending("refresh", function()
			local result = Fetch.fetchAll()
			if result.state then
				setData(result.state)
			elseif result.err then
				overlay.toast({
					kind = "error",
					title = "STATS DESK OFFLINE",
					detail = "Showing your last synced numbers. Pull the tab again to retry.",
				})
			end
			setPendingOffseason(nil :: any)
			setScreen("app")
		end)
	end, {})

	local pickTeam = React.useCallback(function(teamId: string)
		withPending("newFranchise", function()
			local res = Remotes.NewFranchise:InvokeServer(teamId)
			if res and res.ok then
				local result = Fetch.fetchAll()
				if result.state then
					setData(result.state)
					setTab("Season")
					setScreen("app")
					return
				end
			end
			overlay.toast({
				kind = "error",
				title = "FRONT OFFICE UNAVAILABLE",
				detail = "Couldn't start your franchise. Take the podium again.",
			})
		end)
	end, {})

	local simWeek = React.useCallback(function()
		Sound.play("whistle")
		withPending("sim", function()
			local res = Remotes.SimGame:InvokeServer()
			if res and res.ok then
				setLastGame(res)
				setScreen("result")
			else
				overlay.toast({
					kind = "error",
					title = "PLAY CLOCK EXPIRED",
					detail = (res and res.error)
						or "The sim didn't come back. You're still on this week — hit it again.",
				})
			end
		end)
	end, {})

	-- After the game result: season over -> career decision; otherwise back to the app.
	local resultDone = React.useCallback(function()
		if lastGame and lastGame.careerReport then
			setCareer(lastGame.careerReport)
			setScreen("career")
			return
		end
		refreshToApp()
	end, { lastGame, refreshToApp } :: { any })

	local chooseJob = React.useCallback(function(teamId: string)
		withPending("chooseJob", function()
			local res = Remotes.ChooseJob:InvokeServer(teamId)
			if res and res.ok and res.enteringDraft then
				setCareer(nil :: any)
				setDraft(res.draft)
				setScreen("draft")
			else
				overlay.toast({
					kind = "error",
					title = "THE OWNER'S LINE IS BUSY",
					detail = (res and res.error)
						or "Your decision didn't go through. Make the call again.",
				})
			end
		end)
	end, {})

	local scoutProspect = React.useCallback(function(prospectId: string)
		if scouting ~= nil then
			return
		end
		setScouting(prospectId)
		task.spawn(function()
			local ok, res = pcall(function()
				return Remotes.ScoutProspect:InvokeServer(prospectId)
			end)
			setScouting(nil :: any)
			if ok and res and res.ok then
				setDraft(res.draft)
			else
				overlay.toast({
					kind = "error",
					title = "SCOUT WENT DARK",
					detail = "No report came back. Your point wasn't spent.",
				})
			end
		end)
	end, { scouting } :: { any })

	local makePick = React.useCallback(function(prospectId: string)
		Sound.play("pick")
		withPending("pick", function()
			local res = Remotes.MakePick:InvokeServer(prospectId)
			if res and res.ok then
				if res.done then
					setDraft(nil :: any)
					setPendingOffseason(res.offseason)
					setScreen("offseason")
				else
					setDraft(res.draft)
				end
			else
				if res and res.draft then
					setDraft(res.draft)
				end
				overlay.toast({
					kind = "error",
					title = "PICK NEVER REACHED THE PODIUM",
					detail = "Turn it in again — the clock's still yours.",
				})
			end
		end)
	end, {})

	-- After the offseason recap: free agency if the market is open, else next season.
	local offseasonDone = React.useCallback(function()
		withPending("offseason", function()
			local result = Fetch.fetchAll()
			if result.state then
				setData(result.state)
				local fa = result.state.freeAgents
				if typeof(fa) == "table" and #fa > 0 then
					setFreeAgents(fa)
					setPendingOffseason(nil :: any)
					setScreen("freeagency")
					return
				end
				setPendingOffseason(nil :: any)
				setScreen("app")
			else
				-- Keep pendingOffseason so the player can retry from the recap.
				overlay.toast({
					kind = "error",
					title = "LEAGUE OFFICE OFFLINE",
					detail = "Couldn't open the new league year. Try again.",
				})
			end
		end)
	end, {})

	local signFreeAgent = React.useCallback(function(faId: string)
		if signing ~= nil then
			return
		end
		setSigning(faId)
		task.spawn(function()
			local ok, res = pcall(function()
				return Remotes.SignFreeAgent:InvokeServer(faId)
			end)
			setSigning(nil :: any)
			if ok and res and res.ok then
				Sound.play("cash")
				setFreeAgents(res.freeAgents)
				setData((function(prev: Franchise.FranchiseData?): Franchise.FranchiseData?
					if not prev then
						return prev
					end
					local updated = table.clone(prev)
					updated.credits = res.credits
					updated.freeAgents = res.freeAgents
					return updated
				end) :: any)
			else
				overlay.toast({
					kind = "error",
					title = "DEAL FELL THROUGH",
					detail = "Not enough credits — your bank is untouched.",
				})
			end
		end)
	end, { signing } :: { any })

	local finishOffseason = React.useCallback(function()
		withPending("finish", function()
			local res = Remotes.FinishOffseason:InvokeServer()
			if res and res.ok then
				setFreeAgents(nil :: any)
				local result = Fetch.fetchAll()
				if result.state then
					setData(result.state)
				end
				setPendingOffseason(nil :: any)
				setScreen("app")
			else
				overlay.toast({
					kind = "error",
					title = "SEASON WON'T START",
					detail = "The league didn't answer. Kick off again.",
				})
			end
		end)
	end, {})

	local upgradeFacility = React.useCallback(function(key: string)
		if upgrading ~= nil then
			return
		end
		setUpgrading(key)
		task.spawn(function()
			local ok, res = pcall(function()
				return Remotes.UpgradeFacility:InvokeServer(key)
			end)
			setUpgrading(nil :: any)
			if ok and res and res.ok then
				Sound.play("cash")
				-- res is a fresh StatePayload blob; keep the prior standings/schedule.
				setData((function(prev: Franchise.FranchiseData?): Franchise.FranchiseData?
					local fresh = Fetch.normalize(res)
					if prev then
						fresh.standings = prev.standings
						fresh.schedule = prev.schedule
					end
					return fresh
				end) :: any)
			else
				overlay.toast({
					kind = "error",
					title = "CONSTRUCTION DELAYED",
					detail = (res and res.error) or "No credits were spent.",
				})
			end
		end)
	end, { upgrading } :: { any })

	local backToMenu = React.useCallback(function()
		setScreen("menu")
	end, {})

	local onContinue = React.useCallback(function()
		withPending("resume", function()
			if data and data.pendingCareer then
				setCareer(data.pendingCareer :: Franchise.PendingCareer)
				setScreen("career")
			elseif data and data.inDraft then
				local res = Remotes.GetDraft:InvokeServer()
				if res and res.ok then
					if res.draft.done then
						setScreen("app")
					else
						setDraft(res.draft)
						setScreen("draft")
					end
				else
					overlay.toast({
						kind = "error",
						title = "WAR ROOM LOCKED",
						detail = "Couldn't reopen the draft. Try again.",
					})
				end
			elseif data and typeof(data.freeAgents) == "table" and #data.freeAgents > 0 then
				setFreeAgents(data.freeAgents :: { Franchise.FreeAgent })
				setScreen("freeagency")
			else
				setScreen("app")
			end
		end)
	end, { data } :: { any })

	local onNew = React.useCallback(function()
		if data then
			-- Data-loss guard: an existing dynasty ends here.
			overlay.open("confirm-new", function(close: () -> ()): any
				return e(Modal, { title = "START OVER?", onClose = close }, {
					body = e("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						Position = UDim2.fromOffset(0, 36),
					}, {
						layout = e("UIListLayout", {
							Padding = UDim.new(0, Theme.space.md),
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
						pad = e("UIPadding", { PaddingTop = UDim.new(0, Theme.space.xl) }),
						text = e("TextLabel", {
							Text = string.format(
								"A new franchise replaces your current save. The %s era ends here.",
								data.team.name
							),
							Font = Theme.type.body.font,
							TextSize = Theme.type.body.size,
							TextColor3 = Theme.text.secondary,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
							BackgroundTransparency = 1,
							AutomaticSize = Enum.AutomaticSize.Y,
							Size = UDim2.new(1, 0, 0, 0),
							LayoutOrder = 1,
						}),
						keep = e(Button, {
							text = "KEEP MY DYNASTY",
							variant = "ghost" :: Button.Variant,
							onActivated = close,
							layoutOrder = 2,
						}),
						fresh = e(Button, {
							text = "START FRESH",
							variant = "danger" :: Button.Variant,
							onActivated = function()
								close()
								setScreen("select")
							end,
							layoutOrder = 3,
						}),
					}),
				})
			end)
		else
			setScreen("select")
		end
	end, { data } :: { any })

	local recover = React.useCallback(function()
		withPending("recover", function()
			local result = Fetch.fetchAll()
			if result.state then
				setData(result.state)
			end
			setScreen("menu")
		end)
	end, {})

	-- ---- routing ----
	local body: any
	local screenDir: number? = nil

	if screen == "loading" then
		body = e(Loading)
	elseif screen == "menu" then
		body = e(Menu, {
			hasFranchise = data ~= nil,
			continueContext = if data
				then {
					teamName = data.team.city .. " " .. data.team.name,
					year = data.season.year,
					wins = data.record.wins,
					losses = data.record.losses,
				}
				else nil,
			resuming = pending.resume == true,
			onNew = onNew,
			onContinue = onContinue,
		})
	elseif screen == "select" then
		screenDir = 1
		body = e(TeamSelect, {
			pending = pending.newFranchise == true,
			onPick = pickTeam,
			onBack = backToMenu,
		})
	elseif screen == "draft" and draft then
		body = e(DraftRoom, {
			draft = draft :: Franchise.DraftView,
			teams = if data then data.teams else {},
			scouting = scouting,
			picking = pending.pick == true,
			onScout = scoutProspect,
			onPick = makePick,
		})
	elseif screen == "freeagency" and freeAgents and data then
		body = e(FreeAgency, {
			freeAgents = freeAgents :: { Franchise.FreeAgent },
			credits = data.credits,
			signing = signing,
			finishing = pending.finish == true,
			onSign = signFreeAgent,
			onFinish = finishOffseason,
		})
	elseif screen == "result" and lastGame and data then
		body = e(GameResult, {
			game = lastGame :: Franchise.SimGameResponse,
			teamId = data.teamId,
			teams = data.teams,
			onDone = resultDone,
		})
	elseif screen == "career" and career and data then
		body = e(CareerDecision, {
			report = (career :: Franchise.PendingCareer).report,
			offers = (career :: Franchise.PendingCareer).offers,
			awards = (career :: Franchise.PendingCareer).awards,
			team = data.team,
			teams = data.teams,
			prestige = data.prestige,
			choosing = pending.chooseJob == true,
			onChoose = chooseJob,
		})
	elseif screen == "offseason" and pendingOffseason and data then
		body = e(Offseason, {
			summary = pendingOffseason :: Franchise.OffseasonSummary,
			teams = data.teams,
			myTeamId = data.teamId,
			starting = pending.offseason == true,
			onDone = offseasonDone,
		})
	elseif screen == "app" and data then
		local d = data :: Franchise.FranchiseData
		local content: any
		if tab == "Season" then
			content = e(Dashboard, {
				teamId = d.teamId,
				teams = d.teams,
				season = d.season,
				standings = d.standings,
				schedule = d.schedule,
				news = d.news,
				simming = pending.sim == true,
				onSim = simWeek,
				onOpenLeague = function()
					setTab("League")
				end,
			})
		elseif tab == "Roster" then
			content = e(Roster, { team = d.team })
		elseif tab == "League" then
			content = e(LeagueTable, {
				teamId = d.teamId,
				teams = d.teams,
				standings = d.standings,
			})
		elseif tab == "HQ" then
			content = e(Facilities, {
				facilities = d.facilities,
				credits = d.credits,
				upgrading = upgrading,
				onUpgrade = upgradeFacility,
			})
		elseif tab == "Career" then
			content = e(CareerProfile, {
				coach = d.coach,
				team = d.team,
				prestige = d.prestige,
				expectedWins = d.expectedWins,
				record = d.record,
				achievements = d.achievements,
				achievementDefs = d.achievementDefs,
				dynastyScore = d.dynastyScore,
			})
		elseif tab == "History" then
			content = e(History, {
				history = d.history,
				teams = d.teams,
				coach = d.coach,
			})
		end

		local topH = insets.top + Theme.chrome.topBarH
		local botH = Theme.chrome.tabBarH + math.max(insets.bottom, Theme.space.sm)

		body = e("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, {
			top = e(TopBar, {
				team = d.team,
				record = d.record,
				season = d.season,
				credits = d.credits,
				refreshing = pending.refresh == true or pending.offseason == true,
			}),
			-- Tab pane: plain Frame with a directional X-offset slide — NEVER a CanvasGroup.
			content = e(TabPane, {
				tab = tab :: string,
				dir = tabDir,
				topH = topH,
				botH = botH,
			}, { screen = content }),
			tabs = e(TabBar, { active = tab, onSelect = setTab }),
		})
	else
		body = e(Fallback, {
			recovering = pending.recover == true,
			onRecover = recover,
		})
		warn(string.format("[GRIDIRON] router fallthrough: screen=%s", screen))
	end

	local phase: string? = if data then data.season.phase else nil

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.field,
		BorderSizePixel = 0,
	}, {
		bg = e("UIGradient", { Rotation = 90, Color = Theme.appGradient(phase :: any) }),
		body = e(Transition, { trigger = screen, dir = screenDir }, { body = body }),
	})
end

return App
