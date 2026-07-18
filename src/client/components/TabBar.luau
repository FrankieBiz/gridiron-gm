--!strict
-- Bottom tab bar: ONE sliding pill glides behind six icon-over-label buttons (spring
-- with light overshoot), icon hop + label crossfade on activation, safe-area padded.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Nav = require(script.Parent.Parent.Nav)
local SafeArea = require(script.Parent.Parent.SafeArea)
local Sound = require(script.Parent.Parent.Sound)
local motion = require(script.Parent.Parent.motion)

local e = React.createElement

export type Props = {
	active: Nav.Tab,
	onSelect: (tab: Nav.Tab) -> (),
}

local function TabButton(props: {
	def: Nav.TabDef,
	isActive: boolean,
	order: number,
	onSelect: (tab: Nav.Tab) -> (),
})
	local def = props.def
	local hop, hopApi = motion.useMotor(0)
	local fade = motion.useSpring(if props.isActive then 1 else 0, motion.Motion.spring.gentle)

	React.useEffect(function()
		if props.isActive then
			hopApi.snap(0)
			hopApi.impulse(-90)
		end
	end, { props.isActive } :: { any })

	return e("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Size = UDim2.fromScale(1 / #Nav.TABS, 1),
		LayoutOrder = props.order,
		ZIndex = Theme.z.chrome + 1,
		[React.Event.Activated] = function()
			if not props.isActive then
				Sound.play("tick")
				props.onSelect(def.id)
			end
		end,
	}, {
		icon = e("TextLabel", {
			Text = def.icon,
			Font = Theme.font.body,
			TextSize = 18,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),
			Position = hop:map(function(y: number): UDim2
				return UDim2.fromOffset(0, 6 + math.floor(math.clamp(y, -6, 6) * 0.045))
			end),
			ZIndex = Theme.z.chrome + 1,
		}),
		label = e("TextLabel", {
			Text = def.label,
			Font = Theme.type.eyebrow.font,
			TextSize = 10,
			TextColor3 = Theme.chalk,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(1, 0, 0, 12),
			ZIndex = Theme.z.chrome + 1,
			TextTransparency = fade:map(function(f: number): number
				return 0.35 * (1 - math.clamp(f, 0, 1))
			end),
		}),
	})
end

local function TabBar(props: Props)
	local insets = SafeArea.useInsets()
	local bottomPad = math.max(insets.bottom, Theme.space.sm)
	local totalH = Theme.chrome.tabBarH + bottomPad

	local activeIndex = Nav.tabIndex(props.active)
	local pillX = motion.useSpring((activeIndex - 1) / #Nav.TABS, motion.Motion.spring.slide)

	local children: { [string]: any } = {
		_topline = e("Frame", {
			BackgroundColor3 = Theme.border.base,
			Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0,
			ZIndex = Theme.z.chrome + 2,
		}),
		_row = e(
			"Frame",
			{
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 1),
				Size = UDim2.new(1, 0, 0, Theme.chrome.tabBarH),
			},
			(function(): { [string]: any }
				local row: { [string]: any } = {
					layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				}
				for i, def in Nav.TABS do
					row["tab_" .. def.id] = e(TabButton, {
						def = def,
						isActive = props.active == def.id,
						order = i,
						onSelect = props.onSelect,
					})
				end
				return row
			end)()
		),
		_pill = e("Frame", {
			BackgroundColor3 = Theme.flag,
			Size = UDim2.new(1 / #Nav.TABS, -12, 0, Theme.chrome.tabBarH - 12),
			Position = pillX:map(function(x: number): UDim2
				return UDim2.new(x, 6, 0, 7)
			end),
			BorderSizePixel = 0,
			ZIndex = Theme.z.chrome,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
			grad = e("UIGradient", { Rotation = 90, Color = Theme.grad.primaryBtn }),
		}),
	}

	return e("Frame", {
		BackgroundColor3 = Theme.bg.base,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, totalH),
		BorderSizePixel = 0,
		ZIndex = Theme.z.chrome,
	}, children)
end

return TabBar
