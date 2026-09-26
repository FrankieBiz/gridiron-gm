--!strict
-- Last line of defense: any render crash anywhere shows a themed recovery screen
-- instead of a black void. Tapping remounts the whole tree via a generation key.
-- Sits OUTSIDE OverlayProvider so even a provider crash recovers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Theme = require(script.Parent.Theme)

local e = React.createElement

export type Props = { children: any }
type State = { generation: number, message: string? }

local ErrorBoundary = React.Component:extend("ErrorBoundary")

function ErrorBoundary:init()
	self:setState({ generation = 1, message = React.None } :: any)
end

function ErrorBoundary.getDerivedStateFromError(err: any): { message: string }
	return { message = tostring(err) }
end

function ErrorBoundary:componentDidCatch(err: any, info: any)
	warn("[GRIDIRON] UI crashed:", err, info and info.componentStack)
end

function ErrorBoundary:render()
	local state = self.state :: State
	if state.message ~= nil then
		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.field,
			BorderSizePixel = 0,
		}, {
			grad = e("UIGradient", { Rotation = 90, Color = Theme.grad.app }),
			stack = e("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.45),
				Size = UDim2.fromOffset(300, 220),
			}, {
				layout = e("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, Theme.space.md),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				glyph = e("TextLabel", {
					Text = "📋",
					Font = Theme.font.body,
					TextSize = 44,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 52),
					LayoutOrder = 1,
				}),
				title = e("TextLabel", {
					Text = "CLIPBOARD MALFUNCTION",
					Font = Theme.type.h1.font,
					TextSize = Theme.type.h1.size,
					TextColor3 = Theme.chalk,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 26),
					LayoutOrder = 2,
				}),
				body = e("TextLabel", {
					Text = "Something snapped a play sheet in half. Tap below to restart the booth — your franchise is safe on the server.",
					Font = Theme.type.body.font,
					TextSize = Theme.type.body.size,
					TextColor3 = Theme.chalkSoft,
					TextWrapped = true,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 56),
					LayoutOrder = 3,
				}),
				btn = e("TextButton", {
					Text = "RESTART THE BOOTH",
					Font = Theme.type.h2.font,
					TextSize = Theme.type.h2.size,
					TextColor3 = Theme.chalk,
					BackgroundColor3 = Theme.flag,
					AutoButtonColor = true,
					Size = UDim2.new(1, 0, 0, Theme.size.buttonH),
					LayoutOrder = 4,
					BorderSizePixel = 0,
					[React.Event.Activated] = function()
						self:setState({
							generation = (self.state :: State).generation + 1,
							message = React.None,
						} :: any)
					end,
				}, {
					corner = e("UICorner", { CornerRadius = UDim.new(0, Theme.radius.md) }),
					grad = e("UIGradient", { Rotation = 90, Color = Theme.grad.primaryBtn }),
				}),
			}),
		})
	end

	-- Pass children through directly (props.children is already a keyed element table);
	-- the `key` on this wrapper forces a clean remount when generation changes on recovery.
	return e("Frame", {
		key = tostring(state.generation),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, (self.props :: Props).children)
end

return ErrorBoundary
