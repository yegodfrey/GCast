local addonName = "GCast"
local frame = CreateFrame("FRAME")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("ADDON_LOADED")

-- Localization
local L = {}
if GetLocale() == "zhCN" then
    L["GCast Settings"] = "GCast设置"
    L["Set Start Position"] = "设置起始位置"
    L["Toggle Edit Mode"] = "切换编辑模式"
    L["Confirm"] = "确认"
    L["Size"] = "大小"
    L["Opacity"] = "透明度"
    L["Flight Duration"] = "飞行持续时间"
    L["Fade-Out Duration"] = "淡出持续时间"
    L["Flight Directions"] = "飞行方向"
    L["Vertical"] = "垂直"
    L["Horizontal"] = "水平"
    L["Diagonal"] = "对角"
    L["Up"] = "上"
    L["Down"] = "下"
    L["Left"] = "左"
    L["Right"] = "右"
    L["Left Up"] = "左上"
    L["Left Down"] = "左下"
    L["Right Up"] = "右上"
    L["Right Down"] = "右下"
    L["Add Spell"] = "添加技能"
    L["Spell List"] = "技能列表"
else
    L["GCast Settings"] = "GCast Settings"
    L["Set Start Position"] = "Set Start Position"
    L["Toggle Edit Mode"] = "Toggle Edit Mode"
    L["Confirm"] = "Confirm"
    L["Size"] = "Size"
    L["Opacity"] = "Opacity"
    L["Flight Duration"] = "Flight Duration"
    L["Fade-Out Duration"] = "Fade-Out Duration"
    L["Flight Directions"] = "Flight Directions"
    L["Vertical"] = "Vertical"
    L["Horizontal"] = "Horizontal"
    L["Diagonal"] = "Diagonal"
    L["Up"] = "Up"
    L["Down"] = "Down"
    L["Left"] = "Left"
    L["Right"] = "Right"
    L["Left Up"] = "Left Up"
    L["Left Down"] = "Left Down"
    L["Right Up"] = "Right Up"
    L["Right Down"] = "Right Down"
    L["Add Spell"] = "Add Spell"
    L["Spell List"] = "Spell List"
end

local iconTexture, spellID
local defaultSize = 50
local defaultDB = {
    size = defaultSize,
    opacity = 100,
    verticalDirections = { up = false, down = false },
    horizontalDirections = { left = false, right = false },
    diagonalDirections = { leftUp = false, leftDown = false, rightUp = false, rightDown = false },
    directionOrder = {},
    startPoint = { x = 0, y = 0 },
    enabledSpells = {},
    editMode = false,
    flightDuration = 20,
    fadeOutDuration = 25
}
local db = defaultDB -- Initialize with defaults until ADDON_LOADED

-- Helper Functions
local function SetTextWithFallback(editBox, value, default)
    if editBox and editBox.SetText then
        editBox:SetText(string.format("%.2f", value or default))
        editBox:ClearFocus()
    end
end

local function ValidateNumber(input, min, max, default)
    local value = tonumber(input) or default
    return math.max(min, math.min(max, value))
end

local function CreateEditBoxWithLabel(parent, labelText, x, y, width, onEnterPressed, initialValue, defaultValue)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", x, y)
    label:SetText(labelText)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetPoint("TOP", x, y - 15)
    editBox:SetSize(width, 20)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEnterPressed", onEnterPressed)
    SetTextWithFallback(editBox, initialValue, defaultValue)
    return editBox, label
end

