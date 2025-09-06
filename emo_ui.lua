-- EMO_UI Library for DX9WARE
-- Author: Built from scratch for reliability by EMO
-- Unique layout inspired by "SKECH" image, branded "EMO"

local EMO_UI = {}
local activeWindow = nil

function EMO_UI.newWindow(title, x, y, width, height, toggleKey)
    local window = {
        title = title, x = x, y = y, width = width, height = height, toggleKey = toggleKey or "[F2]",
        visible = false, categories = {}, activeCategory = nil, theme = {
            background = {30, 40, 60},  -- Dark slate blue
            font = {0, 255, 100},       -- Neon green
            accent = {0, 255, 100},     -- Neon green
            outline = {200, 200, 200},  -- Metallic silver
            button = {200, 140, 0, 0.8} -- Deep amber
        },
        navWidth = 200
    }
    function window:toggle()
        self.visible = not self.visible
        print("EMO Window " .. self.title .. " toggled: ", self.visible, " at ", os.date("%I:%M %p PDT"))
    end
    function window:draw()
        if not self.visible then return end
        -- Draw window frame with header
        dx9.DrawBox({self.x - 5, self.y - 5}, {self.x + self.width + 5, self.y + self.height + 5}, self.theme.outline)
        dx9.DrawBox({self.x, self.y}, {self.x + self.width, self.y + 30}, self.theme.accent) -- Header
        dx9.DrawString({self.x + 10, self.y + 5}, self.theme.font, "EMO - " .. self.title)
        dx9.DrawBox({self.x, self.y + 30}, {self.x + self.width, self.y + self.height}, self.theme.background)
        
        -- Draw navigation panel
        dx9.DrawBox({self.x, self.y + 30}, {self.x + self.navWidth, self.y + self.height}, self.theme.accent)
        local yOffset = self.y + 40
        for _, category in ipairs(self.categories) do
            local isHovered = dx9.isMouseInRegion({self.x, yOffset - 5}, {self.x + self.navWidth, yOffset + 15})
            local bgColor = isHovered and {0, 200, 80, 0.5} or self.theme.button -- Hover effect
            dx9.DrawBox({self.x, yOffset - 5}, {self.x + self.navWidth, yOffset + 15}, bgColor)
            dx9.DrawString({self.x + 10, yOffset}, self.theme.font, category.name)
            if isHovered and dx9.isLeftClick() then
                category.collapsed = not category.collapsed
                self.activeCategory = category.collapsed and nil or category
                print("EMO Category " .. category.name .. " " .. (category.collapsed and "collapsed" or "expanded") .. " at ", os.date("%I:%M %p PDT"))
                wait(0.2)
            end
            yOffset = yOffset + 20
        end
        
        -- Draw content area
        local contentWidth = self.width - self.navWidth - 10
        if self.activeCategory and not self.activeCategory.collapsed then
            local contentX = self.x + self.navWidth + 10
            local contentY = self.y + 30
            dx9.DrawBox({contentX - 5, contentY - 5}, {contentX + contentWidth + 5, self.y + self.height - 5}, self.theme.outline)
            dx9.DrawBox({contentX, contentY}, {contentX + contentWidth, self.y + self.height}, self.theme.background)
            self.activeCategory:draw(contentX, contentY)
        end
        if dx9.isKeyPressed(self.toggleKey) then self:toggle() wait(0.2) end
    end
    function window:addCategory(name)
        local category = {name = name, controls = {}, collapsed = false}
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
                text = text, state = default, x = 0, y = 0, width = 400, height = 20 -- Wider content area
            }
            function toggle:draw()
                dx9.DrawBox({self.x, self.y}, {self.x + self.width, self.y + self.height}, self.theme.button)
                dx9.DrawString({self.x + 5, self.y + 5}, self.theme.font, self.text .. ": " .. tostring(self.state))
                if dx9.isMouseInRegion({self.x, self.y}, {self.x + self.width, self.y + self.height}) and dx9.isLeftClick() then
                    self.state = not self.state
                    print("EMO " .. self.text .. " toggled: ", self.state, " at ", os.date("%I:%M %p PDT"))
                    wait(0.2) -- Debounce
                end
            end
            table.insert(self.controls, toggle)
            return toggle
        end
        function category:addSlider(text, default, min, max)
            local slider = {
                text = text, value = default, min = min, max = max, x = 0, y = 0, width = 400, height = 20
            }
            function slider:draw()
                dx9.DrawBox({self.x, self.y}, {self.x + self.width, self.y + self.height}, self.theme.button)
                local barWidth = (self.value - self.min) / (self.max - self.min) * (self.width - 20)
                dx9.DrawBox({self.x + 5, self.y + 5}, {self.x + 5 + barWidth, self.y + 15}, self.theme.accent)
                dx9.DrawString({self.x + 5, self.y + 5}, self.theme.font, self.text .. ": " .. self.value)
                if dx9.isMouseInRegion({self.x, self.y}, {self.x + self.width, self.y + self.height}) and dx9.isLeftClickHeld() then
                    local mouseX = dx9.GetMouse().x - self.x - 5
                    self.value = math.floor(math.clamp(mouseX / (self.width - 20) * (self.max - self.min) + self.min, self.min, self.max))
                    print("EMO " .. self.text .. " adjusted: ", self.value, " at ", os.date("%I:%M %p PDT"))
                end
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
