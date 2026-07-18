--!strict
-- Boot screen: wordmark fade + skeleton shimmer while the first fetch runs. App holds
-- this for at least 0.6s so the boot never strobes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local motion = require(script.Parent.Parent.motion)
local Skeleton = require(script.Parent.Parent.components.Skeleton)

local e = React.createElement

local function Loading()
	local entrance = motion.useProgress(nil, { duration = 0.25 })

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		stack = e("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromOffset(280, 140),
		}, {
			layout = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, Theme.space.md),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			word1 = e("TextLabel", {
				Text = "GRIDIRON",
				Font = Theme.type.display.font,
				TextSize = Theme.type.display.size,
				TextColor3 = Theme.chalk,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 34),
				LayoutOrder = 1,
				TextTransparency = entrance:map(function(p: number): number
					return 1 - p
				end),
			}),
			word2 = e("TextLabel", {
				Text = "GM",
				Font = Theme.type.display.font,
				TextSize = Theme.type.display.size,
				TextColor3 = Theme.flag,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 34),
				LayoutOrder = 2,
				TextTransparency = entrance:map(function(p: number): number
					return 1 - p
				end),
			}),
			bone1 = e(Skeleton, { height = 12, width = UDim.new(0, 280), layoutOrder = 3 }),
			bone2 = e(Skeleton, { height = 12, width = UDim.new(0, 200), layoutOrder = 4 }),
			bone3 = e(Skeleton, { height = 12, width = UDim.new(0, 240), layoutOrder = 5 }),
		}),
	})
end

return Loading
