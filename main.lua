--// EMO UI Library //--

--[[  
███████╗███╗   ███╗ ██████╗ 
██╔════╝████╗ ████║██╔═══██╗
█████╗  ██╔████╔██║██║   ██║
██╔══╝  ██║╚██╔╝██║██║   ██║
███████╗██║ ╚═╝ ██║╚██████╔╝
╚══════╝╚═╝     ╚═╝ ╚═════╝ 
   EMO UI Library
]]--

--// Log Function (Temporary Debug)
local log = "_LOG_\n"
function Log(...)
    local temp = ""
    for i,v in pairs({...}) do
        temp = temp..tostring(v).." "
    end
    log = log..temp.."\n"
    dx9.DrawString({1500,0},{255,255,255},log)
end

--// Global Dynamic Values
if _G.EMO == nil then
    _G.EMO = {
        -- Colors (SKECH Style)
        FontColor = {255,255,255};
        MainColor = {18,18,18};         -- dark body
        BackgroundColor = {12,12,12};   -- darker background
        AccentColor = {200,30,30};      -- neon red
        OutlineColor = {50,50,50};
        Black = {0,0,0};

        RainbowHue = 0;
        CurrentRainbowColor = {0,0,0};
        LogoTick = 0;

        Active = false;

        -- Watermark
        Watermark = {
            Text = "EMO";
            Visible = true;
            Location = {150,10};
            MouseOffset = nil;
        };

        -- Windows
        Windows = {};
        WindowCount = 0;
        DraggingWindow = nil;

        InitIndex = 0;

        -- Hook Storage
        LoadstringCaching = {};
        GetCaching = {};
        OldLoadstring = loadstring;
        OldGet = dx9.Get;

        OldPrint = print;
        OldError = error;

        -- Console Vars (optional debug console)
        C_Location = {1000,150};
        C_Size = {dx9.size().width / 2.95, dx9.size().height / 1.21};
        C_Open = true;
        C_Hovering = false;
        C_Dragging = false;
        C_WinMouseOffset = nil;
        C_ErrorColor = {255,100,100};
        C_StoredLogs = {};
        C_Holding = false;

        -- First Run
        FirstRun = nil;

        -- Notifications
        Notifications = {};

        -- Key
        Key = dx9.GetKey();

        -- Cursor
        Cursor = true;
    };
end

local Lib = _G.EMO
Lib.Key = dx9.GetKey()
local Mouse = dx9.GetMouse()

--// First Run check
if Lib.FirstRun == nil then
    Lib.FirstRun = true
elseif Lib.FirstRun == true then
    Lib.FirstRun = false
end

--// Mouse in area check (deadzone safe)
function Lib.MouseInArea(area, deadzone)
    assert(type(area) == "table" and #area == 4, 
        "[Error] MouseInArea: Argument must be table with 4 values!")

    local mx, my = dx9.GetMouse().x, dx9.GetMouse().y

    if deadzone ~= nil then
        if mx > area[1] and my > area[2] and mx < area[3] and my < area[4] then
            if mx > deadzone[1] and my > deadzone[2] and mx < deadzone[3] and my < deadzone[4] then
                return false
            else
                return true
            end
        else
            return false
        end
    else
        return (mx > area[1] and my > area[2] and mx < area[3] and my < area[4])
    end
end

--// RGB to Hex
function Lib:rgbToHex(rgb)
    local hexadecimal = '#'
    for _,value in pairs(rgb) do
        local hex = ''
        while(value > 0) do
            local index = math.fmod(value, 16) + 1
            value = math.floor(value / 16)
            hex = string.sub('0123456789ABCDEF', index, index) .. hex            
        end
        if(string.len(hex) == 0)then
            hex = '00'
        elseif(string.len(hex) == 1)then
            hex = '0' .. hex
        end
        hexadecimal = hexadecimal .. hex
    end
    return hexadecimal
end

--// Get Index From RGB (color picker mapping)
function Lib:GetIndex(clr)
    local FirstBarHue = 0
    local CurrentRainbowColor

    for i = 1, 205 do 
        if FirstBarHue > 1530 then
            FirstBarHue = 0        
        end

        if FirstBarHue <= 255 then
            CurrentRainbowColor = {255, FirstBarHue, 0}
        elseif FirstBarHue <= 510 then
            CurrentRainbowColor = {510 - FirstBarHue, 255, 0}
        elseif FirstBarHue <= 765 then
            CurrentRainbowColor = {0, 255, FirstBarHue - 510}
        elseif FirstBarHue <= 1020 then
            CurrentRainbowColor = {0, 1020 - FirstBarHue, 255}
        elseif FirstBarHue <= 1275 then
            CurrentRainbowColor = {FirstBarHue - 1020, 0, 255}
        elseif FirstBarHue <= 1530 then
            CurrentRainbowColor = {255, 0, 1530 - FirstBarHue}
        end
        FirstBarHue = FirstBarHue + 7.5

        local SecondBarHue = 0
        for v = 1, 205 do 
            local Color = {0,0,0}
            if SecondBarHue > 765 then SecondBarHue = 0 end

            if SecondBarHue < 255 then
                Color = { CurrentRainbowColor[1] * (SecondBarHue / 255),
                          CurrentRainbowColor[2] * (SecondBarHue / 255),
                          CurrentRainbowColor[3] * (SecondBarHue / 255) }
            elseif SecondBarHue < 510 then
                Color = { CurrentRainbowColor[1] + (SecondBarHue - 255),
                          CurrentRainbowColor[2] + (SecondBarHue - 255),
                          CurrentRainbowColor[3] + (SecondBarHue - 255) }
            else
                Color = { (255 - (SecondBarHue - 510)),
                          (255 - (SecondBarHue - 510)),
                          (255 - (SecondBarHue - 510)) }
            end
            SecondBarHue = SecondBarHue + 3.75

            if Color[1] > 255 then Color[1] = 255 end
            if Color[2] > 255 then Color[2] = 255 end
            if Color[3] > 255 then Color[3] = 255 end

            local r1,g1,b1 = Color[1],Color[2],Color[3]
            local r2,g2,b2 = clr[1],clr[2],clr[3]

            if (r1 > (r2-2) and r1 < (r2+2)) and
               (g1 > (g2-2) and g1 < (g2+2)) and
               (b1 > (b2-2) and b1 < (b2+2)) then
                return {v,i}
            end
        end
    end
end

--// Window Stack + Cursor
local use_count = 0
function Lib:WinCheck(Win)
    use_count = use_count + 1
    if use_count > Lib.InitIndex then Lib.InitIndex = use_count end

    if Lib.InitIndex == use_count then
        for _,v in pairs(Lib.Windows) do
            if v.WindowNum > Win.WindowNum then
                v:Render()
            end
            if v.OpenTool then
                v.OpenTool:Render()
            end
        end

        -- Draw Cursor
        if Lib.Cursor and Lib.Active then
            dx9.DrawCircle({Mouse.x, Mouse.y}, Lib.Black, 3)
            dx9.DrawCircle({Mouse.x, Mouse.y}, Lib.CurrentRainbowColor, 2)
        end
    end
end

--// Safe Hooks
if Lib.FirstRun then
    --// Cached loadstring
    function Lib.loadstring(str)
        assert(type(str) == "string", "[Error] loadstring: arg must be string!")
        if Lib.LoadstringCaching[str] == nil then
            Lib.LoadstringCaching[str] = Lib.OldLoadstring(str)
        else
            return Lib.LoadstringCaching[str]
        end
    end
    _G.loadstring = Lib.loadstring

    --// Cached dx9.Get
    function Lib.Get(str)
        assert(type(str) == "string", "[Error] Get: arg must be string!")
        if Lib.GetCaching[str] == nil then
            Lib.GetCaching[str] = Lib.OldGet(str)
        else
            return Lib.GetCaching[str]
        end
    end
    _G.dx9.Get = Lib.Get

    --// Wrap Draw Functions
    for _,fn in pairs({"DrawFilledBox","DrawLine","DrawBox"}) do
        local old = _G["dx9"][fn]
        _G["dx9"][fn] = function(...)
            local args = {...}
            if args[1][1] + args[1][2] == 0 then return end
            if args[2][1] + args[2][2] == 0 then return end
            return old(...)
        end
    end

    -- Circle
    local oldCircle = _G["dx9"]["DrawCircle"]
    _G["dx9"]["DrawCircle"] = function(...)
        local args = {...}
        if args[1][1] + args[1][2] == 0 then return end
        return oldCircle(...)
    end

    -- String
    local oldString = _G["dx9"]["DrawString"]
    _G["dx9"]["DrawString"] = function(...)
        local args = {...}
        if args[1][1] + args[1][2] == 0 then return end
        return oldString(...)
    end
end

