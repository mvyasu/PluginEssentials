local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local PluginComponents = script.Parent
local StudioComponents = PluginComponents.Parent.StudioComponents
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local stripProps = require(StudioComponentsUtil.stripProps)

local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPERTIES = {
	"Id",
	"InitialDockTo",
	"InitialEnabled",
	"ForceInitialEnabled",
	"FloatingSize",
	"MinimumSize",
	"Plugin"
}

type PluginGuiProperties = {
	Id: string,
	Name: string,
	InitialDockTo: string | Enum.InitialDockState,
	InitialEnabled: boolean,
	ForceInitialEnabled: boolean,
	FloatingSize: Vector2,
	MinimumSize: Vector2,
	[any]: any,
}

return function(props: PluginGuiProperties)	
	local newWidget = Plugin:CreateDockWidgetPluginGui(
		props.Id,
		DockWidgetPluginGuiInfo.new(
			if typeof(props.InitialDockTo) == "string" then Enum.InitialDockState[props.InitialDockTo] else props.InitialDockTo,
			props.InitialEnabled,
			props.ForceInitialEnabled,
			props.FloatingSize.X, props.FloatingSize.Y,
			props.MinimumSize.X, props.MinimumSize.Y
		)
	)

	props.Title = props.Name
	
	if typeof(props.Enabled)=="table" and props.Enabled.kind=="Value" then
		props.Enabled:set(newWidget.Enabled)
	end

	return Hydrate(newWidget)(stripProps(props, COMPONENT_ONLY_PROPERTIES))
end
