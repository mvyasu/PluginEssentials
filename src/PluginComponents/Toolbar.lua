local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local PluginComponents = script.Parent
local StudioComponents = PluginComponents.Parent.StudioComponents
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local stripProps = require(StudioComponentsUtil.stripProps)

local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPERTIES = {
	"Name",
}

type ToolbarProperties = {
	Name: string,
	[any]: any,
}

return function(props: ToolbarProperties): PluginToolbar
	local newToolbar = Plugin:CreateToolbar(props.Name)

	return Hydrate(newToolbar)(stripProps(props, COMPONENT_ONLY_PROPERTIES))
end
