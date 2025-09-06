-- EMO_UI Library for DX9WARE
-- Author: Built from scratch for reliability by EMO, adapted from DXLib
-- Unique layout with collapsible categories, inspired by "SKECH"

local EMO_UI = {}
local activeWindow = nil

function EMO_UI.newWindow(title, x, y, width, height, toggleKey)
    local window = {
        title = title, location = {x, y}, size = {width, height}, toggleKey = toggleKey or "[F2]",
        visible = false, categories = {}, activeCategory = nil, theme = {
            background = {30, 40, 60},  -- Dark slate blue
            font = {0, 255, 100},       -- Neon green
            accent = {0, 255, 100},     -- Neon green
            outline = {200, 200, 200},  -- Metallic silver
            button = {200, 140, 0, 0.8} -- Deep amber
        },
        dragging = false, winMouseOffset = nil, navWidth = 250
    }
    function window:toggle()
        self.visible = not self.visible
        print("EMO Window " .. self.title .. " toggled: ", self.visible, " at ", os.date("%I:%M %p PDT"))
    end
    function window:draw()
        print("EMO Starting window draw at ", os.date("%I:%M %p PDT"))
        if not self.visible then 
            print("EMO Window not visible, skipping draw at ", os.date("%I:%M %p PDT"))
            return 
        end
        local loc = self.location
        local size = self.size
        -- Draw window frame
        dx9.DrawFilledBox({loc[1] - 1, loc[2] - 1}, {loc[1] + size[1] + 1, loc[2] + size[2] + 1}, {0, 0, 0})
        dx9.DrawFilledBox(loc, {loc[1] + size[1], loc[2] + size[2]}, self.theme.background)
        dx9.DrawFilledBox({loc[1] + 1, loc[2] + 1}, {loc[1] + size[1] - 1, loc[2] + size[2] - 1}, self.theme.outline)
        -- Draw header
        dx9.DrawFilledBox({loc[1], loc[2]}, {loc[1] + size[1], loc[2] + 30}, self.theme.accent)
        dx9.DrawString({loc[1] + 10, loc[2] + 5}, self.theme.font, "EMO - " .. self.title)
        -- Draw navigation panel
        dx9.DrawFilledBox({loc[1], loc[2] + 30}, {loc[1] + self.navWidth, loc[2] + size[2]}, self.theme.accent)
        local yOffset = loc[2] + 40
        for _, category in ipairs(self.categories) do
            local isHovered = dx9.MouseInArea({loc[1], yOffset - 5, loc[1] + self.navWidth, yOffset + 15})
            local bgColor = isHovered and {0, 200, 80, 0.5} or self.theme.button
            dx9.DrawFilledBox({loc[1], yOffset - 5}, {loc[1] + self.navWidth, yOffset + 15}, bgColor)
            dx9.DrawString({loc[1] + 10, yOffset}, self.theme.font, category.name)
            if isHovered and dx9.isLeftClickHeld() then
                category.collapsed = not category.collapsed
                self.activeCategory = category.collapsed and nil or category
                print("EMO Category " .. category.name .. " " .. (category.collapsed and "collapsed" or "expanded") .. " at ", os.date("%I:%M %p PDT"))
            end
            yOffset = yOffset + 20
        end
        -- Draw content area
        if self.activeCategory and not self.activeCategory.collapsed then
            local contentX = loc[1] + self.navWidth + 10
            local contentWidth = size[1] - self.navWidth - 10
            dx9.DrawFilledBox({contentX - 5, loc[2] + 30 - 5}, {contentX + contentWidth + 5, loc[2] + size[2] - 5}, self.theme.outline)
            dx9.DrawFilledBox({contentX, loc[2] + 30}, {contentX + contentWidth, loc[2] + size[2]}, self.theme.background)
            self.activeCategory:draw(contentX, loc[2] + 30)
        end
        -- Toggle with GetKey
        if dx9.GetKey() and dx9.GetKey().F2 and not self.toggleKeyHolding then
            self:toggle()
            self.toggleKeyHolding = true
        elseif not dx9.GetKey() or not dx9.GetKey().F2 then
            self.toggleKeyHolding = false
        end
        -- Dragging
        if dx9.isLeftClickHeld() and not self.dragging and dx9.MouseInArea({loc[1] - 2, loc[2] - 2, loc[1] + size[1] + 2, loc[2] + 22}) then
            self.dragging = true
            if not self.winMouseOffset then
                self.winMouseOffset = {dx9.GetMouse().x - loc[1], dx9.GetMouse().y - loc[2]}
            end
            self.location = {dx9.GetMouse().x - self.winMouseOffset[1], dx9.GetMouse().y - self.winMouseOffset[2]}
        elseif not dx9.isLeftClickHeld() then
            self.dragging = false
            self.winMouseOffset = nil
        end
        print("EMO Draw completed at ", os.date("%I:%M %p PDT"))
    end
    function window:addCategory(name, toggleKey)
        local category = {name = name, controls = {}, collapsed = false, toggleKey = toggleKey or "[F2]"}
        function category:draw(x, y)
            local yPos = y + 10
            for _, control in ipairs(self.controls) do
                control.x, control.y = x + 10, yPos
                control:draw()
                yPos = yPos + 30
            end
        end
        function category:addToggle(text, default)
            local toggle = {
                text = text, state = default, x = 0, y = 0, width = 400, height = 20
            }
            function toggle:draw()
                local success = pcall(function()
                    dx9.DrawFilledBox({self.x, self.y}, {self.x + self.width, self.y + self.height}, {0, 0, 0})
                    dx9.DrawFilledBox({self.x + 1, self.y + 1}, {self.x + self.width - 1, self.y + self.height - 1}, self.theme.button)
                    dx9.DrawString({self.x + 5, self.y + 5}, self.theme.font, self.text .. ": " .. tostring(self.state))
                    if dx9.MouseInArea({self.x, self.y, self.x + self.width, self.y + self.height}) and dx9.isLeftClickHeld() then
                        self.state = not self.state
                        print("EMO " .. self.text .. " toggled for " .. Config.game .. ": ", self.state, " at ", os.date("%I:%M %p PDT"))
                    end
                end)
                if not success then print("!! EMO Failed to draw toggle " .. self.text .. " at ", os.date("%I:%M %p PDT")) end
            end
            table.insert(self.controls, toggle)
            return toggle
        end
        function category:addSlider(text, default, min, max)
            local slider = {
                text = text, value = default, min = min, max = max, x = 0, y = 0, width = 400, height = 20
            }
            function slider:draw()
                local success = pcall(function()
                    dx9.DrawFilledBox({self.x, self.y}, {self.x + self.width, self.y + self.height}, {0, 0, 0})
                    dx9.DrawFilledBox({self.x + 1, self.y + 1}, {self.x + self.width - 1, self.y + self.height - 1}, self.theme.button)
                    local barWidth = (self.value - self.min) / (self.max - self.min) * (self.width - 20)
                    dx9.DrawFilledBox({self.x + 5, self.y + 5}, {self.x + 5 + barWidth, self.y + 15}, self.theme.accent)
                    dx9.DrawString({self.x + 5, self.y + 5}, self.theme.font, self.text .. ": " .. self.value)
                    if dx9.MouseInArea({self.x, self.y, self.x + self.width, self.y + self.height}) and dx9.isLeftClickHeld() then
                        local mouseX = dx9.GetMouse().x - self.x - 5
                        self.value = math.floor(math.clamp(mouseX / (self.width - 20) * (self.max - self.min) + self.min, self.min, self.max))
                        print("EMO " .. self.text .. " adjusted for " .. Config.game .. ": ", self.value, " at ", os.date("%I:%M %p PDT"))
                    end
                end)
                if not success then print("!! EMO Failed to draw slider " .. self.text .. " at ", os.date("%I:%M %p PDT")) end
            end
            table.insert(self.controls, slider)
            return slider
        end
        table.insert(window.categories, category)
        if not window.activeCategory then window.activeCategory = category end
        return category
    end
    activeWindow = window
    return window
