-- DX9WARE UI Script for Feature Controls (Loadstring)
-- Sleek, modern, Valorant/Overwatch-inspired design with Insert key toggle

-- Initialize UI Library (replace with DX9WARE's actual UI library)
local UI = loadstring(dx9.Get("https://raw.githubusercontent.com/soupg/DXLibUI/main/supgLib.lua"))() -- Placeholder for supgLib []
-- Alternative: local UI = dx9.UI() if DX9WARE has a built-in UI module

-- Create UI Table to Return
local FeatureUI = {}

-- Create Main Window (Valorant/Overwatch-inspired)
local Window = UI:CreateWindow({
    Title = "NEXUS CONTROLLER", -- Bold, futuristic name
    Size = Vector2.new(650, 450), -- Larger for modern feel
    Draggable = true,
    Hotkey = Enum.KeyCode.Insert, -- Toggle with Insert key
    Visible = true,
    BackgroundColor = Color3.new(0.05, 0.05, 0.05), -- Near-black
    BorderRadius = 12, -- Rounded edges
    Shadow = { Intensity = 0.6, Color = Color3.new(0, 0.8, 1) } -- Neon cyan shadow
})

-- Apply Modern Styling
Window:SetAccentColor(Color3.new(0, 0.8, 1)) -- Neon cyan
Window:SetTheme("DarkFuturistic") -- Assuming theme support
Window:SetFont("SansBold", 16) -- Bold, modern font
Window:EnableAnimations({
    HoverScale = 1.05, -- Buttons scale on hover
    TransitionSpeed = 0.2, -- Smooth transitions
    GlowEffect = true -- Neon glow on controls
})

-- Explicitly Set Hotkey to Insert
Window:SetHotkey(Enum.KeyCode.Insert) -- Ensure Insert toggles UI []

-- Create Tab System (Vertical, sleek)
local TabSystem = Window:CreateTabSystem({
    Alignment = "Left",
    BackgroundColor = Color3.new(0.1, 0.1, 0.1), -- Dark gray
    TabWidth = 130, -- Wide tabs for bold text
    TabHoverColor = Color3.new(0, 0.8, 1), -- Neon cyan on hover
    TabSelectedColor = Color3.new(0.2, 0.4, 1) -- Softer cyan when selected
})

-- Autofarm Tab
local AutofarmTab = TabSystem:CreateTab({
    Name = "AUTO-FARM",
    Icon = "rbxasset://textures/ui/neon_farm.png", -- Optional
    TextColor = Color3.new(1, 0.2, 0.8) -- Neon magenta
})
AutofarmTab:CreateLabel({
    Text = "AUTO-FARM MODULE",
    FontSize = 18,
    TextColor = Color3.new(1, 1, 1),
    Glow = { Intensity = 0.4, Color = Color3.new(0, 0.8, 1) }
})
FeatureUI.AutofarmToggle = AutofarmTab:CreateToggle({
    Text = "ACTIVATE",
    Default = false,
    Style = "Neon",
    Callback = function(state)
        dxl.ShowConsole("AUTO-FARM: " .. (state and "ON" or "OFF")) []
        if FeatureUI.OnAutofarmToggle then
            FeatureUI.OnAutofarmToggle(state)
        end
    end
})
FeatureUI.AutofarmSlider = AutofarmTab:CreateSlider({
    Text = "SPEED",
    Min = 1,
    Max = 100,
    Default = 50,
    Increment = 1,
    BarColor = Color3.new(0, 0.8, 1),
    Callback = function(value)
        dxl.ShowConsole("FARM SPEED: " .. value) []
        if FeatureUI.OnAutofarmSpeed then
            FeatureUI.OnAutofarmSpeed(value)
        end
    end
})
FeatureUI.AutofarmButton = AutofarmTab:CreateButton({
    Text = "LAUNCH",
    Color = Color3.new(0.2, 0.4, 1),
    HoverColor = Color3.new(0, 0.8, 1),
    Callback = function()
        dxl.ShowConsole("LAUNCHING AUTO-FARM") []
        if FeatureUI.OnAutofarmStart then
            FeatureUI.OnAutofarmStart()
        end
    end
})

-- Autoplay Tab
local AutoplayTab = TabSystem:CreateTab({
    Name = "AUTO-PLAY",
    Icon = "rbxasset://textures/ui/neon_play.png",
    TextColor = Color3.new(1, 0.2, 0.8)
})
AutoplayTab:CreateLabel({
    Text = "AUTO-PLAY MODULE",
    FontSize = 18,
    Glow = { Intensity = 0.4, Color = Color3.new(0, 0.8, 1) }
})
FeatureUI.AutoplayToggle = AutoplayTab:CreateToggle({
    Text = "ACTIVATE",
    Default = false,
    Style = "Neon",
    Callback = function(state)
        dxl.ShowConsole("AUTO-PLAY: " .. (state and "ON" or "OFF")) []
        if FeatureUI.OnAutoplayToggle then
            FeatureUI.OnAutoplayToggle(state)
        end
    end
})
FeatureUI.AutoplayDropdown = AutoplayTab:CreateDropdown({
    Text = "MODE",
    Options = {"MODE 1", "MODE 2", "MODE 3"},
    Default = "MODE 1",
    NeonBorder = true,
    Callback = function(selected)
        dxl.ShowConsole("AUTO-PLAY MODE: " .. selected) []
        if FeatureUI.OnAutoplayMode then
            FeatureUI.OnAutoplayMode(selected)
        end
    end
})

-- Aim Assist Tab
local AimAssistTab = TabSystem:CreateTab({
    Name = "AIM ASSIST",
    Icon = "rbxasset://textures/ui/neon_aim.png",
    TextColor = Color3.new(1, 0.2, 0.8)
})
AimAssistTab:CreateLabel({
    Text = "AIM ASSIST MODULE",
    FontSize = 18,
    Glow = { Intensity = 0.4, Color = Color3.new(0, 0.8, 1) }
})
FeatureUI.AimAssistToggle = AimAssistTab:CreateToggle({
    Text = "ACTIVATE",
    Default = false,
    Style = "Neon",
    Callback = function(state)
        dxl.ShowConsole("AIM ASSIST: " .. (state and "ON" or "OFF")) []
        if FeatureUI.OnAimAssistToggle then
            FeatureUI.OnAimAssistToggle(state)
        end
    end
})
FeatureUI.AimAssistSlider = AimAssistTab:CreateSlider({
    Text = "SENSITIVITY",
    Min = 0,
    Max = 10,
    Default = 5,
    Increment = 0.1,
    BarColor = Color3.new(0, 0.8, 1),
    Callback = function(value)
        dxl.ShowConsole("AIM SENSITIVITY: " .. value) []
        if FeatureUI.OnAimAssistSensitivity then
            FeatureUI.OnAimAssistSensitivity(value)
        end
    end
})

-- Developer Mode Tab
local DeveloperTab = TabSystem:CreateTab({
    Name = "DEV MODE",
    Icon = "rbxasset://textures/ui/neon_dev.png",
    TextColor = Color3.new(1, 0.2, 0.8)
})
DeveloperTab:CreateLabel({
    Text = "DEVELOPER TOOLS",
    FontSize = 18,
    Glow = { Intensity = 0.4, Color = Color3.new(0, 0.8, 1) }
})
FeatureUI.DebugButton = DeveloperTab:CreateButton({
    Text = "RUN DEBUG",
    Color = Color3.new(0.2, 0.4, 1),
    HoverColor = Color3.new(0, 0.8, 1),
    Callback = function()
        dxl.ShowConsole("RUNNING DEBUG") []
        if FeatureUI.OnDebugRun then
            FeatureUI.OnDebugRun()
        end
    end
})
FeatureUI.ScriptTextBox = DeveloperTab:CreateTextBox({
    Text = "CUSTOM CODE",
    Placeholder = "Enter Lua Code",
    MultiLine = true,
    NeonBorder = true,
    Callback = function(input)
        dxl.ShowConsole("EXECUTING: " .. input) []
        if FeatureUI.OnCustomScript then
            FeatureUI.OnCustomScript(input)
        end
    end
})

-- Misc Tab
local MiscTab = TabSystem:CreateTab({
    Name = "MISC",
    Icon = "rbxasset://textures/ui/neon_misc.png",
    TextColor = Color3.new(1, 0.2, 0.8)
})
MiscTab:CreateLabel({
    Text = "MISC FEATURES",
    FontSize = 18,
    Glow = { Intensity = 0.4, Color = Color3.new(0, 0.8, 1) }
})
FeatureUI.ResetButton = MiscTab:CreateButton({
    Text = "RESET ALL",
    Color = Color3.new(1, 0.2, 0.2), -- Red for emphasis
    HoverColor = Color3.new(1, 0.4, 0.4),
    Callback = function()
        dxl.ShowConsole("RESETTING ALL") []
        if FeatureUI.OnReset then
            FeatureUI.OnReset()
        end
    end
})
FeatureUI.DarkModeToggle = MiscTab:CreateToggle({
    Text = "NEON MODE",
    Default = true,
    Style = "Neon",
    Callback = function(state)
        Window:SetTheme(state and "DarkFuturistic" or "LightModern")
        dxl.ShowConsole("NEON MODE: " .. (state and "ON" or "OFF")) []
        if FeatureUI.OnDarkModeToggle then
            FeatureUI.OnDarkModeToggle(state)
        end
    end
})

-- Notification (Valorant-style)
Window:Notify({
    Text = "NEXUS CONTROLLER INITIALIZED",
    Duration = 3,
    Color = Color3.new(0, 0.8, 1),
    Animation = "SlideIn"
})

-- Save Configuration
Window:SaveConfig("C:/Users/[Username]/AppData/Roaming/dx9ware/NexusControllerConfig") -- Adjust path []

-- Expose UI Functions
function FeatureUI:SetCallback(name, callback)
    if self[name] then
        self[name] = callback
        dxl.ShowConsole("Callback set: " .. name) []
    else
        dxl.ShowConsole("Invalid callback: " .. name) []
    end
end

function FeatureUI:GetWindow()
    return Window
end

function FeatureUI:SetVisible(visible)
    Window:SetVisible(visible)
end

-- Return UI Table
return FeatureUI
