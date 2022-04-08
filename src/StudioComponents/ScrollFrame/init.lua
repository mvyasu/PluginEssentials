-- Written by @boatbomber

local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local getState = require(StudioComponentsUtil.getState)
local themeProvider = require(StudioComponentsUtil.themeProvider)
local unwrap = require(StudioComponentsUtil.unwrap)
local types = require(StudioComponentsUtil.types)
local stripProps = require(StudioComponentsUtil.stripProps)

local scrollConstants = require(script.Constants)
local ScrollArrow = require(script.ScrollArrow)

local Computed = Fusion.Computed
local Hydrate = Fusion.Hydrate
local Value = Fusion.Value
local New = Fusion.New
local Children = Fusion.Children
local OnChange = Fusion.OnChange
local Ref = Fusion.Ref
local Out = Fusion.Out

local COMPONENT_ONLY_PROPERTIES = {
	"ScrollingEnabled",
	"VerticalScrollBarPosition",
	"VerticalScrollBarInset",
	Children,
}

type ScrollFrameProperties = {
	ScrollingEnabled: (boolean | types.StateObject<boolean>)?,
	VerticalScrollBarPosition: (Enum.VerticalScrollBarPosition | types.StateObject<Enum.VerticalScrollBarPosition>)?,
	VerticalScrollBarInset: (Enum.ScrollBarInset | types.StateObject<Enum.ScrollBarInset>)?,
	[any]: any,
}

