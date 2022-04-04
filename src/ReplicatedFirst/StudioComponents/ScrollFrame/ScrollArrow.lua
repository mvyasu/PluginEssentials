-- Roact version by @sircfenner
-- Ported to Fusion by @YasuYoshida

local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent.Parent
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local getState = require(StudioComponentsUtil.getState)
local themeProvider = require(StudioComponentsUtil.themeProvider)
local constants = require(StudioComponentsUtil.constants)
local unwrap = require(StudioComponentsUtil.unwrap)
local types = require(StudioComponentsUtil.types)

local scrollConstants = require(script.Parent.Constants)

local Computed = Fusion.Computed
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Hydrate = Fusion.Hydrate
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value
local New = Fusion.New

local ARROW_IMAGE = "rbxassetid://6677623152"
local BAR_SIZE = scrollConstants.ScrollBarSize
local ARROW_IMAGE_SIZE = scrollConstants.ScrollArrowImageSize

local INITIAL_PROPERTIES = {
	"Enabled",
	"Activated",
	"Direction",
	"ZIndex",
}

type ScrollArrowProperties = {
	Enabled: (boolean | types.StateObject<boolean>)?,
	Direction: (string | types.StateObject<string>),
	Activated: () -> nil,
	[any]: any,
}

local function getBaseProperties(mainModifier: types.Computed<Enum.StudioStyleGuideModifier>, props: ScrollArrowProperties)	
	return {
		AnchorPoint = Computed(function()
			local currentDirection = unwrap(props.Direction)
			if currentDirection=="Down" then
				return Vector2.new(0, 1)
			elseif currentDirection=="Left" then
				return Vector2.new(BAR_SIZE, 0)
			elseif currentDirection=="Right" then
				return Vector2.new(1, 0)
			end
			return Vector2.new(0, 0)
		end),
		Position = Computed(function()
			local currentDirection = unwrap(props.Direction)
			if currentDirection=="Down" then
				return UDim2.fromScale(0, 1)
			elseif currentDirection=="Right" then
				return UDim2.fromScale(1, 0)
			end
			return UDim2.fromScale(0, 0)
		end),
		Size = UDim2.fromOffset(BAR_SIZE, BAR_SIZE),
		Image = ARROW_IMAGE,
		ImageRectSize = Vector2.new(ARROW_IMAGE_SIZE, ARROW_IMAGE_SIZE),
		ImageRectOffset = Computed(function()
			local currentDirection = unwrap(props.Direction)
			if currentDirection=="Down" then
				return Vector2.new(0, ARROW_IMAGE_SIZE)
			elseif currentDirection=="Left" then
				return Vector2.new(ARROW_IMAGE_SIZE, 0)
			elseif currentDirection=="Right" then
				return Vector2.new(ARROW_IMAGE_SIZE, ARROW_IMAGE_SIZE)
			end
			return  Vector2.new(0, 0)
		end),
		ImageColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.TitlebarText, mainModifier),
		BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.ScrollBar, mainModifier),
		BorderColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.Border, mainModifier),
	}
end

return function(props: ScrollArrowProperties): ImageButton
	local isEnabled = getState(props.Enabled, true)
	local isHovering = Value(false)
	local isPressed = Value(false)

	local modifier = Computed(function()
		local isDisabled = not unwrap(isEnabled)
		local isPressed = unwrap(isPressed)
		if isDisabled then
			return Enum.StudioStyleGuideModifier.Disabled
		elseif isPressed then
			return Enum.StudioStyleGuideModifier.Pressed
		end
		return Enum.StudioStyleGuideModifier.Default
	end)
	
	local listenConnection = nil
	
	local function disconnect()
		if listenConnection then
			listenConnection:Disconnect()
			listenConnection = nil
		end
	end

	local function connect()
		disconnect()
		if props.Activated then
			local nextAt = os.clock() + 0.35
			listenConnection = game:GetService("RunService").Heartbeat:Connect(function()
				local now = os.clock()
				if now >= nextAt then
					if unwrap(isHovering, false) then
						props.Activated()
					end
					nextAt += 0.05
				end
			end)
		end
	end
	
	local zIndex = Computed(function()
		return unwrap(props.ZIndex) or 2
	end)
	
	local newScrollArrow = New "ImageButton" {
		AutoButtonColor = false,
		ZIndex = zIndex,
		Active = Computed(function()
			local isEnabled = unwrap(isEnabled)
			if not isEnabled then
				disconnect()
			end
			return isEnabled
		end),
		[OnEvent "InputBegan"] = function(inputObject)			
			if not unwrap(isEnabled) then
				return
			elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				isHovering:set(true)
			elseif inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
				isPressed:set(true)
				if props.Activated then
					props.Activated()
				end
				connect()
			end
		end,
		[OnEvent "InputEnded"] = function(inputObject)
			if not unwrap(isEnabled) then
				return
			elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				isHovering:set(false)
			elseif inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
				isPressed:set(false)
				disconnect()
			end
		end,
		[Cleanup] = disconnect,
	}
	
	for index, value in pairs(getBaseProperties(modifier, props)) do
		if props[index]==nil then
			props[index] = value
		end
	end
	
	local hydrateProps = table.clone(props)
	for _,propertyIndex in pairs(INITIAL_PROPERTIES) do
		hydrateProps[propertyIndex] = nil
	end

	return Hydrate(newScrollArrow)(hydrateProps)
end