end

-- Initialize UI
local Interface = EMO_UI.newWindow("EMO - " .. Config.game, 50, 50, 660, 400, "[F2]")
local espCategory = Interface:addCategory("ESP Settings", "[F2]")
espCategory:addToggle("ESP Enabled", Config.esp_enabled)
espCategory:addSlider("Max Distance", Config.max_distance, 0, 5000)
local aimbotCategory = Interface:addCategory("Aimbot Settings", "[F3]")
aimbotCategory:addToggle("Aimbot Enabled", Config.aimbot_enabled)
aimbotCategory:addSlider("Aimbot Smoothness", Config.aimbot_smoothness, 1, 10)
print("EMO UI initialized for " .. Config.game .. " at ", os.date("%I:%M %p PDT"))

-- Main loop
print("EMO Entering debug loop for " .. Config.game .. " at ", os.date("%I:%M %p PDT"))
while true do
    local success, err = pcall(function()
        dx9.ClearConsole()
        if Interface then
            print("EMO Starting draw at ", os.date("%I:%M %p PDT"))
            Interface:draw()
            print("EMO Draw completed at ", os.date("%I:%M %p PDT"))
        end
        dx9.DrawString({150, 150}, {255, 255, 255}, "EMO Debug Test")
        dx9.DrawBox({140, 140}, {160, 160}, {255, 255, 255}) -- Test box
    end)
    if not success then
        print("!! EMO Error in main loop: " .. err .. " at ", os.date("%I:%M %p PDT"))
    end
    dx9.Wait(0.016) -- 60 FPS
end
