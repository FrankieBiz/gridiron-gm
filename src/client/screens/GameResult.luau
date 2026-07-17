--!strict
-- The "feel a game" screen: reveal the play-by-play one beat at a time with the score
-- climbing, then a win/loss banner. In a game with no 3D, this reveal IS the special effect.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Parent.components.Button)

local e = React.createElement

type Props = {
	game: any, -- { result, homeName, awayName, record }
	teamId: string?,
	onDone: () -> (),
}

local REVEAL_INTERVAL = 0.55

local function GameResult(props: Props)
	local game = props.game
	local result = game.result
	local plays = result.plays

	local revealed, setRevealed = React.useState(0)
	local done, setDone = React.useState(#plays == 0)

	React.useEffect(function()
		local running = true
		task.spawn(function()
			for i = 1, #plays do
				if not running then
					return
				end
				task.wait(REVEAL_INTERVAL)
				setRevealed(i)
			end
			if running then
				setDone(true)
			end
		end)
		return function()
			running = false
		end
	end, {})

	local playerIsHome = props.teamId == result.homeId

	local hs, as = 0, 0
	if done then
		hs, as = result.home.score, result.away.score
	elseif revealed > 0 then
		hs, as = plays[revealed].homeScore, plays[revealed].awayScore
	end

	-- Ticker rows, latest first.
	local ticker: { [string]: any } = {
		layout = e("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	local shown = if done then #plays else revealed
	local order = 0
	for i = shown, 1, -1 do
		order += 1
		local play = plays[i]
		ticker["play_" .. i] = e("TextLabel", {
			Text = string.format("Q%d  %s   %s", play.quarter, play.clock, play.text),
			Font = if play.big then Enum.Font.GothamBold else Enum.Font.Gotham,
			TextScaled = true,
			TextColor3 = if play.big then Theme.flag else Theme.chalkSoft,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -8, 0, 34),
			LayoutOrder = order,
		})
	end

	local playerWon = result.winnerId == props.teamId
	local myBox = if playerIsHome then result.home else result.away
	local oppBox = if playerIsHome then result.away else result.home

	local footer: { [string]: any }
	if done then
		footer = {
			banner = e("TextLabel", {
				Text = if playerWon then "WIN!" else "LOSS",
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextColor3 = if playerWon then Theme.gold else Theme.chalkSoft,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.34),
			}),
			stats = e("TextLabel", {
				Text = string.format(
					"YOU  %d pass / %d rush / %d TO      OPP  %d pass / %d rush / %d TO",
					myBox.passYards,
					myBox.rushYards,
					myBox.turnovers,
					oppBox.passYards,
					oppBox.rushYards,
					oppBox.turnovers
				),
				Font = Enum.Font.Gotham,
				TextScaled = true,
				TextColor3 = Theme.chalkSoft,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.22),
				Position = UDim2.fromScale(0, 0.36),
			}),
			cont = e("Frame", {
				Size = UDim2.fromScale(0.7, 0.32),
				Position = UDim2.fromScale(0.15, 0.62),
				BackgroundTransparency = 1,
			}, {
				btn = e(
					Button,
					{ text = "CONTINUE", onActivated = props.onDone, size = UDim2.fromScale(1, 1) }
				),
			}),
		}
	else
		footer = {
			skip = e("Frame", {
				Size = UDim2.fromScale(0.5, 0.4),
				Position = UDim2.fromScale(0.25, 0.3),
				BackgroundTransparency = 1,
			}, {
				btn = e(Button, {
					text = "SKIP ▶▶",
					color = Theme.field2,
					onActivated = function()
						setRevealed(#plays)
						setDone(true)
					end,
					size = UDim2.fromScale(1, 1),
				}),
			}),
		}
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		scoreboard = e("Frame", {
			BackgroundColor3 = Theme.field3,
			Size = UDim2.fromScale(1, 0.2),
			BorderSizePixel = 0,
		}, {
			home = e("TextLabel", {
				Text = string.format("%s  %d", game.homeName, hs),
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextColor3 = if playerIsHome then Theme.flag else Theme.chalk,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.06, 0.16),
				Size = UDim2.fromScale(0.88, 0.32),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			away = e("TextLabel", {
				Text = string.format("%s  %d", game.awayName, as),
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextColor3 = if not playerIsHome then Theme.flag else Theme.chalk,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.06, 0.54),
				Size = UDim2.fromScale(0.88, 0.32),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),
		ticker = e("ScrollingFrame", {
			Size = UDim2.fromScale(0.92, 0.48),
			Position = UDim2.fromScale(0.04, 0.22),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, ticker),
		footer = e("Frame", {
			Size = UDim2.fromScale(0.92, 0.26),
			Position = UDim2.fromScale(0.04, 0.72),
			BackgroundTransparency = 1,
		}, footer),
	})
end

return GameResult
