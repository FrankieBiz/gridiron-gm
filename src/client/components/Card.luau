--!strict
-- Rounded, subtly-stroked panel. Pass position/size + children.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

type Props = {
	size: UDim2,
	position: UDim2?,
	color: Color3?,
	layoutOrder: number?,
	children: { [string]: any }?,
}

local function Card(props: Props)
	local children: { [string]: any } = {
		corner = e("UICorner", { CornerRadius = UDim.new(0, 14) }),
		stroke = e("UIStroke", {
			Color = Theme.stroke,
			Transparency = Theme.strokeT,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	}
	if props.children then
		for k, v in props.children do
			children[k] = v
		end
	end

	return e("Frame", {
		Size = props.size,
		Position = props.position,
		BackgroundColor3 = props.color or Theme.field2,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, children)
end

return Card
