-- EMO Loadstring Test Script with Inline DXLibUI and Reinjection Mitigation
-- Minimal script to test loading and rendering with Brycki404's UI adapted for EMO

-- Reinjection guard with state preservation
if _G.EMO_TEST_INITIALIZED then
    print("EMO Test already initialized, checking state at ", os.date("%I:%M %p PDT"))
    if _G.EMO_TEST_WINDOW then
        print("EMO Previous window found, attempting to render at ", os.date("%I:%M %p PDT"))
    else
        print("EMO No previous window, reinitializing at ", os.date("%I:%M %p PDT"))
        _G.EMO_TEST_INITIALIZED = nil -- Allow reinitialization
    end
else
    _G.EMO_TEST_INITIALIZED = true
end

-- Attempt to enable console
local consoleEnabled = pcall(function() dx9.ShowConsole(true) end)
if consoleEnabled then
    print("EMO Console enabled successfully at ", os.date("%I:%M %p PDT"))
else
    print("!! EMO Failed to enable console, using fallback at ", os.date("%I:%M %p PDT"))
end

-- Initialize logging
print("EMO Loadstring Test starting at ", os.date("%I:%M %p PDT"))

-- Inline DXLibUI adapted for EMO
local function initializeLib()
    print("EMO Initializing library at ", os.date("%I:%M %p PDT"))
    if _G.EMO_LIB == nil then
        _G.EMO_LIB = {
            Key = dx9.GetKey(),
            FirstRun = true,
            Windows = {},
            WindowCount = 0,
            DraggingWindow = nil,
            InitIndex = 0,
            FontColor = {0, 255, 100},  -- EMO Neon green
            MainColor = {30, 40, 60},   -- EMO Dark slate blue
            BackgroundColor = {20, 20, 20},
            AccentColor = {0, 255, 100}, -- EMO Neon green
            OutlineColor = {200, 200, 200}, -- EMO Metallic silver
            Black = {0, 0, 0},
            RainbowHue = 0,
            CurrentRainbowColor = {0, 0, 0},
            LogoTick = 0,
            Active = false,
            Watermark = {Text = "EMO UI", Visible = true, Location = {150, 10}, MouseOffset = nil},
            Notifications = {}
        }
    end
    local Lib = _G.EMO_LIB
    Lib.Key = dx9.GetKey()
    print("EMO Library initialized, validating dx9 functions at ", os.date("%I:%M %p PDT"))
    
    -- Validate dx9 functions
    if not dx9.GetMouse or not dx9.DrawFilledBox or not dx9.DrawString then
        print("!! EMO Missing required dx9 functions at ", os.date("%I:%M %p PDT"))
        return nil
    end

    -- Mouse in area check
    function Lib.MouseInArea(area, deadzone)
        assert(type(area) == "table" and #area == 4, "[Error] MouseInArea: First Argument needs to be a table with 4 values!")
        local mouse = dx9.GetMouse()
        if deadzone then
            if mouse.x > area[1] and mouse.y > area[2] and mouse.x < area[3] and mouse.y < area[4] then
                if mouse.x > deadzone[1] and mouse.y > deadzone[2] and mouse.x < deadzone[3] and mouse.y < deadzone[4] then
                    return false
                else
                    return true
                end
            else
                return false
            end
        else
            return mouse.x > area[1] and mouse.y > area[2] and mouse.x < area[3] and mouse.y < area[4]
        end
    end

    -- RGB to Hex (simplified)
    function Lib.rgbToHex(rgb)
        local hexadecimal = '#'
        for _, value in pairs(rgb) do
            local hex = string.format("%02X", value)
            hexadecimal = hexadecimal .. hex
        end
        return hexadecimal
    end

    -- Create Window
    function Lib.CreateWindow(params)
        print("EMO Creating window with params: ", params.Name, " at ", os.date("%I:%M %p PDT"))
        assert(type(params) == "table", "[Error] CreateWindow: Parameter must be a table!")
        local WindowName = params.Name or params.Title
        local ToggleKeyPreset = "[F2]" -- EMO default, avoiding F1
        if params.ToggleKey and type(params.ToggleKey) == "string" then
            ToggleKeyPreset = string.upper(params.ToggleKey)
        end
        assert(type(WindowName) == "string" or type(WindowName) == "number", "[Error] CreateWindow: Window name must be a string or number!")
        assert(type(ToggleKeyPreset) == "string" and string.sub(ToggleKeyPreset, 1, 1) == "[", "[Error] CreateWindow: ToggleKey needs [KEY] format!")

        if Lib.Windows[WindowName] == nil then
            Lib.Windows[WindowName] = {
                Location = params.StartLocation or {100, 100},
                Size = params.Size or {300, 200},
                Title = WindowName,
                WinMouseOffset = nil,
                WindowNum = Lib.WindowCount + 1,
                ID = WindowName,
                Tabs = {},
                CurrentTab = nil,
                TabMargin = 0,
                Dragging = false,
                Resizing = false,
                ToggleKeyHolding = false,
                ToggleKeyHovering = false,
                ToggleKey = ToggleKeyPreset,
                ToggleReading = false,
                Active = true,
                Restraint = {160, 200},
                DeadZone = nil,
                OpenTool = nil,
                FontColor = params.FontColor or Lib.FontColor,
                MainColor = params.MainColor or Lib.MainColor,
                BackgroundColor = params.BackgroundColor or Lib.BackgroundColor,
                AccentColor = params.AccentColor or Lib.AccentColor,
                OutlineColor = params.OutlineColor or Lib.OutlineColor
            }
            Lib.WindowCount = Lib.WindowCount + 1
        end
        local Win = Lib.Windows[WindowName]

        function Win:SetRestraint(table)
            if table[1] > Win.Restraint[1] then Win.Restraint[1] = table[1] end
            if table[2] > Win.Restraint[2] then Win.Restraint[2] = table[2] end
        end
        if Win.Size[1] < Win.Restraint[1] then Win.Size[1] = Win.Restraint[1] end
        if Win.Size[2] < Win.Restraint[2] then Win.Size[2] = Win.Restraint[2] end

        function Win:Render()
            print("EMO Rendering window ", Win.Title, " at ", os.date("%I:%M %p PDT"))
            if Win.Active then
                -- Toggle key logic
                if Lib.Key and Lib.Key ~= "[None]" and Lib.Key == Win.ToggleKey and not Win.ToggleReading then
                    Win.Active = not Win.Active
                    print("EMO Window toggled to ", Win.Active, " at ", os.date("%I:%M %p PDT"))
                end

                -- Drag logic
                if dx9.isLeftClickHeld() and Win.Active then
                    if not Win.Resizing and (Win.Dragging or Lib.MouseInArea({Win.Location[1] - 2, Win.Location[2] - 2, Win.Location[1] + Win.Size[1] + 2, Win.Location[2] + 22})) then
                        Win.Dragging = true
                        if Win.WinMouseOffset == nil then
                            Win.WinMouseOffset = {dx9.GetMouse().x - Win.Location[1], dx9.GetMouse().y - Win.Location[2]}
                        end
                        Win.Location = {dx9.GetMouse().x - Win.WinMouseOffset[1], dx9.GetMouse().y - Win.WinMouseOffset[2]}
                        if Win.Location[1] < 0 then Win.Location[1] = 0 end
                        if Win.Location[2] < 0 then Win.Location[2] = 0 end
                        if Win.Location[1] + Win.Size[1] > dx9.size().width then Win.Location[1] = dx9.size().width - Win.Size[1] end
                        if Win.Location[2] + Win.Size[2] > dx9.size().height then Win.Location[2] = dx9.size().height - Win.Size[2] end
                    else
                        Win.Dragging = false
                        Win.WinMouseOffset = nil
                    end
                end

                -- Draw window
                local TrimmedWinName = Win.Title
                if dx9.CalcTextWidth(TrimmedWinName) >= Win.Size[1] - 25 then
                    repeat TrimmedWinName = TrimmedWinName:sub(1, -2) until dx9.CalcTextWidth(TrimmedWinName) <= Win.Size[1] - 25
                end
                dx9.DrawFilledBox({Win.Location[1] - 1, Win.Location[2] - 1}, {Win.Location[1] + Win.Size[1] + 1, Win.Location[2] + Win.Size[2] + 1}, Lib.Black)
                dx9.DrawFilledBox(Win.Location, {Win.Location[1] + Win.Size[1], Win.Location[2] + Win.Size[2]}, Win.AccentColor)
                dx9.DrawFilledBox({Win.Location[1] + 1, Win.Location[2] + 1}, {Win.Location[1] + Win.Size[1] - 1, Win.Location[2] + Win.Size[2] - 1}, Win.MainColor)
                dx9.DrawFilledBox({Win.Location[1] + 5, Win.Location[2] + 20}, {Win.Location[1] + Win.Size[1] - 5, Win.Location[2] + Win.Size[2] - 32}, Win.BackgroundColor)
                dx9.DrawBox({Win.Location[1] + 5, Win.Location[2] + 20}, {Win.Location[1] + Win.Size[1] - 5, Win.Location[2] + Win.Size[2] - 31}, Win.OutlineColor)
                dx9.DrawString(Win.Location, Win.FontColor, " " .. TrimmedWinName)

                -- Render tabs
                for tabName, tab in pairs(Win.Tabs) do
                    if Win.CurrentTab == tabName then
                        dx9.DrawFilledBox({Win.Location[1] + 10 + Win.TabMargin, Win.Location[2] + 25}, {Win.Location[1] + 14 + dx9.CalcTextWidth(tabName) + Win.TabMargin, Win.Location[2] + 50}, Win.OutlineColor)
                        dx9.DrawFilledBox({Win.Location[1] + 11 + Win.TabMargin, Win.Location[2] + 26}, {Win.Location[1] + 13 + dx9.CalcTextWidth(tabName) + Win.TabMargin, Win.Location[2] + 50}, Win.MainColor)
                        dx9.DrawFilledBox({Win.Location[1] + 11 + Win.TabMargin, Win.Location[2] + 26}, {Win.Location[1] + 13 + dx9.CalcTextWidth(tabName) + Win.TabMargin, Win.Location[2] + 27}, Win.AccentColor)
                    else
                        dx9.DrawFilledBox({Win.Location[1] + 10 + Win.TabMargin, Win.Location[2] + 26}, {Win.Location[1] + 14 + dx9.CalcTextWidth(tabName) + Win.TabMargin, Win.Location[2] + 50}, Win.OutlineColor)
                        dx9.DrawFilledBox({Win.Location[1] + 11 + Win.TabMargin, Win.Location[2] + 27}, {Win.Location[1] + 13 + dx9.CalcTextWidth(tabName) + Win.TabMargin, Win.Location[2] + 49}, Win.MainColor)
                    end
                    dx9.DrawString({Win.Location[1] + 12 + Win.TabMargin, Win.Location[2] + 28}, Win.FontColor, " " .. tabName)
                    tab.Boundary = {Win.Location[1] + 10 + Win.TabMargin, Win.Location[2] + 26, Win.Location[1] + 14 + dx9.CalcTextWidth(tabName) + Win.TabMargin, Win.Location[2] + 50}
                    Win.TabMargin = Win.TabMargin + dx9.CalcTextWidth(tabName) + 3
                    if Lib.MouseInArea(tab.Boundary) and not Win.Dragging and dx9.isLeftClickHeld() then
                        Win.CurrentTab = tabName
                    end
                end

                -- Render groups (simplified collapsible categories)
                if Win.CurrentTab then
                    local tab = Win.Tabs[Win.CurrentTab]
                    local leftStack = 60
                    for groupName, group in pairs(tab.Groupboxes) do
                        local isCollapsed = group.collapsed or false
                        if not isCollapsed then
                            local rootX, rootY = Win.Location[1] + 20, Win.Location[2] + leftStack
                            dx9.DrawFilledBox({rootX, rootY}, {rootX + group.Size[1], rootY + group.Size[2]}, Win.OutlineColor)
                            dx9.DrawFilledBox({rootX + 1, rootY + 1}, {rootX + group.Size[1] - 1, rootY + 3}, Win.AccentColor)
                            dx9.DrawFilledBox({rootX + 1, rootY + 4}, {rootX + group.Size[1] - 1, rootY + group.Size[2] - 1}, Win.BackgroundColor)
                            dx9.DrawString({rootX + (group.Size[1] / 2) - (dx9.CalcTextWidth(groupName) / 2), rootY + 4}, Win.FontColor, groupName)
                            group.Root = {rootX + 1, rootY + 10}
                            for _, tool in pairs(group.Tools) do
                                if tool.draw then tool:draw() end
                            end
                            leftStack = leftStack + group.Size[2] + 10
                            Win:SetRestraint({0, leftStack + 35})
                        end
                        if Lib.MouseInArea({rootX, rootY, rootX + group.Size[1], rootY + 15}, Win.DeadZone) and dx9.isLeftClickHeld() then
                            group.collapsed = not group.collapsed
                        end
                    end
                end

                -- Simplified footer
                local footerWidth = 0
                local watermark = "EMO UI"
                local watermarkWidth = dx9.CalcTextWidth(watermark)
                dx9.DrawBox({Win.Location[1] + 5, Win.Location[2] + Win.Size[2] - 28}, {Win.Location[1] + 15 + watermarkWidth, Win.Location[2] + Win.Size[2] - 4}, Win.OutlineColor)
                dx9.DrawFilledBox({Win.Location[1] + 7, Win.Location[2] + Win.Size[2] - 26}, {Win.Location[1] + 13 + watermarkWidth, Win.Location[2] + Win.Size[2] - 6}, Win.BackgroundColor)
                dx9.DrawString({Win.Location[1] + 10, Win.Location[2] + Win.Size[2] - 25}, Lib.CurrentRainbowColor, watermark)
                footerWidth = footerWidth + watermarkWidth + 12
            end
        end

        return Win
    end

    -- Add Tab with collapsible category support
    function Win:AddTab(TabName)
        print("EMO Adding tab ", TabName, " at ", os.date("%I:%M %p PDT"))
        if Win.Tabs[TabName] == nil then
            Win.Tabs[TabName] = {Groupboxes = {}, Leftstack = 60, Rightstack = 60}
        end
        local Tab = Win.Tabs[TabName]
        Win.TabMargin = Win.TabMargin + dx9.CalcTextWidth(TabName) + 3
        Win:SetRestraint({Win.TabMargin + dx9.CalcTextWidth(TabName) + 24, 0})
        function Tab:AddGroupbox(GroupboxName, side)
            print("EMO Adding groupbox ", GroupboxName, " to tab ", TabName, " at ", os.date("%I:%M %p PDT"))
            if Tab.Groupboxes[GroupboxName] == nil then
                Tab.Groupboxes[GroupboxName] = {ToolSpacing = 0, Visible = true, Tools = {}, Root = {}, Size = {0, 30}, WidthRestraint = dx9.CalcTextWidth(GroupboxName) + 50, collapsed = false}
            end
            local Groupbox = Tab.Groupboxes[GroupboxName]
            if dx9.CalcTextWidth(GroupboxName) + 50 > Groupbox.WidthRestraint then Groupbox.WidthRestraint = dx9.CalcTextWidth(GroupboxName) + 50 end
            if side == "left" then Groupbox.Size[1] = (Win.Size[1] / 2) - 23
            elseif side == "right" then Groupbox.Size[1] = (Win.Size[1] / 2) - 23
            else Groupbox.Size[1] = Win.Size[1] - 40 end
            Win:SetRestraint({Groupbox.WidthRestraint * 2, 0})
            return Groupbox
        end
        return Tab
    end

    -- Basic Toggle
    function Groupbox:AddToggle(Text, Default)
        print("EMO Adding toggle ", Text, " to groupbox ", GroupboxName, " at ", os.date("%I:%M %p PDT"))
        local Toggle = {Boundary = {0, 0, 0, 0}, Value = Default or false, Holding = false, Hovering = false}
        function Toggle:draw()
            if Win.Active then
                local root = Groupbox.Root
                if Toggle.Hovering then dx9.DrawFilledBox({root[1] + 4, root[2] + Groupbox.ToolSpacing}, {root[1] + 23, root[2] + 38 + Groupbox.ToolSpacing}, Win.AccentColor)
                else dx9.DrawFilledBox({root[1] + 4, root[2] + Groupbox.ToolSpacing}, {root[1] + 23, root[2] + 38 + Groupbox.ToolSpacing}, Lib.Black) end
                dx9.DrawFilledBox({root[1] + 5, root[2] + 1 + Groupbox.ToolSpacing}, {root[1] + 22, root[2] + 37 + Groupbox.ToolSpacing}, Win.OutlineColor)
                dx9.DrawFilledBox({root[1] + 6, root[2] + 2 + Groupbox.ToolSpacing}, {root[1] + 21, root[2] + 36 + Groupbox.ToolSpacing}, Toggle.Value and Win.AccentColor or Win.MainColor)
                dx9.DrawString({root[1] + 25, root[2] + Groupbox.ToolSpacing}, Win.FontColor, Text)
                Toggle.Boundary = {root[1] + 4, root[2] + Groupbox.ToolSpacing, root[1] + 23, root[2] + 38 + Groupbox.ToolSpacing}
                if Lib.MouseInArea(Toggle.Boundary, Win.DeadZone) and not Win.Dragging and dx9.isLeftClickHeld() then
                    Toggle.Value = not Toggle.Value
                    print("EMO Toggle ", Text, " set to ", Toggle.Value, " at ", os.date("%I:%M %p PDT"))
                end
            end
        end
        table.insert(Groupbox.Tools, Toggle)
        Groupbox.ToolSpacing = Groupbox.ToolSpacing + 40
        Groupbox.Size[2] = Groupbox.Size[2] + 40
        return Toggle
    end

    -- Rainbow and Notifications
    Lib.RainbowHue = (Lib.RainbowHue or 0) + 3
    if Lib.RainbowHue > 1530 then Lib.RainbowHue = 0 end
    if Lib.RainbowHue <= 255 then Lib.CurrentRainbowColor = {255, Lib.RainbowHue, 0}
    elseif Lib.RainbowHue <= 510 then Lib.CurrentRainbowColor = {510 - Lib.RainbowHue, 255, 0}
    elseif Lib.RainbowHue <= 765 then Lib.CurrentRainbowColor = {0, 255, Lib.RainbowHue - 510}
    elseif Lib.RainbowHue <= 1020 then Lib.CurrentRainbowColor = {0, 1020 - Lib.RainbowHue, 255}
    elseif Lib.RainbowHue <= 1275 then Lib.CurrentRainbowColor = {Lib.RainbowHue - 1020, 0, 255}
    else Lib.CurrentRainbowColor = {255, 0, 1530 - Lib.RainbowHue} end

    function Lib.Notify(text, length, color)
        if length == nil then length = 3 end
        if color == nil then color = Lib.FontColor end
        table.insert(Lib.Notifications, {Text = text, Start = os.clock(), Length = length, Color = color})
    end
    for i, v in pairs(Lib.Notifications) do
        if v.Start < os.clock() - v.Length then table.remove(Lib.Notifications, i) end
    end

    return Lib
end

local Lib = initializeLib()
if not Lib then
    print("!! EMO Library initialization failed at ", os.date("%I:%M %p PDT"))
    return
end

-- Test window creation
if not _G.EMO_TEST_WINDOW then
    print("EMO Attempting to create test window at ", os.date("%I:%M %p PDT"))
    _G.EMO_TEST_WINDOW = Lib.CreateWindow({Name = "Test Window", StartLocation = {100, 100}, Size = {300, 200}})
    if _G.EMO_TEST_WINDOW then
        print("EMO Test window created successfully at ", os.date("%I:%M %p PDT"))
        local tab = _G.EMO_TEST_WINDOW:AddTab("Settings")
        local group = tab:AddGroupbox("Controls", "middle")
        group:AddToggle("Test Toggle", true)
    else
        print("!! EMO Failed to create test window at ", os.date("%I:%M %p PDT"))
    end
else
    print("EMO Using existing test window at ", os.date("%I:%M %p PDT"))
end

-- Simple draw loop to test rendering
local drawCount = 0
while true do
    if drawCount == 0 then
        print("EMO Entering draw loop at ", os.date("%I:%M %p PDT"))
    end
    local success, err = pcall(function()
        dx9.ClearConsole()
        if _G.EMO_TEST_WINDOW then
            print("EMO Before draw call at ", os.date("%I:%M %p PDT"), " count: ", drawCount)
            _G.EMO_TEST_WINDOW:Render()
            print("EMO After draw call at ", os.date("%I:%M %p PDT"), " count: ", drawCount)
        end
        dx9.DrawString({150, 150}, {255, 255, 255}, "Loadstring Test")
        dx9.DrawBox({140, 140}, {160, 160}, {255, 255, 255})
    end)
    if not success then
        print("!! EMO Error in draw loop: " .. err .. " at ", os.date("%I:%M %p PDT"), " count: ", drawCount)
    end
    drawCount = drawCount + 1
    dx9.Wait(0.016) -- 60 FPS
end
