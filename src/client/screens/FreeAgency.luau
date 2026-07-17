--!strict
-- Free agency: sign available veterans with coaching credits, then start the season.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Parent.components.Button)

local e = React.createElement

type Props = {
	freeAgents: { any },
	credits: number,
	onSign: (id: string) -> (),
	onFinish: () -> (),
}

local function FreeAgency(props: Props)
	local rows: { [string]: any } = {
		layout = e(
			"UIListLayout",
			{ Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
		),
	}

	if #props.freeAgents == 0 then
		rows.empty = e("TextLabel", {
			Text = "No free agents left. Start the season!",
			Font = Theme.font.body,
			TextColor3 = Theme.chalkSoft,
			TextSize = 15,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	for i, fa in props.freeAgents do
		local afford = props.credits >= fa.cost
		rows["fa_" .. fa.id] = e("Frame", {
			BackgroundColor3 = Theme.field2,
			Size = UDim2.new(1, 0, 0, 54),
			LayoutOrder = i,
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			pos = e("TextLabel", {
				Text = fa.position,
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = Theme.flag,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(12, 9),
				Size = UDim2.fromOffset(44, 18),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 16 }) }),
			name = e("TextLabel", {
				Text = fa.name,
				Font = Theme.font.bold,
				TextScaled = true,
				TextColor3 = Theme.chalk,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(60, 8),
				Size = UDim2.new(1, -220, 0, 18),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 15 }) }),
			meta = e("TextLabel", {
				Text = string.format("Age %d   ·   %d OVR", fa.age, fa.overall),
				Font = Theme.font.medium,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(60, 30),
				Size = UDim2.new(1, -220, 0, 14),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 13 }) }),
			sign = e("TextButton", {
				Text = "🪙 " .. fa.cost,
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = if afford then Theme.chalk else Theme.chalkSoft,
				BackgroundColor3 = if afford then Theme.flag else Theme.field3,
				Position = UDim2.new(1, -84, 0.5, -18),
				Size = UDim2.fromOffset(74, 36),
				BorderSizePixel = 0,
				AutoButtonColor = afford,
				[React.Event.Activated] = function()
					if afford then
						props.onSign(fa.id)
					end
				end,
			}, {
				corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
				pad = e(
					"UIPadding",
					{ PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }
				),
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.field,
		BorderSizePixel = 0,
	}, {
		grad = e(
			"UIGradient",
			{ Rotation = 90, Color = ColorSequence.new(Theme.bgTop, Theme.bgBottom) }
		),
		header = e("Frame", {
			BackgroundColor3 = Theme.field3,
			Size = UDim2.new(1, 0, 0, 60),
			BorderSizePixel = 0,
		}, {
			title = e("TextLabel", {
				Text = "💰 FREE AGENCY",
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = Theme.chalk,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(16, 12),
				Size = UDim2.fromScale(0.55, 0.6),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 24 }) }),
			credits = e("TextLabel", {
				Text = "🪙 " .. props.credits,
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = Theme.gold,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -120, 0, 14),
				Size = UDim2.fromOffset(106, 32),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 24 }) }),
		}),
		list = e("ScrollingFrame", {
			Size = UDim2.new(1, -24, 1, -140),
			Position = UDim2.fromOffset(12, 68),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, rows),
		start = e("Frame", {
			Size = UDim2.new(1, -24, 0, 56),
			Position = UDim2.new(0, 12, 1, -66),
			BackgroundTransparency = 1,
		}, {
			btn = e(Button, {
				text = "START THE SEASON  ▶",
				onActivated = props.onFinish,
				size = UDim2.fromScale(1, 1),
			}),
		}),
	})
end

return FreeAgency
