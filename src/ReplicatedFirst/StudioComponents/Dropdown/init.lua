-- Roact version by @sircfenner
-- Ported to Fusion by @YasuYoshida

local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local ScrollFrame = require(StudioComponents.ScrollFrame)
local BoxBorder = require(StudioComponents.BoxBorder)
local DropdownItem = require(script.DropdownItem)

local getState = require(StudioComponentsUtil.getState)
local themeProvider = require(StudioComponentsUtil.themeProvider)
local constants = require(StudioComponentsUtil.constants)
local unwrap = require(StudioComponentsUtil.unwrap)
local types = require(StudioComponentsUtil.types)

local dropdownConstants = require(script.Constants)

local ForValues = Fusion.ForValues
local Computed = Fusion.Computed
local Children = Fusion.Children
local OnChange = Fusion.OnChange
local OnEvent = Fusion.OnEvent
local Hydrate = Fusion.Hydrate
local Value = Fusion.Value
local New = Fusion.New

local INITIAL_PROPERTIES = {
	"Enabled",
	"MaxVisibleItems",
	"Items",
	"Value",
	"ZIndex",
	"OnSelected",
	"Size",
}

type DropdownProperties = {
	Enabled: (boolean | types.StateObject<boolean>)?,
	Value: (string | types.Value<string>)?,
	Items: {string} | types.StateObject<{string}>,
	MaxVisibleItems: (number | types.StateObject<number>)?,
	OnSelected: (newItem: string) -> nil,
	[any]: any,
}

