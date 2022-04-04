local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local Hyrdrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent

local INITIAL_PROPERTIES = {
	"ToolTip",
	"Name",
	"Image",
	"Toolbar",
}

type ToolbarProperties = {
	Toolbar: PluginToolbar,
	ClickableWhenViewportHidden: boolean?,
	ToolTip: string,
	Image: string,
	Name: string,
	[any]: any,
}

return function(props: ToolbarProperties)
	local toolbarButton = props.Toolbar:CreateButton(
		props.Name,
		props.ToolTip,
		props.Image
	)
	
	local hydrateProps = table.clone(props)
	for _,propertyName in pairs(INITIAL_PROPERTIES) do
		hydrateProps[propertyName] = nil
	end

	return Hyrdrate(toolbarButton)(hydrateProps)
end