--!strict
-- Team HQ: spend coaching credits to upgrade facilities. Tangible, visible progression.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Parent.components.Button)
local Card = require(script.Parent.Parent.components.Card)
local FacilitiesData = require(ReplicatedStorage.Shared.Data.Facilities)

local e = React.createElement

type Props = {
	facilities: { [string]: number },
	credits: number,
	onUpgrade: (key: string) -> (),
}

local function pips(level: number): any
	local children: { [string]: any } = {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for i = 1, FacilitiesData.MAX_LEVEL do
		children["p" .. i] = e("Frame", {
			BackgroundColor3 = if i <= level then Theme.flag else Theme.line,
			Size = UDim2.fromScale(1 / FacilitiesData.MAX_LEVEL, 1),
			LayoutOrder = i,
			BorderSizePixel = 0,
		}, { corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }) })
	end
	return e("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 10) }, children)
end

local function Facilities(props: Props)
	local cards: { [string]: any } = {
		layout = e(
			"UIListLayout",
			{ Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }
		),
		pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 12),
		}),
	}

	for i, fac in FacilitiesData.list do
		local level = props.facilities[fac.key] or 1
		local maxed = level >= FacilitiesData.MAX_LEVEL
		local cost = FacilitiesData.costForNext(level)
		local afford = props.credits >= cost
		local btnText = if maxed then "MAX LEVEL" else string.format("UPGRADE · 🪙 %d", cost)

		cards["c_" .. fac.key] = e(Card, {
			size = UDim2.new(1, 0, 0, 148),
			layoutOrder = i,
			children = {
				icon = e("TextLabel", {
					Text = fac.icon,
					TextScaled = true,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(14, 12),
					Size = UDim2.fromOffset(40, 40),
				}),
				name = e("TextLabel", {
					Text = string.upper(fac.name),
					Font = Theme.font.display,
					TextScaled = true,
					TextColor3 = Theme.chalk,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.fromOffset(62, 14),
					Size = UDim2.new(1, -160, 0, 20),
				}, { max = e("UITextSizeConstraint", { MaxTextSize = 19 }) }),
				lvl = e("TextLabel", {
					Text = "LEVEL " .. level,
					Font = Theme.font.bold,
					TextScaled = true,
					TextColor3 = Theme.flag,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Right,
					Position = UDim2.new(1, -110, 0, 14),
					Size = UDim2.fromOffset(96, 18),
				}, { max = e("UITextSizeConstraint", { MaxTextSize = 15 }) }),
				effect = e("TextLabel", {
					Text = fac.effect,
					Font = Theme.font.body,
					TextScaled = true,
					TextColor3 = Theme.chalkSoft,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.fromOffset(62, 40),
					Size = UDim2.new(1, -76, 0, 28),
				}, { max = e("UITextSizeConstraint", { MaxTextSize = 14 }) }),
				pips = e("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(14, 78),
					Size = UDim2.new(1, -28, 0, 10),
				}, { bar = pips(level) }),
				upgrade = e("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(14, 98),
					Size = UDim2.new(1, -28, 0, 38),
				}, {
					btn = e(Button, {
						text = btnText,
						size = UDim2.fromScale(1, 1),
						disabled = maxed or not afford,
						color = if maxed then Theme.field3 else nil,
						onActivated = function()
							props.onUpgrade(fac.key)
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
	}, cards)
end

return Facilities
