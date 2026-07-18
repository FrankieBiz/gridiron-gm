--!strict
-- Renders the modal stack inside the overlay gui: scrim (tap = close) + centered card
-- shell with spring entrance. Only the topmost modal receives input. The card surface
-- is an inert TextButton so taps never fall through to the screen below.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Parent.Theme)
local Sound = require(script.Parent.Parent.Sound)
local motion = require(script.Parent.Parent.motion)

local e = React.createElement

type ModalEntry = {
	id: string,
	build: (close: () -> ()) -> any,
}

export type Props = {
	modals: { ModalEntry },
	onClose: (id: string) -> (),
}

local function ModalShell(props: {
	entry: ModalEntry,
	topmost: boolean,
	onClose: (id: string) -> (),
})
	local entry = props.entry

	local scrimT = motion.useSpring(Theme.scrim.transparency, motion.Motion.spring.gentle)
	local scale, scaleApi = motion.useMotor(0.92)
	local closingRef = React.useRef(false)

	React.useEffect(function()
		Sound.play("swoosh")
		scaleApi.setTarget(1, motion.Motion.spring.pop)
	end, {})

	-- The app's one deferred unmount: reverse the entrance, then actually close.
	local function requestClose()
		if closingRef.current then
			return
		end
		closingRef.current = true
		Sound.play("swoosh", { speed = 1.1 })
		scaleApi.setTarget(0.94, motion.Motion.spring.snappy)
		task.delay(0.13, function()
			props.onClose(entry.id)
		end)
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = Theme.z.modal,
	}, {
		_scrim = e("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Theme.scrim.color,
			BackgroundTransparency = scrimT,
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			Active = props.topmost,
			ZIndex = Theme.z.modal,
			[React.Event.Activated] = requestClose,
		}),
		_card = e("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			AutomaticSize = Enum.AutomaticSize.XY,
			ZIndex = Theme.z.modal + 1,
		}, {
			_scale = e("UIScale", { Scale = scale }),
			content = entry.build(requestClose),
		}),
	})
end

local function ModalHost(props: Props)
	local children: { [string]: any } = {}
	for i, entry in props.modals do
		children["m_" .. entry.id] = e(ModalShell, {
			entry = entry,
			topmost = i == #props.modals,
			onClose = props.onClose,
		})
	end
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = Theme.z.modal,
	}, children)
end

return ModalHost