--// CreateWindow
function Lib:CreateWindow(params)
    assert(type(params) == "table", "[Error] CreateWindow: Parameter must be a table!")

    local WindowName = params.Name or params.Title
    assert(type(WindowName) == "string" or type(WindowName) == "number", 
        "[ERROR] CreateWindow: Window name must be string or number!")

    local StartRainbow = params.Rainbow or params.RGB or false
    local ToggleKeyPreset = "[ESCAPE]"
    if params.ToggleKey ~= nil and type(params.ToggleKey) == "string" then
        ToggleKeyPreset = string.upper(params.ToggleKey)
    end
    local resizable = params.Resizable or false

    -- Trim window title if too wide
    local TrimmedWinName = WindowName
    if dx9.CalcTextWidth(TrimmedWinName) >= params.Size[1] - 25 then
        repeat
            TrimmedWinName = TrimmedWinName:sub(1, -2)
        until dx9.CalcTextWidth(TrimmedWinName) <= params.Size[1] - 25
    end

    -- initialize window if not created
    if Lib.Windows[WindowName] == nil then
        Lib.Windows[WindowName] = {
            Location = params.StartLocation or {100, 100},
            Size = params.Size or {600, 500},
            Restraint = {160, 200},

            Rainbow = StartRainbow,
            Title = TrimmedWinName,
            ID = params.Index or WindowName,

            WindowNum = Lib.WindowCount + 1,
            Tabs = {},
            CurrentTab = nil,
            TabMargin = 0,

            Dragging = false,
            Resizing = false,
            WinMouseOffset = nil,

            -- toggling
            ToggleKey = ToggleKeyPreset,
            ToggleKeyHolding = false,
            ToggleKeyHovering = false,
            ToggleReading = false,

            -- RGB key
            RGBKeyHolding = false,
            RGBKeyHovering = false,

            -- active state
            Active = true,

            -- footer
            FooterToggle = params.FooterToggle ~= false,
            FooterRGB = params.FooterRGB ~= false,
            FooterMouseCoords = params.FooterMouseCoords ~= false,

            -- color theme
            FontColor = params.FontColor or Lib.FontColor,
            MainColor = params.MainColor or Lib.MainColor,
            BackgroundColor = params.BackgroundColor or Lib.BackgroundColor,
            AccentColor = params.AccentColor or Lib.AccentColor,
            OutlineColor = params.OutlineColor or Lib.OutlineColor,

            -- tool handling
            DeadZone = nil,
            OpenTool = nil,
            InitIndex = 0,
        }
        Lib.WindowCount = Lib.WindowCount + 1
    end

    local Win = Lib.Windows[WindowName]

    -- apply size restraints
    if Win.Size[1] < Win.Restraint[1] then Win.Size[1] = Win.Restraint[1] end
    if Win.Size[2] < Win.Restraint[2] then Win.Size[2] = Win.Restraint[2] end

    -- rainbow accent swap
    if Win.Rainbow then 
        Win.AccentColor = Lib.CurrentRainbowColor
    end

    -- toggle UI open/close
    if Lib.Key and Lib.Key ~= "[None]" and Lib.Key == Win.ToggleKey and not Win.ToggleReading then
        Win.Active = not Win.Active
    end
    Lib.Active = Win.Active

    -- clamp window position to screen
    local screen = dx9.size()
    if Win.Location[1] < 0 then Win.Location[1] = 0 end
    if Win.Location[2] < 0 then Win.Location[2] = 0 end
    if Win.Location[1] + Win.Size[1] > screen.width then
        Win.Location[1] = screen.width - Win.Size[1]
    end
    if Win.Location[2] + Win.Size[2] > screen.height then
        Win.Location[2] = screen.height - Win.Size[2]
    end

    -- left click handling (drag/resize/tab switching)
    if dx9.isLeftClickHeld() and Win.Active then
        -- dragging
        if not Win.Resizing and (Win.Dragging or Lib.MouseInArea({
            Win.Location[1]-2, Win.Location[2]-2, Win.Location[1]+Win.Size[1]+2, Win.Location[2]+22 })) then
            
            if Lib.DraggingWindow == nil or Lib.DraggingWindow == Win.ID then
                Lib.DraggingWindow = Win.ID
                Win.Dragging = true

                if Win.WinMouseOffset == nil then
                    Win.WinMouseOffset = {
                        dx9.GetMouse().x - Win.Location[1],
                        dx9.GetMouse().y - Win.Location[2]
                    }
                end

                Win.Location = {
                    dx9.GetMouse().x - Win.WinMouseOffset[1],
                    dx9.GetMouse().y - Win.WinMouseOffset[2]
                }
            end
        -- resizing
        elseif resizable and (Win.Resizing or Lib.MouseInArea({
            Win.Location[1] + Win.Size[1] - 10,
            Win.Location[2] + Win.Size[2] - 10,
            Win.Location[1] + Win.Size[1] + 3,
            Win.Location[2] + Win.Size[2] + 3
        })) then
            Win.Resizing = true
            local x = dx9.GetMouse().x - Win.Location[1]
            local y = dx9.GetMouse().y - Win.Location[2]
            if x < Win.Restraint[1] then x = Win.Restraint[1] end
            if y < Win.Restraint[2] then y = Win.Restraint[2] end
            Win.Size = {x, y}
        else
            -- tab click detection
            for i, t in pairs(Win.Tabs) do
                if Lib.MouseInArea({t.Boundary[1], t.Boundary[2], t.Boundary[3], t.Boundary[4]}) and not Win.Dragging then
                    Win.CurrentTab = i
                end
            end
        end
    else
        Win.Dragging = false
        Win.Resizing = false
        Win.WinMouseOffset = nil
        Lib.DraggingWindow = nil
    end

    --// Render Window
    function Win:Render()
        if Win.Active then

            --// Drawing Main Box
            do
                -- Outer glow border
                dx9.DrawFilledBox(
                    { Win.Location[1] - 2 , Win.Location[2] - 2 },
                    { Win.Location[1] + Win.Size[1] + 2 , Win.Location[2] + Win.Size[2] + 2 },
                    { 10, 10, 10 } -- subtle shadow
                )

                -- Accent neon red frame
                dx9.DrawFilledBox(
                    Win.Location,
                    { Win.Location[1] + Win.Size[1], Win.Location[2] + Win.Size[2] },
                    Win.AccentColor or {255,0,0}
                )

                -- Inner dark body
                dx9.DrawFilledBox(
                    { Win.Location[1] + 1 , Win.Location[2] + 1 },
                    { Win.Location[1] + Win.Size[1] - 1 , Win.Location[2] + Win.Size[2] - 1 },
                    Win.MainColor or {15,15,15}
                )

                -- Main inner area
                dx9.DrawFilledBox(
                    { Win.Location[1] + 5 , Win.Location[2] + 20 },
                    { Win.Location[1] + Win.Size[1] - 5 , Win.Location[2] + Win.Size[2] - 32 },
                    Win.BackgroundColor or {20,20,20}
                )

                -- EMO Logo top-left
                local logoColor = {255, 0 + (Lib.LogoTick % 50), 0} -- pulsing red glow
                dx9.DrawString(
                    { Win.Location[1] + 12 , Win.Location[2] + 4 },
                    logoColor,
                    "[EMO UI]"
                )

                -- Section box (like SKETCH)
                dx9.DrawFilledBox(
                    { Win.Location[1] + 10 , Win.Location[2] + 49 },
                    { Win.Location[1] + Win.Size[1] - 10 , Win.Location[2] + Win.Size[2] - 36 },
                    Win.OutlineColor
                )
                dx9.DrawFilledBox(
                    { Win.Location[1] + 11 , Win.Location[2] + 50 },
                    { Win.Location[1] + Win.Size[1] - 11 , Win.Location[2] + Win.Size[2] - 37 },
                    Win.MainColor
                )
            end

            --// Footer //--
            local FooterWidth = 0
            --// Watermark --
            local Watermark = "   EMO"
            local Watermark_Width = dx9.CalcTextWidth(Watermark)

            -- Neon red glow (pulses with LogoTick)
            local glow = {255, 50 + (Lib.LogoTick % 150), 50}

            dx9.DrawBox(
                { Win.Location[1] + 5 , Win.Location[2] + Win.Size[2] - 28 },
                { Win.Location[1] + 15 + Watermark_Width , Win.Location[2] + Win.Size[2] - 4 },
                Win.OutlineColor
            )
            dx9.DrawBox(
                { Win.Location[1] + 6 , Win.Location[2] + Win.Size[2] - 27 },
                { Win.Location[1] + 14 + Watermark_Width , Win.Location[2] + Win.Size[2] - 5 },
                Lib.Black
            )
            dx9.DrawFilledBox(
                { Win.Location[1] + 7 , Win.Location[2] + Win.Size[2] - 26 },
                { Win.Location[1] + 13 + Watermark_Width , Win.Location[2] + Win.Size[2] - 6 },
                Win.BackgroundColor
            )

            dx9.DrawString(
                { Win.Location[1] + 10 , Win.Location[2] + Win.Size[2] - 25 },
                glow,
                Watermark
            )
            FooterWidth = FooterWidth + Watermark_Width + 12

            --// EMO Logo Glow Box --
            local epic = (Lib.LogoTick / 5) % 8
            local TL = { Win.Location[1] + 12 + epic , Win.Location[2] + Win.Size[2] - 20 }
            local TR = { Win.Location[1] + 28 , Win.Location[2] + Win.Size[2] - 20 + epic }
            local BL = { Win.Location[1] + 12 , Win.Location[2] + Win.Size[2] - 12 - epic }
            local BR = { Win.Location[1] + 28 - epic , Win.Location[2] + Win.Size[2] - 12 }

            -- Draw glowing EMO red rectangle (instead of generic square)
            dx9.DrawLine(TL, TR, glow)
            dx9.DrawLine(BL, BR, glow)
            dx9.DrawLine(TR, BR, glow)
            dx9.DrawLine(BL, TL, glow)

            --// Toggle Key --
            if Win.FooterToggle then
                local Toggle = "UI Toggle: "..Win.ToggleKey
                if Win.ToggleKey == "[ESCAPE]" then Toggle = "UI Toggle: [NONE]" end
                if Win.ToggleReading then Toggle = "Reading Key..." end

                local Toggle_Width = dx9.CalcTextWidth(Toggle)

                dx9.DrawBox(
                    { FooterWidth + Win.Location[1] + 5 , Win.Location[2] + Win.Size[2] - 28 },
                    { FooterWidth + Win.Location[1] + 15 + Toggle_Width , Win.Location[2] + Win.Size[2] - 4 },
                    Win.OutlineColor
                )

                -- Hover highlight in neon red
                if Win.ToggleKeyHovering then
                    dx9.DrawBox(
                        { FooterWidth + Win.Location[1] + 6 , Win.Location[2] + Win.Size[2] - 27 },
                        { FooterWidth + Win.Location[1] + 14 + Toggle_Width , Win.Location[2] + Win.Size[2] - 5 },
                        glow
                    )
                else
                    dx9.DrawBox(
                        { FooterWidth + Win.Location[1] + 6 , Win.Location[2] + Win.Size[2] - 27 },
                        { FooterWidth + Win.Location[1] + 14 + Toggle_Width , Win.Location[2] + Win.Size[2] - 5 },
                        Lib.Black
                    )
                end

                dx9.DrawFilledBox(
                    { FooterWidth + Win.Location[1] + 7 , Win.Location[2] + Win.Size[2] - 26 },
                    { FooterWidth + Win.Location[1] + 13 + Toggle_Width , Win.Location[2] + Win.Size[2] - 6 },
                    Win.BackgroundColor
                )

                if Win.ToggleReading then
                    dx9.DrawString(
                        { FooterWidth + Win.Location[1] + 10 , Win.Location[2] + Win.Size[2] - 25 },
                        glow,
                        Toggle
                    )
                else
                    dx9.DrawString(
                        { FooterWidth + Win.Location[1] + 10 , Win.Location[2] + Win.Size[2] - 25 },
                        Win.FontColor,
                        Toggle
                    )
                end

               --// Hover Detection
                if Lib.MouseInArea(
                    { FooterWidth + Win.Location[1] + 5 , Win.Location[2] + Win.Size[2] - 28 , FooterWidth + Win.Location[1] + 15 + Toggle_Width , Win.Location[2] + Win.Size[2] - 4 },
                    Win.DeadZone
                ) then
                    if dx9.isLeftClickHeld() then
                        Win.ToggleKeyHolding = true
                    else
                        if Win.ToggleKeyHolding then
                            Win.ToggleReading = true
                            Win.ToggleKeyHolding = false
                        end
                    end
                    Win.ToggleKeyHovering = true
                else
                    if dx9.isLeftClickHeld() and Win.ToggleReading then
                        Win.ToggleReading = false
                    end
                    Win.ToggleKeyHovering = false
                    Win.ToggleKeyHolding = false
                end

                --// Toggle Key Set Detect
                if Win.ToggleReading and Lib.Key and Lib.Key ~= "[None]" and Lib.Key ~= "[Unknown]" and Lib.Key ~= "[LBUTTON]" then
                    Win.ToggleKey = Lib.Key
                    Win.ToggleReading = false
                end
                
                FooterWidth = FooterWidth + Toggle_Width + 12
            end

            --// RGB //--
            if Win.FooterRGB then
                local RGB = "RGB: OFF"
                local RGB_Width = dx9.CalcTextWidth(RGB)
                if Win.Rainbow then RGB = "RGB: ON" end

                local glow = {255, 50 + (Lib.LogoTick % 150), 50}

                dx9.DrawBox(
                    { FooterWidth + Win.Location[1] + 5 , Win.Location[2] + Win.Size[2] - 28 },
                    { FooterWidth + Win.Location[1] + 15 + RGB_Width , Win.Location[2] + Win.Size[2] - 4 },
                    Win.OutlineColor
                )

                if Win.RGBHovering then
                    dx9.DrawBox(
                        { FooterWidth + Win.Location[1] + 6 , Win.Location[2] + Win.Size[2] - 27 },
                        { FooterWidth + Win.Location[1] + 14 + RGB_Width , Win.Location[2] + Win.Size[2] - 5 },
                        glow -- EMO hover glow
                    )
                else
                    dx9.DrawBox(
                        { FooterWidth + Win.Location[1] + 6 , Win.Location[2] + Win.Size[2] - 27 },
                        { FooterWidth + Win.Location[1] + 14 + RGB_Width , Win.Location[2] + Win.Size[2] - 5 },
                        Lib.Black
                    )
                end

                dx9.DrawFilledBox(
                    { FooterWidth + Win.Location[1] + 7 , Win.Location[2] + Win.Size[2] - 26 },
                    { FooterWidth + Win.Location[1] + 13 + RGB_Width , Win.Location[2] + Win.Size[2] - 6 },
                    Win.BackgroundColor
                )

                dx9.DrawString(
                    { FooterWidth + Win.Location[1] + 10 , Win.Location[2] + Win.Size[2] - 25 },
                    Win.FontColor,
                    RGB
                )

                --// Click Detect
                if Lib.MouseInArea(
                    { FooterWidth + Win.Location[1] + 5 , Win.Location[2] + Win.Size[2] - 28 , FooterWidth + Win.Location[1] + 15 + RGB_Width , Win.Location[2] + Win.Size[2] - 4 },
                    Win.DeadZone
                ) then
                    if dx9.isLeftClickHeld() then
                        Win.RGBKeyHolding = true
                    else
                        if Win.RGBKeyHolding then
                            Win.Rainbow = not Win.Rainbow
                            Win.RGBKeyHolding = false
                        end
                    end
                    Win.RGBHovering = true
                else
                    Win.RGBHovering = false
                    Win.RGBKeyHolding = false
                end

                FooterWidth = FooterWidth + RGB_Width + 12
            end

            --// Mouse Coords //--
            if Win.FooterMouseCoords then
                local Coords = "Mouse: "..dx9.GetMouse().x..", "..dx9.GetMouse().y
                local Coords_Width = dx9.CalcTextWidth(Coords)

                dx9.DrawBox(
                    { FooterWidth + Win.Location[1] + 5 , Win.Location[2] + Win.Size[2] - 28 },
                    { FooterWidth + Win.Location[1] + 15 + Coords_Width , Win.Location[2] + Win.Size[2] - 4 },
                    Win.OutlineColor
                )
                dx9.DrawBox(
                    { FooterWidth + Win.Location[1] + 6 , Win.Location[2] + Win.Size[2] - 27 },
                    { FooterWidth + Win.Location[1] + 14 + Coords_Width , Win.Location[2] + Win.Size[2] - 5 },
                    Lib.Black
                )
                dx9.DrawFilledBox(
                    { FooterWidth + Win.Location[1] + 7 , Win.Location[2] + Win.Size[2] - 26 },
                    { FooterWidth + Win.Location[1] + 13 + Coords_Width , Win.Location[2] + Win.Size[2] - 6 },
                    Win.BackgroundColor
                )

                dx9.DrawString(
                    { FooterWidth + Win.Location[1] + 10 , Win.Location[2] + Win.Size[2] - 25 },
                    Win.FontColor,
                    Coords
                )
                FooterWidth = FooterWidth + Coords_Width + 12
            end
        end
    end

    function Win:AddTab(TabName)
        --// Pre-Defs
        local Tab = {}

        --// Init-Defs
        if Win.Tabs[TabName] == nil then
            Win.Tabs[TabName] = { 
                Boundary = { 0 , 0 , 0 , 0 };
                Groupboxes = {};

                Leftstack = 60;
                Rightstack = 60;
             };
        end

        --// Re-Defining
        Tab = Win.Tabs[TabName]; 

        --// Setting TabLength
        local TabLength = dx9.CalcTextWidth(TabName) + 7
        
        --// Set Restraint
        Win:SetRestraint({Win.TabMargin + TabLength + 24, 0})

        --// Display Tab
        if Win.Active then
            if Win.CurrentTab ~= nil and Win.CurrentTab == TabName then 
                -- Selected Tab
                local pulse = {255, 50 + (Lib.LogoTick % 150), 50} -- EMO glow

                dx9.DrawFilledBox(
                    { Win.Location[1] + 10 + Win.TabMargin , Win.Location[2] + 25 },
                    { Win.Location[1] + 14 + TabLength + Win.TabMargin , Win.Location[2] + 50 },
                    Win.OutlineColor
                )
                dx9.DrawFilledBox(
                    { Win.Location[1] + 11 + Win.TabMargin , Win.Location[2] + 26 },
                    { Win.Location[1] + 13 + TabLength + Win.TabMargin , Win.Location[2] + 50 },
                    Win.MainColor
                )
                dx9.DrawFilledBox(
                    { Win.Location[1] + 12 + Win.TabMargin , Win.Location[2] + 27 },
                    { Win.Location[1] + 12 + TabLength + Win.TabMargin , Win.Location[2] + 50 },
                    Win.MainColor
                )

                -- Top accent line glow
                dx9.DrawFilledBox(
                    { Win.Location[1] + 11 + Win.TabMargin , Win.Location[2] + 26 },
                    { Win.Location[1] + 13 + TabLength + Win.TabMargin , Win.Location[2] + 27 },
                    pulse
                )
            else
                -- Unselected Tab
                dx9.DrawFilledBox(
                    { Win.Location[1] + 10 + Win.TabMargin , Win.Location[2] + 26 },
                    { Win.Location[1] + 14 + TabLength + Win.TabMargin , Win.Location[2] + 50 },
                    Win.OutlineColor
                )
                dx9.DrawFilledBox(
                    { Win.Location[1] + 11 + Win.TabMargin , Win.Location[2] + 27 },
                    { Win.Location[1] + 13 + TabLength + Win.TabMargin , Win.Location[2] + 49 },
                    Win.MainColor
                )
                dx9.DrawFilledBox(
                    { Win.Location[1] + 12 + Win.TabMargin , Win.Location[2] + 28 },
                    { Win.Location[1] + 12 + TabLength + Win.TabMargin , Win.Location[2] + 48 },
                    Win.BackgroundColor
                )
            end

            --// Draw Tab Name
            local textColor = Win.FontColor
            if Win.Rainbow then textColor = Lib.CurrentRainbowColor end

            dx9.DrawString(
                { Win.Location[1] + 12 + Win.TabMargin , Win.Location[2] + 28 },
                textColor,
                " "..TabName
            )
            
            --// Defining Boundaries and Setting Margin
            Tab.Boundary = {
                Win.Location[1] + 10 + Win.TabMargin ,
                Win.Location[2] + 26 ,
                Win.Location[1] + 14 + TabLength + Win.TabMargin ,
                Win.Location[2] + 50
            }
            Win.TabMargin = Win.TabMargin + TabLength + 3
        end

        function Tab:AddGroupbox(GroupboxName, side)
            --// Error Handling
            assert(type(GroupboxName) == "string" or type(GroupboxName) == "number",
                "[ERROR] AddGroupbox: First Argument (groupbox name) must be a string or number!")
            side = string.lower(side)

            local Groupbox = {}
            if Tab.Groupboxes[GroupboxName] == nil then
                Tab.Groupboxes[GroupboxName] = { 
                    ToolSpacing = 0;
                    Visible = true;
                    Tools = {};
                    Root = {};
                    Size = {0, 30};
                    WidthRestraint = dx9.CalcTextWidth(GroupboxName) + 50;
                    AnimTick = 0; -- For EMO animations
                }
            end
            Groupbox = Tab.Groupboxes[GroupboxName]

            --// Adjusting Restraint
            if dx9.CalcTextWidth(GroupboxName) + 50 > Groupbox.WidthRestraint then 
                Groupbox.WidthRestraint = dx9.CalcTextWidth(GroupboxName) + 50 
            end

            --// Setting a width restraint (according to groupbox length)
            if side == "right" or side == "left" then
                Groupbox.Size[1] = (Win.Size[1] / 2) - 23
                Win:SetRestraint({Groupbox.WidthRestraint * 2, 0})
            else
                Groupbox.Size[1] = (Win.Size[1]) - 40
                Win:SetRestraint({Groupbox.WidthRestraint , 0})
            end

            if Win.CurrentTab ~= nil and Win.CurrentTab == TabName and Win.Active then
                Groupbox.Visible = true

                -- Determine accent color (rainbow or static)
                local accentColor = Win.AccentColor
                if Win.Rainbow then accentColor = Lib.CurrentRainbowColor end

                -- Animated pulse line (EMO UI flair)
                Groupbox.AnimTick = (Groupbox.AnimTick or 0) + 1
                local glow = {255, 100 + (Groupbox.AnimTick % 100), 100}

                if side == "left" then
                    -- Left Groupbox
                    dx9.DrawFilledBox(
                        {Win.Location[1] + 20, Win.Location[2] + Tab.Leftstack},
                        {Win.Location[1] + (Win.Size[1] / 2) - 3, Win.Location[2] + Tab.Leftstack + Groupbox.Size[2]},
                        Win.OutlineColor
                    )
                    dx9.DrawFilledBox(
                        {Win.Location[1] + 21, Win.Location[2] + Tab.Leftstack + 1},
                        {Win.Location[1] + (Win.Size[1] / 2) - 4, Win.Location[2] + Tab.Leftstack + 3},
                        accentColor
                    )
                    dx9.DrawFilledBox(
                        {Win.Location[1] + 21, Win.Location[2] + Tab.Leftstack + 4},
                        {Win.Location[1] + (Win.Size[1] / 2) - 4, Win.Location[2] + Tab.Leftstack + Groupbox.Size[2] - 1},
                        Win.BackgroundColor
                    )

                    dx9.DrawString(
                        {Win.Location[1] + (Win.Size[1] / 4 + 10) - (dx9.CalcTextWidth(GroupboxName) / 2), Win.Location[2] + Tab.Leftstack + 4},
                        Win.FontColor, GroupboxName
                    )

                    -- Root position for child tools
                    Groupbox.Root = {Win.Location[1] + 21, Win.Location[2] + Tab.Leftstack + 10}

                    -- Stack update
                    Tab.Leftstack = Tab.Leftstack + Groupbox.Size[2] + 10
                    Win:SetRestraint({0, Tab.Leftstack + 35})

                elseif side == "right" then
                    -- Right Groupbox
                    dx9.DrawFilledBox(
                        {Win.Location[1] + (Win.Size[1] / 2) + 3, Win.Location[2] + Tab.Rightstack},
                        {Win.Location[1] + (Win.Size[1]) - 20, Win.Location[2] + Tab.Rightstack + Groupbox.Size[2]},
                        Win.OutlineColor
                    )
                    dx9.DrawFilledBox(
                        {Win.Location[1] + (Win.Size[1] / 2) + 4, Win.Location[2] + Tab.Rightstack + 1},
                        {Win.Location[1] + (Win.Size[1]) - 21, Win.Location[2] + Tab.Rightstack + 3},
                        accentColor
                    )
                    dx9.DrawFilledBox(
                        {Win.Location[1] + (Win.Size[1] / 2) + 4, Win.Location[2] + Tab.Rightstack + 4},
                        {Win.Location[1] + (Win.Size[1]) - 21, Win.Location[2] + Tab.Rightstack + Groupbox.Size[2] - 1},
                        Win.BackgroundColor
                    )

                    dx9.DrawString(
                        {Win.Location[1] + (Win.Size[1] / 1.4 + 10) - (dx9.CalcTextWidth(GroupboxName) / 2), Win.Location[2] + Tab.Rightstack + 4},
                        Win.FontColor, GroupboxName
                    )

                    Groupbox.Root = {math.floor(Win.Location[1] + (Win.Size[1] / 2) + 4 + 0.5), math.floor(Win.Location[2] + Tab.Rightstack + 10 + 0.5)}

                    Tab.Rightstack = Tab.Rightstack + Groupbox.Size[2] + 10
                    Win:SetRestraint({0, Tab.Rightstack + 35})

                else
                    -- Middle Groupbox (full-width)
                    local largest_stack = math.max(Tab.Leftstack, Tab.Rightstack)

                    dx9.DrawFilledBox(
                        {Win.Location[1] + 20, Win.Location[2] + largest_stack},
                        {Win.Location[1] + (Win.Size[1]) - 20, Win.Location[2] + largest_stack + Groupbox.Size[2]},
                        Win.OutlineColor
                    )
                    dx9.DrawFilledBox(
                        {Win.Location[1] + 21, Win.Location[2] + largest_stack + 1},
                        {Win.Location[1] + (Win.Size[1]) - 21, Win.Location[2] + largest_stack + 3},
                        accentColor
                    )
                    dx9.DrawFilledBox(
                        {Win.Location[1] + 21, Win.Location[2] + largest_stack + 4},
                        {Win.Location[1] + (Win.Size[1]) - 21, Win.Location[2] + largest_stack + Groupbox.Size[2] - 1},
                        Win.BackgroundColor
                    )

                    dx9.DrawString(
                        {Win.Location[1] + (Win.Size[1] / 2) - (dx9.CalcTextWidth(GroupboxName) / 2), Win.Location[2] + largest_stack + 4},
                        Win.FontColor, GroupboxName
                    )

                    Groupbox.Root = {Win.Location[1] + 21, Win.Location[2] + largest_stack + 10}

                    Tab.Leftstack = largest_stack + Groupbox.Size[2] + 10
                    Tab.Rightstack = largest_stack + Groupbox.Size[2] + 10

                    Win:SetRestraint({0, largest_stack + Groupbox.Size[2] + 45})
                end
            else
                Groupbox.Visible = false
            end

            -- Add tools methods to Groupbox
            Groupbox:AddButton = function(Groupbox, ButtonName, ButtonFunc)
                local idx = "btn_" .. ButtonName
                local Button = {}

                if Groupbox.Tools[idx] == nil then
                    Groupbox.Tools[idx] = { 
                        Boundary = {0, 0, 0, 0};
                        Holding = false;
                        Cooldown = false;
                        Hovering = false;
                        KeybindHolding = false;
                        ConnectedKeybindButton = nil;
                        LastClick = 0; -- prevent spam clicking
                    }
                end
                Button = Groupbox.Tools[idx]

                -- Disconnect / Connect keybind logic
                function Button:DisconnectKeybindButton()
                    Button.ConnectedKeybindButton = nil
                end
                function Button:ConnectKeybindButton(KeybindButton)
                    assert(type(KeybindButton) == "table", "[ERROR] ConnectKeybindButton: expected table (KeybindButton).")
                    Button.ConnectedKeybindButton = KeybindButton
                end

                -- Keybind detection
                if Button.ConnectedKeybindButton ~= nil then
                    if Button.ConnectedKeybindButton.Key ~= nil then
                        if Button.ConnectedKeybindButton.KeyDown then
                            Button.KeybindHolding = true
                        else
                            if Button.KeybindHolding == true then
                                if ButtonFunc ~= nil then ButtonFunc() end
                                Button.KeybindHolding = false
                            end
                        end
                    end
                end

                -- Draw Button in Groupbox
                if Win.CurrentTab ~= nil and Win.CurrentTab == TabName and Win.Active and Groupbox.Visible then

                    -- Handle multi-line button names
                    local n = 0
                    local NewButtonName = ""
                    if string.gmatch(ButtonName, "([^\n]+)") ~= nil then
                        for i in string.gmatch(ButtonName, "([^\n]+)") do
                            local temp = i
                            if dx9.CalcTextWidth(temp) >= Groupbox.Size[1] - 20 then
                                repeat
                                    temp = temp:sub(1,-2)
                                until dx9.CalcTextWidth(temp) <= Groupbox.Size[1] - 20
                            end
                            NewButtonName = NewButtonName .. temp .. "\n"
                            n = n + 1
                        end
                    else
                        NewButtonName = ButtonName
                        n = 1
                    end

                    -- Calculate Button Size
                    local BtnHeight = (n * 15) + 8
                    local BtnY = Groupbox.Root[2] + Groupbox.ToolSpacing
                    local BtnX1 = Groupbox.Root[1] + 5
                    local BtnX2 = Groupbox.Root[1] + Groupbox.Size[1] - 5
                    local BtnY2 = BtnY + BtnHeight

                    -- Store boundaries for interaction
                    Button.Boundary = {BtnX1, BtnY, BtnX2, BtnY2}

                    -- Hover detection
                    if Lib.MouseInArea(Button.Boundary, Win.DeadZone) then
                        Button.Hovering = true
                    else
                        Button.Hovering = false
                    end

                    -- Button colors
                    local BtnColor = Win.BackgroundColor
                    if Button.Hovering then
                        BtnColor = Win.Rainbow and Lib.CurrentRainbowColor or Win.AccentColor
                    end

                    -- Draw button
                    dx9.DrawFilledBox({BtnX1, BtnY}, {BtnX2, BtnY2}, Win.OutlineColor)
                    dx9.DrawFilledBox({BtnX1+1, BtnY+1}, {BtnX2-1, BtnY2-1}, BtnColor)
                    dx9.DrawString({BtnX1 + 5, BtnY + 3}, Win.FontColor, NewButtonName)

                    -- Click detection
                    if Lib.MouseInArea(Button.Boundary, Win.DeadZone) then
                        if dx9.isLeftClickHeld() and not Button.Holding then
                            Button.Holding = true
                        elseif not dx9.isLeftClickHeld() and Button.Holding then
                            Button.Holding = false

                            -- Cooldown check
                            if os.clock() - (Button.LastClick or 0) > 0.2 then
                                if ButtonFunc ~= nil then ButtonFunc() end
                                Button.LastClick = os.clock()
                            end
                        end
                    else
                        Button.Holding = false
                    end

                    -- Update spacing for next control
                    Groupbox.ToolSpacing = Groupbox.ToolSpacing + BtnHeight + 5
                    if Groupbox.ToolSpacing + 30 > Groupbox.Size[2] then
                        Groupbox.Size[2] = Groupbox.ToolSpacing + 30
                    end
                end

                -- Tooltip Function
                function Button:AddTooltip(str)
                    if Win.CurrentTab ~= nil and Win.CurrentTab == TabName and Win.Active and Groupbox.Visible then
                        local n = 0
                        local Tooltip = ""
                        if string.gmatch(str, "([^\n]+)") ~= nil then
                            for i in string.gmatch(str, "([^\n]+)") do
                                Tooltip = Tooltip .. i .. "\n"
                                n = n + 1
                            end
                        else
                            Tooltip = str
                            n = 1
                        end

                        if Button.Hovering then
                            dx9.DrawFilledBox(
                                {Mouse.x - 1, Mouse.y + 1},
                                {Mouse.x + dx9.CalcTextWidth(Tooltip) + 5, Mouse.y - (18 * n) - 1},
                                Win.AccentColor
                            )
                            dx9.DrawFilledBox(
                                {Mouse.x, Mouse.y},
                                {Mouse.x + dx9.CalcTextWidth(Tooltip) + 4, Mouse.y - (18 * n)},
                                Win.OutlineColor
                            )
                            dx9.DrawString(
                                {Mouse.x + 2, Mouse.y - (18 * n)},
                                Win.FontColor,
                                str
                            )
                        end
                    end
                    return Button
                end

                Lib:WinCheck(Win)
                return Button
            end

            function Groupbox:AddColorPicker(params)
                local Picker = {}
                local Text = params.Text or params.Name or params.Index
                local Index = params.Index or Text

                -- Error Handling
                assert(type(Text) == "string" or type(Text) == "number",
                    "[ERROR] AddColorPicker: Name / Text Variable must be a number or string!")

                -- Init Defaults
                if Groupbox.Tools[Index] == nil then
                    Groupbox.Tools[Index] = {
                        Boundary = {0, 0, 0, 0},
                        Value = params.Default or {0, 0, 0},
                        Holding = false,
                        Hovering = false,
                        AddonY = nil,
                        Changed = true,

                        -- Stored Color Indexes
                        TopColor = params.Default or {0, 0, 0},
                        StoredIndex = Lib:GetIndex(params.Default or {0, 0, 0})[1],
                        StoredIndex2 = Lib:GetIndex(params.Default or {0, 0, 0})[2],

                        -- Bar Hover states
                        FirstBarHovering = false,
                        SecondBarHovering = false,
                    }
                end

                -- Re-Defs
                Groupbox.Tools[Index].Text = Text
                Picker = Groupbox.Tools[Index]

                -- Setter
                function Picker:SetValue(value)
                    Picker.Value = value
                    local idx = Lib:GetIndex(value)
                    Picker.StoredIndex = idx[1]
                    Picker.StoredIndex2 = idx[2]
                    Picker.Changed = true
                end

                -- Show/Hide
                function Picker:Show()
                    Win.OpenTool = Picker
                end
                function Picker:Hide()
                    Win.OpenTool = nil
                    Win.DeadZone = nil
                end

                -- Tooltip
                function Picker:AddTooltip(str)
                    if Win.CurrentTab ~= nil and Win.CurrentTab == TabName and Win.Active and Groupbox.Visible then
                        local n, Tooltip = 0, ""
                        if string.gmatch(str, "([^\n]+)") ~= nil then
                            for i in string.gmatch(str, "([^\n]+)") do
                                Tooltip = Tooltip .. i .. "\n"
                                n = n + 1
                            end
                        else
                            Tooltip = str
                            n = 1
                        end

                        if Picker.Hovering then
                            dx9.DrawFilledBox({Mouse.x - 1, Mouse.y + 1},
                                {Mouse.x + dx9.CalcTextWidth(Tooltip) + 5, Mouse.y - (18 * n) - 1},
                                Win.AccentColor)
                            dx9.DrawFilledBox({Mouse.x, Mouse.y},
                                {Mouse.x + dx9.CalcTextWidth(Tooltip) + 4, Mouse.y - (18 * n)},
                                Win.OutlineColor)
                            dx9.DrawString({Mouse.x + 2, Mouse.y - (18 * n)}, Win.FontColor, str)
                        end
                    end
                    return Picker
                end

                -- Draw Color Picker inside Groupbox
                if Win.CurrentTab ~= nil and Win.CurrentTab == TabName and Win.Active and Groupbox.Visible then

                    -- Mini Swatch
                    if Picker.Hovering then
                        dx9.DrawFilledBox({Groupbox.Root[1] + 6, Groupbox.Root[2] + 21 + Groupbox.ToolSpacing},
                                          {Groupbox.Root[1] + 33, Groupbox.Root[2] + 38 + Groupbox.ToolSpacing}, Win.AccentColor)
                    else
                        dx9.DrawFilledBox({Groupbox.Root[1] + 6, Groupbox.Root[2] + 21 + Groupbox.ToolSpacing},
                                          {Groupbox.Root[1] + 33, Groupbox.Root[2] + 38 + Groupbox.ToolSpacing}, Lib.Black)
                    end
                    dx9.DrawFilledBox({Groupbox.Root[1] + 7, Groupbox.Root[2] + 22 + Groupbox.ToolSpacing},
                                      {Groupbox.Root[1] + 32, Groupbox.Root[2] + 37 + Groupbox.ToolSpacing}, Win.OutlineColor)
                    dx9.DrawFilledBox({Groupbox.Root[1] + 8, Groupbox.Root[2] + 23 + Groupbox.ToolSpacing},
                                      {Groupbox.Root[1] + 31, Groupbox.Root[2] + 36 + Groupbox.ToolSpacing}, Picker.Value)

                    -- Trim Text if needed
                    local TrimmedToggleText = Text
                    if dx9.CalcTextWidth(TrimmedToggleText) >= Groupbox.Size[1] - 45 then
                        repeat
                            TrimmedToggleText = TrimmedToggleText:sub(1, -2)
                        until dx9.CalcTextWidth(TrimmedToggleText) <= Groupbox.Size[1] - 45
                    end
                    dx9.DrawString({Groupbox.Root[1] + 33, Groupbox.Root[2] + 19 + Groupbox.ToolSpacing}, Win.FontColor, " " .. TrimmedToggleText)

                    -- Boundaries
                    Picker.Boundary = {
                        Groupbox.Root[1] + 4,
                        Groupbox.Root[2] + 19 + Groupbox.ToolSpacing,
                        Groupbox.Root[1] + Groupbox.Size[1] - 5,
                        Groupbox.Root[2] + 40 + Groupbox.ToolSpacing
                    }
                    Picker.AddonY = Groupbox.ToolSpacing

                    -- Expand groupbox height for picker
                    Groupbox.Size[2] = Groupbox.Size[2] + 25
                    Groupbox.ToolSpacing = Groupbox.ToolSpacing + 25

                    -- Click detection for swatch
                    if Lib.MouseInArea({Picker.Boundary[1], Picker.Boundary[2], Picker.Boundary[3], Picker.Boundary[4]}, Win.DeadZone)
                        and not Win.Dragging then
                        if dx9.isLeftClickHeld() then
                            Picker.Holding = true
                        else
                            if Picker.Holding == true then
                                if Win.OpenTool == Picker then Picker:Hide() else Picker:Show() end
                                Picker.Holding = false
                            end
                        end
                        Picker.Hovering = true
                    else
                        Picker.Hovering = false
                        Picker.Holding = false
                    end

                    -- Popup Panel
                    Picker.Render = function()
                        if Win.CurrentTab ~= nil and Win.CurrentTab == TabName and Win.Active and Groupbox.Visible then
                            -- Define panel deadzone
                            Win.DeadZone = {Groupbox.Root[1] + 6, Groupbox.Root[2] + 42 + Picker.AddonY,
                                            Groupbox.Root[1] + 223, Groupbox.Root[2] + 125 + Picker.AddonY}

                            -- Panel Base
                            dx9.DrawFilledBox({Groupbox.Root[1] + 6, Groupbox.Root[2] + 42 + Picker.AddonY},
                                              {Groupbox.Root[1] + 223, Groupbox.Root[2] + 125 + Picker.AddonY}, Lib.Black)
                            dx9.DrawFilledBox({Groupbox.Root[1] + 7, Groupbox.Root[2] + 43 + Picker.AddonY},
                                              {Groupbox.Root[1] + 222, Groupbox.Root[2] + 124 + Picker.AddonY}, Win.OutlineColor)
                            dx9.DrawFilledBox({Groupbox.Root[1] + 8, Groupbox.Root[2] + 44 + Picker.AddonY},
                                              {Groupbox.Root[1] + 221, Groupbox.Root[2] + 123 + Picker.AddonY}, Win.BackgroundColor)
                            dx9.DrawFilledBox({Groupbox.Root[1] + 8, Groupbox.Root[2] + 44 + Picker.AddonY},
                                              {Groupbox.Root[1] + 221, Groupbox.Root[2] + 46 + Picker.AddonY}, Win.AccentColor)

                            -- Rainbow Bar
                            local FirstBarHue, CurrentRainbowColor = 0, nil
                            for i = 1, 205 do
                                if FirstBarHue > 1530 then FirstBarHue = 0 end
                                if FirstBarHue <= 255 then
                                    CurrentRainbowColor = {255, FirstBarHue, 0}
                                elseif FirstBarHue <= 510 then
                                    CurrentRainbowColor = {510 - FirstBarHue, 255, 0}
                                elseif FirstBarHue <= 765 then
                                    CurrentRainbowColor = {0, 255, FirstBarHue - 510}
                                elseif FirstBarHue <= 1020 then
                                    CurrentRainbowColor = {0, 1020 - FirstBarHue, 255}
                                elseif FirstBarHue <= 1275 then
                                    CurrentRainbowColor = {FirstBarHue - 1020, 0, 255}
                                elseif FirstBarHue <= 1530 then
                                    CurrentRainbowColor = {255, 0, 1530 - FirstBarHue}
                                end
                                FirstBarHue = FirstBarHue + 7.5

                                dx9.DrawBox(
                                    {Groupbox.Root[1] + 12 + i, Groupbox.Root[2] + 51 + Picker.AddonY},
                                    {Groupbox.Root[1] + 12 + i, Groupbox.Root[2] + 69 + Picker.AddonY},
                                    CurrentRainbowColor
                                )

                                -- Mouse Interaction
                                if Lib.MouseInArea({Groupbox.Root[1] + 12, Groupbox.Root[2] + 51 + Picker.AddonY,
                                                    Groupbox.Root[1] + 217, Groupbox.Root[2] + 69 + Picker.AddonY}) then
                                    Picker.SecondBarHovering = true
                                    if dx9.isLeftClickHeld()
                                        and Lib.MouseInArea({Groupbox.Root[1] + 12 + i, Groupbox.Root[2] + 51 + Picker.AddonY,
                                                             Groupbox.Root[1] + 15 + i, Groupbox.Root[2] + 69 + Picker.AddonY})
                                        and not Win.Dragging then
                                        if i < 5 then
                                            Picker.StoredIndex2 = 1
                                        elseif i > 200 then
                                            Picker.StoredIndex2 = 205
                                        else
                                            Picker.StoredIndex2 = i
                                        end
                                    end
                                else
                                    Picker.SecondBarHovering = false
                                end

                                if Picker.StoredIndex2 == i then Picker.TopColor = CurrentRainbowColor end
                            end

                            -- Brightness / Saturation Bar
                            local SecondBarHue = 0
                            for i = 1, 205 do
                                local Color = {0, 0, 0}

                                if SecondBarHue > 765 then SecondBarHue = 0 end

                                if SecondBarHue < 255 then
                                    Color = {
                                        Picker.TopColor[1] * (SecondBarHue / 255),
                                        Picker.TopColor[2] * (SecondBarHue / 255),
                                        Picker.TopColor[3] * (SecondBarHue / 255)
                                    }
                                elseif SecondBarHue < 510 then
                                    Color = {
                                        Picker.TopColor[1] + (SecondBarHue - 255),
                                        Picker.TopColor[2] + (SecondBarHue - 255),
                                        Picker.TopColor[3] + (SecondBarHue - 255)
                                    }
                                else
                                    Color = {
                                        (255 - (SecondBarHue - 510)),
                                        (255 - (SecondBarHue - 510)),
                                        (255 - (SecondBarHue - 510))
                                    }
                                end

                                SecondBarHue = SecondBarHue + 3.75
                                if Color[1] > 255 then Color[1] = 255 end
                                if Color[2] > 255 then Color[2] = 255 end
                                if Color[3] > 255 then Color[3] = 255 end

                                -- Hover detection on brightness bar
                                if Lib.MouseInArea({Groupbox.Root[1] + 12, Groupbox.Root[2] + 51 + 25 + Picker.AddonY,
                                                    Groupbox.Root[1] + 217, Groupbox.Root[2] + 69 + 25 + Picker.AddonY}) then
                                    Picker.FirstBarHovering = true
                                    if dx9.isLeftClickHeld()
                                        and Lib.MouseInArea({Groupbox.Root[1] + 12 + i, Groupbox.Root[2] + 51 + 25 + Picker.AddonY,
                                                             Groupbox.Root[1] + 15 + i, Groupbox.Root[2] + 69 + 25 + Picker.AddonY})
                                        and not Win.Dragging then

                                        -- Clamp indices to "snap" points
                                        if i < 5 then
                                            Picker.StoredIndex = 1
                                        elseif i >= 66 and i <= 72 then
                                            Picker.StoredIndex = 69
                                        elseif i >= 134 and i <= 140 then
                                            Picker.StoredIndex = 137
                                        elseif i > 200 then
                                            Picker.StoredIndex = 205
                                        else
                                            Picker.StoredIndex = i
                                        end
                                    end
                                else
                                    Picker.FirstBarHovering = false
                                end

                                -- If selection changed, update Value
                                if Picker.StoredIndex == i then
                                    if Color ~= Picker.Value then
                                        Picker.Value = Color
                                        Picker.Changed = true
                                    end
                                end

                                dx9.DrawBox(
                                    {Groupbox.Root[1] + 12 + i, Groupbox.Root[2] + 51 + 25 + Picker.AddonY},
                                    {Groupbox.Root[1] + 12 + i, Groupbox.Root[2] + 69 + 25 + Picker.AddonY},
                                    Color
                                )
                            end

                            -- Selection markers
                            dx9.DrawFilledBox(
                                {Groupbox.Root[1] + 12 + Picker.StoredIndex2, Groupbox.Root[2] + 50 + Picker.AddonY},
                                {Groupbox.Root[1] + 15 + Picker.StoredIndex2, Groupbox.Root[2] + 70 + Picker.AddonY},
                                Win.OutlineColor
                            )
                            dx9.DrawBox(
                                {Groupbox.Root[1] + 12 + Picker.StoredIndex2, Groupbox.Root[2] + 49 + Picker.AddonY},
                                {Groupbox.Root[1] + 15 + Picker.StoredIndex2, Groupbox.Root[2] + 71 + Picker.AddonY},
                                Lib.Black
                            )

                            dx9.DrawFilledBox(
                                {Groupbox.Root[1] + 12 + Picker.StoredIndex, Groupbox.Root[2] + 75 + Picker.AddonY},
                                {Groupbox.Root[1] + 15 + Picker.StoredIndex, Groupbox.Root[2] + 95 + Picker.AddonY},
                                Win.OutlineColor
                            )
                            dx9.DrawBox(
                                {Groupbox.Root[1] + 12 + Picker.StoredIndex, Groupbox.Root[2] + 74 + Picker.AddonY},
                                {Groupbox.Root[1] + 15 + Picker.StoredIndex, Groupbox.Root[2] + 96 + Picker.AddonY},
                                Lib.Black
                            )
                        end
                    end
                end
            end
        end

        -- OnChanged hook
        function Picker:OnChanged(func)
            if Picker.Changed then
                Picker.Changed = false
                func(Picker.Value)
            end
            return Picker
        end

        Lib:WinCheck(Win)
        return Picker
    end

    function Groupbox:AddSlider(params)
        local Slider = {}
        local Text = params.Text or params.Name or params.Index
        local Index = params.Index or Text

        -- Error Handling
        assert(type(Text) == "string" or type(Text) == "number",
            "[ERROR] AddSlider: Name / Text Variable must be a number or string!")
        assert(type(params.Min) == "number" and type(params.Max) == "number",
            "[ERROR] AddSlider: Min and Max must be numbers!")

        -- Init Defaults
        if Groupbox.Tools[Index] == nil then
            Groupbox.Tools[Index] = {
                Boundary = {0, 0, 0, 0},
                Value = params.Default or params.Min or 0,
                Min = params.Min or 0,
                Max = params.Max or 100,
                Holding = false,
                Hovering = false,
                AddonY = nil,
                Changed = true,
                Rounding = params.Rounding or 0,
                Suffix = params.Suffix or "",
            }
        end

        -- Re-Defs
        Groupbox.Tools[Index].Text = Text
        Slider = Groupbox.Tools[Index]

        -- Setter
        function Slider:SetValue(value)
            if type(value) == "number" then
                Slider.Value = math.max(Slider.Min, math.min(Slider.Max, value))
                Slider.Changed = true
            end
        end

        -- Show/Hide (not applicable for sliders, but included for consistency)
        function Slider:Show() end
        function Slider:Hide() end

        -- Tooltip
        function Slider:AddTooltip(str)
            if Win.CurrentTab ~= nil and Win.CurrentTab == TabName and Win.Active and Groupbox.Visible then
                local n, Tooltip = 0, ""
                if string.gmatch(str, "([^\n]+)") ~= nil then
                    for i in string.gmatch(str, "([^\n]+)") do
                        Tooltip = Tooltip .. i .. "\n"
                        n = n + 1
                    end
                else
                    Tooltip = str
                    n = 1
                end

                if Slider.Hovering then
                    dx9.DrawFilledBox({Mouse.x - 1, Mouse.y + 1},
                        {Mouse.x + dx9.CalcTextWidth(Tooltip) + 5, Mouse.y - (18 * n) - 1},
                        Win.AccentColor)
                    dx9.DrawFilledBox({Mouse.x, Mouse.y},
                        {Mouse.x + dx9.CalcTextWidth(Tooltip) + 4, Mouse.y - (18 * n)},
                        Win.OutlineColor)
                    dx9.DrawString({Mouse.x + 2, Mouse.y - (18 * n)}, Win.FontColor, str)
                end
            end
            return Slider
        end

        -- Draw Slider inside Groupbox
        if Win.CurrentTab ~= nil and Win.CurrentTab == TabName and Win.Active and Groupbox.Visible then
            -- Trim Text if needed
            local TrimmedText = Text
            if dx9.CalcTextWidth(TrimmedText) >= Groupbox.Size[1] - 50 then
                repeat
                    TrimmedText = TrimmedText:sub(1, -2)
                until dx9.CalcTextWidth(TrimmedText) <= Groupbox.Size[1] - 50
            end

            -- Calculate slider position and size
            local sliderWidth = Groupbox.Size[1] - 30
            local sliderX = Groupbox.Root[1] + 10
            local sliderY = Groupbox.Root[2] + 20 + Groupbox.ToolSpacing
            local valuePercent = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            local handleX = sliderX + (sliderWidth * valuePercent)

            -- Draw slider background
            dx9.DrawFilledBox({sliderX, sliderY}, {sliderX + sliderWidth, sliderY + 5}, Win.OutlineColor)
            dx9.DrawFilledBox({sliderX + 1, sliderY + 1}, {sliderX + sliderWidth - 1, sliderY + 4}, Win.BackgroundColor)

            -- Draw slider fill
            dx9.DrawFilledBox({sliderX + 1, sliderY + 1}, {sliderX + math.max(1, math.floor(sliderWidth * valuePercent)) - 1, sliderY + 4}, Win.AccentColor)

            -- Draw slider handle
            if Slider.Hovering or Slider.Holding then
                dx9.DrawFilledBox({handleX - 3, sliderY - 2}, {handleX + 3, sliderY + 7}, Win.AccentColor)
            else
                dx9.DrawFilledBox({handleX - 2, sliderY - 1}, {handleX + 2, sliderY + 6}, Win.AccentColor)
            end

            -- Draw text and value
            local displayValue = Slider.Rounding > 0 and string.format("%." .. Slider.Rounding .. "f", Slider.Value) or tostring(Slider.Value)
            local fullText = TrimmedText .. ": " .. displayValue .. Slider.Suffix
            dx9.DrawString({sliderX, sliderY - 15}, Win.FontColor, fullText)

            -- Boundaries
            Slider.Boundary = {sliderX, sliderY - 15, sliderX + sliderWidth, sliderY + 7}

            -- Expand groupbox height
            Groupbox.Size[2] = Groupbox.Size[2] + 25
            Groupbox.ToolSpacing = Groupbox.ToolSpacing + 25

            -- Click detection for slider
            if Lib.MouseInArea(Slider.Boundary, Win.DeadZone) and not Win.Dragging then
                if dx9.isLeftClickHeld() then
                    Slider.Holding = true
                    local newValue = Slider.Min + ((dx9.GetMouse().x - sliderX) / sliderWidth) * (Slider.Max - Slider.Min)
                    Slider:SetValue(newValue)
                else
                    if Slider.Holding then
                        Slider.Holding = false
                    end
                end
                Slider.Hovering = true
            else
                Slider.Hovering = false
                if not dx9.isLeftClickHeld() then
                    Slider.Holding = false
                end
            end
        end

        -- OnChanged hook
        function Slider:OnChanged(func)
            if Slider.Changed then
                Slider.Changed = false
                func(Slider.Value)
            end
            return Slider
        end

        Lib:WinCheck(Win)
        return Slider
    end

    function Groupbox:AddToggle(params)
        local Toggle = {}
        local Text = params.Text or params.Name or params.Index
        local Index = params.Index or Text

        -- Error Handling
        assert(type(Text) == "string" or type(Text) == "number",
            "[ERROR] AddToggle: Name / Text Variable must be a number or string!")

        -- Init Defaults
        if Groupbox.Tools[Index] == nil then
            Groupbox.Tools[Index] = {
                Boundary = {0, 0, 0, 0},
                Value = params.Default or false,
                Holding = false,
                Hovering = false,
                Changed = true,
            }
        end

        -- Re-Defs
        Groupbox.Tools[Index].Text = Text
        Toggle = Groupbox.Tools[Index]

        -- Setter
        function Toggle:SetValue(value)
            if type(value) == "boolean" then
                Toggle.Value = value
                Toggle.Changed = true
            end
        end

        -- Show/Hide (not applicable for toggles, but included for consistency)
        function Toggle:Show() end
        function Toggle:Hide() end

        -- Tooltip
        function Toggle:AddTooltip(str)
            if Win.CurrentTab ~= nil and Win.CurrentTab == TabName and Win.Active and Groupbox.Visible then
                local n, Tooltip = 0, ""
                if string.gmatch(str, "([^\n]+)") ~= nil then
                    for i in string.gmatch(str, "([^\n]+)") do
                        Tooltip = Tooltip .. i .. "\n"
                        n = n + 1
                    end
                else
                    Tooltip = str
                    n = 1
                end

                if Toggle.Hovering then
                    dx9.DrawFilledBox({Mouse.x - 1, Mouse.y + 1},
                        {Mouse.x + dx9.CalcTextWidth(Tooltip) + 5, Mouse.y - (18 * n) - 1},
                        Win.AccentColor)
                    dx9.DrawFilledBox({Mouse.x, Mouse.y},
                        {Mouse.x + dx9.CalcTextWidth(Tooltip) + 4, Mouse.y - (18 * n)},
                        Win.OutlineColor)
                    dx9.DrawString({Mouse.x + 2, Mouse.y - (18 * n)}, Win.FontColor, str)
                end
            end
            return Toggle
        end

        -- Draw Toggle inside Groupbox
        if Win.CurrentTab ~= nil and Win.CurrentTab == TabName and Win.Active and Groupbox.Visible then
            -- Trim Text if needed
            local TrimmedText = Text
            if dx9.CalcTextWidth(TrimmedText) >= Groupbox.Size[1] - 30 then
                repeat
                    TrimmedText = TrimmedText:sub(1, -2)
                until dx9.CalcTextWidth(TrimmedText) <= Groupbox.Size[1] - 30
            end

            -- Calculate toggle position
            local toggleX = Groupbox.Root[1] + 5
            local toggleY = Groupbox.Root[2] + 20 + Groupbox.ToolSpacing
            local toggleSize = 15

            -- Draw toggle background
            dx9.DrawFilledBox({toggleX, toggleY}, {toggleX + toggleSize, toggleY + toggleSize}, Win.OutlineColor)
            dx9.DrawFilledBox({toggleX + 1, toggleY + 1}, {toggleX + toggleSize - 1, toggleY + toggleSize - 1}, Win.BackgroundColor)

            -- Draw toggle state
            if Toggle.Value then
                dx9.DrawFilledBox({toggleX + 2, toggleY + 2}, {toggleX + toggleSize - 2, toggleY + toggleSize - 2}, Win.AccentColor)
            end

            -- Draw text
            dx9.DrawString({toggleX + toggleSize + 5, toggleY + 2}, Win.FontColor, TrimmedText)

            -- Boundaries
            Toggle.Boundary = {toggleX, toggleY, toggleX + toggleSize, toggleY + toggleSize}

            -- Expand groupbox height
            Groupbox.Size[2] = Groupbox.Size[2] + 25
            Groupbox.ToolSpacing = Groupbox.ToolSpacing + 25

            -- Click detection for toggle
            if Lib.MouseInArea(Toggle.Boundary, Win.DeadZone) and not Win.Dragging then
                if dx9.isLeftClickHeld() then
                    Toggle.Holding = true
                else
                    if Toggle.Holding then
                        Toggle:SetValue(not Toggle.Value)

                        Toggle.Holding = false
                    end
                end
                Toggle.Hovering = true
            else
                Toggle.Hovering = false
                if not dx9.isLeftClickHeld() then
                    Toggle.Holding = false
                end
            end
        end

        -- OnChanged hook
        function Toggle:OnChanged(func)
            if Toggle.Changed then
                Toggle.Changed = false
                func(Toggle.Value)
            end
            return Toggle
        end

        Lib:WinCheck(Win)
        return Toggle
    end

    function Groupbox:AddKeybindButton(params)
        local Keybind = {}
        local Text = params.Text or params.Name or params.SideText
        local Index = params.Index or Text
        local SideText = params.SideText or params.Text or params.Name

        -- Error Handling
        assert(type(Text) == "string" or type(Text) == "number",
            "[ERROR] AddKeybindButton: Text / Name / SideText must be a string or number!")

        -- Init Defaults
        if Groupbox.Tools[Index] == nil then
            Groupbox.Tools[Index] = {
                Boundary = {0, 0, 0, 0},
                Key = params.Default or "[None]",
                Holding = false,
                Hovering = false,
                Reading = false,
                Changed = true,
            }
        end

        -- Re-Defs
        Groupbox.Tools[Index].Text = Text
        Groupbox.Tools[Index].SideText = SideText
        Keybind = Groupbox.Tools[Index]

        -- Setter
        function Keybind:SetValue(value)
            if type(value) == "string" then
                Keybind.Key = value
                Keybind.Changed = true
            end
        end

        -- Show/Hide (not applicable for keybind buttons, but included for consistency)
        function Keybind:Show() end
        function Keybind:Hide() end

        -- Tooltip
        function Keybind:AddTooltip(str)
            if Win.CurrentTab ~= nil and Win.CurrentTab == TabName and Win.Active and Groupbox.Visible then
                local n, Tooltip = 0, ""
                if string.gmatch(str, "([^\n]+)") ~= nil then
                    for i in string.gmatch(str, "([^\n]+)") do
                        Tooltip = Tooltip .. i .. "\n"
                        n = n + 1
                    end
                else
                    Tooltip = str
                    n = 1
                end

                if Keybind.Hovering then
                    dx9.DrawFilledBox({Mouse.x - 1, Mouse.y + 1},
                        {Mouse.x + dx9.CalcTextWidth(Tooltip) + 5, Mouse.y - (18 * n) - 1},
                        Win.AccentColor)
                    dx9.DrawFilledBox({Mouse.x, Mouse.y},
                        {Mouse.x + dx9.CalcTextWidth(Tooltip) + 4, Mouse.y - (18 * n)},
                        Win.OutlineColor)
                    dx9.DrawString({Mouse.x + 2, Mouse.y - (18 * n)}, Win.FontColor, str)
                end
            end
            return Keybind
        end

        -- Draw Keybind Button inside Groupbox
        if Win.CurrentTab ~= nil and Win.CurrentTab == TabName and Win.Active and Groupbox.Visible then
            -- Trim Text if needed
            local TrimmedText = SideText
            if dx9.CalcTextWidth(TrimmedText) >= Groupbox.Size[1] - 50 then
                repeat
                    TrimmedText = TrimmedText:sub(1, -2)
                until dx9.CalcTextWidth(TrimmedText) <= Groupbox.Size[1] - 50
            end

            -- Calculate keybind button position
            local keybindX = Groupbox.Root[1] + 5
            local keybindY = Groupbox.Root[2] + 20 + Groupbox.ToolSpacing
            local keybindWidth = dx9.CalcTextWidth(TrimmedText .. ": [ ]") + 10

            -- Draw keybind background
            dx9.DrawFilledBox({keybindX, keybindY}, {keybindX + keybindWidth, keybindY + 20}, Win.OutlineColor)
            dx9.DrawFilledBox({keybindX + 1, keybindY + 1}, {keybindX + keybindWidth - 1, keybindY + 19}, Win.BackgroundColor)

            -- Draw text and key
            local displayKey = Keybind.Reading and "[...]" or Keybind.Key
            dx9.DrawString({keybindX + 5, keybindY + 3}, Win.FontColor, TrimmedText .. ": [" .. displayKey .. "]")

            -- Boundaries
            Keybind.Boundary = {keybindX, keybindY, keybindX + keybindWidth, keybindY + 20}

            -- Expand groupbox height
            Groupbox.Size[2] = Groupbox.Size[2] + 25
            Groupbox.ToolSpacing = Groupbox.ToolSpacing + 25

            -- Click detection for keybind
            if Lib.MouseInArea(Keybind.Boundary, Win.DeadZone) and not Win.Dragging then
                if dx9.isLeftClickHeld() then
                    Keybind.Holding = true
                else
                    if Keybind.Holding and not Keybind.Reading then
                        Keybind.Reading = true
                        Keybind.Holding = false
                    end
                end
                Keybind.Hovering = true
            else
                if dx9.isLeftClickHeld() and Keybind.Reading then
                    Keybind.Reading = false
                end
                Keybind.Hovering = false
                Keybind.Holding = false
            end

            -- Key reading logic
            if Keybind.Reading and Lib.Key and Lib.Key ~= "[None]" and Lib.Key ~= "[Unknown]" and Lib.Key ~= "[LBUTTON]" then
                Keybind:SetValue(Lib.Key)
                Keybind.Reading = false
            end
        end

        -- OnChanged hook
        function Keybind:OnChanged(func)
            if Keybind.Changed then
                Keybind.Changed = false
                func(Keybind.Key)
            end
            return Keybind
        end

        Lib:WinCheck(Win)
        return Keybind
    end

    Lib:WinCheck(Win)
    return Win
