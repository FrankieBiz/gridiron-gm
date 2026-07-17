--!strict
-- Between-seasons career decision: your grade from the owner, then stay or take a job offer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Card = require(script.Parent.Parent.components.Card)
local Button = require(script.Parent.Parent.components.Button)

local e = React.createElement

type Props = {
	report: any,
	offers: { any },
	team: any,
	prestige: number,
	onChoose: (teamId: string) -> (),
}

local function stars(n: number): string
	return string.rep("★", n) .. string.rep("☆", 5 - n)
end

local function CareerDecision(props: Props)
	local r = props.report
	local fired = r.fired
	local gradeText = string.format(
		"Owner wanted %d+ wins — you won %d.\n%s%s  ·  Reputation %s%d",
		r.expectedWins,
		r.actualWins,
		if r.champion
			then "🏆 CHAMPIONS!  "
			elseif r.madePlayoffs then "Made the playoffs.  "
			else "Missed the playoffs.  ",
		if r.met then "Expectations met." else "Fell short.",
		if r.repDelta >= 0 then "+" else "",
		r.repDelta
	)

	local items: { [string]: any } = {
		layout = e(
			"UIListLayout",
			{ Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }
		),
		pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
		}),
		grade = e(Card, {
			size = UDim2.new(1, 0, 0, 132),
			layoutOrder = 1,
			color = if fired then Theme.flagDeep else Theme.field2,
			children = {
				title = e("TextLabel", {
					Text = if fired then "YOU'VE BEEN FIRED" else "SEASON REVIEW",
					Font = Theme.font.display,
					TextScaled = true,
					TextColor3 = Theme.chalk,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.fromOffset(16, 14),
					Size = UDim2.new(1, -32, 0, 26),
				}, { max = e("UITextSizeConstraint", { MaxTextSize = 24 }) }),
				grade = e("TextLabel", {
					Text = gradeText,
					Font = Theme.font.medium,
					TextColor3 = if fired then Theme.chalk else Theme.chalkSoft,
					TextScaled = false,
					TextSize = 15,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					Position = UDim2.fromOffset(16, 48),
					Size = UDim2.new(1, -32, 0, 72),
				}),
			},
		}),
	}

	local order = 2

	if not fired then
		items.stay = e(Card, {
			size = UDim2.new(1, 0, 0, 92),
			layoutOrder = order,
			children = {
				info = e("TextLabel", {
					Text = string.format(
						"STAY  ·  %s %s  %s",
						props.team.city,
						props.team.name,
						stars(props.prestige)
					),
					Font = Theme.font.bold,
					TextScaled = true,
					TextColor3 = Theme.chalk,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.fromOffset(16, 12),
					Size = UDim2.new(1, -32, 0, 18),
				}, { max = e("UITextSizeConstraint", { MaxTextSize = 16 }) }),
				btn = e("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(16, 40),
					Size = UDim2.new(1, -32, 0, 38),
				}, {
					b = e(Button, {
						text = "CONTINUE HERE",
						color = Theme.field3,
						size = UDim2.fromScale(1, 1),
						onActivated = function()
							props.onChoose(props.team.id)
						end,
					}),
				}),
			},
		})
		order += 1
	end

	local hasOffers = props.offers and #props.offers > 0
	if hasOffers then
		items.offersTitle = e("TextLabel", {
			Text = if fired then "TAKE A NEW JOB" else "JOB OFFERS",
			Font = Theme.font.bold,
			TextScaled = true,
			TextColor3 = Theme.flag,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = order,
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 15 }) })
		order += 1

		for i, offer in props.offers do
			items["offer_" .. offer.teamId] = e(Card, {
				size = UDim2.new(1, 0, 0, 96),
				layoutOrder = order + i,
				children = {
					info = e("TextLabel", {
						Text = string.format(
							"%s %s  %s",
							offer.city,
							offer.name,
							stars(offer.prestige)
						),
						Font = Theme.font.bold,
						TextScaled = true,
						TextColor3 = Theme.chalk,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						Position = UDim2.fromOffset(16, 12),
						Size = UDim2.new(1, -32, 0, 18),
					}, { max = e("UITextSizeConstraint", { MaxTextSize = 16 }) }),
					tag = e("TextLabel", {
						Text = string.format(
							"%s  ·  owner wants %d+ wins",
							offer.tag,
							offer.expectedWins
						),
						Font = Theme.font.medium,
						TextScaled = true,
						TextColor3 = Theme.chalkSoft,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						Position = UDim2.fromOffset(16, 32),
						Size = UDim2.new(1, -32, 0, 14),
					}, { max = e("UITextSizeConstraint", { MaxTextSize = 13 }) }),
					btn = e("Frame", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(16, 50),
						Size = UDim2.new(1, -32, 0, 34),
					}, {
						b = e(Button, {
							text = "ACCEPT JOB",
							size = UDim2.fromScale(1, 1),
							onActivated = function()
								props.onChoose(offer.teamId)
							end,
						}),
					}),
				},
			})
		end
	elseif fired then
		-- Safety net: no team bit, owner reconsiders.
		items.reconsider = e(Card, {
			size = UDim2.new(1, 0, 0, 80),
			layoutOrder = order,
			children = {
				btn = e("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(16, 20),
					Size = UDim2.new(1, -32, 0, 40),
				}, {
					b = e(Button, {
						text = "OWNER RECONSIDERS — STAY",
						size = UDim2.fromScale(1, 1),
						onActivated = function()
							props.onChoose(props.team.id)
						end,
					}),
				}),
			},
		})
	end

	return e("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, items)
end

return CareerDecision
