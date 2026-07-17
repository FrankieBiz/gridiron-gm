--!strict
-- The interactive draft board: scout prospects to narrow their fog-of-war range, then
-- draft one when you're on the clock. AI fills the rest.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

type Props = {
	draft: any, -- DraftBoard.view output
	onScout: (prospectId: string) -> (),
	onPick: (prospectId: string) -> (),
}

local function DraftRoom(props: Props)
	local d = props.draft
	local onClock = d.isMyPick

	local rows: { [string]: any } = {
		layout = e(
			"UIListLayout",
			{ Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
		),
	}
	for i, p in d.prospects do
		local ovrRange = if p.ovrMin == p.ovrMax
			then tostring(p.ovrMin)
			else (p.ovrMin .. "-" .. p.ovrMax)
		local potRange = if p.potMin == p.potMax
			then tostring(p.potMin)
			else (p.potMin .. "-" .. p.potMax)
		local fog = (p.ovrMax - p.ovrMin) -- wider = less scouted
		rows["p_" .. p.id] = e("Frame", {
			BackgroundColor3 = Theme.field2,
			Size = UDim2.new(1, 0, 0, 58),
			LayoutOrder = i,
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			pos = e("TextLabel", {
				Text = p.position,
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = Theme.flag,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(12, 10),
				Size = UDim2.fromOffset(44, 18),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 16 }) }),
			name = e("TextLabel", {
				Text = p.name,
				Font = Theme.font.bold,
				TextScaled = true,
				TextColor3 = Theme.chalk,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(60, 9),
				Size = UDim2.new(1, -260, 0, 18),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 15 }) }),
			ratings = e("TextLabel", {
				Text = string.format(
					"OVR %s   ▲%s   %s",
					ovrRange,
					potRange,
					if fog <= 2 then "scouted" else "scouting…"
				),
				Font = Theme.font.medium,
				TextScaled = true,
				TextColor3 = if fog <= 2 then Theme.gold else Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(60, 30),
				Size = UDim2.new(1, -260, 0, 16),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 13 }) }),
			scout = e("TextButton", {
				Text = "🔍",
				Font = Theme.font.bold,
				TextScaled = true,
				TextColor3 = Theme.chalk,
				BackgroundColor3 = Theme.field3,
				Position = UDim2.new(1, -104, 0.5, -18),
				Size = UDim2.fromOffset(44, 36),
				BorderSizePixel = 0,
				AutoButtonColor = d.scoutPoints > 0,
				[React.Event.Activated] = function()
					if d.scoutPoints > 0 then
						props.onScout(p.id)
					end
				end,
			}, {
				corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
				pad = e(
					"UIPadding",
					{ PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }
				),
			}),
			pick = e("TextButton", {
				Text = "PICK",
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = if onClock then Theme.chalk else Theme.chalkSoft,
				BackgroundColor3 = if onClock then Theme.flag else Theme.field3,
				Position = UDim2.new(1, -52, 0.5, -18),
				Size = UDim2.fromOffset(44, 36),
				BorderSizePixel = 0,
				AutoButtonColor = onClock,
				[React.Event.Activated] = function()
					if onClock then
						props.onPick(p.id)
					end
				end,
			}, {
				corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
				pad = e("UIPadding", {
					PaddingTop = UDim.new(0, 6),
					PaddingBottom = UDim.new(0, 6),
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
				}),
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
			Size = UDim2.new(1, 0, 0, 76),
			BorderSizePixel = 0,
		}, {
			title = e("TextLabel", {
				Text = "🎯 THE DRAFT",
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = Theme.chalk,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(16, 12),
				Size = UDim2.fromScale(0.6, 0.4),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 24 }) }),
			status = e("TextLabel", {
				Text = if onClock
					then string.format(
						"YOU'RE ON THE CLOCK  ·  pick %d of %d",
						d.pickNumber,
						d.totalPicks
					)
					else string.format("Pick %d of %d", d.pickNumber, d.totalPicks),
				Font = Theme.font.bold,
				TextScaled = true,
				TextColor3 = if onClock then Theme.flag else Theme.chalkSoft,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(16, 46),
				Size = UDim2.fromScale(0.6, 0.28),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 15 }) }),
			scoutPts = e("TextLabel", {
				Text = "🔍 " .. d.scoutPoints,
				Font = Theme.font.display,
				TextScaled = true,
				TextColor3 = Theme.gold,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -110, 0, 20),
				Size = UDim2.fromOffset(96, 34),
			}, { max = e("UITextSizeConstraint", { MaxTextSize = 26 }) }),
		}),
		list = e("ScrollingFrame", {
			Size = UDim2.new(1, -24, 1, -92),
			Position = UDim2.fromOffset(12, 84),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, rows),
	})
end

return DraftRoom
