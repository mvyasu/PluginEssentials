-- Roact version by @sircfenner
-- Ported to Fusion by @YasuYoshida

local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent.Parent
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local getState = require(StudioComponentsUtil.getState)
local themeProvider = require(StudioComponentsUtil.themeProvider)
local unwrap = require(StudioComponentsUtil.unwrap)
local types = require(StudioComponentsUtil.types)

local Computed = Fusion.Computed
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Hydrate = Fusion.Hydrate
local Value = Fusion.Value
local New = Fusion.New

local INITIAL_PROPERTIES = {
	"ZIndex",
	"Enabled",
	"DragBegan",
	"DragEnded",
	"DragChanged"
}

type eventFn = () -> nil
type ScrollBarHandleProperties = {
	Enabled: (boolean | types.StateObject<boolean>)?,
	DragBegan: eventFn,
	DragEnded: eventFn,
	DragChanged: (differenceVector: Vector2) -> nil,
	[any]: any,
}

return function(props: ScrollBarHandleProperties): TextButton
	local isEnabled = getState(props.Enabled, true)
	local isDragging = Value(false)
	local isHovering = Value(false)
	
	local dragBegin = nil
	
	local modifier = Computed(function()
		local isDisabled = not unwrap(isEnabled)
		local isDragging = unwrap(isDragging)
		local isHovering = unwrap(isHovering)
		if isDisabled then
			return Enum.StudioStyleGuideModifier.Disabled
		elseif isDragging or isHovering then
			return Enum.StudioStyleGuideModifier.Pressed
		end
		return Enum.StudioStyleGuideModifier.Default
	end)
	
	local zIndex = Computed(function()
		return (unwrap(props.ZIndex) or 0) + 1
	end)
	
	local newScrollBarHandle = New "TextButton" {
		AutoButtonColor = false,
		ZIndex = zIndex,
		BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.ScrollBar, modifier),
		BorderColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.Border),
		Text = "",
		[OnEvent "InputBegan"] = function(inputObject)
			if not unwrap(isEnabled) then
				return
			elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				isHovering:set(true)
			elseif inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
				isDragging:set(true)
				dragBegin = inputObject.Position
				if props.DragBegan then
					props.DragBegan()
				end
			end
		end,
		[OnEvent "InputEnded"] = function(inputObject)
			local currentlyDragging = unwrap(isDragging)
			if not unwrap(isEnabled) then
				return
			elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				isHovering:set(false)
			elseif inputObject.UserInputType == Enum.UserInputType.MouseButton1 and currentlyDragging then
				if props.DragEnded then
					props.DragEnded()
				end
				dragBegin = nil
				isDragging:set(false)
			end
		end,
		[OnEvent "InputChanged"] = function(inputObject)		
			local isDragging = unwrap(isDragging)
			if not unwrap(isEnabled) then
				return
			elseif not isDragging or not dragBegin --[[or dragConnection]] then
				return
			elseif inputObject.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end
			
			local diff = inputObject.Position - dragBegin
			if props.DragChanged then
				props.DragChanged(Vector2.new(diff.x, diff.y))
			end
		end,
	}
	
	local hydrateProps = table.clone(props)
	for _,propertyIndex in pairs(INITIAL_PROPERTIES) do
		hydrateProps[propertyIndex] = nil
	end
	
	return Hydrate(newScrollBarHandle)(hydrateProps)
end