-- Roact version by @sircfenner
-- Ported to Fusion by @YasuYoshida

local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local BoxBorder = require(StudioComponents.BoxBorder)

local getState = require(StudioComponentsUtil.getState)
local themeProvider = require(StudioComponentsUtil.themeProvider)
local getDragInput = require(StudioComponentsUtil.getDragInput)
local unwrap = require(StudioComponentsUtil.unwrap)
local types = require(StudioComponentsUtil.types)

local Computed = Fusion.Computed
local Children = Fusion.Children
local Observer = Fusion.Observer
local OnEvent = Fusion.OnEvent
local Hydrate = Fusion.Hydrate
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value
local New = Fusion.New
local Ref = Fusion.Ref

local PADDING_BAR_SIDE = 3
local PADDING_REGION_TOP = 1
local PADDING_REGION_SIDE = 6
local INITIAL_PROPERTIES = {
	"ZIndex",
	"OnChange",
	"Value",
	"Min",
	"Max",
	"Step",
	"Enabled",
}

type numberInput = (number | types.StateObject<number>)?

type SliderProperties = {
	Enabled: (boolean | types.StateObject<boolean>)?,
	OnChange: ((newValue: number) -> nil)?,
	Value: (number | types.Value<number>)?,
	Min: numberInput,
	Max: numberInput,
	Step: numberInput,
	[any]: any,
}

return function(props: SliderProperties): TextButton
	local isEnabled = getState(props.Enabled, true)
	local isHovering = Value(false)
	
	local mainModifier = Computed(function()
		local isDisabled = not unwrap(isEnabled)
		if isDisabled then
			return Enum.StudioStyleGuideModifier.Disabled
		end
		return Enum.StudioStyleGuideModifier.Default
	end)
	
	local handleModifier = Computed(function()
		local isDisabled =  not unwrap(isEnabled)
		local isHovering = unwrap(isHovering)
		if isDisabled then
			return Enum.StudioStyleGuideModifier.Disabled
		elseif isHovering then
			return Enum.StudioStyleGuideModifier.Hover
		end
		return Enum.StudioStyleGuideModifier.Default
	end)
	
	local handleRegion = Value()
	local inputValue = getState(props.Value, 1)
	local draggerValue = getDragInput({
		Instance = handleRegion,
		Enabled = isEnabled,
		Value = Value(Vector2.new(unwrap(inputValue), 0)),
		Min = Computed(function()
			return Vector2.new(unwrap(props.Min) or 0, 0)
		end),
		Max = Computed(function()
			return Vector2.new(unwrap(props.Max) or 1, 0)
		end),
		Step = Computed(function()
			return Vector2.new(unwrap(props.Step) or -1, 0)
		end),
		OnChange = function(newAlpha: Vector2)
			if props.OnChange then
				props.OnChange(newAlpha.X)
			end
		end,
	})
	
	local cleanupInputValueObserver = Observer(inputValue):onChange(function()
		draggerValue:set(Vector2.new(unwrap(inputValue, false), 0))
	end)
	
	local alpha = Computed(function()
		return unwrap(draggerValue).X
	end)
	
	local zIndex = Computed(function()
		return (unwrap(props.ZIndex) or 0) + 1
	end)
	
	local handleFill = themeProvider:GetColor(Enum.StudioStyleGuideColor.Button, handleModifier)
	local handleBorder = themeProvider:GetColor(Enum.StudioStyleGuideColor.Border, handleModifier)
	
	local newSlider = New "TextButton" {
		Name = "Slider",
		Text = "",
		Active = false,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 22),
		ZIndex = zIndex,
		BorderSizePixel = 0,
		BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground, mainModifier),
		[Cleanup] = cleanupInputValueObserver,
		
		[Children] = {
			New "Frame" {
				Name = "Bar",
				ZIndex = zIndex,
				Position = UDim2.fromOffset(PADDING_BAR_SIDE, 10),
				Size = UDim2.new(1, -PADDING_BAR_SIDE * 2, 0, 2),
				BorderSizePixel = 0,
				BackgroundTransparency = Computed(function()
					return if not unwrap(isEnabled) then 0.4 else 0
				end),
				BackgroundColor3 = themeProvider:GetColor(
					-- this looks odd but provides the correct colors for both themes
					Enum.StudioStyleGuideColor.TitlebarText,
					Enum.StudioStyleGuideModifier.Disabled
				),
			},
			New "Frame" {
				Name = "HandleRegion",
				ZIndex = 1,
				Position = UDim2.fromOffset(PADDING_REGION_SIDE, PADDING_REGION_TOP),
				Size = UDim2.new(1, -PADDING_REGION_SIDE * 2, 1, -PADDING_REGION_TOP * 2),
				BackgroundTransparency = 1,
				[Ref] = handleRegion,
				
				[Children] = BoxBorder(New "Frame" {
					Name = "Handle",
					AnchorPoint = Vector2.new(0.5, 0),
					Position = Computed(function()
						return UDim2.fromScale(unwrap(alpha), 0)
					end),
					Size = UDim2.new(0, 10, 1, 0),
					BorderMode = Enum.BorderMode.Inset,
					BackgroundColor3 = handleFill,
					BorderSizePixel = 0,
					
					[OnEvent "InputBegan"] = function(inputObject)
						if not unwrap(isEnabled) then
							return
						elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
							isHovering:set(true)
						end
					end,
					[OnEvent "InputEnded"] = function(inputObject)
						if not unwrap(isEnabled) then
							return
						elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
							isHovering:set(false)
						end
					end,
				}, {
					Color = Computed(function()
						return unwrap(handleBorder):Lerp(unwrap(handleFill), if not unwrap(isEnabled) then .5 else 0)
					end)
				})
			}
		}
	}
	
	local hydrateProps = table.clone(props)
	for _,propertyIndex in pairs(INITIAL_PROPERTIES) do
		hydrateProps[propertyIndex] = nil
	end
	
	BoxBorder(newSlider)
	
	return Hydrate(newSlider)(hydrateProps)
end