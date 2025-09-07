-- ESP Library for DX9Ware (Roblox Executor)
-- Author: Grok 4, inspired by SKECH menu visuals
-- Version: 1.0 (Professional, modular ESP with boxes, tracers, names, distances, healthbars)
-- Usage: Host on GitHub, load via loadstring(dx9.Get("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/ESP_Lib.lua"))()
-- Features: 3D/2D boxes, ground circles, tracers, customizable via params
-- Integration: Use with SKECH UI toggles (e.g., enable/disable, colors)

local esp = {}

-- Helper: Draw 3D Box
local function box_3d(pos1, pos2, box_color)
    assert(type(pos1) == "table" and #pos1 == 3, "[Error] Box3d: First Argument needs to be a table with 3 position values!")
    assert(type(pos2) == "table" and #pos2 == 3, "[Error] Box3d: Second Argument needs to be a table with 3 position values!")
    assert(type(box_color) == "table" and #box_color == 3, "[Error] Box3d: Third Argument needs to be a table with 3 RGB values!")

    local box_matrix = {
        1, 1, 1, -1, 1, 1,
        -1, 1, 1, -1, -1, 1,
        1, 1, 1, 1, -1, 1,
        1, -1, 1, -1, -1, 1,
        1, 1, 1, 1, 1, -1,
        1, 1, -1, -1, 1, -1,
        -1, 1, -1, -1, 1, 1,
        -1, 1, 1, -1, -1, 1,
        1, 1, -1, 1, -1, -1,
        1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, 1,
        -1, -1, 1, 1, -1, 1,
        1, -1, -1, 1, 1, -1,
        1, 1, -1, -1, 1, -1,
        -1, 1, -1, -1, -1, -1,
        -1, -1, -1, 1, -1, -1
    }

    local x = pos1[1] - pos2[1]
    local y = pos1[2] - pos2[2]
    local z = pos1[3] - pos2[3]
    local size = {x, y, z}

    dx9.Box3d(box_matrix, {(pos1[1] + pos2[1]) / 2, (pos1[2] + pos2[2]) / 2, (pos1[3] + pos2[3]) / 2}, {0, 0, 0}, size, box_color)
end

-- Helper: Get Distance to Part
local function get_distance(part)
    local v1 = dx9.get_localplayer().Position
    local v2 = part
    local a = (v1.x - v2.x) * (v1.x - v2.x)
    local b = (v1.y - v2.y) * (v1.y - v2.y)
    local c = (v1.z - v2.z) * (v1.z - v2.z)
    return math.floor(math.sqrt(a + b + c) + 0.5)
end

-- Ground Circle ESP
function esp.ground_circle(params)
    local target = params.target or nil
    local hipheight = params.hipheight or 3
    local nametagheight = params.nametagheight or 0
    local nametag = params.nametag or false
    local custom_nametag = params.custom_nametag or false
    local distance = params.distance or false
    local custom_distance = params.custom_distance or false
    local radius = params.radius or 2.5
    local color = params.color or {255, 255, 255}
    local steps = params.steps or 36
    local tracer = params.tracer or false
    local tracertype = params.tracer_type or 1  -- 1=near-bottom, 2=bottom, 3=top, 4=Mouse
    local position = params.position or (target and dx9.GetPosition(target)) or nil

    if not position then
        print("[Error] GroundCircle: Either params.target or params.position must be provided")
        return
    end

    local groundposition = {x = position.x, y = position.y - hipheight, z = position.z}
    local nametagposition = {x = position.x, y = position.y + nametagheight, z = position.z}

    -- Nametag with Distance
    if nametag and custom_nametag then
        if distance and custom_distance then
            custom_nametag = custom_nametag .. " [" .. tostring(custom_distance) .. " m]"
        end
        local world_to_screen = dx9.WorldToScreen({nametagposition.x, nametagposition.y, nametagposition.z})
        if world_to_screen then
            dx9.DrawString({world_to_screen.x - (dx9.CalcTextWidth(custom_nametag) / 2), world_to_screen.y + 20}, color, custom_nametag)
        end
    end

    -- Tracer
    if tracer then
        local loc
        if tracertype == 1 then
            loc = {dx9.size().width / 2, dx9.size().height / 1.1}
        elseif tracertype == 2 then
            loc = {dx9.size().width / 2, dx9.size().height}
        elseif tracertype == 3 then
            loc = {dx9.size().width / 2, 1}
        else
            loc = {dx9.GetMouse().x, dx9.GetMouse().y}
        end
        local world_to_screen = dx9.WorldToScreen({position.x, position.y, position.z})
        if world_to_screen then
            dx9.DrawLine(loc, {world_to_screen.x, world_to_screen.y}, color)
        end
    end

    -- Draw Circle
    local pi = math.pi
    for i = 0, steps - 1 do
        local angle_1 = (2 * pi * i) / steps
        local angle_2 = (2 * pi * (i + 1)) / steps
        local point_1 = {x = groundposition.x + radius * math.cos(angle_1), y = groundposition.y, z = groundposition.z + radius * math.sin(angle_1)}
        local point_2 = {x = groundposition.x + radius * math.cos(angle_2), y = groundposition.y, z = groundposition.z + radius * math.sin(angle_2)}
        local screen_1 = dx9.WorldToScreen({point_1.x, point_1.y, point_1.z})
        local screen_2 = dx9.WorldToScreen({point_2.x, point_2.y, point_2.z})
        if screen_1 and screen_2 then
            dx9.DrawLine({screen_1.x, screen_1.y}, {screen_2.x, screen_2.y}, color)
        end
    end
end

-- Simple Circle ESP
function esp.circle(params)
    local target = params.target or nil
    local nametag = params.nametag or false
    local radius = params.radius or 5
    local color = params.color or {255, 255, 255}
    local no_circle = params.no_circle or false

    if not target then
        print("[Error] CircleESP: Target can't be nil")
        return false
    end

    local position = dx9.GetPosition(target)
    local world_to_screen = dx9.WorldToScreen({position.x, position.y, position.z})
    if not world_to_screen then return end

    if nametag then
        dx9.DrawString({world_to_screen.x - (dx9.CalcTextWidth(nametag) / 2), world_to_screen.y + 20}, color, nametag)
    end

    if not no_circle then
        dx9.DrawCircle({world_to_screen.x, world_to_screen.y}, color, radius)
    end
end

-- Main Draw ESP Function
function esp.draw(params)
    -- params = {target = model_ptr, color = {r,g,b}, healthbar = false, distance = false, nametag = false, custom_nametag = false, custom_distance = nil, 
    --           custom_root = "HumanoidRootPart", custom_size = nil, tracer = false, tracer_type = 1, box_type = 1}
    local target = params.target or nil
    local box_color = params.color or {255, 255, 255}
    local healthbar = params.healthbar or false
    local distance = params.distance or false
    local nametag = params.nametag or false
    local custom_nametag = params.custom_nametag or false
    local custom_distance = params.custom_distance or nil
    local custom_root = params.custom_root or "HumanoidRootPart"
    local custom_size = params.custom_size or nil
    local tracer = params.tracer or false
    local tracertype = params.tracer_type or 1  -- 1=near-bottom, 2=bottom, 3=top, 4=Mouse
    local box_type = params.box_type or 1  -- 1=corners, 2=2d box, 3=3d box

    -- Error Handling
    assert(type(tracertype) == "number" and tracertype >= 1 and tracertype <= 4, "[Error] DrawESP: tracer_type must be 1-4")
    assert(type(box_type) == "number" and box_type >= 1 and box_type <= 3, "[Error] DrawESP: box_type must be 1-3")
    assert(type(target) == "number" and dx9.GetChildren(target), "[Error] DrawESP: target must be a valid pointer to character")
    assert(type(box_color) == "table" and #box_color == 3, "[Error] DrawESP: color must be RGB table")

    local root = dx9.FindFirstChild(target, custom_root)
    if not root then
        print("[Error] DrawESP: No root part found (" .. custom_root .. ")")
        return
    end

    local position = dx9.GetPosition(root)
    local Top = dx9.WorldToScreen({position.x, position.y + 2.5, position.z})  -- Approximate head
    local Bottom = dx9.WorldToScreen({position.x, position.y - 3.5, position.z})  -- Approximate feet
    if not Top or not Bottom then return end

    local height = math.abs(Top.y - Bottom.y)
    local width = height / 2

    -- Draw Box
    if box_type == 1 then  -- Corners
        dx9.DrawLine({Top.x - width, Top.y}, {Top.x - width / 2, Top.y}, box_color)
        dx9.DrawLine({Top.x - width, Top.y}, {Top.x - width, Top.y + height / 4}, box_color)
        dx9.DrawLine({Top.x + width, Top.y}, {Top.x + width / 2, Top.y}, box_color)
        dx9.DrawLine({Top.x + width, Top.y}, {Top.x + width, Top.y + height / 4}, box_color)
        dx9.DrawLine({Bottom.x - width, Bottom.y}, {Bottom.x - width / 2, Bottom.y}, box_color)
        dx9.DrawLine({Bottom.x - width, Bottom.y}, {Bottom.x - width, Bottom.y - height / 4}, box_color)
        dx9.DrawLine({Bottom.x + width, Bottom.y}, {Bottom.x + width / 2, Bottom.y}, box_color)
        dx9.DrawLine({Bottom.x + width, Bottom.y}, {Bottom.x + width, Bottom.y - height / 4}, box_color)
    elseif box_type == 2 then  -- 2D Box
        dx9.DrawBox({Top.x - width, Top.y}, {Bottom.x + width, Bottom.y}, box_color)
    else  -- 3D Box
        box_3d({position.x - 2, position.y + 2.5, position.z - 2}, {position.x + 2, position.y - 3.5, position.z + 2}, box_color)
    end

    -- Healthbar
    if healthbar then
        local humanoid = dx9.FindFirstChild(target, "Humanoid")
        if humanoid then
            local hp = dx9.GetHealth(humanoid)
            local maxhp = dx9.GetMaxHealth(humanoid)
            local tl = {Top.x - width - 5, Top.y}
            local br = {Top.x - width - 1, Bottom.y}
            local bar_height = height * (hp / maxhp)
            dx9.DrawBox({tl[1] - 1, tl[2] - 1}, {br[1] + 1, br[2] + 1}, box_color)  -- Outer
            dx9.DrawFilledBox({tl[1], tl[2]}, {br[1], br[2]}, {0, 0, 0})  -- Inner black
            dx9.DrawFilledBox({tl[1], Bottom.y - bar_height}, {br[1], Bottom.y}, {0, 255, 0})  -- Green health
        else
            print("[Warning] DrawESP: No Humanoid for healthbar")
        end
    end

    -- Nametag
    if nametag then
        local name = custom_nametag or dx9.GetName(target)
        dx9.DrawString({Top.x - (dx9.CalcTextWidth(name) / 2), Top.y - 20}, box_color, name)
    end

    -- Distance
    if distance then
        local dist = custom_distance or get_distance(position)
        dx9.DrawString({Bottom.x - (dx9.CalcTextWidth(tostring(dist)) / 2), Bottom.y + 10}, box_color, tostring(dist) .. " studs")
    end

    -- Tracer
    if tracer then
        local loc
        if tracertype == 1 then
            loc = {dx9.size().width / 2, dx9.size().height / 1.1}
        elseif tracertype == 2 then
            loc = {dx9.size().width / 2, dx9.size().height}
        elseif tracertype == 3 then
            loc = {dx9.size().width / 2, 0}
        else
            loc = {dx9.GetMouse().x, dx9.GetMouse().y}
        end
        dx9.DrawLine(loc, {Bottom.x, Bottom.y}, box_color)
    end
end

-- Additional Feature: Skeleton ESP (Professional Addition)
function esp.skeleton(params)
    local target = params.target or nil
    local color = params.color or {255, 255, 255}

    if not target then return end

    local parts = {"Head", "HumanoidRootPart", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}  -- Basic skeleton
    local connections = {
        {"Head", "HumanoidRootPart"},
        {"HumanoidRootPart", "LeftArm"},
        {"HumanoidRootPart", "RightArm"},
        {"HumanoidRootPart", "LeftLeg"},
        {"HumanoidRootPart", "RightLeg"}
    }

    for _, conn in ipairs(connections) do
        local part1 = dx9.FindFirstChild(target, conn[1])
        local part2 = dx9.FindFirstChild(target, conn[2])
        if part1 and part2 then
            local pos1 = dx9.GetPosition(part1)
            local pos2 = dx9.GetPosition(part2)
            local screen1 = dx9.WorldToScreen({pos1.x, pos1.y, pos1.z})
            local screen2 = dx9.WorldToScreen({pos2.x, pos2.y, pos2.z})
            if screen1 and screen2 then
                dx9.DrawLine({screen1.x, screen1.y}, {screen2.x, screen2.y}, color)
            end
        end
    end
end

-- Main Loop Example (Call in RenderStepped, integrate with UI)
function esp.enable_for_all(params)
    -- params: global toggles/colors from UI
    local players = dx9.GetPlayers()  -- Assume dx9.GetPlayers() or loop dx9.GetChildren(game.Players)
    for _, player in ipairs(players) do
        if player ~= dx9.get_localplayer() then  -- Skip self
            esp.draw({target = player, color = params.color, box_type = params.box_type, -- etc.
            })
            if params.skeleton then
                esp.skeleton({target = player, color = params.color})
            end
        end
    end
end

return esp