-- Define dottedFrame
local dottedFrame = CreateFrame("Frame", nil, UIParent)
dottedFrame:SetSize(defaultSize, defaultSize)
dottedFrame:SetPoint("CENTER", UIParent, "CENTER", db.startPoint.x, db.startPoint.y)
dottedFrame:Hide()
local dottedTexture = dottedFrame:CreateTexture(nil, "OVERLAY")
dottedTexture:SetAllPoints()
dottedTexture:SetTexture("Interface\\Buttons\\WHITE8x8")
dottedTexture:SetVertexColor(1, 1, 1, 0.5)
dottedFrame:EnableMouse(true)
dottedFrame:SetMovable(true)
dottedFrame:SetScript("OnMouseDown", function(self, button)
    if db.editMode and button == "LeftButton" then
        self:StartMoving()
    end
end)
dottedFrame:SetScript("OnMouseUp", function(self, button)
    if db.editMode and button == "LeftButton" and self:IsMovable() then
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local parentX, parentY = UIParent:GetCenter()
        db.startPoint.x = x and parentX and tonumber(string.format("%.2f", x - parentX)) or 0
        db.startPoint.y = y and parentY and tonumber(string.format("%.2f", y - parentY)) or 0
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", db.startPoint.x, db.startPoint.y)
    end
end)

-- Coordinate Settings Panel
local function CreateCoordPanel()
    local dialog = CreateFrame("Frame", "GCastCoordPanel", UIParent, "BackdropTemplate")
    dialog:SetSize(200, 180)
    dialog:SetPoint("RIGHT", _G["GCastSettings"] or UIParent, "LEFT", -12, 0)
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    dialog:SetScript("OnHide", function()
        db.editMode = false
        dottedFrame:Hide()
        if _G["GCastSettings"] and _G["GCastSettings"]:IsShown() then
            tinsert(UISpecialFrames, "GCastSettings")
        end
    end)
    tinsert(UISpecialFrames, "GCastCoordPanel")

    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText(L["Set Start Position"])

    local xLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xLabel:SetPoint("TOPLEFT", 20, -40)
    xLabel:SetText("X:")
    dialog.xEdit = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    dialog.xEdit:SetPoint("LEFT", xLabel, "RIGHT", 10, 0)
    dialog.xEdit:SetSize(100, 20)
    dialog.xEdit:SetAutoFocus(false)
    dialog.xEdit:SetScript("OnEnterPressed", function(self)
        local x = tonumber(self:GetText()) or db.startPoint.x
        db.startPoint.x = tonumber(string.format("%.2f", x))
        dottedFrame:ClearAllPoints()
        dottedFrame:SetPoint("CENTER", UIParent, "CENTER", db.startPoint.x, db.startPoint.y)
        SetTextWithFallback(self, x, 0)
        self:ClearFocus()
    end)
    SetTextWithFallback(dialog.xEdit, db.startPoint.x, 0)

    local yLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yLabel:SetPoint("TOPLEFT", 20, -70)
    yLabel:SetText("Y:")
    dialog.yEdit = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    dialog.yEdit:SetPoint("LEFT", yLabel, "RIGHT", 10, 0)
    dialog.yEdit:SetSize(100, 20)
    dialog.yEdit:SetAutoFocus(false)
    dialog.yEdit:SetScript("OnEnterPressed", function(self)
        local y = tonumber(self:GetText()) or db.startPoint.y
        db.startPoint.y = tonumber(string.format("%.2f", y))
        dottedFrame:ClearAllPoints()
        dottedFrame:SetPoint("CENTER", UIParent, "CENTER", db.startPoint.x, db.startPoint.y)
        SetTextWithFallback(self, y, 0)
        self:ClearFocus()
    end)
    SetTextWithFallback(dialog.yEdit, db.startPoint.y, 0)

    local confirmButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    confirmButton:SetPoint("TOP", 0, -100)
    confirmButton:SetSize(80, 22)
    confirmButton:SetText(L["Confirm"])
    confirmButton:SetScript("OnClick", function()
        local x = tonumber(dialog.xEdit:GetText()) or db.startPoint.x
        local y = tonumber(dialog.yEdit:GetText()) or db.startPoint.y
        db.startPoint.x = tonumber(string.format("%.2f", x))
        db.startPoint.y = tonumber(string.format("%.2f", y))
        dottedFrame:ClearAllPoints()
        dottedFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
        SetTextWithFallback(dialog.xEdit, x, 0)
        SetTextWithFallback(dialog.yEdit, y, 0)
        db.editMode = false
        dottedFrame:Hide()
        dialog:Hide()
    end)

    dialog:SetScript("OnShow", function()
        SetTextWithFallback(dialog.xEdit, db.startPoint.x, 0)
        SetTextWithFallback(dialog.yEdit, db.startPoint.y, 0)
    end)

    dialog:SetScript("OnUpdate", function(self)
        if self:IsVisible() and db.editMode then
            local x, y = dottedFrame:GetCenter()
            local parentX, parentY = UIParent:GetCenter()
            local xCoord = x and parentX and tonumber(string.format("%.2f", x - parentX)) or db.startPoint.x
            local yCoord = y and parentY and tonumber(string.format("%.2f", y - parentY)) or db.startPoint.y
            SetTextWithFallback(self.xEdit, xCoord, 0)
            SetTextWithFallback(self.yEdit, yCoord, 0)
        end
    end)

    return dialog
