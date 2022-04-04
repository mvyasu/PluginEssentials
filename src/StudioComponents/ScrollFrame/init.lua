-- Roact version by @sircfenner
-- Ported to Fusion by @YasuYoshida

local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local ScrollArrow = require(script.ScrollArrow)
local ScrollBarHandle = require(script.ScrollBarHandle)

local getState = require(StudioComponentsUtil.getState)
local themeProvider = require(StudioComponentsUtil.themeProvider)
local unwrap = require(StudioComponentsUtil.unwrap)
local types = require(StudioComponentsUtil.types)

local scrollConstants = require(script.Constants)

local Children = Fusion.Children
local Computed = Fusion.Computed
local OnChange = Fusion.OnChange
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value
local New = Fusion.New

local BAR_SIZE = scrollConstants.ScrollBarSize
local SCROLL_STEP = scrollConstants.ScrollStep

local INITIAL_PROPERTIES = {
	"Enabled",
	"OnScrolled",
	"ScrollingDirection",
	"UIPadding",
	"Layout",
	"ZIndex",
	Children,
}

local function maxVector(vec, limit)
	return Vector2.new(math.max(vec.x, limit.x), math.max(vec.y, limit.y))
end

local function clampVector(vec, min, max)
	return Vector2.new(math.clamp(vec.x, min.x, max.x), math.clamp(vec.y, min.y, max.y))
end

local defaultLayout = {
	SortOrder = Enum.SortOrder.LayoutOrder,
}

local baseProperties = {
	BorderSizePixel = 1,
	ScrollingDirection = Enum.ScrollingDirection.Y,
}

type ScrollFrameProperties = {
	Enabled: (boolean | types.StateObject<boolean>)?,
	OnScrolled: ((newCanvasPosition: Vector2) -> nil)?,
	ScrollingDirection: (Enum.ScrollingDirection | types.StateObject<Enum.ScrollingDirection>)?,
	UIPadding: UIPadding?,
	Layout: UILayout?,
	[any]: any,
}

