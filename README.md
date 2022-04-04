# FusionStudioComponents
This is a Fusion port of [StudioComponents](https://github.com/sircfenner/StudioComponents) by sircfenner. This is by no means a 1-1 port, but it's close enough to where you should be able to port over a plugin that uses StudioComponents with ease. There is bound to be mistakes, but hopefully those can be ironed out in the future.

Most of the components shouldn't interfere too much with you attempting to make a new component out of them. Below is an example of a TextInput component, but with the ability to limit how many characters are allowed in the box as an example of what I'm talking about.

```lua
local Plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Fusion = require(Plugin:FindFirstChild("Fusion", true))

local StudioComponents = script.Parent.StudioComponents
local StudioComponentsUtil = StudioComponents:FindFirstChild("Util")

local TextInput = require(StudioComponents.TextInput)

local getState = require(StudioComponentsUtil.getState)
local themeProvider = require(StudioComponentsUtil.themeProvider)
local constants = require(StudioComponentsUtil.constants)
local unwrap = require(StudioComponentsUtil.unwrap)
local types = require(StudioComponentsUtil.types)

local Observer = Fusion.Observer
local Computed = Fusion.Computed
local OnChange = Fusion.OnChange
local Children = Fusion.Children
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value
local New = Fusion.New

type numberInput = (number | types.StateObject<number>)?

export type LimitedTextInputProperties = TextInput.TextInputProperties & {
	Text: (string | types.Value<string>)?,
	GraphemesLimit: numberInput,
	OnChange: (newText: string) -> nil,
	TextLimit: numberInput,
}

return function(props: LimitedTextInputProperties)
	local currentText = getState(props.Text, "", "Value")

	local createProps = table.clone(props)
	createProps.Text = currentText
	createProps.GraphemesLimit = nil
	createProps.TextLimit = nil
	createProps.OnChange = nil
	
	local function limitText(newText: string)
		local desiredGraphemeLimit = unwrap(props.GraphemesLimit)
		local desiredTextLimit = unwrap(props.TextLimit)

		local hasDesiredTextLimit = (desiredTextLimit and desiredTextLimit > -1)
		local hasDesiredGraphemeLimit = (desiredGraphemeLimit  and desiredGraphemeLimit > -1)
		local newCurrentText = newText

		if (hasDesiredTextLimit or hasDesiredGraphemeLimit) then
			local textWithTextLimit = newText:sub(1, if hasDesiredTextLimit then desiredTextLimit else #newText)

			if hasDesiredGraphemeLimit then					
				local graphemesToLength = {}
				for first, last in utf8.graphemes(textWithTextLimit) do 
					table.insert(graphemesToLength, last)
				end

				local cutoffLength = graphemesToLength[desiredGraphemeLimit] or graphemesToLength[#graphemesToLength]
				local textWithGraphemeLimit = textWithTextLimit:sub(1, cutoffLength)

				newCurrentText = textWithGraphemeLimit
			else
				newCurrentText = textWithTextLimit
			end
		end
		return newCurrentText
	end
	
	local textBoxRef = TextInput(createProps)
	local lastUpdateText = textBoxRef.Text
	
	local function updateWithLimitedText(newText: string)
		local newCurrentText = limitText(newText)
		
		textBoxRef.Text = newCurrentText
		currentText:set(newCurrentText)
		
		if lastUpdateText~=unwrap(currentText) then
			lastUpdateText = newCurrentText
			if props.OnChange then
				props.OnChange(newCurrentText)
			end
		end
	end
	
	updateWithLimitedText(textBoxRef.Text)
	
	return Hydrate (textBoxRef) {
		[OnChange "Text"] = updateWithLimitedText,
	}
end
```

There's no documentation at the moment, but each component has a property type that should give you an idea of what it expects for the properties.