end

--// Notification System
function Lib:Notify(text, length, color)
    if length == nil then length = 3 end
    if color == nil then color = Lib.FontColor end

    local notif = {
        Text = text,
        Start = os.clock(),
        Length = length,
        Color = color
    }

    table.insert(Lib.Notifications, notif)
end

for i,v in pairs(Lib.Notifications) do
    if v.Start < os.clock() - v.Length then
        table.remove(Lib.Notifications, i)
    elseif v ~= nil then
        --// Notification Root
        local root = {0, 200 + (22 * (i-1))}

        --// Text Length
        local length = dx9.CalcTextWidth(v.Text)

        --// Draw Notification
        dx9.DrawFilledBox({root[1] + 4, root[2] + 19}, {root[1] + 4 + length + 12, root[2] + 22 + 18}, Lib.Black)
        dx9.DrawFilledBox({root[1] + 5, root[2] + 20}, {root[1] + 3 + length + 12, root[2] + 21 + 18}, Lib.OutlineColor)
        dx9.DrawFilledBox({root[1] + 6, root[2] + 21}, {root[1] + 2 + length + 12, root[2] + 20 + 18}, Lib.MainColor)
        dx9.DrawFilledBox({root[1] + 6, root[2] + 21}, {root[1] + 8, root[2] + 20 + ((os.clock() - v.Start) * (18 / v.Length))}, Lib.CurrentRainbowColor)

        dx9.DrawString({root[1] + 11, root[2] + 20}, v.Color, v.Text)
    end
