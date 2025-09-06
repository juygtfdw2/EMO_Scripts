-- EMO_UI Library for DX9WARE
-- Author: Built from scratch for reliability by EMO, inspired by "SKECH" and adapted from Brycki404's DXLibUI
-- Enhanced with drag support, quality improvements, collapsible categories, and improved toggle detection

local EMO_UI = {}
local activeWindow = nil

-- Integrate basic Lib functionality from DXLib
local Lib = {
    MouseInArea = function(area, deadzone)
        assert(type(area) == "table" and #area == 4, "[Error] MouseInArea: First Argument needs to be a table with 4 values!")
        local mouse = dx9.GetMouse()
        if deadzone ~= nil then
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
}

function EMO_UI.newWindow(title, x, y, width, height, toggleKey)
    local window = {
        title = title, location = {x, y}, size = {width, height}, toggleKey = toggleKey or "[F2]",
        visible = true, -- Match Brycki404's default visibility
        categories = {}, activeCategory = nil, theme = {
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
        local mouse = dx9.GetMouse()
        local key = dx9.GetKey()
        local keyName = string.sub(self.toggleKey, 2, -2) -- Extract "F2" from "[F2]"
        
        -- Draw window frame with improved layering
        dx9.DrawFilledBox({loc[1] - 1, loc[2] - 1}, {loc[1] + size[1] + 1, loc[2] + size[2] + 1}, {0, 0, 0}) -- Outer shadow
        dx9.DrawFilledBox(loc, {loc[1] + size[1], loc[2] + size[2]}, self.theme.background) -- Background
        dx9.DrawFilledBox({loc[1] + 1, loc[2] + 1}, {loc[1] + size[1] - 1, loc[2] + size[2] - 1}, self.theme.outline) -- Inner outline
        print("EMO Drew frame at ", os.date("%I:%M %p PDT"), " coords: ", loc[1], loc[2], size[1], size[2])

        -- Draw header with better contrast and drag region
        dx9.DrawFilledBox({loc[1], loc[2]}, {loc[1] + size[1], loc[2] + 30}, self.theme.accent)
        dx9.DrawString({loc[1] + 10, loc[2] + 5}, self.theme.font, "EMO - " .. self.title)
        print("EMO Drew header at ", os.date("%I:%M %p PDT"))

        -- Draw navigation panel with quality enhancement
        local navX = loc[1]
        local navY = loc[2] + 30
        local navEndX = math.min(loc[1] + self.navWidth, loc[1] + size[1]) -- Cap at window width
        dx9.DrawFilledBox({navX, navY}, {navEndX, loc[2] + size[2]}, self.theme.accent)
        local yOffset = navY + 10
        for _, category in ipairs(self.categories) do
            local isHovered = Lib.MouseInArea({navX, yOffset - 5, navEndX, yOffset + 15})
            print("EMO Checking hover for " .. category.name .. " at ", os.date("%I:%M %p PDT"), " area: ", navX, yOffset - 5, navEndX, yOffset + 15, " hovered: ", isHovered)
            local bgColor = isHovered and {0, 200, 80, 0.5} or self.theme.button
            dx9.DrawFilledBox({navX, yOffset - 5}, {navEndX, yOffset + 15}, bgColor)
            dx9.DrawString({navX + 10, yOffset}, self.theme.font, category.name)
            if isHovered and dx9.isLeftClickHeld() then
                category.collapsed = not category.collapsed
                self.activeCategory = category.collapsed and nil or category
                print("EMO Category " .. category.name .. " " .. (category.collapsed and "collapsed" or "expanded") .. " at ", os.date("%I:%M %p PDT"))
            end
            yOffset = yOffset + 25 -- Increased spacing for readability
        end
        print("EMO Drew navigation panel at ", os.date("%I:%M %p PDT"), " coords: ", navX, navY, navEndX, loc[2] + size[2])

        -- Draw content area with improved clarity
        if self.activeCategory and not self.activeCategory.collapsed then
            local contentX = loc[1] + self.navWidth + 10
            local contentWidth = size[1] - self.navWidth - 10
            if contentX + contentWidth > loc[1] + size[1] then contentWidth = size[1] - self.navWidth - 10 end
            dx9.DrawFilledBox({contentX - 2, loc[2] + 30 - 2}, {contentX + contentWidth + 2, loc[2] + size[2] + 2}, self.theme.outline) -- Thicker outline
            dx9.DrawFilledBox({contentX, loc[2] + 30}, {contentX + contentWidth, loc[2] + size[2]}, self.theme.background)
            self.activeCategory:draw(contentX, loc[2] + 30)
            print("EMO Drew content area for " .. self.activeCategory.name .. " at ", os.date("%I:%M %p PDT"), " coords: ", contentX, loc[2] + 30, contentWidth, size[2])
        end

        -- Dragging support (fixed to ensure functionality)
        if dx9.isLeftClickHeld() and not self.dragging and Lib.MouseInArea({loc[1], loc[2], loc[1] + size[1], loc[2] + 30}) then -- Drag only header
            self.dragging = true
            if not self.winMouseOffset then
                self.winMouseOffset = {mouse.x - loc[1], mouse.y - loc[2]}
            end
            self.location = {mouse.x - self.winMouseOffset[1], mouse.y - self.winMouseOffset[2]}
            -- Keep within screen bounds
            if self.location[1] < 0 then self.location[1] = 0 end
            if self.location[2] < 0 then self.location[2] = 0 end
            if self.location[1] + size[1] > dx9.size().width then self.location[1] = dx9.size().width - size[1] end
            if self.location[2] + size[2] > dx9.size().height then self.location[2] = dx9.size().height - size[2] end
            print("EMO Dragging at ", os.date("%I:%M %p PDT"), " new loc: ", self.location[1], self.location[2])
        elseif not dx9.isLeftClickHeld() then
            self.dragging = false
            self.winMouseOffset = nil
        end

        -- Toggle with enhanced GetKey detection (aligned with Brycki404)
        print("EMO Checking toggle key ", keyName, " at ", os.date("%I:%M %p PDT"), " key pressed: ", key and key[keyName], " raw key: ", key)
        if key and key[keyName] and not self.toggleKeyHolding then
            self:toggle()
            self.toggleKeyHolding = true
        elseif not key or not key[keyName] then
            self.toggleKeyHolding = false
        end
        -- Fallback toggle checks
        if key and key.F2 and not self.toggleKeyHolding then
            self:toggle()
            self.toggleKeyHolding = true
        elseif not key or not key.F2 then
            self.toggleKeyHolding = false
        end
        if key and key["0x71"] and not self.toggleKeyHolding then -- VK_F2
            self:toggle()
            self.toggleKeyHolding = true
        elseif not key or not key["0x71"] then
            self.toggleKeyHolding = false
        end
        -- Initial toggle to match Brycki404's behavior
        if not self.initialToggled and drawCount == 0 then -- Assume first frame toggle
            self:toggle()
            self.initialToggled = true
            print("EMO Initial toggle activated at ", os.date("%I:%M %p PDT"))
        end

        print("EMO Draw completed at ", os.date("%I:%M %p PDT"))
    end
    function window:addCategory(name, toggleKey)
        local category = {name = name, controls = {}, collapsed = false, toggleKey = toggleKey or "[F2]"}
        function category:draw(x, y)
            local yPos = y + 10
            for _, control in ipairs(self.controls) do
                control.x, control.y = x + 10, yPos
                local success = pcall(function()
                    control:draw()
                    if control.x + control.width > x + 400 or control.y + control.height > y + 400 then
                        print("!! EMO Control out of bounds at ", os.date("%I:%M %p PDT"), " type: ", control.text, " coords: ", control.x, control.y)
                    end
                end)
                if not success then print("!! EMO Failed to draw control at ", os.date("%I:%M %p PDT"), " type: ", control.text or "unknown", " coords: ", control.x, control.y, " error: ", debug.traceback()) end
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
                    if Lib.MouseInArea({self.x, self.y, self.x + self.width, self.y + self.height}) and dx9.isLeftClickHeld() then
                        self.state = not self.state
                        print("EMO " .. self.text .. " toggled for " .. Config.game .. ": ", self.state, " at ", os.date("%I:%M %p PDT"))
                    end
                end)
                if not success then print("!! EMO Failed to draw toggle " .. self.text .. " at ", os.date("%I:%M %p PDT"), " coords: ", self.x, self.y, " error: ", debug.traceback()) end
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
                    if Lib.MouseInArea({self.x, self.y, self.x + self.width, self.y + self.height}) and dx9.isLeftClickHeld() then
                        local mouseX = dx9.GetMouse().x - self.x - 5
                        self.value = math.floor(math.clamp(mouseX / (self.width - 20) * (self.max - self.min) + self.min, self.min, self.max))
                        print("EMO " .. self.text .. " adjusted for " .. Config.game .. ": ", self.value, " at ", os.date("%I:%M %p PDT"))
                    end
                end)
                if not success then print("!! EMO Failed to draw slider " .. self.text .. " at ", os.date("%I:%M %p PDT"), " coords: ", self.x, self.y, " error: ", debug.traceback()) end
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

return EMO_UI
