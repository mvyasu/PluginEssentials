# PluginEssentials
[![GitHub Issues](https://img.shields.io/github/issues/mvyasu/PluginEssentials.svg)](https://github.com/mvyasu/PluginEssentials/issues)
[![GitHub Stars](https://img.shields.io/github/stars/mvyasu/PluginEssentials.svg)](https://github.com/mvyasu/PluginEssentials/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

This is a repository with components that I find essential to making plugins with [Fusion](https://github.com/Elttob/Fusion). You'll find in the src folder that there's two folders. Each one has a specific set of components which you can learn more about below.

There's no documentation at the moment, but each component has a property type that should give you an idea of what it expects for the properties.

## PluginComponents

These components use specific properties to create their corresponding plugin object. Afterwards, they use Hydrate on the created object and return it. You don't need to use these components, but the most useful one by far is the Widget component.

| Component | Description | Returns |
| --- | --- | --- |
| [Widget](https://github.com/mvyasu/PluginEssentials/blob/main/src/PluginComponents/Widget.lua) | A PluginGui that displays its contents inside a dockable Roblox Studio window. | DockWidgetPluginGui |
| [Toolbar](https://github.com/mvyasu/PluginEssentials/blob/main/src/PluginComponents/Toolbar.lua) | An object used to create PluginToolbarButtons. | PluginToolbar |
| [ToolbarButton](https://github.com/mvyasu/PluginEssentials/blob/main/src/PluginComponents/ToolbarButton.lua) | An object that allows the user to initiate a single, one-off action in Roblox Studio through the Click event. | PluginToolbarButton |

## StudioComponents

This is a Fusion port of [StudioComponents](https://github.com/sircfenner/StudioComponents) by sircfenner. This is by no means a 1-1 port, but it's close enough to where you should be able to port over a plugin that uses StudioComponents with ease. There is bound to be mistakes, but hopefully those can be ironed out in the future.

| Component | Description | Returns |
| --- | --- | --- |
| [Background](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/Background.lua) | A borderless Frame with a background color that matches the user's current theme. | Frame |
| [Label](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/Label.lua) | A simple text label following Studio style guidelines for body text. | TextLabel |
| [Title](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/Title.lua) | A simple text label following Studio style guidelines for title text. | TextLabel |
| [BaseButton](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/BaseButton.lua) | A TextButton that reacts to different states like hover, press, and disabled. | TextButton |
| [Button](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/Button.lua) | BaseButton, but with a different name. | TextButton |
| [MainButton](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/MainButton.lua) | BaseButton, but uses the style of a main button, which is usually a blue background color. | TextButton |
| [IconButton](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/IconButton.lua) | A button with an image on it instead of text. | TextButton |
| [Checkbox](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/Checkbox.lua) | A checkbox that reacts to different states like hover, checked, indeterminate, and disabled. | Frame |
| [ClassIcon](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/ClassIcon.lua) | An image of a given ClassName from the user's installed Studio icon set. | ImageLabel |
| [Shadow](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/Shadow.lua) | A subtle shadow positioned on the side of your choosing. | ImageLabel |
| [Loading](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/Loading.lua) | An animated component to display whilst something else loads. | Frame |
| [Dropdown](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/Dropdown/init.lua) | A button that shows the selected item and a list of items in a dropdown when clicking on it. | Frame |
| [ColorPicker](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/ColorPicker.lua) | An HSV color picker that uses a value slider. | Frame |
| [BaseScrollFrame](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/BaseScrollFrame/init.lua) | A custom scrolling frame that uses Roblox's ScrollingFrame for input and padding. | Frame |
| [ScrollFrame](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/ScrollFrame.lua) | Same as BaseScrollFrame, but has properties that will determine the CanvasSize for the BaseScrollFrame. | Frame |
| [Slider](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/Slider.lua) | A slider that reacts to being dragged. | TextButton |
| [ProgressBar](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/ProgressBar.lua) | A bar that fills up with an accent color. | TextBox |
| [TextInput](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/TextInput.lua) | A TextBox that reacts to states like hover, focus, and disabled. | TextBox |
| [LimitedTextInput](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/LimitedTextInput.lua) | TextInput, but contains properties for limiting the length of input to the TextBox. | TextBox |
| [VerticalExpandingList](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/VerticalExpandingList.lua) | A Frame that uses AutomaticSize for the Y axis and contains a UIListLayout. | Frame |
| [VerticalCollapsibleSection](https://github.com/mvyasu/PluginEssentials/blob/main/src/StudioComponents/VerticalCollapsibleSection.lua) | A frame that contains a header and a content frame. The content frame can be collapsed by clicking on the header.  | Frame |
