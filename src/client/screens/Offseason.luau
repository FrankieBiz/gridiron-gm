--!strict
-- Between-seasons recap: who won it all, who retired, who you drafted, credits earned.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Parent.components.Button)

local e = React.createElement

type Props = {
	summary: any,
	teams: { any },
	onDone: () -> (),
}

local function Offseason(props: Props)
	local s = props.summary
	local byId = {}
	for _, t in props.teams do
		byId[t.id] = t
	end
	local champTeam = s.champion and byId[s.champion]
	local champName = champTeam and (champTeam.city .. " " .. champTeam.name) or "—"

	local feed: { [string]: any } = {
		layout = e(
			"UIListLayout",
			{ Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
		),
	}
	local order = 0
	local function line(key: string, text: string, color: Color3)
		order += 1
		feed[key] = e("TextLabel", {
			Text = text,
			Font = Enum.Font.GothamMedium,
			TextScaled = true,
			TextColor3 = color,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -8, 0, 30),
			LayoutOrder = order,
		})
	end

	line("champ", "🏆 Champion: " .. champName, Theme.gold)
	line(
		"credhdr",
		string.format("🪙 +%d coaching credits (total %d)", s.creditsEarned, s.totalCredits),
		Theme.gold
	)

	line("rethdr", "— RETIREMENTS —", Theme.flag)
	if #s.retirees == 0 then
		line("ret_none", "None this year.", Theme.chalkSoft)
	else
		for i, p in s.retirees do
			line(
				"ret_" .. i,
				string.format("%s  %s  (age %d, %d OVR)", p.position, p.name, p.age, p.overall),
				Theme.chalkSoft
			)
		end
	end

	line("drafthdr", "— YOUR DRAFT PICKS —", Theme.flag)
	if #s.rookies == 0 then
		line("dr_none", "No picks.", Theme.chalkSoft)
	else
		for i, d in s.rookies do
			line(
				"dr_" .. i,
				string.format(
					"R%d  %s  %s  (%d OVR ▲%d, %s)",
					d.round,
					d.position,
					d.name,
					d.overall,
					d.potential,
					string.upper(d.devTrait or "normal")
				),
				Theme.devColor(d.devTrait)
			)
		end
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.field,
		BorderSizePixel = 0,
	}, {
		title = e("TextLabel", {
			Text = string.format("OFFSEASON · YEAR %d", s.year),
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			TextColor3 = Theme.chalk,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.05, 0.04),
			Size = UDim2.fromScale(0.9, 0.08),
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		list = e("ScrollingFrame", {
			Size = UDim2.fromScale(0.92, 0.72),
			Position = UDim2.fromScale(0.04, 0.14),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, feed),
		cont = e("Frame", {
			Size = UDim2.fromScale(0.92, 0.09),
			Position = UDim2.fromScale(0.04, 0.88),
			BackgroundTransparency = 1,
		}, {
			btn = e(Button, {
				text = string.format("START YEAR %d  ▶", s.nextYear),
				onActivated = props.onDone,
				size = UDim2.fromScale(1, 1),
			}),
		}),
	})
end

return Offseason
