--!strict
-- Hosts the toast queue: top-center stack (max 3 visible), auto-dismiss timers, slot
-- positions springing as toasts come and go. State arrives via props from the provider.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local SafeArea = require(script.Parent.Parent.SafeArea)
local Sound = require(script.Parent.Parent.Sound)
local motion = require(script.Parent.Parent.motion)
local Toast = require(script.Parent.Parent.components.Toast)

local e = React.createElement

type ToastEntry = {
	id: number,
	kind: "error" | "success" | "info",
	title: string,
	detail: string?,
	duration: number,
}

export type Props = {
	toasts: { ToastEntry },
	onDismiss: (id: number) -> (),
}

local SLOT_H = 64 -- nominal slot pitch; AutomaticSize toasts may run taller but 3 max

local function ToastItem(props: {
	entry: ToastEntry,
	slot: number,
	width: number,
	topInset: number,
	onDismiss: (id: number) -> (),
})
	local entry = props.entry
	local targetY = props.topInset + Theme.space.sm + (props.slot - 1) * (SLOT_H + Theme.space.sm)

	local y, yApi = motion.useMotor(targetY - 56)

	React.useEffect(function()
		yApi.setTarget(targetY, motion.Motion.spring.slide)
	end, { targetY } :: { any })

	React.useEffect(function()
		Sound.play(if entry.kind == "error" then "toast_error" else "toast_ok")
		local alive = true
		task.delay(entry.duration, function()
			if alive then
				props.onDismiss(entry.id)
			end
		end)
		return function()
			alive = false
		end
	end, {})

	return e(Toast, {
		kind = entry.kind,
		title = entry.title,
		detail = entry.detail,
		y = y,
		width = props.width,
		onDismiss = function()
			props.onDismiss(entry.id)
		end,
	})
end

local function ToastStack(props: Props)
	local insets = SafeArea.useInsets()
	local camera = workspace.CurrentCamera
	local viewportW = if camera then camera.ViewportSize.X else 375
	local width = math.min(viewportW - 32, 420)

	local children: { [string]: any } = {}
	local visible = math.min(#props.toasts, 3)
	for slot = 1, visible do
		local entry = props.toasts[slot]
		children["t" .. entry.id] = e(ToastItem, {
			entry = entry,
			slot = slot,
			width = width,
			topInset = insets.top,
			onDismiss = props.onDismiss,
		})
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = Theme.z.toast,
	}, children)
end

return ToastStack
