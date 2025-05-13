local addonName = "GCast"
local _G = _G
local GCast = _G[addonName] or {}
_G[addonName] = GCast

GCast.SettingsUI = GCast.SettingsUI or {}

function GCast.SettingsUI:CreateControl(parent, frameType, template, size, point, extras)
    if not frameType or frameType == "" or type(frameType) ~= "string" then
        error("Invalid frame type: " .. tostring(frameType))
    end
    if template and type(template) ~= "string" then
        error("Invalid template: " .. tostring(template))
    end
    if parent and type(parent) ~= "table" then
        error("Invalid parent: " .. tostring(parent))
    end
    if extras and type(extras) ~= "function" then
        error("Invalid extras: " .. tostring(extras))
    end
    local frame = CreateFrame(frameType, nil, parent, template)
    if not frame then
        error("Failed to create frame: type=" .. tostring(frameType) .. ", template=" .. tostring(template) .. ", parent=" .. tostring(parent))
    end
    if size then frame:SetSize(unpack(size)) end
    if point then frame:SetPoint(unpack(point)) end
    if extras then extras(frame) end
    return frame
end

function GCast.SettingsUI:InitDottedFrame()
    if GCast.dottedFrame then return end
    GCast.dottedFrame = CreateFrame("Frame", "GCastDottedFrame", UIParent, "BackdropTemplate")
    GCast.dottedFrame:SetSize(GCast.db.global.visual.size or 50, GCast.db.global.visual.size or 50)
    GCast.dottedFrame:SetPoint("CENTER", UIParent, "CENTER", GCast.db.player.visual.startPoint.x or 0, GCast.db.player.visual.startPoint.y or 0)
    GCast.dottedFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    GCast.dottedFrame:Hide()
    GCast.dottedFrame:EnableMouse(true)
    GCast.dottedFrame:SetMovable(true)
    GCast.dottedFrame:RegisterForDrag("LeftButton")
    GCast.dottedFrame:SetScript("OnDragStart", function(frame)
        if GCast.db.player.visual.editMode then
            frame:StartMoving()
            GCast.Utils:Log("Started dragging dotted frame", true)
        end
    end)
    GCast.dottedFrame:SetScript("OnMouseUp", function(frame, button)
        if GCast.db.player.visual.editMode and button == "LeftButton" then
            frame:StopMovingOrSizing()
            local x, y = frame:GetCenter()
            local parentX, parentY = UIParent:GetCenter()
            local newX = x and parentX and tonumber(string.format("%.1f", x - parentX)) or 0
            local newY = y and parentY and tonumber(string.format("%.1f", y - parentY)) or 0
            GCast.SettingsUI:UpdateStartPoint(newX, newY)
            GCast.Utils:Log("Updated coordinates: x=" .. newX .. ", y=" .. newY, true)
        end
    end)
    GCast.dottedFrame:SetScript("OnDragStop", function(frame)
        if GCast.db.player.visual.editMode then
            frame:StopMovingOrSizing()
            local x, y = frame:GetCenter()
            local parentX, parentY = UIParent:GetCenter()
            local newX = x and parentX and tonumber(string.format("%.1f", x - parentX)) or 0
            local newY = y and parentY and tonumber(string.format("%.1f", y - parentY)) or 0
            GCast.SettingsUI:UpdateStartPoint(newX, newY)
            GCast.Utils:Log("Updated coordinates: x=" .. newX .. ", y=" .. newY, true)
        end
    end)
    GCast.dottedFrame:SetScript("OnUpdate", function(frame, elapsed)
        if GCast.db.player.visual.editMode and IsMouseButtonDown("LeftButton") then
            local lastUpdate = frame.lastUpdate or 0
            if GetTime() - lastUpdate > 0.1 then
                local x, y = frame:GetCenter()
                local parentX, parentY = UIParent:GetCenter()
                local newX = x and parentX and tonumber(string.format("%.1f", x - parentX)) or 0
                local newY = y and parentY and tonumber(string.format("%.1f", y - parentY)) or 0
                GCast.SettingsUI:UpdateStartPoint(newX, newY)
                frame.lastUpdate = GetTime()
                GCast.Utils:Log("Real-time coordinate update: x=" .. newX .. ", y=" .. newY, true)
            end
        end
    end)
    GCast.dottedFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" and GCast.db.player.visual.editMode then
            GCast.db.player.visual.editMode = false
            GCast.dottedFrame:Hide()
            local coordPanel = _G["GCastCoordPanel"]
            if coordPanel then
                coordPanel:Hide()
                GCast.Utils:Log("Hid coord panel on ESC", true)
            end
            if _G["GCastSettings"] and _G["GCastSettings"]:IsShown() then
                local editButton = _G["GCastSettings"]:GetChildren()
                if editButton and editButton.SetText then
                    editButton:SetText(GCast.L["Toggle Edit Mode"] or "Toggle Edit Mode")
                end
            end
            GCast.Utils:Log("Exited edit mode via ESC", true)
        end
    end)
    GCast.dottedFrame:EnableKeyboard(true)
end

function GCast.SettingsUI:UpdateStartPoint(x, y)
    GCast.DB:EnsureInitialized()
    if type(x) ~= "number" or type(y) ~= "number" then
        GCast.Utils:Log("Invalid coordinates x=" .. tostring(x) .. ", y=" .. tostring(y))
        return
    end

    GCast.db.player.visual.startPoint = GCast.db.player.visual.startPoint or {}
    GCast.db.player.visual.startPoint.x = x
    GCast.db.player.visual.startPoint.y = y

    if GCast.dottedFrame then
        GCast.dottedFrame:ClearAllPoints()
        GCast.dottedFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    end
    
    local coordPanel = _G["GCastCoordPanel"]
    if coordPanel then
        local xEdit = coordPanel.xEdit
        local yEdit = coordPanel.yEdit
        if xEdit then xEdit:SetText(string.format("%.1f", x)) end
        if yEdit then yEdit:SetText(string.format("%.1f", y)) end
        GCast.Utils:Log("Updated coord panel: x=" .. x .. ", y=" .. y, true)
    end
end

function GCast.SettingsUI:ToggleSettingsUI()
    if not GCast.settingsPanel then
        GCast.settingsPanel = GCast.SettingsUI:CreateSettingsPanel()
        if not GCast.settingsPanel then
            GCast.Utils:Log("Failed to create settings panel")
            return
        end
    end
    if GCast.settingsPanel:IsShown() then
        GCast.settingsPanel:Hide()
        GCast.Utils:Log("Hid settings panel", true)
    else
        GCast.settingsPanel:Show()
        if not GCast.db.player.visual.editMode then
            tinsert(UISpecialFrames, "GCastSettings")
        end
        local currentTab = 1
        for i = 1, 2 do
            local tab = _G["GCastTab"..i]
            if tab and not tab:IsEnabled() then
                currentTab = i
                break
            end
        end
        local content = _G["GCastTabContent"..currentTab]
        if content and content.Update then
            content:Update()
        end
        GCast:UpdateKeybindOverlays()
        if GCast.currentClassCooldownManager and GCast.currentClassCooldownManager.syncGlobalSettings then
            GCast.currentClassCooldownManager:syncGlobalSettings()
        end
        GCast.Utils:Log("Showed settings panel, active tab=" .. currentTab, true)
    end