return function(props: ScrollFrameProperties): Frame
	-- properties --
	
	local function joinDictionaries(d1, d2)
		for index,value in pairs(d1) do
			if d2[index]==nil then
				d2[index] = value
			end
		end
		return d2
	end
	
	props = joinDictionaries(baseProperties, props)
	
	local isEnabled = getState(props.Enabled, true)
	
	local modifier = Computed(function()
		if not unwrap(isEnabled) then
			return Enum.StudioStyleGuideModifier.Disabled
		end
		return Enum.StudioStyleGuideModifier.Default
	end)
	
	-- input
	
	local listContentSize = Value(Vector2.new())
	local paddingAdjustment = Value({
		PaddingBottom = UDim.new(),
		PaddingLeft = UDim.new(),
		PaddingRight = UDim.new(),
		PaddingTop = UDim.new(),
	})
	
	local contentSize = Computed(function()
		local listContentSize = unwrap(listContentSize)
		local paddingAdjustment = unwrap(paddingAdjustment)
		return Vector2.new(
			listContentSize.X + paddingAdjustment.PaddingLeft.Offset + paddingAdjustment.PaddingRight.Offset,
			listContentSize.Y + paddingAdjustment.PaddingTop.Offset + paddingAdjustment.PaddingBottom.Offset
		)
	end)
	
	local windowSize = Value(Vector2.new())
	local canvasPosition = Value(Vector2.new())
	
	local function setCanvasPosition(newPosition)
		if props.OnScrolled then
			props.OnScrolled(newPosition)
		end
		canvasPosition:set(newPosition)
	end
	
	local scrollingDirection = getState(props.ScrollingDirection, Enum.ScrollingDirection.Y)
	local innerWindowSize = Computed(function()
		local direction =  unwrap(scrollingDirection)
		local hasX = direction ~= Enum.ScrollingDirection.Y
		local hasY = direction ~= Enum.ScrollingDirection.X
		
		local windowSize = unwrap(windowSize)
		local windowSizeWithBars = windowSize - Vector2.new(BAR_SIZE + 1, BAR_SIZE + 1)
		
		local contentSize = unwrap(contentSize)
		local barVisible = {
			x = hasX and contentSize.x > windowSizeWithBars.x,
			y = hasY and contentSize.y > windowSizeWithBars.y,
		}

		local sizeX = windowSize.x - (barVisible.y and BAR_SIZE + 1 or 0) -- +1 for inner bar border
		local sizeY = windowSize.y - (barVisible.x and BAR_SIZE + 1 or 0) -- as above
		return maxVector(Vector2.new(sizeX, sizeY), Vector2.new(0, 0))
	end)
	
	local barPosScale = Computed(function()
		local windowSize = unwrap(innerWindowSize)
		local region = unwrap(contentSize) - unwrap(windowSize)
		local canvasPosition = unwrap(canvasPosition)
		return Vector2.new(
			region.x > 0 and canvasPosition.x / region.x or 0,
			region.y > 0 and canvasPosition.y / region.y or 0
		)
	end)
	
	local barSizeScale = Computed(function()
		local contentSize = unwrap(contentSize)
		local windowSize = unwrap(innerWindowSize)
		local region = contentSize - windowSize
		return Vector2.new(
			region.x > 0 and windowSize.x / contentSize.x or 0,
			region.y > 0 and windowSize.y / contentSize.y or 0
		)
	end)
	
	local barVisible = Computed(function()
		local size = unwrap(barSizeScale)
		local direction = unwrap(scrollingDirection)
		local hasX = direction ~= Enum.ScrollingDirection.Y
		local hasY = direction ~= Enum.ScrollingDirection.X
		return {
			x = hasX and size.x > 0 and size.x < 1,
			y = hasY and size.y > 0 and size.y < 1,
		}
	end)
	
	local function refreshCanvasPosition()
		local contentSize = unwrap(contentSize)
		local windowSize = unwrap(innerWindowSize)
		local max = maxVector(contentSize - windowSize, Vector2.new(0, 0))
		
		local current = unwrap(canvasPosition)
		local target = clampVector(current, Vector2.new(0, 0), max)
		setCanvasPosition(target)
	end
	
	local function scroll(dir)
		local contentSize = unwrap(contentSize, false)
		local windowSize = unwrap(innerWindowSize, false)
		local max = maxVector(contentSize - windowSize, Vector2.new(0, 0))
		
		local current = unwrap(canvasPosition, false)
		local amount = dir * SCROLL_STEP
		setCanvasPosition(clampVector(current + amount, Vector2.new(0, 0), max))
	end
	
	local function maybeScrollInput(inputObject)
		if not unwrap(isEnabled, false) then
			return
		elseif inputObject.UserInputType == Enum.UserInputType.MouseWheel then
			local factor = -inputObject.Position.z
			local visible =  unwrap(barVisible, false)
			if visible.y then
				scroll(Vector2.new(0, factor))
			elseif visible.x then
				scroll(Vector2.new(factor, 0))
			end
		end
	end
	
	local dragBegin = nil
	
	local function onDragBegan()
		dragBegin = unwrap(canvasPosition, false)
	end
	
	local function onDragEnded()
		dragBegin = nil
	end
	
	local function onDragChanged(amount)
		local windowSize = unwrap(innerWindowSize, false)
		local contentSize = unwrap(contentSize, false)
		local region = maxVector(contentSize - windowSize, Vector2.new(0, 0))
		local barAreaSize = windowSize - 2 * Vector2.new(BAR_SIZE, BAR_SIZE) -- buttons
		local alpha = amount / barAreaSize
		local pos = dragBegin + alpha * contentSize
		setCanvasPosition(clampVector(pos, Vector2.new(0, 0), region))
	end
	
	local zIndex = Computed(function()
		return unwrap(props.ZIndex) or 1
	end)
	
	local newScrollFrame = New "Frame" {
		ZIndex = Computed(function()
			return unwrap(zIndex) - 1
		end),
		Name = "ScrollFrame",
		Size = UDim2.fromScale(1, 1),
		BorderMode = Enum.BorderMode.Inset,
		BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.MainBackground, modifier),
		BorderColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.Border, modifier),
		
		[OnChange "AbsoluteSize"] = function(newAbsoluteSize)
			local border = props.BorderSizePixel * Vector2.new(2, 2) -- each border
			windowSize:set(newAbsoluteSize - border)
			refreshCanvasPosition()
		end,
		[OnEvent "InputBegan"] = maybeScrollInput,
		[OnEvent "InputChanged"] = maybeScrollInput,
		
		[Children] = {
			New "Frame" {
				Name = "Cover",
				Visible = Computed(function()
					return not unwrap(isEnabled)
				end),
				ZIndex = Computed(function()
					return unwrap(zIndex) + 1
				end),
				Size = Computed(function()
					local visible = unwrap(barVisible)
					return UDim2.new(
						UDim.new(1, visible.y and -BAR_SIZE or 0),
						UDim.new(1, visible.x and -BAR_SIZE or 0)
					)
				end),
				BorderSizePixel = 0,
				BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.MainBackground),
				BackgroundTransparency = .25,
			},
			New "Frame" {
				Name = "Clipping",
				ZIndex = Computed(function()
					return unwrap(zIndex) - 1
				end),
				Size = Computed(function()
					local visible = unwrap(barVisible)
					return UDim2.new(
						UDim.new(1, visible.y and -BAR_SIZE-1 or 0),
						UDim.new(1, visible.x and -BAR_SIZE-1 or 0)
					)
				end),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				
				[Children] = New "Frame" {
					Name = "Holder",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Position = Computed(function()
						local pos = unwrap(canvasPosition)
						return UDim2.fromOffset(-pos.x, -pos.y)
					end),
					
					[Children] = {
						Computed(function()
							local layoutInstance = props.Layout or New "UIListLayout" (defaultLayout)
							return Hydrate(layoutInstance)({
								[OnChange "AbsoluteContentSize"] = function(newAbsoluteContentSize)
									listContentSize:set(newAbsoluteContentSize)
									refreshCanvasPosition()
								end,
							})
						end),
						Computed(function()
							local uiPadding = props.UIPadding
							if uiPadding then
								local function updatePaddingAdjust()
									paddingAdjustment:set({
										PaddingBottom = uiPadding.PaddingBottom,
										PaddingLeft = uiPadding.PaddingLeft,
										PaddingRight = uiPadding.PaddingRight,
										PaddingTop = uiPadding.PaddingTop
									})
								end
								
								return Hydrate(props.UIPadding)({
									[OnEvent "Changed"] = updatePaddingAdjust,
								})
							end
						end),
						props[Children]
					}
				}
			},
			New "Frame" {
				Name = "BarVertical",
				ZIndex = zIndex,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.ScrollBarBackground, modifier),
				BorderColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.Border, modifier),
				BorderSizePixel = 1,
				Size = Computed(function()
					local visible = unwrap(barVisible)
					local shift = visible.x and (-BAR_SIZE - 1) or 0
					return UDim2.new(0, BAR_SIZE, 1, shift)
				end),
				Visible = Computed(function()
					local visible = unwrap(barVisible)
					return visible.y
				end),
				
				[Children] = {
					ScrollArrow {
						ZIndex = zIndex,
						Name = "UpArrow",
						Enabled = isEnabled,
						Direction = "Up",
						Activated = function()
							scroll(Vector2.new(0, -0.25))
						end,
					},
					ScrollArrow {
						ZIndex = zIndex,
						Name = "DownArrow",
						Enabled = isEnabled,
						Direction = "Down",
						Activated = function()
							scroll(Vector2.new(0, 0.25))
						end,
					},
					New "Frame" {
						Name = "BarBackground",
						ZIndex = zIndex,
						Position = UDim2.fromOffset(0, BAR_SIZE + 1),
						Size = UDim2.new(1, 0, 1, -BAR_SIZE * 2 - 2),
						BackgroundTransparency = 1,
						
						[Children] = ScrollBarHandle {
							ZIndex = zIndex,
							Enabled = isEnabled,
							Position = Computed(function()
								local scale = unwrap(barPosScale)
								return UDim2.fromScale(0, scale.y)
							end),
							AnchorPoint = Computed(function()
								local scale = unwrap(barPosScale)
								return Vector2.new(0, scale.y)
							end),
							Size = Computed(function()
								local scale = unwrap(barSizeScale)
								return UDim2.fromScale(1, scale.y)
							end),
							
							DragBegan = onDragBegan,
							DragEnded = onDragEnded,
							DragChanged = function(amount)
								onDragChanged(amount * Vector2.new(0, 1))
							end,
						}
					}
				}
			},
			New "Frame" {
				Name = "BarHorizontal",
				ZIndex = zIndex,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.ScrollBarBackground, modifier),
				BorderColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.Border, modifier),
				BorderSizePixel = 1,
				Size = Computed(function()
					local visible = unwrap(barVisible)
					local shift = visible.y and (-BAR_SIZE - 1) or 0
					return UDim2.new(1, shift, 0, BAR_SIZE)
				end),
				Visible = Computed(function()
					local visible = unwrap(barVisible)
					return visible.x
				end),
				
				[Children] = {
					ScrollArrow {
						ZIndex = zIndex,
						Name = "LeftArrow",
						Enabled = isEnabled,
						Direction = "Left",
						Activated = function()
							scroll(Vector2.new(-0.25, 0))
						end,
					},
					ScrollArrow {
						ZIndex = zIndex,
						Name = "RightArrow",
						Enabled = isEnabled,
						Direction = "Right",
						Activated = function()
							scroll(Vector2.new(0.25, 0))
						end,
					},
					New "Frame" {
						Name = "BarBackground",
						Position = UDim2.fromOffset(BAR_SIZE + 1, 0),
						Size = UDim2.new(1, -BAR_SIZE * 2 - 2, 1, 0),
						BackgroundTransparency = 1,
						
						[Children] = ScrollBarHandle {
							Enabled = isEnabled,
							Position = Computed(function()
								local scale = unwrap(barPosScale)
								return UDim2.fromScale(scale.x, 0)
							end),
							AnchorPoint = Computed(function()
								local scale = unwrap(barPosScale)
								return Vector2.new(scale.x, 0)
							end),
							Size = Computed(function()
								local scale = unwrap(barSizeScale)
								return UDim2.fromScale(scale.x, 1)
							end),
							
							DragBegan = onDragBegan,
							DragEnded = onDragEnded,
							DragChanged = function(amount)
								onDragChanged(amount * Vector2.new(1, 0))
							end,
						}
					}
				}
			},
		}
	}
	
	local hydrateProps = table.clone(props)
	for _,propertyIndex in pairs(INITIAL_PROPERTIES) do
		hydrateProps[propertyIndex] = nil
	end
	
	return Hydrate(newScrollFrame)(hydrateProps)
end