local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local Hyrdrate = Fusion.Hydrate
local Children = Fusion.Children

local INITIAL_PROPERTIES = {
	"Name",
}

type ToolbarProperties = {
	Name: string,
	[any]: any,
}


return function(props: ToolbarProperties): PluginToolbar
	local newToolbar = Plugin:CreateToolbar(props.Name)
	
	local hydrateProps = table.clone(props)
	for _,propertyName in pairs(INITIAL_PROPERTIES) do
		hydrateProps[propertyName] = nil
	end

	return Hyrdrate(newToolbar)(hydrateProps)
end