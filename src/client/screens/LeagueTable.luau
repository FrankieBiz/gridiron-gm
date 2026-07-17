--!strict
-- Full league standings with points for / against.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

type Props = {
	teamId: string,
	teams: { any },
	standings: { any },
}

local function LeagueTable(props: Props)
	local byId = {}
	for _, t in props.teams do
		byId[t.id] = t
	end

	local rows: { [string]: any } = {
		layout = e(
			"UIListLayout",
			{ Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }
		),
		header = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),
			LayoutOrder = 0,
		}, {
			t = e("TextLabel", {
				Text = "TEAM",
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(36, 2),
				Size = UDim2.fromOffset(120, 16),
			}),
			r = e("TextLabel", {
				Text = "W-L      PF/PA      DIFF",
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -230, 0, 2),
				Size = UDim2.fromOffset(222, 16),
			}),
		}),
	}

	for i, row in props.standings do
		local t = byId[row.teamId]
		local mine = row.teamId == props.teamId
		local isTop4 = i <= 4
		rows["s_" .. row.teamId] = e("Frame", {
			BackgroundColor3 = if mine then Theme.field2 else Theme.field3,
			Size = UDim2.new(1, 0, 0, 34),
			LayoutOrder = i,
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
			seed = e("Frame", {
				BackgroundColor3 = if isTop4 then Theme.flag else Theme.line,
				Size = UDim2.new(0, 4, 1, 0),
				BorderSizePixel = 0,
			}),
			rank = e("TextLabel", {
				Text = tostring(i),
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextColor3 = if isTop4 then Theme.flag else Theme.chalkSoft,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 8),
				Size = UDim2.fromOffset(22, 18),
			}),
			name = e("TextLabel", {
				Text = t and (t.abbr .. "  " .. t.name) or row.teamId,
				Font = if mine then Enum.Font.GothamBlack else Enum.Font.Gotham,
				TextScaled = true,
				TextColor3 = if mine then Theme.flag else Theme.chalk,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(40, 8),
				Size = UDim2.new(1, -260, 0, 18),
			}),
			stats = e("TextLabel", {
				Text = string.format(
					"%d-%d      %d/%d      %+d",
					row.w,
					row.l,
					row.pf,
					row.pa,
					row.diff
				),
				Font = Enum.Font.GothamMedium,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -230, 0, 8),
				Size = UDim2.fromOffset(222, 18),
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		title = e("TextLabel", {
			Text = "STANDINGS  ·  TOP 4 MAKE PLAYOFFS",
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = Theme.chalkSoft,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(14, 12),
			Size = UDim2.fromOffset(320, 16),
		}),
		list = e("ScrollingFrame", {
			Size = UDim2.new(1, -24, 1, -46),
			Position = UDim2.fromOffset(12, 36),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, rows),
	})
end

return LeagueTable