end

--// Rainbow Tick
do
    if Lib.RainbowHue > 1530 then
        Lib.RainbowHue = 0
    else
        Lib.RainbowHue = Lib.RainbowHue + 3
    end

    if Lib.RainbowHue <= 255 then
        Lib.CurrentRainbowColor = {255, Lib.RainbowHue, 0}
    elseif Lib.RainbowHue <= 510 then
        Lib.CurrentRainbowColor = {510 - Lib.RainbowHue, 255, 0}
    elseif Lib.RainbowHue <= 765 then
        Lib.CurrentRainbowColor = {0, 255, Lib.RainbowHue - 510}
    elseif Lib.RainbowHue <= 1020 then
        Lib.CurrentRainbowColor = {0, 1020 - Lib.RainbowHue, 255}
    elseif Lib.RainbowHue <= 1275 then
        Lib.CurrentRainbowColor = {Lib.RainbowHue - 1020, 0, 255}
    elseif Lib.RainbowHue <= 1530 then
        Lib.CurrentRainbowColor = {255, 0, 1530 - Lib.RainbowHue}
    end
end

--// Logo Tick (simple loop animation)
if Lib.LogoTick > 80 then
    Lib.LogoTick = 0
else
    Lib.LogoTick = Lib.LogoTick + 1
end

--// End Statements
_G.EMO = Lib
return Lib            
