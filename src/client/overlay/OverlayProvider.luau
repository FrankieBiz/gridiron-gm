--!strict
-- Overlay service: toasts, modals, and celebrations rendered via createPortal into the
-- GridironGM_Overlay ScreenGui, above all screens and chrome. Hosts receive state via
-- props (never useOverlay — require cycle). API: toast / open / close / celebrate.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local ToastStack = require(script.Parent.ToastStack)
local ModalHost = require(script.Parent.ModalHost)
local Celebration = require(script.Parent.Celebration)

local e = React.createElement

export type ToastKind = "error" | "success" | "info"
export type ToastInput = {
	kind: ToastKind,
	title: string, -- ALL-CAPS broadcast headline
	detail: string?,
	duration: number?, -- defaults: error 5.0, success 3.5, info 3.0
}
export type CelebrationKind = "confetti" | "goldBloom"

export type OverlayApi = {
	toast: (input: ToastInput) -> (),
	open: (id: string, build: (close: () -> ()) -> any) -> (),
	close: (id: string) -> (),
	celebrate: (kind: CelebrationKind) -> (),
}

export type ToastEntry = {
	id: number,
	kind: ToastKind,
	title: string,
	detail: string?,
	duration: number,
}

export type ModalEntry = {
	id: string,
	build: (close: () -> ()) -> any,
}

local Overlay = {}

Overlay.Context = React.createContext(nil :: OverlayApi?)

local DURATIONS: { [ToastKind]: number } = { error = 5.0, success = 3.5, info = 3.0 }

export type ProviderProps = {
	gui: ScreenGui,
	children: any,
}

function Overlay.Provider(props: ProviderProps): any
	local toasts, setToasts = React.useState({} :: { ToastEntry })
	local modals, setModals = React.useState({} :: { ModalEntry })
	local celebration, setCelebration = React.useState(nil :: CelebrationKind?)
	local nextId = React.useRef(0)

	local api: OverlayApi = React.useMemo(function(): OverlayApi
		local function close(id: string)
			setModals(function(prev: { ModalEntry }): { ModalEntry }
				local out = {}
				for _, m in prev do
					if m.id ~= id then
						table.insert(out, m)
					end
				end
				return out
			end)
		end
		return {
			toast = function(input: ToastInput)
				nextId.current += 1
				local entry: ToastEntry = {
					id = nextId.current,
					kind = input.kind,
					title = input.title,
					detail = input.detail,
					duration = input.duration or DURATIONS[input.kind],
				}
				setToasts(function(prev: { ToastEntry }): { ToastEntry }
					-- Dedupe: refresh instead of stacking an identical visible toast.
					for _, t in prev do
						if t.kind == entry.kind and t.title == entry.title then
							return prev
						end
					end
					local out = table.clone(prev)
					table.insert(out, entry)
					return out
				end)
			end,
			open = function(id: string, build: (close: () -> ()) -> any)
				setModals(function(prev: { ModalEntry }): { ModalEntry }
					local out = {}
					for _, m in prev do
						if m.id ~= id then
							table.insert(out, m)
						end
					end
					table.insert(out, { id = id, build = build })
					return out
				end)
			end,
			close = close,
			celebrate = function(kind: CelebrationKind)
				setCelebration(kind)
			end,
		}
	end, {})

	local function dismissToast(id: number)
		setToasts(function(prev: { ToastEntry }): { ToastEntry }
			local out = {}
			for _, t in prev do
				if t.id ~= id then
					table.insert(out, t)
				end
			end
			return out
		end)
	end

	return e(Overlay.Context.Provider, { value = api }, {
		children = React.createElement(React.Fragment, nil, props.children),
		portal = ReactRoblox.createPortal({
			celebration = e(Celebration, {
				kind = celebration,
				onDone = function()
					setCelebration(nil)
				end,
			}),
			modals = e(ModalHost, {
				modals = modals,
				onClose = api.close,
			}),
			toasts = e(ToastStack, {
				toasts = toasts,
				onDismiss = dismissToast,
			}),
		}, props.gui),
	})
end

function Overlay.useOverlay(): OverlayApi
	local api = React.useContext(Overlay.Context)
	assert(api ~= nil, "useOverlay called outside OverlayProvider")
	return api
end

return Overlay
