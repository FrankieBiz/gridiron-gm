--!strict
-- Your roster: overall, age, potential, and dev trait for every player.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local PlayerCard = require(script.Parent.Parent.components.PlayerCard)

local e = React.createElement

type Props = {
	team: any, -- full team with roster
}

local function Roster(props: Props)
	local selected, setSelected = React.useState(nil :: any)

	local sorted = table.clone(props.team.roster)
	table.sort(sorted, function(a, b)
		return a.overall > b.overall
	end)

	local rows: { [string]: any } = {
		layout = e(
			"UIListLayout",
			{ Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
		),
	}
	for i, p in sorted do
		rows["p_" .. p.id] = e("TextButton", {
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = Theme.field2,
			Size = UDim2.new(1, -12, 0, 50),
			LayoutOrder = i,
			BorderSizePixel = 0,
			[React.Event.Activated] = function()
				setSelected(p)
			end,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			dev = e("Frame", {
				BackgroundColor3 = Theme.devColor(p.devTrait),
				Size = UDim2.new(0, 5, 1, 0),
				BorderSizePixel = 0,
			}, { corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }) }),
			pos = e("TextLabel", {
				Text = p.position,
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextColor3 = Theme.flag,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(16, 8),
				Size = UDim2.fromOffset(48, 20),
			}),
			name = e("TextLabel", {
				Text = p.name,
				Font = Enum.Font.GothamMedium,
				TextScaled = true,
				TextColor3 = Theme.chalk,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(70, 7),
				Size = UDim2.new(1, -230, 0, 20),
			}),
			meta = e("TextLabel", {
				Text = string.format("Age %d · %s", p.age, string.upper(p.devTrait or "normal")),
				Font = Enum.Font.Gotham,
				TextScaled = true,
				TextColor3 = Theme.devColor(p.devTrait),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(70, 28),
				Size = UDim2.new(1, -230, 0, 14),
			}),
			ovr = e("TextLabel", {
				Text = tostring(p.overall),
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextColor3 = Theme.ovrColor(p.overall),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -110, 0, 8),
				Size = UDim2.fromOffset(50, 34),
			}),
			pot = e("TextLabel", {
				Text = "▲" .. tostring(p.potential),
				Font = Enum.Font.GothamMedium,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -56, 0, 15),
				Size = UDim2.fromOffset(48, 20),
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		title = e("TextLabel", {
			Text = string.format("ROSTER · %d PLAYERS", #sorted),
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = Theme.chalkSoft,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(14, 12),
			Size = UDim2.fromOffset(260, 16),
		}),
		hint = e("TextLabel", {
			Text = "tap a player for details",
			Font = Theme.font.body,
			TextScaled = true,
			TextColor3 = Theme.chalkSoft,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(1, -140, 0, 12),
			Size = UDim2.fromOffset(126, 16),
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 12 }) }),
		list = e("ScrollingFrame", {
			Size = UDim2.new(1, -24, 1, -46),
			Position = UDim2.fromOffset(12, 36),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, rows),
		modal = if selected
			then e(PlayerCard, {
				player = selected,
				onClose = function()
					setSelected(nil)
				end,
			})
			else nil,
	})
end

return Roster
