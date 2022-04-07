-- Roact version by @sircfenner
-- Ported to Fusion by @YasuYoshida

local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local Background = require(StudioComponents.Background)
local BoxBorder = require(StudioComponents.BoxBorder)

local unwrap = require(StudioComponentsUtil.unwrap)
local types = require(StudioComponentsUtil.types)
local stripProps = require(StudioComponentsUtil.stripProps)

local Children = Fusion.Children
local Computed = Fusion.Computed
local Hydrate = Fusion.Hydrate
local New = Fusion.New

local COMPONENT_ONLY_PROPERTIES = {
	"Padding",
}

type VerticalExpandingListProperties = {
	Padding: (UDim | types.StateObject<UDim>)?,
	[any]: any,
}

return function(props: VerticalExpandingListProperties): Frame
	local hydrateProps = stripProps(props, COMPONENT_ONLY_PROPERTIES)

	return Hydrate(
		BoxBorder {
			[Children] = Background {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,

				[Children] = New "UIListLayout" {
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Vertical,
					Padding = Computed(function()
						return unwrap(props.Padding) or UDim.new(0, 10)
					end),
				}
			}
		}
	)(hydrateProps)
end
