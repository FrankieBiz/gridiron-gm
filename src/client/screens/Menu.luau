--!strict
-- Title screen — the first impression. Big wordmark, gradient field, accent bars, and
-- premium menu buttons. (Kept static-safe; entrance animation lives in App's mount.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Parent.components.Button)

local e = React.createElement

type Props = {
	hasFranchise: boolean,
	onNew: () -> (),
	onContinue: () -> (),
}

local function Menu(props: Props)
	local menuChildren: { [string]: any } = {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	if props.hasFranchise then
		menuChildren.continueBtn = e(Button, {
			text = "▶  CONTINUE DYNASTY",
			onActivated = props.onContinue,
			layoutOrder = 1,
			size = UDim2.new(1, 0, 0, 58),
		})
		menuChildren.newBtn = e(Button, {
			text = "NEW FRANCHISE",
			onActivated = props.onNew,
			color = Theme.field2,
			layoutOrder = 2,
			size = UDim2.new(1, 0, 0, 52),
		})
	else
		menuChildren.newBtn = e(Button, {
			text = "▶  START YOUR DYNASTY",
			onActivated = props.onNew,
			layoutOrder = 1,
			size = UDim2.new(1, 0, 0, 58),
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.field,
		BorderSizePixel = 0,
	}, {
		grad = e("UIGradient", {
			Rotation = 115,
			Color = ColorSequence.new(Theme.bgTop, Theme.bgBottom),
		}),
		-- Decorative yard-line stripes down the field.
		stripes = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			s1 = e("Frame", {
				BackgroundColor3 = Theme.line,
				BackgroundTransparency = 0.5,
				Size = UDim2.new(0, 2, 1, 0),
				Position = UDim2.fromScale(0.25, 0),
				BorderSizePixel = 0,
			}),
			s2 = e("Frame", {
				BackgroundColor3 = Theme.line,
				BackgroundTransparency = 0.5,
				Size = UDim2.new(0, 2, 1, 0),
				Position = UDim2.fromScale(0.5, 0),
				BorderSizePixel = 0,
			}),
			s3 = e("Frame", {
				BackgroundColor3 = Theme.line,
				BackgroundTransparency = 0.5,
				Size = UDim2.new(0, 2, 1, 0),
				Position = UDim2.fromScale(0.75, 0),
				BorderSizePixel = 0,
			}),
		}),
		kicker = e("TextLabel", {
			Text = "FRONT-OFFICE FOOTBALL",
			Font = Theme.font.bold,
			TextScaled = true,
			TextColor3 = Theme.flag,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.1, 0.17),
			Size = UDim2.fromScale(0.8, 0.035),
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 18 }) }),
		accent = e("Frame", {
			BackgroundColor3 = Theme.flag,
			Size = UDim2.fromScale(0.14, 0.006),
			Position = UDim2.fromScale(0.1, 0.215),
			BorderSizePixel = 0,
		}),
		title1 = e("TextLabel", {
			Text = "GRIDIRON",
			Font = Theme.font.display,
			TextScaled = true,
			TextColor3 = Theme.chalk,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.1, 0.24),
			Size = UDim2.fromScale(0.8, 0.13),
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 76 }) }),
		title2 = e("TextLabel", {
			Text = "GM",
			Font = Theme.font.display,
			TextScaled = true,
			TextColor3 = Theme.flag,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.1, 0.37),
			Size = UDim2.fromScale(0.8, 0.13),
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 76 }) }),
		tagline = e("TextLabel", {
			Text = "Build a dynasty. Draft the future. Win it all.",
			Font = Theme.font.medium,
			TextScaled = true,
			TextColor3 = Theme.chalkSoft,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.1, 0.52),
			Size = UDim2.fromScale(0.8, 0.04),
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 17 }) }),
		menu = e("Frame", {
			Size = UDim2.fromScale(0.8, 0.24),
			Position = UDim2.fromScale(0.1, 0.62),
			BackgroundTransparency = 1,
		}, menuChildren),
		footer = e("TextLabel", {
			Text = "v1 · a two-person studio game",
			Font = Theme.font.body,
			TextScaled = true,
			TextColor3 = Theme.chalkSoft,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.1, 0.94),
			Size = UDim2.fromScale(0.8, 0.03),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, { max = e("UITextSizeConstraint", { MaxTextSize = 13 }) }),
	})
end

return Menu