return function(props: ScrollFrameProperties): Frame
	local isEnabled = getState(props.ScrollingEnabled, true)
	local vertPos = getState(props.VerticalScrollBarPosition, Enum.VerticalScrollBarPosition.Right)
	local vertInset = getState(props.VerticalScrollBarInset, Enum.ScrollBarInset.ScrollBar)

	local showVertBar, showHoriBar = Value(false), Value(false)

	local canvasPosition = Value(Vector2.zero)
	local contentSize = Value(Vector2.zero)
	local windowSize = Value(Vector2.zero)
	local absSize = Value(Vector2.zero)

	-- Offset the bar area by the buttons
	local relativeOffsetX = Computed(function()
		local size = unwrap(absSize) or Vector2.zero
		return (2*scrollConstants.ScrollBarSize)/size.X
	end)
	local relativeOffsetY = Computed(function()
		local size = unwrap(absSize) or Vector2.zero
		return (2*scrollConstants.ScrollBarSize)/size.Y
	end)

	local scrollFrame = Value(nil)
	local function computeShowBar()
		local scroll = unwrap(scrollFrame)
		if not scroll then
			showVertBar:set(false)
			return
		end

		local size, canvas = scroll.AbsoluteSize, scroll.AbsoluteCanvasSize

		showVertBar:set(size.Y < canvas.Y)
		showHoriBar:set(size.X < canvas.X)
	end

	local containerFrame = New "Frame" {
		Name = "ScrollFrame",
		BackgroundTransparency = 1,

		[Children] = {
			New "Frame" {
				Name = "VerticalBar",
				Visible = showVertBar,
				ZIndex = 2,
				BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.ScrollBarBackground),
				BorderColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.Border),
				BorderMode = Enum.BorderMode.Outline,
				BorderSizePixel = 1,
				Position = Computed(function()
					local vert = unwrap(vertPos)
					if vert == Enum.VerticalScrollBarPosition.Right then
						return UDim2.fromScale(1, 0)
					else
						return UDim2.fromScale(0, 0)
					end
				end),
				AnchorPoint = Computed(function()
					local vert = unwrap(vertPos)
					if vert == Enum.VerticalScrollBarPosition.Right then
						return Vector2.new(1, 0)
					else
						return Vector2.new(0, 0)
					end
				end),
				Size = UDim2.new(0, scrollConstants.ScrollBarSize, 1, 0),

				[Children] = {
					ScrollArrow {
						Name = "UpArrow",
						Direction = "Up",
						Activated = function()
							local p = unwrap(canvasPosition) or Vector2.zero
							canvasPosition:set(Vector2.new(
								p.X,
								math.clamp(p.Y-25, 0, math.huge)
							))
						end,
					},
					ScrollArrow {
						Name = "DownArrow",
						Direction = "Down",
						Activated = function()
							local p = unwrap(canvasPosition) or Vector2.zero
							local window = unwrap(windowSize) or Vector2.zero
							local content = unwrap(contentSize) or Vector2.zero
							canvasPosition:set(Vector2.new(
								p.X,
								math.clamp(p.Y+25, 0, content.Y-window.Y)
							))
						end,
					},
					New "Frame" {
						Name = "Handle",
						ZIndex = 10,
						Size = Computed(function()
							local window = unwrap(windowSize) or Vector2.zero
							local content = unwrap(contentSize) or Vector2.zero
							local relativeOffset = unwrap(relativeOffsetY)

							return UDim2.fromScale(
								1,
								(window.Y/content.Y) * (1-relativeOffset)
							)
						end),
						Position = Computed(function()
							local content = unwrap(contentSize) or Vector2.zero
							local pos = unwrap(canvasPosition) or Vector2.zero
							local relativeOffset = unwrap(relativeOffsetY)
							local relativePos = (pos.Y/content.Y)

							return UDim2.new(
								0, 0,
								relativePos * (1-relativeOffset), scrollConstants.ScrollBarSize
							)
						end),
						BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
						BorderColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.Border),
						BorderMode = Enum.BorderMode.Outline,
						BorderSizePixel = 1,
					},
				}
			},
			New "Frame" {
				Name = "HorizontalBar",
				Visible = showHoriBar,
				ZIndex = 2,
				BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.ScrollBarBackground),
				BorderColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.Border),
				BorderMode = Enum.BorderMode.Outline,
				BorderSizePixel = 1,
				Position = UDim2.fromScale(0, 1),
				AnchorPoint = Vector2.new(0,1),
				Size = UDim2.new(1, -scrollConstants.ScrollBarSize, 0, scrollConstants.ScrollBarSize),

				[Children] = {
					ScrollArrow {
						Name = "LeftArrow",
						Direction = "Left",
						Activated = function()
							local p = unwrap(canvasPosition) or Vector2.zero
							canvasPosition:set(Vector2.new(
								math.clamp(p.X-25, 0, math.huge),
								p.Y
							))
						end,
					},
					ScrollArrow {
						Name = "RightArrow",
						Direction = "Right",
						Activated = function()
							local p = unwrap(canvasPosition) or Vector2.zero
							local window = unwrap(windowSize) or Vector2.zero
							local content = unwrap(contentSize) or Vector2.zero
							canvasPosition:set(Vector2.new(
								math.clamp(p.X+25, 0, content.X-window.X),
								p.Y
							))
						end,
					},
					New "Frame" {
						Name = "Handle",
						ZIndex = 10,
						Size = Computed(function()
							local window = unwrap(windowSize) or Vector2.zero
							local content = unwrap(contentSize) or Vector2.zero
							local relativeOffset = unwrap(relativeOffsetX)

							return UDim2.fromScale(
								(window.X/content.X) * (1-relativeOffset),
								1
							)
						end),
						Position = Computed(function()
							local content = unwrap(contentSize) or Vector2.zero
							local pos = unwrap(canvasPosition) or Vector2.zero
							local relativeOffset = unwrap(relativeOffsetX)
							local relativePos = (pos.X/content.X)

							return UDim2.new(
								relativePos * (1-relativeOffset), scrollConstants.ScrollBarSize,
								0, 0
							)
						end),
						BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
						BorderColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.Border),
						BorderMode = Enum.BorderMode.Outline,
						BorderSizePixel = 1,
					},
				}
			},
			New "ScrollingFrame" {
				[Ref] = scrollFrame,

				Name = "Canvas",
				Size = UDim2.fromScale(1, 1),
				CanvasSize = Computed(function()
					local s = unwrap(contentSize) or Vector2.zero
					return UDim2.fromOffset(0, s.Y)
				end),
				BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
				TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
				MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
				ScrollingEnabled = isEnabled,
				ScrollBarThickness = 12,
				VerticalScrollBarPosition = vertPos,
				HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
				VerticalScrollBarInset = vertInset,
				ScrollBarImageTransparency = 1,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,

				CanvasPosition = canvasPosition,
				[Out "CanvasPosition"] = canvasPosition,
				[Out "AbsoluteWindowSize"] = windowSize,
				[Out "AbsoluteSize"] = absSize,

				[OnChange "AbsoluteWindowSize"] = computeShowBar,
				[OnChange "AbsoluteCanvasSize"] = computeShowBar,

				[Children] = {
					New "UIListLayout" {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 0),
						[Out "AbsoluteContentSize"] = contentSize,
					},
					props[Children],
				}
			}
		}
	}

	local hydrateProps = stripProps(props, COMPONENT_ONLY_PROPERTIES)
	return Hydrate(containerFrame)(hydrateProps)
end