end

-- Settings Panel
local function CreateSettingsPanel()
    local sliders = {
        { label = L["Size"], key = "size", default = defaultSize, y = -90, width = 170, editBox = nil },
        { label = L["Opacity"], key = "opacity", default = 100, y = -140, width = 170, editBox = nil },
        { label = L["Flight Duration"], key = "flightDuration", default = 20, y = -190, width = 170, editBox = nil },
        { label = L["Fade-Out Duration"], key = "fadeOutDuration", default = 25, y = -240, width = 170, editBox = nil }
    }

    local panel = CreateFrame("Frame", "GCastSettings", UIParent, "BackdropTemplate")
    panel:SetSize(370, 650)
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

    for _, s in ipairs(sliders) do
        s.editBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    end

    panel:SetScript("OnShow", function()
        if not db.editMode and not (_G["GCastCoordPanel"] and _G["GCastCoordPanel"]:IsShown()) then
            tinsert(UISpecialFrames, "GCastSettings")
        end
        for _, s in ipairs(sliders) do
            SetTextWithFallback(s.editBox, db[s.key], s.default)
        end
    end)
    panel:SetScript("OnHide", function()
        for i, frameName in ipairs(UISpecialFrames) do
            if frameName == "GCastSettings" then
                table.remove(UISpecialFrames, i)
                break
            end
        end
    end)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText(L["GCast Settings"])

    local closeButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)

    -- Edit Mode Button
    local editButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    editButton:SetPoint("TOP", 0, -60)
    editButton:SetSize(120, 22)
    editButton:SetText(L["Toggle Edit Mode"])
    editButton:SetScript("OnClick", function()
        db.editMode = not db.editMode
        if db.editMode then
            dottedFrame:Show()
            local coordPanel = _G["GCastCoordPanel"] or CreateCoordPanel()
            coordPanel:Show()
            for i, frameName in ipairs(UISpecialFrames) do
                if frameName == "GCastSettings" then
                    table.remove(UISpecialFrames, i)
                    break
                end
            end
        else
            dottedFrame:Hide()
            if _G["GCastCoordPanel"] then
                _G["GCastCoordPanel"]:Hide()
            end
            if panel:IsShown() then
                tinsert(UISpecialFrames, "GCastSettings")
            end
        end
    end)

    -- Slider and Text Box Setup
    for _, s in ipairs(sliders) do
        local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOP", 0, s.y - 15)
        label:SetText(s.label)
        local slider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
        slider:SetPoint("TOP", -20, s.y)
        slider:SetWidth(s.width)
        slider:SetMinMaxValues(0, s.key == "fadeOutDuration" and 50 or 100)
        slider:SetValue(db[s.key] or s.default)
        slider:SetValueStep(1)
        local minText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        minText:SetPoint("LEFT", slider, "LEFT", -25, 0)
        minText:SetText("0")
        local maxText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        maxText:SetPoint("RIGHT", slider, "RIGHT", 30, 0)
        maxText:SetText(s.key == "fadeOutDuration" and "50" or "100")
        s.editBox:SetPoint("LEFT", slider, "RIGHT", 40, 0)
        s.editBox:SetSize(50, 20)
        s.editBox:SetAutoFocus(false)
        s.editBox:SetNumeric(true)
        SetTextWithFallback(s.editBox, db[s.key], s.default)
        s.editBox:SetScript("OnEnterPressed", function(self)
            local maxVal = (s.key == "fadeOutDuration") and 50 or 100
            local value = ValidateNumber(self:GetText(), 0, maxVal, db[s.key] or s.default)
            db[s.key] = value
            slider:SetValue(value)
            SetTextWithFallback(self, value, s.default)
            if s.key == "size" then
                dottedFrame:SetSize(value, value)
            end
        end)
        slider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value)
            db[s.key] = value
            SetTextWithFallback(s.editBox, value, s.default)
            if s.key == "size" then
                dottedFrame:SetSize(value, value)
            end
        end)
    end

    -- Flight Settings
    local orientationLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    orientationLabel:SetPoint("TOP", 0, -300)
    local directions = {
        { label = L["Up"], key = "up", group = "verticalDirections", y = -340, x = 20, dir = "UP" },
        { label = L["Down"], key = "down", group = "verticalDirections", y = -360, x = 20, dir = "DOWN" },
        { label = L["Left"], key = "left", group = "horizontalDirections", y = -340, x = 120, dir = "LEFT" },
        { label = L["Right"], key = "right", group = "horizontalDirections", y = -360, x = 120, dir = "RIGHT" },
        { label = L["Left Up"], key = "leftUp", group = "diagonalDirections", y = -340, x = 220, dir = "LEFT_UP" },
        { label = L["Left Down"], key = "leftDown", group = "diagonalDirections", y = -360, x = 220, dir = "LEFT_DOWN" },
        { label = L["Right Up"], key = "rightUp", group = "diagonalDirections", y = -380, x = 220, dir = "RIGHT_UP" },
        { label = L["Right Down"], key = "rightDown", group = "diagonalDirections", y = -400, x = 220, dir = "RIGHT_DOWN" }
    }

    for i, d in ipairs(directions) do
        if d.label == L["Up"] or d.label == L["Left"] or d.label == L["Left Up"] then
            local groupLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            groupLabel:SetPoint("TOPLEFT", d.x, -320)
            groupLabel:SetText(d.group == "verticalDirections" and L["Vertical"] or d.group == "horizontalDirections" and L["Horizontal"] or L["Diagonal"])
        end
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", d.x, d.y)
        check.orderLabel = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        check.orderLabel:SetPoint("LEFT", check, "RIGHT", 5, 0)
        check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        check.text:SetPoint("LEFT", check.orderLabel, "RIGHT", 2, 0)
        check.text:SetText(d.label)
        check:SetChecked(db[d.group][d.key])
        d.check = check
        check:SetScript("OnClick", function(self)
            db[d.group][d.key] = self:GetChecked()
            if self:GetChecked() then
                if not db.directionOrder[d.dir] then
                    local maxOrder = 0
                    for _, order in pairs(db.directionOrder) do
                        maxOrder = math.max(maxOrder, order)
                    end
                    db.directionOrder[d.dir] = maxOrder + 1
                end
                self.orderLabel:SetText(tostring(db.directionOrder[d.dir]) .. ":")
            else
                db.directionOrder[d.dir] = nil
                self.orderLabel:SetText("")
                panel:ReassignDirectionOrders()
            end
            panel:UpdateFlightSettings()
        end)
        check:SetScript("OnShow", function(self)
            self.orderLabel:SetText(db.directionOrder[d.dir] and tostring(db.directionOrder[d.dir]) .. ":" or "")
        end)
    end

    -- Reassign Direction Orders
    function panel:ReassignDirectionOrders()
        local activeDirections = {}
        for _, d in ipairs(directions) do
            if db[d.group][d.key] then
                table.insert(activeDirections, d.dir)
            end
        end
        db.directionOrder = {}
        for i, dir in ipairs(activeDirections) do
            db.directionOrder[dir] = i
        end
        panel:UpdateFlightSettings()
    end

    -- Update Flight Settings
    function panel:UpdateFlightSettings()
        for _, d in ipairs(directions) do
            if d.check and d.check.orderLabel then
                d.check.orderLabel:SetText(db.directionOrder[d.dir] and tostring(db.directionOrder[d.dir]) .. ":" or "")
            end
        end
    end

    -- Separator Line with Label
    local separator = panel:CreateTexture(nil, "BORDER")
    separator:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
    separator:SetSize(350, 8)
    separator:SetPoint("TOP", 0, -430)
    local separatorLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    separatorLabel:SetPoint("CENTER", separator, "CENTER", 0, 0)
    separatorLabel:SetText(L["Spell List"])

    -- Spell Selection
    local spellEditBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    spellEditBox:SetPoint("TOPLEFT", 30, -450)
    spellEditBox:SetSize(150, 20)
    spellEditBox:SetAutoFocus(false)
    spellEditBox:SetNumeric(true)
    
    local addSpellButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    addSpellButton:SetPoint("LEFT", spellEditBox, "RIGHT", 10, 0)
    addSpellButton:SetSize(80, 22)
    addSpellButton:SetText(L["Add Spell"])
    addSpellButton:SetScript("OnClick", function()
        local spellID = tonumber(spellEditBox:GetText())
        if spellID then
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            if spellInfo and spellInfo.name then
                db.enabledSpells[spellID] = spellInfo.name
                spellEditBox:SetText("")
                if panel.spellList then
                    panel.spellList:Update()
                end
            end
        end
    end)

    -- Spell List
    local spellListFrame = CreateFrame("Frame", nil, panel)
    spellListFrame:SetPoint("TOP", 0, -480)
    spellListFrame:SetSize(350, 100)
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", spellListFrame, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", spellListFrame, "BOTTOMRIGHT", -30, 0)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(320, 100)
    spellListFrame.Update = function()
        for _, child in ipairs({scrollChild:GetChildren()}) do
            child:Hide()
        end
        local yOffset = -5
        for spellID, spellName in pairs(db.enabledSpells) do
            local spellButton = CreateFrame("Button", nil, scrollChild)
            spellButton:SetPoint("TOP", 0, yOffset)
            spellButton:SetSize(320, 20)
            local removeButton = CreateFrame("Button", nil, spellButton, "UIPanelButtonTemplate")
            removeButton:SetPoint("LEFT", 0, 0)
            removeButton:SetSize(20, 20)
            removeButton:SetText("-")
            removeButton:SetScript("OnClick", function()
                db.enabledSpells[spellID] = nil
                spellListFrame:Update()
            end)
            local spellText = spellButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            spellText:SetPoint("LEFT", removeButton, "RIGHT", 5, 0)
            spellText:SetText(spellName)
            yOffset = yOffset - 25
        end
        scrollChild:SetHeight(-yOffset)
    end
    panel.spellList = spellListFrame

    panel:UpdateFlightSettings()
    return panel
