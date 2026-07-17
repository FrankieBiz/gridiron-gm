--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Parent.components.Button)
local Teams = require(ReplicatedStorage.Shared.Data.Teams)

local e = React.createElement

type Props = {
	onPick: (teamId: string) -> (),
	onBack: () -> (),
}

local function TeamSelect(props: Props)
	local rows: { [string]: any } = {
		layout = e("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),
	}

	for i, team in Teams do
		rows["team_" .. team.id] = e("TextButton", {
			Text = "",
			BackgroundColor3 = Theme.hex(team.primary),
			Size = UDim2.new(1, -12, 0, 70),
			LayoutOrder = i,
			AutoButtonColor = true,
			BorderSizePixel = 0,
			[React.Event.Activated] = function()
				props.onPick(team.id)
			end,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 10) }),
			stripe = e("Frame", {
				BackgroundColor3 = Theme.hex(team.secondary),
				Size = UDim2.new(0, 8, 1, 0),
				BorderSizePixel = 0,
			}),
			label = e("TextLabel", {
				Text = string.upper(team.city) .. "  " .. team.name,
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.chalk,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(22, 12),
				Size = UDim2.new(1, -34, 1, -24),
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		header = e("TextLabel", {
			Text = "SELECT YOUR TEAM",
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			TextColor3 = Theme.chalk,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.9, 0.08),
			Position = UDim2.fromScale(0.05, 0.04),
		}),
		list = e("ScrollingFrame", {
			Size = UDim2.fromScale(0.9, 0.72),
			Position = UDim2.fromScale(0.05, 0.14),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, rows),
		back = e("Frame", {
			Size = UDim2.fromScale(0.9, 0.09),
			Position = UDim2.fromScale(0.05, 0.88),
			BackgroundTransparency = 1,
		}, {
			btn = e(Button, {
				text = "BACK",
				onActivated = props.onBack,
				color = Theme.field2,
				size = UDim2.fromScale(1, 1),
			}),
		}),
	})
end

return TeamSelect
