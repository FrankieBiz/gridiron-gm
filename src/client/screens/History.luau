--!strict
-- Franchise history: championship banners and a season-by-season log. The trophy case
-- that makes a long save feel like YOUR dynasty.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Card = require(script.Parent.Parent.components.Card)

local e = React.createElement

type Props = {
	history: { any }, -- { year, wins, losses, champion, wonIt }
	teams: { any },
	coach: any,
}

local function History(props: Props)
	local history = props.history or {}
	local titles = 0
	for _, s in history do
		if s.wonIt then
			titles += 1
		end
	end

	local rows: { [string]: any } = {
		layout = e(
			"UIListLayout",
			{ Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }
		),
	}

	-- Trophy banner.
	rows.banner = e(Card, {
		size = UDim2.new(1, 0, 0, 84),
		layoutOrder = 1,
		color = if titles > 0 then Theme.field2 else Theme.field3,
		children = {
			t = e("TextLabel", {
				Text = if titles > 0
					then string.rep("🏆", math.min(titles, 8))
					else "No titles… yet.",
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = Theme.gold,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, 12),
				Size = UDim2.new(1, -32, 0, 34),
				TextXAlignment = Enum.TextXAlignment.Left,
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 30 }) }),
			sub = e("TextLabel", {
				Text = string.format(
					"%d CHAMPIONSHIP%s  ·  %d SEASONS",
					titles,
					if titles == 1 then "" else "S",
					#history
				),
				Font = Theme.font.bold,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, 52),
				Size = UDim2.new(1, -32, 0, 16),
				TextXAlignment = Enum.TextXAlignment.Left,
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 14 }) }),
		},
	})

	if #history == 0 then
		rows.empty = e("TextLabel", {
			Text = "Finish a season to start writing your history.",
			Font = Theme.font.body,
			TextColor3 = Theme.chalkSoft,
			TextSize = 14,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = 2,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	-- Newest season first.
	for idx = #history, 1, -1 do
		local s = history[idx]
		rows["y_" .. s.year] = e("Frame", {
			BackgroundColor3 = if s.wonIt then Theme.field2 else Theme.field3,
			Size = UDim2.new(1, 0, 0, 42),
			LayoutOrder = 100 - idx,
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			stripe = e("Frame", {
				BackgroundColor3 = if s.wonIt then Theme.gold else Theme.line,
				Size = UDim2.new(0, 4, 1, 0),
				BorderSizePixel = 0,
			}),
			year = e("TextLabel", {
				Text = "Y" .. s.year,
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = Theme.chalk,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, 11),
				Size = UDim2.fromOffset(44, 20),
				TextXAlignment = Enum.TextXAlignment.Left,
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 18 }) }),
			rec = e("TextLabel", {
				Text = string.format("%d-%d", s.wins, s.losses),
				Font = Theme.font.bold,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(66, 12),
				Size = UDim2.fromOffset(70, 18),
				TextXAlignment = Enum.TextXAlignment.Left,
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 16 }) }),
			result = e("TextLabel", {
				Text = if s.wonIt
					then "🏆 CHAMPIONS"
					else ("Champion: " .. tostring(s.champion or "—")),
				Font = Theme.font.medium,
				TextScaled = true,
				TextColor3 = if s.wonIt then Theme.gold else Theme.chalkSoft,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -170, 0, 12),
				Size = UDim2.fromOffset(158, 18),
				TextXAlignment = Enum.TextXAlignment.Right,
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 14 }) }),
		})
	end

	return e("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, {
		pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 12),
		}),
		rows = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, rows),
	})
end

return History
