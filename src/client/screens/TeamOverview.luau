--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Parent.components.Button)

local e = React.createElement

type Props = {
	team: any, -- full team with roster
	record: { wins: number, losses: number, gamesPlayed: number },
	onSim: () -> (),
	onBack: () -> (),
}

local function ovrColor(ovr: number): Color3
	if ovr >= 85 then
		return Theme.gold
	elseif ovr >= 75 then
		return Theme.chalk
	end
	return Theme.chalkSoft
end

local function TeamOverview(props: Props)
	local team = props.team

	local sorted = table.clone(team.roster)
	table.sort(sorted, function(a, b)
		return a.overall > b.overall
	end)

	local rows: { [string]: any } = {
		layout = e("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for i, p in sorted do
		rows["p_" .. p.id] = e("Frame", {
			BackgroundColor3 = Theme.field2,
			Size = UDim2.new(1, -12, 0, 46),
			LayoutOrder = i,
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			pos = e("TextLabel", {
				Text = p.position,
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextColor3 = Theme.flag,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0.2, 0),
				Size = UDim2.new(0, 52, 0.6, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			name = e("TextLabel", {
				Text = p.name,
				Font = Enum.Font.GothamMedium,
				TextScaled = true,
				TextColor3 = Theme.chalk,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 70, 0.22, 0),
				Size = UDim2.new(1, -150, 0.56, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			ovr = e("TextLabel", {
				Text = tostring(p.overall),
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextColor3 = ovrColor(p.overall),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -60, 0.2, 0),
				Size = UDim2.new(0, 48, 0.6, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		bar = e("Frame", {
			BackgroundColor3 = Theme.hex(team.primary),
			Size = UDim2.fromScale(1, 0.16),
			BorderSizePixel = 0,
		}, {
			name = e("TextLabel", {
				Text = string.upper(team.city) .. " " .. team.name,
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextColor3 = Theme.chalk,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.05, 0.2),
				Size = UDim2.fromScale(0.9, 0.4),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			record = e("TextLabel", {
				Text = string.format("RECORD  %d - %d", props.record.wins, props.record.losses),
				Font = Enum.Font.GothamMedium,
				TextScaled = true,
				TextColor3 = Theme.hex(team.secondary),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.05, 0.62),
				Size = UDim2.fromScale(0.6, 0.26),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),
		list = e("ScrollingFrame", {
			Size = UDim2.fromScale(0.92, 0.6),
			Position = UDim2.fromScale(0.04, 0.18),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, rows),
		sim = e("Frame", {
			Size = UDim2.fromScale(0.92, 0.11),
			Position = UDim2.fromScale(0.04, 0.8),
			BackgroundTransparency = 1,
		}, {
			btn = e(Button, {
				text = "▶  SIM NEXT GAME",
				onActivated = props.onSim,
				size = UDim2.fromScale(1, 1),
			}),
		}),
		back = e("Frame", {
			Size = UDim2.fromScale(0.92, 0.06),
			Position = UDim2.fromScale(0.04, 0.925),
			BackgroundTransparency = 1,
		}, {
			btn = e(Button, {
				text = "MENU",
				onActivated = props.onBack,
				color = Theme.field2,
				size = UDim2.fromScale(1, 1),
			}),
		}),
	})
end

return TeamOverview
