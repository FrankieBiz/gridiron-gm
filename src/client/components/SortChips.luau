--!strict
-- Sort control row for data tables (Roster, FreeAgency): pill chips, active shows
-- direction; tapping the active chip flips ascending.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Sound = require(script.Parent.Parent.Sound)

local e = React.createElement

export type Option = { id: string, label: string }

export type Props = {
	options: { Option },
	active: string,
	ascending: boolean,
	onSelect: (id: string) -> (),
	layoutOrder: number?,
}

local function SortChips(props: Props)
	local children: { [string]: any } = {
		_layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, Theme.space.sm),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for i, opt in props.options do
		local isActive = props.active == opt.id
		local label = if isActive
			then opt.label .. (if props.ascending then " ▲" else " ▼")
			else opt.label
		children["chip_" .. opt.id] = e("TextButton", {
			Text = string.upper(label),
			Font = Theme.type.eyebrow.font,
			TextSize = Theme.type.eyebrow.size,
			TextColor3 = if isActive then Theme.chalk else Theme.text.secondary,
			BackgroundColor3 = if isActive then Theme.flag else Theme.surface.base,
			AutoButtonColor = false,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 28),
			LayoutOrder = i,
			BorderSizePixel = 0,
			[React.Event.Activated] = function()
				Sound.play("tick", { volume = 0.18 })
				props.onSelect(opt.id)
			end,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			pad = e("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}),
			stroke = if not isActive
				then e("UIStroke", {
					Color = Theme.strokes.hairline.color,
					Transparency = Theme.strokes.hairline.transparency,
					Thickness = 1,
				})
				else nil,
		})
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = props.layoutOrder,
	}, children)
end

return SortChips
