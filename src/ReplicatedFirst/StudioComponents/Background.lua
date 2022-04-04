-- Roact version by @sircfenner
-- Ported to Fusion by @YasuYoshida

type BackgroundProperties = {
	[any]: any,
}

local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local StudioComponents = Plugin:FindFirstChild("StudioComponents", true)
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local themeProvider = require(StudioComponentsUtil.themeProvider)

local New = Fusion.New
local Hydrate = Fusion.Hydrate

return function(props: BackgroundProperties): Frame
	return Hydrate(New "Frame" {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		AnchorPoint = Vector2.new(0, 0),
		LayoutOrder = 0,
		ZIndex = 1,
		BorderSizePixel = 0,
		BackgroundColor3 = themeProvider:GetColor(Enum.StudioStyleGuideColor.MainBackground),
	})(props)
end