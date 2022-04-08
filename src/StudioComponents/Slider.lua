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
local constants = require(StudioComponentsUtil.constants)
local stripProps = require(StudioComponentsUtil.stripProps)

local Computed = Fusion.Computed
local Children = Fusion.Children
local Observer = Fusion.Observer
local OnEvent = Fusion.OnEvent
local Hydrate = Fusion.Hydrate
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value
local New = Fusion.New
local Ref = Fusion.Ref
local Spring = Fusion.Spring

local COMPONENT_ONLY_PROPERTIES = {
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

	local handleRegion = Value()
	local inputValue = getState(props.Value, 1)
	local currentValue, currentAlpha, isDragging = getDragInput({
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
		OnChange = function(newValue: Vector2)
			inputValue:set(newValue.X)
			if props.OnChange then
				props.OnChange(newValue.X)
			end
		end,
	})

	local cleanupInputValueObserver = Observer(inputValue):onChange(function()
		currentValue:set(Vector2.new(unwrap(inputValue, false), 0))
	end)

	local zIndex = Computed(function()
		return (unwrap(props.ZIndex) or 0) + 1
	end)

	local mainModifier = Computed(function()
		local isDisabled = not unwrap(isEnabled)
		if isDisabled then
			return Enum.StudioStyleGuideModifier.Disabled
		end
		return Enum.StudioStyleGuideModifier.Default
	end)

	local handleModifier = Computed(function()
		local isDisabled = not unwrap(isEnabled)
		local isHovering = unwrap(isHovering)
		local isDragging = unwrap(isDragging)
		if isDisabled then
			return Enum.StudioStyleGuideModifier.Disabled
		elseif isDragging then
			return Enum.StudioStyleGuideModifier.Selected
		elseif isHovering then
			return Enum.StudioStyleGuideModifier.Hover
		end
		return Enum.StudioStyleGuideModifier.Default
	end)

	local handleFill = themeProvider:GetColor(Enum.StudioStyleGuideColor.Button)
	local handleBorder = themeProvider:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder, handleModifier)

	local newSlider = New "Frame" {
		Name = "Slider",
		Size = UDim2.new(1, 0, 0, 22),
		ZIndex = zIndex,
		BackgroundTransparency = 1,
		[Cleanup] = cleanupInputValueObserver,

		[Children] = {
			BoxBorder {
				Color = themeProvider:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder),

				[Children] = New "Frame" {
					Name = "Bar",
					ZIndex = zIndex,
					Size = UDim2.new(1, 0, 0, 3),
					Position = UDim2.fromScale(0, 0.5),
					AnchorPoint = Vector2.new(0, 0.5),
					BorderSizePixel = 0,
					BackgroundTransparency = Spring(Computed(function()
						return if not unwrap(isEnabled) then 0.4 else 0
					end), 40),
					BackgroundColor3 = Spring(themeProvider:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground, mainModifier), 40),
				}
			},
			New "Frame" {
				Name = "HandleRegion",
				ZIndex = 1,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				[Ref] = handleRegion,

				[Children] = BoxBorder {
					Color =  Spring(Computed(function()
						return unwrap(handleBorder):Lerp(unwrap(handleFill), if not unwrap(isEnabled) then .5 else 0)
					end), 40),

					[Children] = New "Frame" {
						Name = "Handle",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = Spring(Computed(function()
							return UDim2.fromScale(unwrap(currentAlpha).X, 0.5)
						end), 40),
						Size = UDim2.new(0, 10, 0, constants.TextSize*1.3),
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
					}
				}
			}
		}
	}

	local hydrateProps = stripProps(props, COMPONENT_ONLY_PROPERTIES)
	return Hydrate(newSlider)(hydrateProps)
end
