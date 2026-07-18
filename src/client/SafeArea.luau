--!strict
-- Safe-area insets: both ScreenGuis keep IgnoreGuiInset=true (backgrounds bleed to the
-- screen edge), so CONTENT insets by these measured values. TopBar total height =
-- insets.top + Theme.chrome.topBarH; TabBar total = Theme.chrome.tabBarH + max(insets.bottom, 8).

local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

export type Insets = { top: number, bottom: number, left: number, right: number }

local SafeArea = {}

function SafeArea.get(): Insets
	local tl, br = GuiService:GetGuiInset()
	return { top = tl.Y, left = tl.X, right = br.X, bottom = br.Y }
end

local function sameInsets(a: Insets, b: Insets): boolean
	return a.top == b.top and a.bottom == b.bottom and a.left == b.left and a.right == b.right
end

-- Hook: insets that re-render on viewport changes (rotation, window resize).
function SafeArea.useInsets(): Insets
	local insets, setInsets = React.useState(SafeArea.get())

	React.useEffect(function()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local conn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			local fresh = SafeArea.get()
			setInsets(function(prev: Insets)
				return if sameInsets(prev, fresh) then prev else fresh
			end)
		end)
		return function()
			conn:Disconnect()
		end
	end, {})

	return insets
end

return SafeArea
