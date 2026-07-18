--!strict
-- Roster tab: roster-health strip (AVG OVR / STARS / AVG AGE), sort chips, and the
-- staggered PlayerRow list; tapping a row opens PlayerDetailModal via the overlay
-- (spec: ui-v2-ixd §4.5 IXD-29 — TeamOverview's live ideas are absorbed here).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)
local Overlay = require(script.Parent.Parent.overlay.OverlayProvider)
local SectionHeader = require(script.Parent.Parent.components.SectionHeader)
local StatChip = require(script.Parent.Parent.components.StatChip)
local SortChips = require(script.Parent.Parent.components.SortChips)
local PlayerRow = require(script.Parent.Parent.components.PlayerRow)
local PlayerDetailModal = require(script.Parent.Parent.components.PlayerDetailModal)
local EmptyState = require(script.Parent.Parent.components.EmptyState)

local e = React.createElement

export type Props = {
	team: Franchise.LeagueTeam,
}

local SORT_OPTIONS: { SortChips.Option } = {
	{ id = "ovr", label = "OVR" },
	{ id = "pos", label = "POS" },
	{ id = "age", label = "AGE" },
	{ id = "pot", label = "POT" },
}

-- Direction a fresh tap on each chip starts with (tap the active chip to flip).
local DEFAULT_ASC: { [string]: boolean } = { ovr = false, pos = true, age = true, pot = false }

local HEADER_H = 28 + Theme.space.sm + 56 + Theme.space.sm + 36 + Theme.space.sm

local function Roster(props: Props)
	local roster: { Franchise.RosterPlayer } = props.team.roster or {}
	local sortKey, setSortKey = React.useState("ovr")
	local ascending, setAscending = React.useState(false)
	local overlay = Overlay.useOverlay()

	local stagger = motion.useStagger("roster", {
		count = math.min(#roster, 14),
		step = 0.035,
		span = 0.24,
		maxTotal = 0.8,
	})

	local onSort = React.useCallback(function(id: string)
		if id == sortKey then
			setAscending(not ascending)
		else
			setSortKey(id)
			setAscending(DEFAULT_ASC[id] == true)
		end
	end, { sortKey, ascending } :: { any })

	local sorted = React.useMemo(function(): { Franchise.RosterPlayer }
		local out = table.clone(roster)
		table.sort(out, function(a: Franchise.RosterPlayer, b: Franchise.RosterPlayer): boolean
			if sortKey == "pos" then
				if a.position ~= b.position then
					if ascending then
						return a.position < b.position
					end
					return a.position > b.position
				end
				return a.overall > b.overall
			end
			local av: number, bv: number
			if sortKey == "age" then
				av, bv = a.age, b.age
			elseif sortKey == "pot" then
				av, bv = a.potential, b.potential
			else
				av, bv = a.overall, b.overall
			end
			if av == bv then
				return a.name < b.name
			end
			if ascending then
				return av < bv
			end
			return av > bv
		end)
		return out
	end, { roster, sortKey, ascending } :: { any })

	if #roster == 0 then
		-- Nil/empty guard: draft night hasn't happened yet.
		return e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			empty = e(EmptyState, {
				icon = "📋",
				title = "NO ONE ON THE BOOKS",
				body = "Your roster fills in on draft night. The war room is waiting.",
			}),
		})
	end

	-- Roster health strip.
	local totalOvr, totalAge, stars = 0, 0, 0
	for _, p in roster do
		totalOvr += p.overall
		totalAge += p.age
		if p.devTrait == "star" or p.devTrait == "superstar" then
			stars += 1
		end
	end
	local avgOvr = math.floor(totalOvr / #roster + 0.5)

	local rows: { [string]: any } = {
		_layout = e("UIListLayout", {
			Padding = UDim.new(0, Theme.space.sm),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		_pad = e("UIPadding", { PaddingBottom = UDim.new(0, Theme.space.xl) }),
	}
	for i, p in sorted do
		local player = p
		rows["p_" .. p.id] = e(PlayerRow, {
			player = p,
			index = i,
			entrance = stagger.item(math.min(i, 14)),
			layoutOrder = i,
			onTap = function()
				overlay.open("player", function(close: () -> ()): any
					return e(PlayerDetailModal, { player = player, onClose = close })
				end)
			end,
		})
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		_pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, Theme.chrome.padX),
			PaddingRight = UDim.new(0, Theme.chrome.padX),
			PaddingTop = UDim.new(0, Theme.space.md),
		}),
		header = e(SectionHeader, {
			text = string.format("ROSTER · %d PLAYERS", #roster),
		}),
		chips = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 28 + Theme.space.sm),
			Size = UDim2.new(1, 0, 0, 56),
		}, {
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, Theme.space.sm),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			ovr = e(StatChip, {
				label = "AVG OVR",
				value = avgOvr,
				accent = Theme.ovrColor(avgOvr),
				size = UDim2.new(1 / 3, -Theme.space.sm, 1, 0),
				layoutOrder = 1,
			}),
			stars = e(StatChip, {
				label = "STARS",
				value = stars,
				accent = Theme.gold,
				size = UDim2.new(1 / 3, -Theme.space.sm, 1, 0),
				layoutOrder = 2,
			}),
			age = e(StatChip, {
				label = "AVG AGE",
				value = string.format("%.1f", totalAge / #roster),
				size = UDim2.new(1 / 3, -Theme.space.sm, 1, 0),
				layoutOrder = 3,
			}),
		}),
		sort = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 28 + Theme.space.sm + 56 + Theme.space.sm),
			Size = UDim2.new(1, 0, 0, 36),
		}, {
			chips = e(SortChips, {
				options = SORT_OPTIONS,
				active = sortKey,
				ascending = ascending,
				onSelect = onSort,
			}),
		}),
		scroll = e("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, HEADER_H),
			Size = UDim2.new(1, 0, 1, -HEADER_H),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.line,
		}, rows),
	})
end

return Roster