return function(props: DropdownProperties): Frame
	local isInputEnabled = getState(props.Enabled, true)
	local isHovering = Value(false)
	local isOpen = Value(false)
	local isEmpty = Value(false)
	
	local isEnabled = Computed(function()
		local isInputEnabled = unwrap(isInputEnabled)
		local isEmpty = unwrap(isEmpty)
		return isInputEnabled and not isEmpty
	end)

	local modifier = Computed(function()
		local isHovering = unwrap(isHovering)
		local isEnabled = unwrap(isEnabled)
		if not isEnabled then
			return Enum.StudioStyleGuideModifier.Disabled
		elseif isHovering then
			return Enum.StudioStyleGuideModifier.Hover
		end
		return Enum.StudioStyleGuideModifier.Default
	end)
	
	local backgroundStyleGuideColor = Computed(function()
		local isHovering = unwrap(isHovering)
		local isOpen = unwrap(isOpen)
		if isOpen or isHovering then
			return Enum.StudioStyleGuideColor.InputFieldBackground
		end
		return Enum.StudioStyleGuideColor.MainBackground
	end)
	
	local itemValue = getState(props.Value, nil)
	local function onSelectedItem(item)
		isOpen:set(false)
		itemValue:set(item)
		if props.OnSelected then
			props.OnSelected(item)
		end
	end
	
	--should this reallly be trying to select the
	--currently selected item? that might conflict with stuff
	local selectedItem = Computed(function()
		local dropdownItemList = unwrap(props.Items)
		local currentItem = unwrap(itemValue)
		if currentItem==nil then
			local _,nextItem = next(dropdownItemList)
			if nextItem~=nil then
				onSelectedItem(nextItem)
				return nextItem
			end
			isEmpty:set(true)
			return "Empty"
		end
		isEmpty:set(false)
		return currentItem
	end)
	
	local spaceBetweenTopAndDropdown = 5
	local dropdownPadding = UDim.new(0, 2)
	local dropdownSize = Computed(function()
		local propsSize = unwrap(props.Size)
		return propsSize or UDim2.new(1, 0, 0, dropdownConstants.RowHeight)
	end)
	
	local absoluteDropdownSize = Value(UDim2.new())
	
	local dropdownItems = Computed(function()
		local itemList = {}
		local dropdownItemList = unwrap(props.Items)
		if unwrap(isOpen) then
			for i, item in ipairs(dropdownItemList) do
				itemList[i] = {
					OnSelected = onSelectedItem,
					Size = Computed(function()
						return UDim2.new(1, 0, 0, unwrap(absoluteDropdownSize).Y.Offset)
					end),
					LayoutOrder = i,
					Item = item,
				}
			end
		end
		return itemList
	end)
	
	local maxVisibleRows = Computed(function()
		return unwrap(props.MaxVisibleItems) or dropdownConstants.MaxVisibleRows
	end)

	local rowPadding = 1
	local scrollHeight = Computed(function()
		local itemSize = unwrap(absoluteDropdownSize)
		local visibleItems = math.min(unwrap(maxVisibleRows), #unwrap(dropdownItems))
		return visibleItems * (itemSize.Y.Offset) -- item heights
			+ (visibleItems - 1) * rowPadding -- row padding
			+ (dropdownPadding.Offset * 2) -- top and bottom
	end)
	
	local zIndex = Computed(function()
		return unwrap(props.ZIndex) or 5
	end)
	
	local newDropdown = New "Frame" {
		Name = "Dropdown",
		Size = dropdownSize,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		
		[OnEvent "InputBegan"] = function(inputObject)
			if not unwrap(isEnabled) then
				return
			elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				isHovering:set(true)
			elseif inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
				isOpen:set(not unwrap(isOpen))
			end
		end,
		[OnEvent "InputEnded"] = function(inputObject)
			if not unwrap(isEnabled) then
				return
			elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				isHovering:set(false)
			end
		end,
		[OnChange "AbsoluteSize"] = function(newAbsoluteSize)
			absoluteDropdownSize:set(UDim2.fromOffset(newAbsoluteSize.X, newAbsoluteSize.Y))
		end, 
		
		[Children] = {
			-- this frame hides the dropdown if the mouse leaves it
			-- maybe this should be done with a mouse click instead
			-- but I don't know the cleanest way to do that right now
			New "Frame" {
				Name = "WholeDropdownInput",
				BackgroundTransparency = 1,
				Size = Computed(function()
					local topDropdownSize = unwrap(absoluteDropdownSize, false)
					local dropdownHeight = unwrap(scrollHeight)
					if topDropdownSize and dropdownHeight then
						local dropdownTotalHeight = topDropdownSize.Y.Offset + dropdownHeight + spaceBetweenTopAndDropdown
						return UDim2.fromOffset(topDropdownSize.X.Offset, dropdownTotalHeight)
					end
					return UDim2.new()
				end),
				
				[OnEvent "InputEnded"] = function(inputObject)
					if not unwrap(isOpen) then
						return
					elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
						isOpen:set(false)
					end
				end,
			},
			BoxBorder(New "TextLabel" {
				Name = "Selected",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = themeProvider:GetColor(backgroundStyleGuideColor, modifier),
				Text = selectedItem,
				Font = themeProvider:GetFont("Default"),
				TextSize = constants.TextSize,
				TextColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.MainText, modifier),
				TextXAlignment = Enum.TextXAlignment.Left,

				[Children] = New "UIPadding" {
					PaddingLeft = UDim.new(0, dropdownConstants.TextPaddingLeft),
					PaddingRight = UDim.new(0, dropdownConstants.TextPaddingRight),
				}
			}, {
				Color = themeProvider:GetColor(Enum.StudioStyleGuideColor.CheckedFieldBorder, modifier)
			}),
			New "Frame" {
				Name = "ArrowContainer",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, 18, 1, 0),
				BackgroundTransparency = 1,
				
				[Children] = New "ImageLabel" {
					Name = "Arrow",
					Image = "rbxassetid://7260137654",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(8, 4),
					BackgroundTransparency = 1,
					ImageColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.TitlebarText, modifier),
				}
			},
			Computed(function()
				if unwrap(isOpen) then
					return BoxBorder(ScrollFrame {
						ZIndex = zIndex,
						Name = "Drop",
						BorderSizePixel = 0,
						Position = UDim2.new(0, 0, 1, spaceBetweenTopAndDropdown),
						Size = Computed(function()
							return UDim2.new(1, 0, 0, unwrap(scrollHeight))
						end),
						Layout = New "UIListLayout" {
							Padding = UDim.new(0, rowPadding),	
						},
						UIPadding = New "UIPadding" {
							PaddingLeft = dropdownPadding,
							PaddingRight = dropdownPadding,
							PaddingTop = dropdownPadding,
							PaddingBottom = dropdownPadding,
						},

						[Children] = ForValues(dropdownItems, function(props)
							props.ZIndex = unwrap(zIndex) + 1
							return DropdownItem(props)
						end),
					})
				end
				return nil
			end)
		},
	}
	
	local hydrateProps = table.clone(props)
	for _,propertyIndex in pairs(INITIAL_PROPERTIES) do
		hydrateProps[propertyIndex] = nil
	end
	
	return Hydrate(newDropdown)(hydrateProps)
end