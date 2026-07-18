--!strict
-- Navigation vocabulary: the only legal screen/tab ids in the app. A setScreen typo is
-- now a compile error, and the TabBar/tab-slide direction math lives beside the list.

export type Screen =
	"loading"
	| "menu"
	| "select"
	| "draft"
	| "freeagency"
	| "result"
	| "career"
	| "offseason"
	| "app"

export type Tab = "Season" | "Roster" | "League" | "HQ" | "Career" | "History"

export type TabDef = { id: Tab, icon: string, label: string }

local Nav = {}

Nav.TABS = {
	{ id = "Season" :: Tab, icon = "🏈", label = "SEASON" },
	{ id = "Roster" :: Tab, icon = "📋", label = "ROSTER" },
	{ id = "League" :: Tab, icon = "🏆", label = "LEAGUE" },
	{ id = "HQ" :: Tab, icon = "🏟️", label = "HQ" },
	{ id = "Career" :: Tab, icon = "💼", label = "CAREER" },
	{ id = "History" :: Tab, icon = "📜", label = "HISTORY" },
} :: { TabDef }

-- 1-based position of a tab; drives the directional tab slide and the TabBar pill.
function Nav.tabIndex(tab: Tab): number
	for i, def in Nav.TABS do
		if def.id == tab then
			return i
		end
	end
	return 1
end

return Nav
