-- EMO_UI Library for DX9WARE
-- Author: Built from scratch for reliability by EMO
-- Professional UI with multi-game support and "EMO" branding

local EMO_UI = {}
local activeWindow = nil

-- Window class
function EMO_UI.newWindow(title, x, y, width, height, toggleKey)
    local window = {
        title = title, x = x, y = y, width = width, height = height, toggleKey = toggleKey or "[F2]",
        visible = false, tabs = {}, activeTab = nil, theme = {
            background = {20, 20, 20}, -- Deep charcoal gray
            font = {150, 70, 200},     -- Electric purple
            accent = {150, 70, 200},   -- Electric purple for highlights
            outline = {50, 150, 255},  -- Neon blue
            button = {0, 100, 100, 0.8} -- Muted teal with transparency
        }
    }
    function window:toggle()
        self.visible = not self.visible
        if _G.Config then
            print("EMO Window " .. self.title .. " toggled for " .. _G.Config.game .. ": ", self.visible, " at ", os.date("%I:%M %p PDT"))
        end
    end
    function window:draw()
        if not self.visible then return end
        -- Draw outline and background
        dx9.DrawBox({self.x - 5, self.y - 5}, {self.x + self.width + 5, self.y + self.height + 5}, self.theme.outline)
        dx9.DrawBox({self.x, self.y}, {self.x + self.width, self.y + 20}, self.theme.accent) -- Title bar
        dx9.DrawBox({self.x, self.y + 20}, {self.x + self.width, self.y + self.height}, self.theme.background)
        dx9.DrawString({self.x + 5, self.y + 5}, self.theme.font, self.title)
        if self.activeTab then self.activeTab:draw(self.x + 10, self.y + 30) end
        if dx9.isKeyPressed(self.toggleKey) then self:toggle() wait(0.2) end
    end
    function window:addTab(name)
        local tab = {name = name, groupboxes = {}, yOffset = 0}
        function tab:draw(x, y)
            self.yOffset = y
            for i, groupbox in ipairs(self.groupboxes) do
                groupbox:draw(x + (i == 1 and 0 or 200), self.yOffset) -- Left and right layout
            end
        end
        function tab:addGroupbox(title)
            local groupbox = {
                title = title, x = 0, y = 0, width = 180, height = 200, controls = {},
                theme = {background = {0, 100, 100, 0.8}, font = {150, 70, 200}} -- Muted teal buttons, purple text
            }
            function groupbox:draw(x, y)
                self.x, self.y = x, y
                dx9.DrawBox({self.x, self.y}, {self.x + self.width, self.y + self.height}, self.theme.background)
                dx9.DrawString({self.x + 5, self.y + 5}, self.theme.font, self.title)
                for _, control in pairs(self.controls) do
                    control:draw()
                end
            end
            function groupbox:addToggle(text, default)
                local toggle = {
                    text = text, state = default, x = self.x + 5, y = self.y + 20, width = self.width - 10, height = 20
                }
                function toggle:draw()
                    dx9.DrawBox({self.x, self.y}, {self.x + self.width, self.y + self.height}, {0.3, 0.3, 0.7, 0.8})
                    dx9.DrawString({self.x + 5, self.y + 5}, {150, 70, 200}, self.text .. ": " .. tostring(self.state))
                    if dx9.isMouseInRegion({self.x, self.y}, {self.x + self.width, self.y + self.height}) and dx9.isLeftClick() then
                        self.state = not self.state
                        if _G.Config then
                            print("EMO " .. self.text .. " toggled for " .. _G.Config.game .. ": ", self.state, " at ", os.date("%I:%M %p PDT"))
                        end
                        wait(0.2) -- Debounce
                    end
                end
                table.insert(self.controls, toggle)
                return toggle
            end
            function groupbox:addSlider(text, default, min, max)
                local slider = {
                    text = text, value = default, min = min, max = max, x = self.x + 5, y = self.y + 40, width = self.width - 10, height = 20
                }
                function slider:draw()
                    dx9.DrawBox({self.x, self.y}, {self.x + self.width, self.y + self.height}, {0.3, 0.3, 0.7, 0.8})
                    local barWidth = (self.value - self.min) / (self.max - self.min) * (self.width - 20)
                    dx9.DrawBox({self.x + 5, self.y + 5}, {self.x + 5 + barWidth, self.y + 15}, {0, 100, 100, 0.8})
                    dx9.DrawString({self.x + 5, self.y + 5}, {150, 70, 200}, self.text .. ": " .. self.value)
                    if dx9.isMouseInRegion({self.x, self.y}, {self.x + self.width, self.y + self.height}) and dx9.isLeftClickHeld() then
                        local mouseX = dx9.GetMouse().x - self.x - 5
                        self.value = math.floor(math.clamp(mouseX / (self.width - 20) * (self.max - self.min) + self.min, self.min, self.max))
                        if _G.Config then
                            print("EMO " .. self.text .. " adjusted for " .. _G.Config.game .. ": ", self.value, " at ", os.date("%I:%M %p PDT"))
                        end
                    end
                end
                table.insert(self.controls, slider)
                return slider
            end
            table.insert(self.groupboxes, groupbox)
            return groupbox
        end
        table.insert(window.tabs, tab)
        if not window.activeTab then window.activeTab = tab end
        return tab
    end
    activeWindow = window
    return window
end

return EMO_UI
