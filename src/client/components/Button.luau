--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

type Props = {
	text: string,
	onActivated: () -> (),
	color: Color3?,
	textColor: Color3?,
	size: UDim2?,
	layoutOrder: number?,
}

local function Button(props: Props)
	return e("TextButton", {
		Text = props.text,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = props.textColor or Theme.chalk,
		BackgroundColor3 = props.color or Theme.flag,
		Size = props.size or UDim2.fromScale(0.72, 0.12),
		AutoButtonColor = true,
		LayoutOrder = props.layoutOrder or 0,
		BorderSizePixel = 0,
		[React.Event.Activated] = props.onActivated,
	}, {
		corner = e("UICorner", { CornerRadius = UDim.new(0, 10) }),
		pad = e("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}),
	})
end

return Button