end

local function UpdateSpellList(scrollChild, spellList, settings, isKeybindMode, categoryIndex)
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:ClearAllPoints()
    end

    local scrollFrame = scrollChild:GetParent()
    if not scrollFrame then
        GCast.Utils:Log("ScrollFrame not found")
        return
    end
    
    scrollFrame:Show()
    scrollChild:Show()
    
    if #spellList == 0 then
        local noSpellLabel = scrollChild.noSpellLabel
        if not noSpellLabel then
            noSpellLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noSpellLabel:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
            noSpellLabel:SetText(GCast.L["No Spells"])
            noSpellLabel:SetTextColor(0.7, 0.7, 0.7)
            scrollChild.noSpellLabel = noSpellLabel
        end
        noSpellLabel:Show()
        scrollChild:SetSize(270, 300)
        scrollFrame:SetHeight(290)
        if scrollFrame:GetParent() then
            scrollFrame:GetParent():SetHeight(300)
        end
        scrollFrame:UpdateScrollChildRect()
        return
    end

    if scrollChild.noSpellLabel then
        scrollChild.noSpellLabel:Hide()
    end

    if isKeybindMode then
        local withKeybinds = {}
        local withoutKeybinds = {}
        
        for _, spell in ipairs(spellList) do
            local keybindValue = settings.customKeybinds[tostring(spell.id)]
            if keybindValue and keybindValue ~= "" then
                table.insert(withKeybinds, spell)
            else
                table.insert(withoutKeybinds, spell)
            end
        end
        
        table.sort(withKeybinds, function(a, b) return a.name < b.name end)
        table.sort(withoutKeybinds, function(a, b) return a.name < b.name end)
        
        spellList = {}
        for _, spell in ipairs(withKeybinds) do
            table.insert(spellList, spell)
        end
        for _, spell in ipairs(withoutKeybinds) do
            table.insert(spellList, spell)
        end
    end

    local itemHeight = 28
    local totalHeight = math.max(300, #spellList * itemHeight + 20)
    scrollChild:SetSize(270, totalHeight)
    
    local containerHeight = math.min(300, totalHeight)
    scrollFrame:SetHeight(containerHeight)
    if scrollFrame:GetParent() then
        scrollFrame:GetParent():SetHeight(containerHeight + 10)
    end

    local rowWidth = 270
    for i, spell in ipairs(spellList) do
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(rowWidth, itemHeight)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((i-1) * itemHeight + 10))
        row:SetFrameLevel(scrollChild:GetFrameLevel() + 1)
        row:Show()

        if i % 2 == 0 then
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(row)
            bg:SetColorTexture(0.2, 0.2, 0.2, 0.3)
            bg:Show()
        end

        local spellText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        spellText:SetPoint("LEFT", isKeybindMode and 30 or 50, 0)
        spellText:SetWidth(isKeybindMode and 200 or 170)
        spellText:SetJustifyH("LEFT")
        spellText:SetText(spell.name)
        
        if isKeybindMode then
            local keybindValue = settings.customKeybinds[tostring(spell.id)]
            if not keybindValue or keybindValue == "" then
                spellText:SetTextColor(0.5, 0.5, 0.5)
            else
                spellText:SetTextColor(1, 1, 1)
            end
            
            local keybindEdit = GCast.Utils:CreateEditBox(row, {50, 20}, {"LEFT", spellText, "RIGHT", -10, 0}, false, 20, function(edit)
                edit:SetFontObject("GameFontHighlight")
                edit:SetTextInsets(8, 8, 0, 0)
                edit:SetJustifyH("RIGHT")
                edit:SetTextColor(1, 1, 0)
                edit:Show()
            end)

            keybindEdit:SetText(keybindValue or "")

            keybindEdit:SetScript("OnEnterPressed", function(self)
                local bindText = self:GetText()
                local idStr = tostring(spell.id)

                if bindText and bindText ~= "" then
                    GCast.Keybinds:SetSpellBinding(spell.id, bindText, categoryIndex)
                    spellText:SetTextColor(1, 1, 1)
                else
                    GCast.Keybinds:ClearSpellBinding(spell.id, categoryIndex)
                    spellText:SetTextColor(0.5, 0.5, 0.5)
                end

                self:ClearFocus()
                GCast.Keybinds:UpdateOverlays(categoryIndex)
                pcall(GCast.DB.SaveSettings)

                local currentSpells = {}
                for _, s in ipairs(spellList) do
                    table.insert(currentSpells, s)
                end
                local withKeybinds = {}
                local withoutKeybinds = {}
                for _, s in ipairs(currentSpells) do
                    local keybindValue = settings.customKeybinds[tostring(s.id)]
                    if keybindValue and keybindValue ~= "" then
                        table.insert(withKeybinds, s)
                    else
                        table.insert(withoutKeybinds, s)
                    end
                end
                table.sort(withKeybinds, function(a, b) return a.name < b.name end)
                table.sort(withoutKeybinds, function(a, b) return a.name < b.name end)
                currentSpells = {}
                for _, s in ipairs(withKeybinds) do
                    table.insert(currentSpells, s)
                end
                for _, s in ipairs(withoutKeybinds) do
                    table.insert(currentSpells, s)
                end

                UpdateSpellList(scrollChild, currentSpells, settings, isKeybindMode, categoryIndex)
            end)

            keybindEdit:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)
        else
            local removeButton = GCast.Utils:CreateButton(row, "-", {30, 20}, function()
                local spellID = tostring(spell.id)
                GCast.db.player.visual.enabledSpells[spellID] = nil
                GCast.Utils:Log("Removed spell ID " .. spellID .. " (" .. spell.name .. ")", true)
                pcall(GCast.DB.SaveSettings)
                local visualContent = _G["GCastTabContent1"]
                if visualContent and visualContent.Update then
                    visualContent:Update()
                    GCast.Utils:Log("Visual spell list updated", true)
                else
                    GCast.Utils:Log("Failed to update visual spell list")
                end
                local spellsStr = ""
                for k, v in pairs(GCast.db.player.visual.enabledSpells) do
                    spellsStr = spellsStr .. k .. "=" .. v .. ", "
                end
                GCast.Utils:Log("enabledSpells=" .. (spellsStr == "" and "empty" or spellsStr), true)
            end)
            removeButton:SetPoint("LEFT", 10, 0)
            removeButton:Show()
        end
    end
    
    scrollFrame:UpdateScrollChildRect()
    scrollFrame:SetVerticalScroll(0)
    
    scrollFrame:Show()
    scrollChild:Show()
    
    if scrollFrame:GetParent() then
        scrollFrame:GetParent():Show()
    end
    
    GCast.Utils:Log("Rendered spell list with " .. #spellList .. " spells", true)
end

function GCast.SettingsUI:CreateSettingsPanel()
    GCast.DB:EnsureInitialized()

    local panel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    if not panel then
        GCast.Utils:Log("Failed to create settings panel")
        return nil
    end
    panel:SetSize(800, 600)
    panel:SetPoint("CENTER")
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    panel:Hide()
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetFrameStrata("DIALOG")
    GCast.settingsPanel = panel

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText(GCast.L["GCast Settings"])

    local closeButton = GCast.SettingsUI:CreateControl(panel, "Button", "UIPanelCloseButton", nil, {"TOPRIGHT", -5, -5})

    local tabContainer = CreateFrame("Frame", nil, panel)
    tabContainer:SetPoint("TOPLEFT", 40, -50)
    tabContainer:SetSize(400, 32)

    local visualEffectSpellListFrame

    local function CreateTabButton(id, text)
        local button = GCast.Utils:CreateButton(tabContainer, text, {200, 32}, function(self)
            for i = 1, 2 do
                local content = _G["GCastTabContent"..i]
                local tab = _G["GCastTab"..i]
                if content then content:Hide() end
                if tab then tab:Enable() end
            end
            local content = _G["GCastTabContent"..id]
            if content then
                content:Show()
                if content.Update then
                    content:Update()
                    if id == 1 and visualEffectSpellListFrame and visualEffectSpellListFrame.scrollFrame then
                        visualEffectSpellListFrame.scrollFrame:UpdateScrollChildRect()
                        GCast.Utils:Log("Visual effect tab scroll frame updated", true)
                    end
                end
            end
            self:Disable()
        end)
        button:SetID(id)
        button:SetPoint("TOPLEFT", (id - 1) * 220, 0)
        _G["GCastTab"..id] = button
        return button
    end

    local function CreateTabContent(id)
        local content = CreateFrame("Frame", "GCastTabContent"..id, panel)
        content:SetPoint("TOPLEFT", 50, -70)
        content:SetPoint("BOTTOMRIGHT", -50, 25)
        content:Hide()
        content:SetFrameStrata("DIALOG")
        return content
    end

    local visualTab = CreateTabButton(1, GCast.L["Visual Effects"])
    local keybindTab = CreateTabButton(2, GCast.L["Cooldown Manager Keybinds"])
    local visualContent = CreateTabContent(1)
    local keybindContent = CreateTabContent(2)

    local function CreateVisualSliders(content)
        local sliders = {
            { label = GCast.L["Size"], key = "size", x = 10, y = -70, width = 60, default = 50 },
            { label = GCast.L["Opacity"], key = "opacity", x = 180, y = -70, width = 60, default = 100 },
            { label = GCast.L["Flight Duration"], key = "flightDuration", x = 10, y = -110, width = 60, default = 20 },
            { label = GCast.L["Fade-Out Duration"], key = "fadeOutDuration", x = 180, y = -110, width = 60, default = 25 }
        }

        local slidersLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        slidersLabel:SetPoint("TOPLEFT", 10, -30)
        slidersLabel:SetText(GCast.L["Visual Settings"])

        for _, s in ipairs(sliders) do
            local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("TOPLEFT", s.x, s.y)
            label:SetText(s.label .. ":")

            GCast.editBoxes[s.key] = GCast.Utils:CreateEditBox(content, {s.width, 20}, {"LEFT", label, "RIGHT", 10, 0}, true, nil, function(edit)
                edit:SetNumeric(true)
                edit:SetAutoFocus(false)
            end)

            local value = GCast.db.global.visual[s.key] or s.default
            if GCast.editBoxes[s.key] then
                GCast.editBoxes[s.key]:SetText(tostring(value))
                GCast.editBoxes[s.key]:SetScript("OnEnterPressed", function(self)
                    local newValue = tonumber(self:GetText()) or s.default
                    GCast:UpdateConfig(s.key, newValue)
                    self:SetText(tostring(newValue))
                    self:ClearFocus()
                end)
            end
        end

        return slidersLabel
    end

    local function CreateEditButton(content, slidersLabel)
        local editButton = GCast.Utils:CreateButton(content, GCast.L["Toggle Edit Mode"], {150, 28}, function(self)
            local enteringEditMode = not GCast.db.player.visual.editMode
            if enteringEditMode then
                local coordPanel = _G["GCastCoordPanel"] or GCast.SettingsUI:CreateCoordPanel()
                if coordPanel then
                    coordPanel:Show()
                    GCast.Utils:Log("Showing coord panel", true)
                else
                    GCast.Utils:Log("Failed to create coord panel")
                end
                GCast.db.player.visual.editMode = true
                if GCast.dottedFrame then GCast.dottedFrame:Show() end
                for i, frameName in ipairs(UISpecialFrames) do
                    if frameName == "GCastSettings" then
                        tremove(UISpecialFrames, i)
                        break
                    end
                end
                GCast.Utils:Log("Entered edit mode, editMode=" .. tostring(GCast.db.player.visual.editMode), true)
            else
                GCast.db.player.visual.editMode = false
                if GCast.dottedFrame then GCast.dottedFrame:Hide() end
                local coordPanel = _G["GCastCoordPanel"]
                if coordPanel then
                    coordPanel:Hide()
                    GCast.Utils:Log("Hid coord panel", true)
                end
                if _G["GCastSettings"] and _G["GCastSettings"]:IsShown() then
                    tinsert(UISpecialFrames, "GCastSettings")
                end
                GCast.Utils:Log("Exited edit mode, editMode=" .. tostring(GCast.db.player.visual.editMode), true)
            end
            self:SetText(GCast.db.player.visual.editMode and GCast.L["Exit Edit Mode"] or GCast.L["Toggle Edit Mode"])
        end)
        editButton:SetPoint("LEFT", slidersLabel, "RIGHT", 20, 0)
    end

    local function CreateDirectionControls(content)
        local directions = {
            { label = GCast.L["Up"], key = "UP", group = "verticalDirections", x = 360, y = -90, dir = "UP" },
            { label = GCast.L["Left"], key = "LEFT", group = "horizontalDirections", x = 460, y = -90, dir = "LEFT" },
            { label = GCast.L["Left Up"], key = "LEFT_UP", group = "diagonalDirections", x = 560, y = -90, dir = "LEFT_UP" },
            { label = GCast.L["Down"], key = "DOWN", group = "verticalDirections", x = 360, y = -130, dir = "DOWN" },
            { label = GCast.L["Right"], key = "RIGHT", group = "horizontalDirections", x = 460, y = -130, dir = "RIGHT" },
            { label = GCast.L["Left Down"], key = "LEFT_DOWN", group = "diagonalDirections", x = 560, y = -130, dir = "LEFT_DOWN" },
            { label = GCast.L["Right Up"], key = "RIGHT_UP", group = "diagonalDirections", x = 560, y = -170, dir = "RIGHT_UP" },
            { label = GCast.L["Right Down"], key = "RIGHT_DOWN", group = "diagonalDirections", x = 560, y = -210, dir = "RIGHT_DOWN" }
        }

        local rightHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        rightHeader:SetPoint("TOPLEFT", 360, -30)
        rightHeader:SetText(GCast.L["Flight Directions"])

        local dirCheckButtons = {}
        local orderEditBoxes = {}

        local function UpdateDirectionOrder()
            GCast.db.global.visual.directionOrder = GCast.db.global.visual.directionOrder or {}
            local enabledDirections = {}
            for _, d in ipairs(directions) do
                if GCast.db.global.visual[d.group] and GCast.db.global.visual[d.group][d.key] then
                    local order = GCast.db.global.visual.directionOrder[d.dir] or #enabledDirections + 1
                    table.insert(enabledDirections, { dir = d.dir, order = order })
                end
            end

            table.sort(enabledDirections, function(a, b) return a.order < b.order end)
            local newOrder = {}
            for i, entry in ipairs(enabledDirections) do
                newOrder[entry.dir] = i
            end

            for dir in pairs(GCast.db.global.visual.directionOrder) do
                if not newOrder[dir] then
                    GCast.db.global.visual.directionOrder[dir] = nil
                end
            end

            for dir, order in pairs(newOrder) do
                GCast.db.global.visual.directionOrder[dir] = order
            end

            for i, btn in ipairs(dirCheckButtons) do
                if btn and orderEditBoxes[i] then
                    local d = directions[i]
                    if GCast.db.global.visual[d.group] then
                        local checked = GCast.db.global.visual[d.group][d.key]
                        btn:SetChecked(checked)
                        if checked then
                            orderEditBoxes[i]:Enable()
                            orderEditBoxes[i]:SetText(tostring(GCast.db.global.visual.directionOrder[d.dir] or ""))
                        else
                            orderEditBoxes[i]:Disable()
                            orderEditBoxes[i]:SetText("")
                        end
                    end
                end
            end
            GCast:UpdateDirectionsCache()
        end

        for i, d in ipairs(directions) do
            if d.label == GCast.L["Up"] then
                local groupLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                groupLabel:SetPoint("TOPLEFT", 360, -70)
                groupLabel:SetText(GCast.L["Vertical"])
            elseif d.label == GCast.L["Left"] then
                local groupLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                groupLabel:SetPoint("TOPLEFT", 460, -70)
                groupLabel:SetText(GCast.L["Horizontal"])
            elseif d.label == GCast.L["Left Up"] then
                local groupLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                groupLabel:SetPoint("TOPLEFT", 560, -70)
                groupLabel:SetText(GCast.L["Diagonal"])
            end

            local btn = GCast.SettingsUI:CreateControl(content, "CheckButton", "UICheckButtonTemplate", {26, 26}, {"TOPLEFT", d.x, d.y}, function(check)
                check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                check.text:SetPoint("LEFT", check, "RIGHT", 5, 0)
                check.text:SetText(d.label)
                if GCast.db.global.visual[d.group] then
                    check:SetChecked(GCast.db.global.visual[d.group][d.key])
                else
                    check:SetChecked(false)
                end
                check:SetScript("OnClick", function(self)
                    if not GCast.db.global.visual[d.group] then return end
                    GCast.db.global.visual[d.group][d.key] = self:GetChecked()
                    if self:GetChecked() then
                        local maxOrder = 0
                        for _, order in pairs(GCast.db.global.visual.directionOrder) do
                            maxOrder = math.max(maxOrder, order)
                        end
                        GCast.db.global.visual.directionOrder[d.dir] = maxOrder + 1
                    else
                        GCast.db.global.visual.directionOrder[d.dir] = nil
                    end
                    UpdateDirectionOrder()
                end)
            end)
            table.insert(dirCheckButtons, btn)

            local orderBox = GCast.Utils:CreateEditBox(content, {30, 20}, {"LEFT", btn.text, "RIGHT", 5, 0}, true, 2, function(edit)
                edit:SetNumeric(true)
                edit:SetAutoFocus(false)
                edit:SetScript("OnEnterPressed", function(self)
                    if not GCast.db.global.visual.directionOrder then return end
                    local val = tonumber(self:GetText()) or 1
                    GCast.db.global.visual.directionOrder[d.dir] = val
                    UpdateDirectionOrder()
                    self:ClearFocus()
                end)
                if GCast.db.global.visual[d.group] and GCast.db.global.visual[d.group][d.key] and GCast.db.global.visual.directionOrder then
                    edit:SetText(tostring(GCast.db.global.visual.directionOrder[d.dir] or ""))
                    edit:Enable()
                else
                    edit:SetText("")
                    edit:Disable()
                end
            end)
            table.insert(orderEditBoxes, orderBox)
        end

        return UpdateDirectionOrder
    end

    local function CreateFlightEffectControls(content)
        local flightEffectsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        flightEffectsLabel:SetPoint("TOPLEFT", 360, -250)
        flightEffectsLabel:SetText(GCast.L["Flight Effect"])

        GCast.db.global.visual.flightEffectType = GCast.db.global.visual.flightEffectType or "straight"

        local flightTypes = {
            { key = "straight", label = GCast.L["Straight Line"], y = -290 },
            { key = "wave", label = GCast.L["Wave"], y = -330 },
            { key = "zigzag", label = GCast.L["Zigzag"], y = -370 }
        }

        local checkButtons = {}

        local function updateFlightTypeUI()
            if not GCast.db.global.visual then return end
            local flightType = GCast.db.global.visual.flightEffectType
            local isWave = flightType == "wave"
            local isZigzag = flightType == "zigzag"

            waveAmplitudeLabel:SetAlpha(isWave and 1 or 0.5)
            GCast.editBoxes.waveAmplitude:SetEnabled(isWave)
            GCast.editBoxes.waveAmplitude:SetAlpha(isWave and 1 or 0.5)
            waveAmplitudeLabel:SetShown(isWave)
            GCast.editBoxes.waveAmplitude:SetShown(isWave)

            zigzagAngleLabel:SetAlpha(isZigzag and 1 or 0.5)
            GCast.editBoxes.zigzagAngle:SetEnabled(isZigzag)
            GCast.editBoxes.zigzagAngle:SetAlpha(isZigzag and 1 or 0.5)
            zigzagAngleLabel:SetShown(isZigzag)
            GCast.editBoxes.zigzagAngle:SetShown(isZigzag)

            for i, check in ipairs(checkButtons) do
                check:SetChecked(GCast.db.global.visual.flightEffectType == check.ft.key)
            end
        end

        for i, ft in ipairs(flightTypes) do
            local check = GCast.SettingsUI:CreateControl(content, "CheckButton", "UICheckButtonTemplate", {26, 26}, {"TOPLEFT", 370, ft.y}, function(check)
                check.ft = ft
                check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                check.text:SetPoint("LEFT", check, "RIGHT", 5, 0)
                check.text:SetText(ft.label)
                check:SetChecked(GCast.db.global.visual.flightEffectType == ft.key)
                check:SetScript("OnClick", function(self)
                    if self:GetChecked() then
                        for j = 1, #flightTypes do
                            if j ~= i then
                                checkButtons[j]:SetChecked(false)
                            end
                        end
                        GCast.db.global.visual.flightEffectType = ft.key
                    else
                        self:SetChecked(true)
                    end
                    updateFlightTypeUI()
                end)
                _G["GCastFlightType"..i] = check
            end)
            table.insert(checkButtons, check)
        end

        local waveAmplitudeLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        waveAmplitudeLabel:SetPoint("TOPLEFT", 450, -330)
        waveAmplitudeLabel:SetText(GCast.L["Wave Amplitude"] .. ":")

        GCast.editBoxes.waveAmplitude = GCast.Utils:CreateEditBox(content, {50, 20}, {"LEFT", waveAmplitudeLabel, "RIGHT", 10, 0}, true, nil, function(edit)
            edit:SetNumeric(true)
            edit:SetAutoFocus(false)
        end)

        GCast.db.global.visual.waveAmplitude = GCast.db.global.visual.waveAmplitude or 20
        if GCast.editBoxes.waveAmplitude then
            GCast.editBoxes.waveAmplitude:SetText(tostring(GCast.db.global.visual.waveAmplitude))
            GCast.editBoxes.waveAmplitude:SetScript("OnEnterPressed", function(self)
                local value = tonumber(self:GetText()) or 20
                GCast:UpdateConfig("waveAmplitude", value)
                self:SetText(tostring(value))
                self:ClearFocus()
            end)
        end

        local zigzagAngleLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        zigzagAngleLabel:SetPoint("TOPLEFT", 450, -370)
        zigzagAngleLabel:SetText(GCast.L["Zigzag Angle"] .. ":")

        GCast.editBoxes.zigzagAngle = GCast.Utils:CreateEditBox(content, {50, 20}, {"LEFT", zigzagAngleLabel, "RIGHT", 10, 0}, true, nil, function(edit)
            edit:SetNumeric(true)
            edit:SetAutoFocus(false)
        end)

        GCast.db.global.visual.zigzagAngle = GCast.db.global.visual.zigzagAngle or 30
        if GCast.editBoxes.zigzagAngle then
            GCast.editBoxes.zigzagAngle:SetText(tostring(GCast.db.global.visual.zigzagAngle))
            GCast.editBoxes.zigzagAngle:SetScript("OnEnterPressed", function(self)
                local value = tonumber(self:GetText()) or 30
                GCast:UpdateConfig("zigzagAngle", value)
                self:SetText(tostring(value))
                self:ClearFocus()
            end)
        end

        return updateFlightTypeUI
    end

    local function CreateVisualSpellList(content)
        local visualEffectSpellListLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        visualEffectSpellListLabel:SetPoint("TOPLEFT", 10, -180)
        visualEffectSpellListLabel:SetText(GCast.L["Spell List"])

        visualEffectSpellListFrame = GCast.SettingsUI:CreateControl(content, "Frame", "BackdropTemplate", {300, 300}, {"TOPLEFT", 8, -210}, function(f)
            f:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            f:SetFrameLevel(content:GetFrameLevel() + 1)
            f:Show()
        end)

        local scrollFrame = GCast.SettingsUI:CreateControl(visualEffectSpellListFrame, "ScrollFrame", "UIPanelScrollFrameTemplate", {270, 290}, {"TOPLEFT", 5, -5, "BOTTOMRIGHT", -20, 5}, function(f)
            f:SetFrameLevel(visualEffectSpellListFrame:GetFrameLevel() + 1)
            f:Show()
        end)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(270, 300)
        scrollFrame:SetScrollChild(scrollChild)
        scrollChild:Show()
        
        visualEffectSpellListFrame.scrollFrame = scrollFrame

        GCast.editBoxes.spellID = GCast.Utils:CreateEditBox(content, {80, 20}, {"LEFT", visualEffectSpellListLabel, "RIGHT", 10, 0}, true, 10, function(edit)
            edit:SetNumeric(true)
            edit:SetAutoFocus(false)
        end)

        local visualEffectAddButton = GCast.Utils:CreateButton(content, GCast.L["Add Spell"], {80, 22}, function()
            local spellID = tonumber(GCast.editBoxes.spellID:GetText())
            if not spellID or spellID <= 0 then
                GCast.Utils:Log("Invalid spell ID: " .. tostring(GCast.editBoxes.spellID:GetText()))
                return
            end
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            if spellInfo and spellInfo.name then
                GCast.db.player.visual.enabledSpells[tostring(spellID)] = spellInfo.name
                GCast.Utils:Log("Added spell ID " .. tostring(spellID) .. " (" .. spellInfo.name .. ")")
                pcall(GCast.DB.SaveSettings)
                content:Update()
                GCast.editBoxes.spellID:SetText("")
                local spellsStr = ""
                for k, v in pairs(GCast.db.player.visual.enabledSpells) do
                    spellsStr = spellsStr .. k .. "=" .. v .. ", "
                end
                GCast.Utils:Log("enabledSpells=" .. (spellsStr == "" and "empty" or spellsStr))
            else
                GCast.Utils:Log("No spell info for ID: " .. tostring(spellID))
            end
        end)
        visualEffectAddButton:SetPoint("LEFT", GCast.editBoxes.spellID, "RIGHT", 10, 0)

        GCast.editBoxes.spellID:SetScript("OnEnterPressed", function(self)
            visualEffectAddButton:Click()
        end)

        local function UpdateVisualSpellList()
            local spellsToShow = {}
            GCast.db.player.visual.enabledSpells = GCast.db.player.visual.enabledSpells or {}
            if type(GCast.db.player.visual.enabledSpells) ~= "table" then
                GCast.db.player.visual.enabledSpells = {}
                GCast.Utils:Log("Reset enabledSpells to empty table")
            end

            for spellID, spellName in pairs(GCast.db.player.visual.enabledSpells) do
                local numSpellID = tonumber(spellID)
                if numSpellID and numSpellID > 0 and type(spellName) == "string" then
                    local spellInfo = C_Spell.GetSpellInfo(numSpellID)
                    if spellInfo and spellInfo.name then
                        table.insert(spellsToShow, { id = numSpellID, name = spellName })
                    else
                        GCast.Utils:Log("Skipping spell ID " .. tostring(spellID) .. " (invalid spell info)")
                    end
                else
                    GCast.Utils:Log("Skipping invalid spell ID " .. tostring(spellID) .. ", name=" .. tostring(spellName))
                end
            end

            table.sort(spellsToShow, function(a, b) return a.name < b.name end)
            GCast.Utils:Log("Updating visual spell list with " .. #spellsToShow .. " spells")

            if not scrollFrame or not scrollChild then
                GCast.Utils:Log("ScrollFrame or ScrollChild not found")
                return
            end

            UpdateSpellList(scrollChild, spellsToShow, GCast.db.player.visual, false, nil)
        end

        return UpdateVisualSpellList
    end

    local function SetupVisualTabContent(content)
        GCast.editBoxes = GCast.editBoxes or {}

        local slidersLabel = CreateVisualSliders(content)
        CreateEditButton(content, slidersLabel)
        local UpdateDirectionOrder = CreateDirectionControls(content)
        local UpdateFlightTypeUI = CreateFlightEffectControls(content)
        local UpdateVisualSpellList = CreateVisualSpellList(content)

        content.Update = function()
            GCast.DB:EnsureInitialized()
            GCast.db.global = GCast.db.global or {}
            GCast.db.player = GCast.db.player or { visual = {} }

            local sliders = {
                { key = "size", default = 50 },
                { key = "opacity", default = 100 },
                { key = "flightDuration", default = 20 },
                { key = "fadeOutDuration", default = 25 }
            }
            for _, s in ipairs(sliders) do
                local value = tonumber(GCast.db.global.visual[s.key]) or s.default
                if GCast.editBoxes[s.key] then
                    GCast.editBoxes[s.key]:SetText(tostring(value))
                end
            end

            if GCast.editBoxes.waveAmplitude then
                local waveAmplitude = tonumber(GCast.db.global.visual.waveAmplitude) or 20
                GCast.editBoxes.waveAmplitude:SetText(tostring(waveAmplitude))
            end

            if GCast.editBoxes.zigzagAngle then
                local zigzagAngle = tonumber(GCast.db.global.visual.zigzagAngle) or 30
                GCast.editBoxes.zigzagAngle:SetText(tostring(zigzagAngle))
            end

            UpdateFlightTypeUI()
            UpdateVisualSpellList()
            UpdateDirectionOrder()
        end
    end

    local function CreateKeybindControls(content, settings, categoryIndex)
        local showKeybindsCheck = GCast.SettingsUI:CreateControl(content, "CheckButton", "UICheckButtonTemplate", {26, 26}, {"TOPLEFT", categoryIndex == 0 and 10 or 380, -70}, function(check)
            check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            check.text:SetPoint("LEFT", check, "RIGHT", 5, 0)
            check.text:SetText(GCast.L["Show Keybinds"])
            check:SetChecked(settings.showKeybinds)
            check:SetScript("OnClick", function(self)
                settings.showKeybinds = self:GetChecked()
                GCast.db.global.keybinds[categoryIndex == 0 and "essential" or "utility"].show = self:GetChecked()
                pcall(GCast.DB.SaveSettings)
                GCast.Keybinds:UpdateOverlays(categoryIndex)
            end)
        end)

        local textSizeLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        textSizeLabel:SetPoint("TOPLEFT", categoryIndex == 0 and 10 or 380, -110)
        textSizeLabel:SetText(GCast.L["Keybind Text Size"] .. ":")

        local keybindTextSizeEdit = GCast.Utils:CreateEditBox(content, {30, 20}, {"LEFT", textSizeLabel, "RIGHT", 5, 0}, true, nil, function(edit)
            edit:SetNumeric(true)
            edit:SetAutoFocus(false)
            edit:SetText(tostring(settings.keybindTextSize or GCast.Config.keybindSettings.textSize.default))
            edit:SetScript("OnEnterPressed", function(self)
                local value = tonumber(self:GetText()) or GCast.Config.keybindSettings.textSize.default
                GCast:UpdateConfig("textSize", value)
                settings.keybindTextSize = value
                GCast.db.global.keybinds[categoryIndex == 0 and "essential" or "utility"].textSize = value
                pcall(GCast.DB.SaveSettings)
                self:SetText(tostring(value))
                self:ClearFocus()
                GCast.Keybinds:UpdateOverlays(categoryIndex)
            end)
        end)

        local xMarginLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        xMarginLabel:SetPoint("TOPLEFT", categoryIndex == 0 and 10 or 380, -150)
        xMarginLabel:SetText(GCast.L["X Margin"] .. ":")

        local xMarginEdit = GCast.Utils:CreateEditBox(content, {45, 20}, {"LEFT", xMarginLabel, "RIGHT", 5, 0}, true, nil, function(edit)
            edit:SetAutoFocus(false)
            edit:SetText(tostring(settings.xMargin or GCast.Config.keybindSettings.xMargin.default))
            edit:SetScript("OnEnterPressed", function(self)
                local value = tonumber(self:GetText()) or GCast.Config.keybindSettings.xMargin.default
                GCast:UpdateConfig("xMargin", value)
                settings.xMargin = value
                GCast.db.global.keybinds[categoryIndex == 0 and "essential" or "utility"].xMargin = value
                pcall(GCast.DB.SaveSettings)
                self:SetText(tostring(value))
                self:ClearFocus()
                GCast.Keybinds:RefreshAll()
            end)
        end)

        local yMarginLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        yMarginLabel:SetPoint("TOPLEFT", categoryIndex == 0 and 130 or 500, -150)
        yMarginLabel:SetText(GCast.L["Y Margin"] .. ":")

        local yMarginEdit = GCast.Utils:CreateEditBox(content, {45, 20}, {"LEFT", yMarginLabel, "RIGHT", 5, 0}, true, nil, function(edit)
            edit:SetAutoFocus(false)
            edit:SetText(tostring(settings.yMargin or GCast.Config.keybindSettings.yMargin.default))
            edit:SetScript("OnEnterPressed", function(self)
                local value = tonumber(self:GetText()) or GCast.Config.keybindSettings.yMargin.default
                GCast:UpdateConfig("yMargin", value)
                settings.yMargin = value
                GCast.db.global.keybinds[categoryIndex == 0 and "essential" or "utility"].yMargin = value
                pcall(GCast.DB.SaveSettings)
                self:SetText(tostring(value))
                self:ClearFocus()
                GCast.Keybinds:RefreshAll()
            end)
        end)
    end

    local function CreateKeybindListFrame(parentFrame, settings, categoryIndex, anchorXOffset)
        local backgroundFrame = GCast.SettingsUI:CreateControl(parentFrame, "Frame", "BackdropTemplate", {300, 300}, {"TOPLEFT", anchorXOffset, -180}, function(f)
            f:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            f:SetFrameLevel(parentFrame:GetFrameLevel() + 1)
            f:Show()
        end)

        local scrollFrame = GCast.SettingsUI:CreateControl(backgroundFrame, "ScrollFrame", "UIPanelScrollFrameTemplate", {270, 290}, {"TOPLEFT", 5, -5, "BOTTOMRIGHT", -20, 5}, function(f)
            f:SetFrameLevel(backgroundFrame:GetFrameLevel() + 1)
            f:Show()
        end)

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(270, 300)
        scrollFrame:SetScrollChild(scrollChild)
        scrollChild.category = categoryIndex == 0 and "essential" or "utility"
        scrollChild.categoryIndex = categoryIndex
        scrollChild.settings = settings
        scrollChild.scrollFrame = scrollFrame

        scrollFrame:UpdateScrollChildRect()
        scrollFrame:SetVerticalScroll(0)

        return scrollChild
    end

    local function SetupKeybindTabContent(content)
        local leftTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        leftTitle:SetPoint("TOPLEFT", 10, -30)
        leftTitle:SetText(GCast.L["Essential"])

        local rightTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        rightTitle:SetPoint("TOPLEFT", 380, -30)
        rightTitle:SetText(GCast.L["Utility"])

        local essentialSettings = GCast.currentClassCooldownManager and GCast.currentClassCooldownManager.layoutSettings["essential"] or { showKeybinds = true, keybindTextSize = 12, xMargin = 0, yMargin = 0, customKeybinds = {}, isManual = {} }
        local utilitySettings = GCast.currentClassCooldownManager and GCast.currentClassCooldownManager.layoutSettings["utility"] or { showKeybinds = true, keybindTextSize = 12, xMargin = 0, yMargin = 0, customKeybinds = {}, isManual = {} }

        CreateKeybindControls(content, essentialSettings, 0)
        CreateKeybindControls(content, utilitySettings, 1)

        local leftScrollChild = CreateKeybindListFrame(content, essentialSettings, 0, 8)
        local rightScrollChild = CreateKeybindListFrame(content, utilitySettings, 1, 372)

        local function CollectButtons(frame, category, spellButtons)
            if not frame then return end
            local spellID
            if frame._spellID then
                spellID = tostring(frame._spellID)
            elseif frame.GetCooldownID and type(frame.GetCooldownID) == "function" then
                local cooldownID = frame:GetCooldownID()
                if cooldownID then
                    local info = C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
                    spellID = info and tostring(info.spellID)
                end
            end
            if spellID then
                local spellName = GCast.Utils:GetSpellName(tonumber(spellID))
                if spellName and spellName ~= "" then
                    table.insert(spellButtons, { id = tonumber(spellID), name = spellName })
                    GCast.Utils:Log("Collected spell ID " .. tostring(spellID) .. " (" .. spellName .. ") for " .. category, true)
                end
            end
            for _, child in ipairs({frame:GetChildren()}) do
                CollectButtons(child, category, spellButtons)
            end
        end

        local function UpdateAllSpellLists()
            local essentialSpells = {}
            local utilitySpells = {}
            local addedSpellIDs = {}

            local essentialViewer = _G["EssentialCooldownViewer"]
            if essentialViewer then
                CollectButtons(essentialViewer, "essential", essentialSpells)
            else
                GCast.Utils:Log("EssentialCooldownViewer not found")
            end

            local utilityViewer = _G["UtilityCooldownViewer"]
            if utilityViewer then
                CollectButtons(utilityViewer, "utility", utilitySpells)
            else
                GCast.Utils:Log("UtilityCooldownViewer not found")
            end

            if GCast.keybindOverlays then
                for _, overlay in pairs(GCast.keybindOverlays) do
                    if overlay:GetParent() then
                        local button = overlay:GetParent()
                        local spellID
                        if button._spellID then
                            spellID = tostring(button._spellID)
                        elseif button.GetCooldownID and type(button.GetCooldownID) == "function" then
                            local cooldownID = button:GetCooldownID()
                            if cooldownID then
                                local info = C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
                                spellID = info and tostring(info.spellID)
                            end
                        end
                        if spellID and not addedSpellIDs[spellID] then
                            local spellName = GCast.Utils:GetSpellName(tonumber(spellID))
                            if spellName and spellName ~= "" then
                                local spellData = { id = tonumber(spellID), name = spellName }
                                if overlay.category == 0 then
                                    table.insert(essentialSpells, spellData)
                                else
                                    table.insert(utilitySpells, spellData)
                                end
                                addedSpellIDs[spellID] = true
                                local idStr = tostring(spellID)
                                if overlay.text and overlay.text:GetText() then
                                    local settings = overlay.category == 0 and essentialSettings or utilitySettings
                                    settings.customKeybinds[idStr] = overlay.text:GetText()
                                    settings.isManual[idStr] = true
                                    GCast.Utils:Log("Synced overlay keybind for spell ID " .. idStr .. ": " .. overlay.text:GetText(), true)
                                end
                            end
                        end
                    end
                end
            end

            table.sort(essentialSpells, function(a, b) return a.name < b.name end)
            table.sort(utilitySpells, function(a, b) return a.name < b.name end)

            GCast.Utils:Log("Essential spells: " .. #essentialSpells .. ", Utility spells: " .. #utilitySpells, true)

            if not GCast.currentClassCooldownManager then
                GCast.currentClassCooldownManager = {
                    layoutSettings = {
                        essential = { showKeybinds = true, keybindTextSize = 12, xMargin = 0, yMargin = 0, customKeybinds = {}, isManual = {} },
                        utility = { showKeybinds = true, keybindTextSize = 12, xMargin = 0, yMargin = 0, customKeybinds = {}, isManual = {} }
                    }
                }
            end

            local leftSettings = GCast.currentClassCooldownManager.layoutSettings["essential"]
            if leftSettings and leftScrollChild and leftScrollChild.scrollFrame then
                UpdateSpellList(leftScrollChild, essentialSpells, leftSettings, true, 0)
                leftScrollChild.scrollFrame:UpdateScrollChildRect()
                leftScrollChild.scrollFrame:SetVerticalScroll(0)
            end

            local rightSettings = GCast.currentClassCooldownManager.layoutSettings["utility"]
            if rightSettings and rightScrollChild and rightScrollChild.scrollFrame then
                UpdateSpellList(rightScrollChild, utilitySpells, rightSettings, true, 1)
                rightScrollChild.scrollFrame:UpdateScrollChildRect()
                rightScrollChild.scrollFrame:SetVerticalScroll(0)
            end
        end

        content.Update = function()
            content:Show()
            
            if GCast.currentClassCooldownManager then
                GCast.Keybinds:SyncFromDB()
                for i = 0, 1 do
                    local categoryName = i == 0 and "essential" or "utility"
                    local settings = GCast.currentClassCooldownManager.layoutSettings[categoryName]
                    local children = {content:GetChildren()}
                    for _, child in ipairs(children) do
                        if child:GetObjectType() == "CheckButton" and child.text and 
                           child.text:GetText() == GCast.L["Show Keybinds"] and
                           ((i == 0 and child:GetPoint(1):match("10")) or 
                            (i == 1 and child:GetPoint(1):match("380"))) then
                            child:SetChecked(settings.showKeybinds)
                            child:Show()
                        end
                        if child:GetObjectType() == "EditBox" then
                            local parent = child:GetParent()
                            if parent == content then
                                local point, relativeTo = child:GetPoint()
                                if relativeTo and relativeTo:GetObjectType() == "FontString" then
                                    local text = relativeTo:GetText()
                                    if text == GCast.L["Keybind Text Size"] .. ":" and
                                       ((i == 0 and relativeTo:GetPoint(1):match("10")) or 
                                        (i == 1 and relativeTo:GetPoint(1):match("380"))) then
                                        child:SetText(tostring(settings.keybindTextSize))
                                        child:Show()
                                        relativeTo:Show()
                                    elseif text == GCast.L["X Margin"] .. ":" and
                                           ((i == 0 and relativeTo:GetPoint(1):match("10")) or 
                                            (i == 1 and relativeTo:GetPoint(1):match("380"))) then
                                        child:SetText(tostring(settings.xMargin))
                                        child:Show()
                                        relativeTo:Show()
                                    elseif text == GCast.L["Y Margin"] .. ":" and
                                           ((i == 0 and relativeTo:GetPoint(1):match("130")) or 
                                            (i == 1 and relativeTo:GetPoint(1):match("500"))) then
                                        child:SetText(tostring(settings.yMargin))
                                        child:Show()
                                        relativeTo:Show()
                                    end
                                end
                            end
                        end
                    end
                end
                
                for _, child in ipairs({content:GetChildren()}) do
                    if child:GetObjectType() == "FontString" and 
                       (child:GetText() == GCast.L["Essential"] or child:GetText() == GCast.L["Utility"]) then
                        child:Show()
                    end
                end
                
                UpdateAllSpellLists()
                
                GCast.Utils:Log("Keybind tab content updated", true)
            end
        end
    end

    SetupVisualTabContent(visualContent)
    SetupKeybindTabContent(keybindContent)
    if _G["GCastTab1"] then
        _G["GCastTab1"]:Click()
    else
        GCast.Utils:Log("Tab1 not found")
    end

    panel:SetScript("OnShow", function()
        if not GCast.db.player.visual.editMode and not (_G["GCastCoordPanel"] and _G["GCastCoordPanel"]:IsShown()) then
            tinsert(UISpecialFrames, "GCastSettings")
        end

        local activeTab
        for i = 1, 2 do
            local tab = _G["GCastTab"..i]
            if tab and not tab:IsEnabled() then
                activeTab = i
                break
            end
        end
        
        if activeTab then
            local content = _G["GCastTabContent"..activeTab]
            if content then
                content:Show()
                if content.Update then 
                    content:Update()
                end
            end
        elseif _G["GCastTab1"] then
            _G["GCastTab1"]:Click()
        end
        
        GCast.Utils:Log("Settings panel shown", true)
    end)

    panel:SetScript("OnHide", function()
        for i, frameName in ipairs(UISpecialFrames) do
            if frameName == "GCastSettings" then
                tremove(UISpecialFrames, i)
                break
            end
        end
    end)

    return panel
end

function GCast.SettingsUI:CreateCoordPanel()
    if _G["GCastCoordPanel"] then
        local coordPanel = _G["GCastCoordPanel"]
        if GCast.db.player.visual.editMode then
            coordPanel:Show()
            GCast.Utils:Log("Existing coord panel shown, editMode=" .. tostring(GCast.db.player.visual.editMode), true)
        else
            coordPanel:Hide()
            GCast.Utils:Log("Existing coord panel hidden, editMode=" .. tostring(GCast.db.player.visual.editMode), true)
        end
        return coordPanel
    end

    local coordPanel = CreateFrame("Frame", "GCastCoordPanel", UIParent, "BackdropTemplate")
    if not coordPanel then
        GCast.Utils:Log("Failed to create coord panel")
        return nil
    end
    coordPanel:SetSize(180, 60)
    coordPanel:SetPoint("CENTER", 0, 200)
    coordPanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    coordPanel:SetMovable(true)
    coordPanel:EnableMouse(true)
    coordPanel:SetClampedToScreen(true)
    coordPanel:SetFrameStrata("HIGH")
    coordPanel:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)
    coordPanel:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:StopMovingOrSizing()
        end
    end)
    if GCast.db.player.visual.editMode then
        coordPanel:Show()
    else
        coordPanel:Hide()
    end

    local xLabel = coordPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    xLabel:SetPoint("TOPLEFT", 15, -30)
    xLabel:SetText("X:")

    local xEdit = GCast.Utils:CreateEditBox(coordPanel, {50, 20}, {"LEFT", xLabel, "RIGHT", 5, 0}, true, nil, function(edit)
        edit:SetAutoFocus(false)
        edit:SetText(string.format("%.1f", GCast.db.player.visual.startPoint.x or 0))
    end)

    local yLabel = coordPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    yLabel:SetPoint("LEFT", xEdit, "RIGHT", 10, 0)
    yLabel:SetText("Y:")

    local yEdit = GCast.Utils:CreateEditBox(coordPanel, {50, 20}, {"LEFT", yLabel, "RIGHT", 5, 0}, true, nil, function(edit)
        edit:SetAutoFocus(false)
        edit:SetText(string.format("%.1f", GCast.db.player.visual.startPoint.y or 0))
    end)

    local updateButton = GCast.Utils:CreateButton(coordPanel, "✔", {16, 16}, function()
        local x = tonumber(xEdit:GetText()) or 0
        local y = tonumber(yEdit:GetText()) or 0
        GCast.SettingsUI:UpdateStartPoint(x, y)
    end)
    updateButton:SetPoint("LEFT", yEdit, "RIGHT", 5, 0)

    xEdit:SetScript("OnEnterPressed", function(self)
        if not coordPanel.xEdit or not coordPanel.yEdit then return end
        local x = tonumber(self:GetText()) or 0
        local y = tonumber(coordPanel.yEdit:GetText()) or 0
        GCast.SettingsUI:UpdateStartPoint(x, y)
        self:ClearFocus()
    end)
    
    xEdit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        if GCast.db.player.visual.editMode then
            GCast.db.player.visual.editMode = false
            if GCast.dottedFrame then GCast.dottedFrame:Hide() end
            if coordPanel then
                coordPanel:Hide()
                GCast.Utils:Log("Hid coord panel on ESC", true)
            end
            if _G["GCastSettings"] and _G["GCastSettings"]:IsShown() then
                local editButton = _G["GCastSettings"]:GetChildren()
                if editButton and editButton.SetText then
                    editButton:SetText(GCast.L["Toggle Edit Mode"] or "Toggle Edit Mode")
                end
            end
            GCast.Utils:Log("Exited edit mode via ESC", true)
        end
    end)

    yEdit:SetScript("OnEnterPressed", function(self)
        if not coordPanel.xEdit or not coordPanel.yEdit then return end
        local x = tonumber(coordPanel.xEdit:GetText()) or 0
        local y = tonumber(self:GetText()) or 0
        GCast.SettingsUI:UpdateStartPoint(x, y)
        self:ClearFocus()
    end)
    
    yEdit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        if GCast.db.player.visual.editMode then
            GCast.db.player.visual.editMode = false
            if GCast.dottedFrame then GCast.dottedFrame:Hide() end
            if coordPanel then
                coordPanel:Hide()
                GCast.Utils:Log("Hid coord panel on ESC", true)
            end
            if _G["GCastSettings"] and _G["GCastSettings"]:IsShown() then
                local editButton = _G["GCastSettings"]:GetChildren()
                if editButton and editButton.SetText then
                    editButton:SetText(GCast.L["Toggle Edit Mode"] or "Toggle Edit Mode")
                end
            end
            GCast.Utils:Log("Exited edit mode via ESC", true)
        end
    end)

    coordPanel.xEdit = xEdit
    coordPanel.yEdit = yEdit
    GCast.Utils:Log("Created coord panel, editMode=" .. tostring(GCast.db.player.visual.editMode), true)
    return coordPanel
end
