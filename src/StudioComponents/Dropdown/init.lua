-- Roact version by @sircfenner
-- Ported to Fusion by @YasuYoshida

local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local ScrollFrame = require(StudioComponents.ScrollFrame)
local BoxBorder = require(StudioComponents.BoxBorder)
local DropdownItem = require(script.DropdownItem)

local getSelectedState = require(StudioComponentsUtil.getSelectedState)
local getMotionState = require(StudioComponentsUtil.getMotionState)
local themeProvider = require(StudioComponentsUtil.themeProvider)
local getModifier = require(StudioComponentsUtil.getModifier)
local stripProps = require(StudioComponentsUtil.stripProps)
local constants = require(StudioComponentsUtil.constants)
local getState = require(StudioComponentsUtil.getState)
local unwrap = require(StudioComponentsUtil.unwrap)
local types = require(StudioComponentsUtil.types)

local dropdownConstants = require(script.Constants)

local ForValues = Fusion.ForValues
local Computed = Fusion.Computed
local Children = Fusion.Children
local OnChange = Fusion.OnChange
local Observer = Fusion.Observer
local Cleanup = Fusion.Cleanup
local OnEvent = Fusion.OnEvent
local Hydrate = Fusion.Hydrate
local Value = Fusion.Value
local New = Fusion.New

local COMPONENT_ONLY_PROPERTIES = {
	"Enabled",
	"MaxVisibleItems",
	"Options",
	"Value",
	"ZIndex",
	"OnSelected",
	"Size",
}

type DropdownProperties = {
	Enabled: (boolean | types.StateObject<boolean>)?,
	Value: (any | types.Value<any>)?,
	Options: {any} | types.StateObject<{any}>,
	MaxVisibleItems: (number | types.StateObject<number>)?,
	OnSelected: (selectedOption: any) -> nil,
	[any]: any,
}

return function(props: DropdownProperties): Frame
	local isInputEnabled = getState(props.Enabled, true)
	local isHovering = Value(false)
	local isOpen = Value(false)
	
	local isEmpty = Computed(function()
		return next(unwrap(props.Options or {}))==nil
	end)

	local isEnabled = Computed(function()
		local isInputEnabled = unwrap(isInputEnabled)
		local isEmpty = unwrap(isEmpty)
		return isInputEnabled and not isEmpty
	end)

	local modifier = getModifier({
		Enabled = isEnabled,
		Hovering = isHovering,
	})

	local backgroundStyleGuideColor = Computed(function()
		local isHovering = unwrap(isHovering)
		local isOpen = unwrap(isOpen)
		if isOpen or isHovering then
			return Enum.StudioStyleGuideColor.InputFieldBackground
		end
		return Enum.StudioStyleGuideColor.MainBackground
	end)
	
	local disconnectGetSelectedState = nil
	local selectedOption, onSelectedOption do
		local inputValue = getState(props.Value, nil, "Value")
		onSelectedOption = function(selectedOption)
			isOpen:set(false)
			inputValue:set(selectedOption)
			if props.OnSelected then
				props.OnSelected(selectedOption)
			end
		end
		
		selectedOption = Computed(getSelectedState {
			Value = inputValue,
			Options = props.Options,
			OnSelected = onSelectedOption,
		})
		--just in case there's never a dependency for selectedOption
		--props.OnSelected should always be ran even if there isn't a dependency
		disconnectGetSelectedState = Observer(selectedOption):onChange(function() end)
	end

	local spaceBetweenTopAndDropdown = 5
	local dropdownPadding = UDim.new(0, 2)
	local dropdownSize = Computed(function()
		local propsSize = unwrap(props.Size)
		return propsSize or UDim2.new(1, 0, 0, dropdownConstants.RowHeight)
	end)

	local absoluteDropdownSize = Value(UDim2.new())

	local dropdownItems = Computed(function()
		local itemList = {}
		local dropdownOptionList = unwrap(props.Options)
		if unwrap(isOpen) then
			for i, item in ipairs(dropdownOptionList) do
				itemList[i] = {
					OnSelected = onSelectedOption,
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
	
	local function getOptionName(option)
		local option = unwrap(option)
		if typeof(option)=="table" and (option.Label or option.Name or option.Title) then
			return tostring(option.Label or option.Name or option.Title)
		elseif typeof(option)=="Instance" or typeof(option)=="EnumItem" then
			return option.Name
		end
		return tostring(option)
	end

	local newDropdown = New "Frame" {
		Name = "Dropdown",
		Size = dropdownSize,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		
		[Cleanup] = disconnectGetSelectedState,

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
			BoxBorder {
				Color = themeProvider:GetColor(Enum.StudioStyleGuideColor.CheckedFieldBorder, modifier),

				[Children] = New "TextLabel" {
					Name = "Selected",
					Size = UDim2.fromScale(1, 1),
					TextSize = constants.TextSize,
					TextXAlignment = Enum.TextXAlignment.Left,

					BackgroundColor3 = getMotionState(themeProvider:GetColor(backgroundStyleGuideColor, modifier), "Spring", 40),
					TextColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.MainText, modifier),
					Font = themeProvider:GetFont("Default"),
					Text = Computed(function()
						return getOptionName(selectedOption)
					end),

					[Children] = New "UIPadding" {
						PaddingLeft = UDim.new(0, dropdownConstants.TextPaddingLeft),
						PaddingRight = UDim.new(0, dropdownConstants.TextPaddingRight),
					}
				}
			},
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
			--Computed(function()
			--if unwrap(isOpen) then
			--[[return]] BoxBorder {
				[Children] = ScrollFrame {
					ZIndex = zIndex,
					Name = "Drop",
					BorderSizePixel = 0,
					Visible = isOpen,
					Position = UDim2.new(0, 0, 1, spaceBetweenTopAndDropdown),
					Size = Computed(function()
						return UDim2.new(1, 0, 0, unwrap(scrollHeight))
					end),

					ScrollBarBorderMode = Enum.BorderMode.Outline,
					CanvasScaleConstraint = Enum.ScrollingDirection.X,

					UILayout = New "UIListLayout" {
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
						props.Text = getOptionName(props.Item) 
						return DropdownItem(props)
					end),
				}
			}
			--end
			--return nil
			--end)
		},
	}

	return Hydrate(newDropdown)(stripProps(props, COMPONENT_ONLY_PROPERTIES))
end