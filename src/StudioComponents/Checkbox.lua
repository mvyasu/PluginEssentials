-- Roact version by @sircfenner
-- Ported to Fusion by @YasuYoshida

local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local BoxBorder = require(StudioComponents.BoxBorder)

local getMotionState = require(StudioComponentsUtil.getMotionState)
local themeProvider = require(StudioComponentsUtil.themeProvider)
local getModifier = require(StudioComponentsUtil.getModifier)
local constants = require(StudioComponentsUtil.constants)
local getState = require(StudioComponentsUtil.getState)
local unwrap = require(StudioComponentsUtil.unwrap)
local types = require(StudioComponentsUtil.types)

local New = Fusion.New
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Children = Fusion.Children
local Hydrate = Fusion.Hydrate

local INDICATOR_IMAGE = "rbxassetid://6652838434"
local COMPONENT_ONLY_PROPERTIES = {
	"OnChange",
	"Alignment",
	"Enabled",
	"Value",
	"Text",
}

type CheckboxProperties = {
	OnChange: ((newValue: boolean) -> nil)?,
	Alignment: (Enum.HorizontalAlignment | types.StateObject<Enum.HorizontalAlignment>)?,
	Enabled: (boolean | types.StateObject<boolean>)?,
	Text: (string | types.StateObject<string>)?,
	Value: (boolean | types.Value<boolean>)?,
	[any]: any,
}

return function(props: CheckboxProperties): Frame
	local currentValue = getState(props.Value, true)
	local isEnabled = getState(props.Enabled, true)
	local isHovering = Value(false)

	local isIndeterminate = Computed(function()
		return unwrap(currentValue)==nil
	end)

	local mainModifier = getModifier({
		Enabled = isEnabled,
		Hovering = isHovering,
	})

	local backModifier = getModifier({
		Enabled = isEnabled,
		Selected = currentValue,
	})

	local checkFieldIndicatorColor = themeProvider:GetColor(Enum.StudioStyleGuideColor.CheckedFieldIndicator, mainModifier)

	local boxHorizontalScale = Computed(function()
		local currentAlignment = unwrap(props.Alignment) or Enum.HorizontalAlignment.Left
		return if currentAlignment==Enum.HorizontalAlignment.Right then 1 else 0
	end)

	local textHorizontalScale = Computed(function()
		return if unwrap(boxHorizontalScale)==1 then 0 else 1
	end)

	local newCheckboxFrame = New "Frame" {
		Name = "Checkbox",
		Size = UDim2.new(1, 0, 0, 15),
		BackgroundTransparency = 1,

		[Children] = {
			New "TextButton" {
				Text = "",
				Active = true,
				Name = "CheckBoxInput",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,

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
				[OnEvent "Activated"] = function()
					if unwrap(isEnabled) then
						local newValue = not unwrap(currentValue, false)
						currentValue:set(newValue)
						if props.OnChange then
							props.OnChange(newValue)
						end
					end
				end,
			},
			BoxBorder {
				Color = getMotionState(themeProvider:GetColor(Enum.StudioStyleGuideColor.CheckedFieldBorder, mainModifier), "Spring", 40),

				[Children] = New "Frame" {
					Name = "Box",
					AnchorPoint = Computed(function()
						return Vector2.new(unwrap(boxHorizontalScale), 0)
					end),
					Position = Computed(function()
						return UDim2.fromScale(unwrap(boxHorizontalScale), 0)
					end),
					BackgroundColor3 = getMotionState(themeProvider:GetColor(Enum.StudioStyleGuideColor.CheckedFieldBackground, backModifier), "Spring", 40),
					Size = UDim2.fromOffset(15, 15),

					[Children] = New "ImageLabel" {
						AnchorPoint = Vector2.new(.5, .5),
						Visible = Computed(function()
							return unwrap(currentValue)~=false
						end),
						Name = "Indicator",
						BackgroundTransparency = 1,
						Size = UDim2.fromOffset(13, 13),
						Position = UDim2.fromScale(.5, .5),
						Image = INDICATOR_IMAGE,
						ImageColor3 = getMotionState(Computed(function()
							local indicatorColor = unwrap(checkFieldIndicatorColor)
							return if unwrap(isIndeterminate) then Color3.fromRGB(255, 255, 255) else indicatorColor
						end), "Spring", 40),
						ImageRectOffset = Computed(function()
							if unwrap(isIndeterminate) then
								return if unwrap(themeProvider.IsDark) then Vector2.new(13, 0) else Vector2.new(26, 0)
							end
							return Vector2.new(0, 0)
						end),
						ImageRectSize = Vector2.new(13, 13),

						[Children] = Computed(function()
							local useCurvedBoxes = unwrap(constants.CurvedBoxes)
							if useCurvedBoxes then
								return New "UICorner" {
									CornerRadius = constants.CornerRadius
								}
							end
						end)
					}
				}
			},
			Computed(function()
				if props.Text then
					return New "TextLabel" {
						BackgroundTransparency = 1,
						AnchorPoint = Computed(function()
							return Vector2.new(unwrap(textHorizontalScale), 0)
						end),
						Position = Computed(function()
							return UDim2.fromScale(unwrap(textHorizontalScale), 0)
						end),
						Size = UDim2.new(1, -20, 1, 0),
						TextXAlignment = Computed(function()
							return if unwrap(textHorizontalScale)==1 then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right
						end),
						TextTruncate = Enum.TextTruncate.AtEnd,
						Text = props.Text,
						Font = themeProvider:GetFont("Default"),
						TextSize = constants.TextSize,
						TextColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.MainText, mainModifier),
					}
				end
			end)
		}
	}

	local hydrateProps = table.clone(props)
	for _,propertyIndex in pairs(COMPONENT_ONLY_PROPERTIES) do
		hydrateProps[propertyIndex] = nil
	end

	return Hydrate(newCheckboxFrame)(hydrateProps)
end
