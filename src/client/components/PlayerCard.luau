--!strict
-- Full-screen player detail modal. Shown when a roster row is tapped; onClose dismisses.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

type Props = {
	player: any,
	onClose: () -> (),
}

-- A labelled attribute bar (0-99).
local function attr(name: string, value: number, order: number): any
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = order,
	}, {
		label = e("TextLabel", {
			Text = name,
			Font = Theme.font.bold,
			TextScaled = true,
			TextColor3 = Theme.chalkSoft,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromOffset(110, 16),
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 13 }) }),
		num = e("TextLabel", {
			Text = tostring(value),
			Font = Theme.font.display,
			TextScaled = true,
			TextColor3 = Theme.ovrColor(value),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(1, -44, 0, 0),
			Size = UDim2.fromOffset(40, 16),
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 15 }) }),
		track = e("Frame", {
			BackgroundColor3 = Theme.field3,
			Position = UDim2.fromOffset(0, 20),
			Size = UDim2.new(1, 0, 0, 8),
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			fill = e("Frame", {
				BackgroundColor3 = Theme.ovrColor(value),
				Size = UDim2.fromScale(math.clamp(value / 99, 0, 1), 1),
				BorderSizePixel = 0,
			}, { corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
		}),
	})
end

local function PlayerCard(props: Props)
	local p = props.player
	return e("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ZIndex = 20,
		[React.Event.Activated] = props.onClose,
	}, {
		card = e("Frame", {
			BackgroundColor3 = Theme.panel,
			Size = UDim2.fromScale(0.86, 0.62),
			Position = UDim2.fromScale(0.07, 0.19),
			BorderSizePixel = 0,
			ZIndex = 21,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 16) }),
			stroke = e(
				"UIStroke",
				{ Color = Theme.devColor(p.devTrait), Transparency = 0.3, Thickness = 2 }
			),
			pad = e("UIPadding", {
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
				PaddingTop = UDim.new(0, 18),
				PaddingBottom = UDim.new(0, 18),
			}),
			pos = e("TextLabel", {
				Text = p.position,
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = Theme.flag,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.fromOffset(70, 30),
				ZIndex = 22,
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 28 }) }),
			ovr = e("TextLabel", {
				Text = tostring(p.overall),
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = Theme.ovrColor(p.overall),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -70, 0, 0),
				Size = UDim2.fromOffset(70, 34),
				ZIndex = 22,
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 34 }) }),
			name = e("TextLabel", {
				Text = p.name,
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = Theme.chalk,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(0, 34),
				Size = UDim2.new(1, 0, 0, 26),
				ZIndex = 22,
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 24 }) }),
			meta = e("TextLabel", {
				Text = string.format(
					"Age %d   ·   %s   ·   ▲ ceiling %d",
					p.age,
					string.upper(p.devTrait or "normal"),
					p.potential
				),
				Font = Theme.font.medium,
				TextScaled = true,
				TextColor3 = Theme.devColor(p.devTrait),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(0, 62),
				Size = UDim2.new(1, 0, 0, 16),
				ZIndex = 22,
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 14 }) }),
			attrs = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 88),
				Size = UDim2.new(1, 0, 0, 116),
				ZIndex = 22,
			}, {
				layout = e(
					"UIListLayout",
					{ Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }
				),
				a1 = attr("SPEED", p.speed, 1),
				a2 = attr("STRENGTH", p.strength, 2),
				a3 = attr("AWARENESS", p.awareness, 3),
			}),
			contract = e("TextLabel", {
				Text = string.format(
					"Contract: %d yr   ·   $%d salary   ·   morale %d",
					p.contractYears,
					p.salary,
					p.morale
				),
				Font = Theme.font.medium,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 0, 1, -46),
				Size = UDim2.new(1, 0, 0, 16),
				ZIndex = 22,
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 13 }) }),
			close = e("TextLabel", {
				Text = "tap anywhere to close",
				Font = Theme.font.body,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.new(0, 0, 1, -20),
				Size = UDim2.new(1, 0, 0, 14),
				ZIndex = 22,
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 12 }) }),
		}),
	})
end

return PlayerCard
