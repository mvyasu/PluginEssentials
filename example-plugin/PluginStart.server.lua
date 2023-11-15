--[[
	MIT License

	Copyright (c) 2022 Yasu Yoshida

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]

local Plugin = plugin

local Components = script.Parent.Components
local Packages = script.Parent.Packages

local PluginComponents = Components:FindFirstChild("PluginComponents")
local Widget = require(PluginComponents.Widget)
local Toolbar = require(PluginComponents.Toolbar)
local ToolbarButton = require(PluginComponents.ToolbarButton)

local StudioComponents = Components:FindFirstChild("StudioComponents")
local Background = require(StudioComponents.Background)
local Checkbox = require(StudioComponents.Checkbox)
local Button = require(StudioComponents.Button)
local MainButton = require(StudioComponents.MainButton)
local ScrollFrame = require(StudioComponents.ScrollFrame)
local Label = require(StudioComponents.Label)
local Dropdown = require(StudioComponents.Dropdown)
local TextInput = require(StudioComponents.TextInput)
local VerticalExpandingList = require(StudioComponents.VerticalExpandingList)
local VerticalCollapsibleSection = require(StudioComponents.VerticalCollapsibleSection)
local Slider = require(StudioComponents.Slider)
local ColorPicker = require(StudioComponents.ColorPicker)

local Title = require(StudioComponents.Title)
local Shadow = require(StudioComponents.Shadow)
local ClassIcon = require(StudioComponents.ClassIcon)

local Fusion = require(Packages.Fusion)

local New = Fusion.New
local Value = Fusion.Value
local Children = Fusion.Children
local OnChange = Fusion.OnChange
local OnEvent = Fusion.OnEvent
local Hydrate = Fusion.Hydrate
local Observer = Fusion.Observer

do --creates the example plugin
	local pluginToolbar = Toolbar {
		Name = "Example Toolbar"
	}

	local widgetsEnabled = Value(false)
	local enableButton = ToolbarButton {
		Toolbar = pluginToolbar,

		ClickableWhenViewportHidden = true,
		Name = "Examples",
		ToolTip = "View Example Components",
		Image = "",

		[OnEvent "Click"] = function()
			widgetsEnabled:set(not widgetsEnabled:get())
		end,
	}

	Plugin.Unloading:Connect(Observer(widgetsEnabled):onChange(function()
		enableButton:SetActive(widgetsEnabled:get(false))
	end))

	local function ExampleWidget(children)
		return Widget {
			Id = game:GetService("HttpService"):GenerateGUID(),
			Name = "Component Examples",

			InitialDockTo = Enum.InitialDockState.Right,
			InitialEnabled = false,
			ForceInitialEnabled = false,
			FloatingSize = Vector2.new(250, 200),
			MinimumSize = Vector2.new(250, 200),

			Enabled = widgetsEnabled,
			[OnChange "Enabled"] = function(isEnabled)
				widgetsEnabled:set(isEnabled)
			end,
			[Children] = ScrollFrame {
				ZIndex = 1,
				Size = UDim2.fromScale(1, 1),

				CanvasScaleConstraint = Enum.ScrollingDirection.X,

				UILayout = New "UIListLayout" {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 7),
				},

				UIPadding = New "UIPadding" {
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 10),
				},

				[Children] = children
			}
		}
	end

	ExampleWidget {
		VerticalCollapsibleSection {
			Text = "Disabled Section",
			Enabled = false,
			[Children] = {
				Checkbox {},
			}
		},
		Label {
			Text = "Slider",
		},
		Slider {
			Step = 1,
			Min = -1,
			Max = 15,
			OnChange = function(newValue)
				print(newValue)
			end,
		},
		Label {
			Text = "Disabled Slider",
		},
		Slider {
			Enabled = false,
			OnChange = function(newValue)
				print(newValue)
			end,
		},
		Label {
			Text = "Text Input",
		},
		require(StudioComponents.LimitedTextInput) {
			GraphemeLimit = 5,
			PlaceholderText = "LimitedTextInput",
			Text = "",
			OnChange = function(newText)
				print("Text:", newText)
			end,
		},
		TextInput {
			PlaceholderText = "Placeholder Text",
			Text = "A TextBox that you can write inside!",
			[OnChange "Text"] = function(newText)
				print("Text:", newText)
			end,
		},
		Dropdown {
			Value = Value("Custom"),
			Options = {"Custom", "Extra", "Test", "Too", "Long"},
			OnSelected = function(newItem)
				print("You've selected:", newItem)
			end,
		},
		Dropdown {
			Options = (function()
				local options = {}
				for _,enum:EnumItem in {Enum.UITheme.Dark, Enum.UITheme.Light} do
					table.insert(options, {
						Label = ("Enum.%s.%s"):format(tostring(enum.EnumType), enum.Name),
						Value = enum
					})
				end
				return options
			end)(),
			OnSelected = function(newItem)
				print("Theme Selected:", newItem.Value)
			end,
		},
		New "Frame" {
			Name = "DropdownAlignment",
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			
			[Children] = {
				New "UIListLayout" {
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
				},
				
				Dropdown {
					Size = UDim2.new(.5, 0, 0, 25),

					Value = Value("Item1"),
					Options = {"Item1", "Item2"},
					OnSelected = function(newItem)
						print("You've selected:", newItem)
					end,
				}
			}
		},
		Button {
			Size = UDim2.new(1, 0, 0, 30),
			Activated = function()
				print("Click!")
			end,
		},
		MainButton {
			Text = "MainButton Disabled",
			Size = UDim2.new(1, 0, 0, 30),
			Selected = true,
			Enabled = Value(false),
		},
		MainButton {
			Text = "MainButton",
			Size = UDim2.new(1, 0, 0, 30),
		},
		New "Frame" {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),

			[Children] = {
				New "UIListLayout" {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 4),
				},

				Title {
					LayoutOrder = 1,
					Text = "Plugin",
					AutomaticSize = Enum.AutomaticSize.XY,
					Size = UDim2.fromOffset(0, 0),
					TextSize = 14
				},
				ClassIcon {
					ClassName = "Plugin",
					AnchorPoint = Vector2.new(.5, .5),
					Position = UDim2.fromScale(.5, .5)
				}
			}
		},
	}

	ExampleWidget {
		[Children] = {
			VerticalCollapsibleSection {
				Text = "Color Picker Component",
				[Children] = {
					ColorPicker {
						ListDisplayMode = Enum.ListDisplayMode.Vertical,
						OnChange = function(newColor)
							print("Color:", "#"..newColor:ToHex())
						end,
					},
					ColorPicker {
						Enabled = false,
						OnChange = function(newColor)
							print("Color:", "#"..newColor:ToHex())
						end,
					},
				}
			},
			VerticalCollapsibleSection {
				Text = "Nested Dropdown",
				Enabled = true,
				[Children] = {
					Dropdown {
						Options = Enum.PartType:GetEnumItems(),
						MaxVisibleItems = 2,
						OnSelected = function(optionSelected)
							print("Selected:", optionSelected)
						end
					},
					Checkbox {
						Value = false,
						Text = "Test Checkbox"
					}
				}
			},
			VerticalCollapsibleSection {
				Text = "Checkbox Component",
				[Children] = {
					Checkbox {
						Value = Value(),
						Text = "Indeterminate"
					},
					Checkbox {
						Text = "Checked",
					},
					Checkbox {
						Text = "Unchecked",
						Value = false
					},
					Checkbox {
						Text = "Checked Disabled",
						Value = true,
						Enabled = Value(false),
						OnChange = function(currentValue)
							print("Toggled:", currentValue)
						end,
					},
					Checkbox {
						Text = "Disabled Unchecked",
						Enabled = false,
						Value = false
					},
					Checkbox {
						Text = "Right Alignment",
						Alignment = Enum.HorizontalAlignment.Right,
					},
				}
			},
		}
	}
end