end

local alternateState = {}
local function CreateIconCopy()
    local iconCopy = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    iconCopy:SetSize(db.size, db.size)
    iconCopy:SetPoint("CENTER", UIParent, "CENTER", db.startPoint.x, db.startPoint.y)
    iconCopy:SetFrameStrata("HIGH")
    iconCopy:SetAlpha((db.opacity or 100) / 100)

    local icon = iconCopy:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints()
    icon:SetTexture(iconTexture)

    local animationGroup = iconCopy:CreateAnimationGroup()
    local fadeIn = animationGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha((db.opacity or 100) / 100)
    fadeIn:SetDuration(0.5)

    local move = animationGroup:CreateAnimation("Translation")
    local xDistance, yDistance = 0, 0
    local smoothing = "OUT"

    local orderedDirections = {}
    for dir, order in pairs(db.directionOrder) do
        orderedDirections[order] = dir
    end

    local direction = "STRAIGHT"
    if next(orderedDirections) and spellID then
        alternateState[spellID] = (alternateState[spellID] or 0) % #orderedDirections + 1
        direction = orderedDirections[alternateState[spellID]] or "STRAIGHT"
    end

    if direction == "UP" then
        xDistance = math.random(-100, 100)
        yDistance = math.random(400, 800)
    elseif direction == "DOWN" then
        xDistance = math.random(-100, 100)
        yDistance = -math.random(400, 800)
    elseif direction == "LEFT" then
        xDistance = -math.random(400, 800)
        yDistance = math.random(-100, 100)
    elseif direction == "RIGHT" then
        xDistance = math.random(400, 800)
        yDistance = math.random(-100, 100)
    elseif direction == "LEFT_UP" then
        xDistance = -math.random(400, 800)
        yDistance = math.random(400, 800)
    elseif direction == "LEFT_DOWN" then
        xDistance = -math.random(400, 800)
        yDistance = -math.random(400, 800)
    elseif direction == "RIGHT_UP" then
        xDistance = math.random(400, 800)
        yDistance = math.random(400, 800)
    elseif direction == "RIGHT_DOWN" then
        xDistance = math.random(400, 800)
        yDistance = -math.random(400, 800)
    else
        local dir = math.random(0, 1) == 0 and -1 or 1
        xDistance = math.random(200, 800) * dir
        yDistance = math.random(-100, 100)
    end

    move:SetOffset(xDistance, yDistance)
    move:SetDuration((db.flightDuration or 20) / 10)
    move:SetSmoothing(smoothing)

    local fadeOut = animationGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha((db.opacity or 100) / 100)
    fadeOut:SetToAlpha(0)
    fadeOut:SetStartDelay(((db.flightDuration or 20) / 10) - ((db.fadeOutDuration or 25) / 100))
    fadeOut:SetDuration((db.fadeOutDuration or 25) / 100)

    animationGroup:SetScript("OnFinished", function() iconCopy:Hide() end)
    animationGroup:Play()
