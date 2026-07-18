--!strict
-- The complete typed client<->server contract: every payload the remotes carry, field
-- for field, verified against the services that build them (FranchiseService.buildState,
-- SeasonService, DraftService). The client casts ONCE at the fetch boundary and every
-- screen consumes real types — no `any` past this file.
--
-- Wire rules this encodes:
-- * `false` (never nil) is the empty sentinel for pendingCareer/freeAgents — DataStore
--   JSON drops nils, so truthiness checks stay valid across saves.
-- * `teams` is identity-only summaries; `team` is the full club with roster — different
--   shapes on purpose (payload discipline). Don't merge them.
-- * team.primary/secondary are "#RRGGBB" hex strings the client parses via Theme.hex.

local Player = require(script.Parent.Player)
local Game = require(script.Parent.Game)

-- Every rostered player carries a development trait the generator assigns.
export type DevTrait = "normal" | "star" | "superstar"

export type RosterPlayer = {
	id: string,
	name: string,
	position: string,
	age: number,
	overall: number,
	speed: number,
	strength: number,
	awareness: number,
	potential: number,
	contractYears: number,
	salary: number,
	morale: number,
	devTrait: DevTrait,
}

-- Identity-only summary (all 12 clubs, for pickers/standings lookups).
export type TeamSummary = {
	id: string,
	city: string,
	name: string,
	abbr: string,
	primary: string,
	secondary: string,
}

-- The player's full club: identity + prestige + live roster.
export type LeagueTeam = {
	id: string,
	city: string,
	name: string,
	abbr: string,
	primary: string,
	secondary: string,
	prestige: number, -- 1..5
	roster: { RosterPlayer },
}

export type TeamRecord = {
	wins: number,
	losses: number,
	gamesPlayed: number,
}

export type SeasonPhase = "regular" | "playoffs" | "offseason"

export type SeasonInfo = {
	year: number,
	week: number,
	phase: SeasonPhase,
	totalWeeks: number,
}

export type FacilityLevels = {
	training: number,
	rehab: number,
	stadium: number,
}

export type Coach = {
	reputation: number, -- 0..100
	jobSecurity: number, -- 0..100
	careerWins: number,
	careerLosses: number,
	championships: number,
	seasonsCoached: number,
	teamsCoached: { string },
}

export type CareerReport = {
	expectedWins: number,
	actualWins: number,
	met: boolean,
	champion: boolean,
	madePlayoffs: boolean,
	secDelta: number,
	repDelta: number,
	fired: boolean,
	jobSecurity: number,
	reputation: number,
}

export type JobOffer = {
	teamId: string,
	city: string,
	name: string,
	prestige: number,
	expectedWins: number,
	tag: string, -- "REBUILD" | "PLAYOFF PUSH" | "WIN NOW"
}

export type Award = {
	title: string, -- "MVP", "Off. Player of the Year", ...
	name: string,
	position: string,
	teamId: string,
	teamName: string,
	overall: number,
	stat: string, -- pre-formatted line, e.g. "4778 yds, 51 TD, 6 INT"
}

export type SeasonAwards = {
	majors: { Award },
	allLeague: { Award },
}

export type PendingCareer = {
	report: CareerReport,
	offers: { JobOffer },
	awards: SeasonAwards,
}

-- Server emits: career | league | title | retire | draft | credits | award.
export type NewsItem = {
	kind: string,
	text: string,
}

export type HistoryEntry = {
	year: number,
	wins: number,
	losses: number,
	champion: string?, -- teamId; absent on saves from before playoffs concluded
	wonIt: boolean,
}

export type AchievementDef = {
	id: string,
	name: string,
	desc: string,
	points: number,
}

export type StandingsRow = {
	teamId: string,
	w: number,
	l: number,
	pf: number,
	pa: number,
	diff: number,
}

export type ScheduledGame = { home: string, away: string }
export type ScheduleWeek = { ScheduledGame }

export type FreeAgent = {
	id: string,
	name: string,
	position: string,
	age: number,
	overall: number,
	speed: number,
	strength: number,
	awareness: number,
	potential: number,
	contractYears: number,
	salary: number,
	morale: number,
	devTrait: DevTrait,
	cost: number, -- coaching credits to sign
}

-- Draft: the fog-of-war view. True ratings live server-side only.
export type ScoutedProspect = {
	id: string,
	name: string,
	position: string,
	age: number,
	ovrMin: number,
	ovrMax: number,
	potMin: number,
	potMax: number,
	scoutPoints: number, -- points spent on this prospect so far
}

export type DraftPick = {
	teamId: string,
	round: number,
	name: string,
	position: string,
	overall: number,
	potential: number,
	devTrait: DevTrait,
	mine: boolean,
}

export type DraftView = {
	onClock: string, -- teamId
	isMyPick: boolean,
	done: boolean,
	scoutPoints: number, -- points I have left to spend
	pickNumber: number,
	totalPicks: number,
	prospects: { ScoutedProspect }, -- best-consensus first
	myPicks: { DraftPick },
}

export type OffseasonSummary = {
	year: number,
	nextYear: number,
	champion: string?, -- teamId
	retirees: { RosterPlayer },
	rookies: { DraftPick },
	creditsEarned: number,
	totalCredits: number,
}

-- ---- remote responses ----

-- GetState / NewFranchise / UpgradeFacility all return this blob (buildState).
export type StatePayload = {
	ok: boolean,
	error: string?,
	hasFranchise: boolean?,
	teamId: string,
	team: LeagueTeam,
	teams: { TeamSummary },
	record: TeamRecord,
	coachingCredits: number?,
	facilities: FacilityLevels?,
	coach: Coach,
	prestige: number?,
	expectedWins: number?,
	pendingCareer: PendingCareer | false,
	news: { NewsItem },
	history: { HistoryEntry },
	achievements: { [string]: boolean },
	achievementDefs: { AchievementDef },
	dynastyScore: number?,
	inDraft: boolean,
	freeAgents: { FreeAgent } | false,
	season: SeasonInfo,
}

export type SeasonPayload = {
	ok: boolean,
	error: string?,
	year: number,
	week: number,
	phase: SeasonPhase,
	totalWeeks: number,
	standings: { StandingsRow },
	schedule: { ScheduleWeek },
}

export type SimGameResponse = {
	ok: boolean,
	error: string?,
	result: Game.GameResult,
	homeName: string,
	awayName: string,
	record: TeamRecord,
	label: string, -- "Week N" | "Semifinals" | "Championship"
	phase: SeasonPhase,
	champion: string?,
	year: number,
	week: number,
	careerReport: PendingCareer?, -- present only on the game that ends a season
}

-- The single normalized table App builds from GetState + GetSeason. Screens consume
-- THIS type — every field is present (or-defaulted at the boundary).
export type FranchiseData = {
	teamId: string,
	team: LeagueTeam,
	teams: { TeamSummary },
	credits: number,
	record: TeamRecord,
	season: SeasonInfo,
	facilities: FacilityLevels,
	coach: Coach,
	prestige: number,
	expectedWins: number,
	pendingCareer: PendingCareer | false,
	news: { NewsItem },
	history: { HistoryEntry },
	achievements: { [string]: boolean },
	achievementDefs: { AchievementDef },
	dynastyScore: number,
	standings: { StandingsRow },
	schedule: { ScheduleWeek },
	inDraft: boolean,
	freeAgents: { FreeAgent } | false,
}

export type Player = Player.Player
export type GameResult = Game.GameResult
export type PlayEvent = Game.PlayEvent
export type TeamBox = Game.TeamBox

return {}