end

local function HandleAddonLoaded(panel)
    if not GCastDB then
        GCastDB = defaultDB
    else
        for k, v in pairs(defaultDB) do
            if GCastDB[k] == nil then
                GCastDB[k] = v
            elseif type(v) == "table" then
                for tk, tv in pairs(v) do
                    if GCastDB[k][tk] == nil then
                        GCastDB[k][tk] = tv
                    end
                end
            end
        end
    end
    db = GCastDB
    panel.spellList:Update()
    dottedFrame:ClearAllPoints()
    dottedFrame:SetPoint("CENTER", UIParent, "CENTER", db.startPoint.x, db.startPoint.y)
end

local function HandleCombatLog()
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, eventSpellID = CombatLogGetCurrentEventInfo()
    if eventType == "SPELL_CAST_SUCCESS" and sourceName == UnitName("player") and db.enabledSpells[eventSpellID] then
        iconTexture = C_Spell.GetSpellTexture(eventSpellID)
        spellID = eventSpellID
        CreateIconCopy()
    end
end

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        local panel = CreateSettingsPanel()
        HandleAddonLoaded(panel)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        HandleCombatLog()
    end
end)

-- Slash Command
SLASH_GCAST1 = "/gc"
SlashCmdList["GCAST"] = function()
    local panel = _G["GCastSettings"] or CreateSettingsPanel()
    panel:SetShown(not panel:IsShown())
    if panel:IsShown() and panel.spellList then
        panel.spellList:Update()
    end
end