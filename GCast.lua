local addonName = "GCast"
local _G = _G

local GCast = _G[addonName] or {}
_G[addonName] = GCast

GCast.Utils = GCast.Utils or {}
GCast.DB = GCast.DB or {}
GCast.Keybinds = GCast.Keybinds or {}
GCast.Debug = false

function GCast.Utils:CreateButton(parent, text, size, onClick)
    return GCast.SettingsUI:CreateControl(parent, "Button", "UIPanelButtonTemplate", size, nil, function(btn)
        btn:SetText(text)
        btn:SetScript("OnClick", onClick)
    end)
end

function GCast.Utils:CreateEditBox(parent, size, point, numeric, maxLetters, extras)
    return GCast.SettingsUI:CreateControl(parent, "EditBox", "InputBoxTemplate", size, point, function(edit)
        if numeric then edit:SetNumeric(true) end
        if maxLetters then edit:SetMaxLetters(maxLetters) end
        edit:SetAutoFocus(false)
        if extras then extras(edit) end
    end)
end

function GCast.Utils:Log(message, debugOnly)
    if not debugOnly or GCast.Debug then
        print("GCast Debug: " .. message)
    end
end

function GCast.Utils:GetSpellName(spellID)
    if not spellID or type(spellID) ~= "number" then return "Unknown Spell" end
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    return spellInfo and spellInfo.name or "Unknown Spell #" .. tostring(spellID)
end

GCast.ConfigRanges = {
    size = { min = 10, max = 100 },
    opacity = { min = 0, max = 100 },
    flightDuration = { min = 1, max = 100 },
    fadeOutDuration = { min = 1, max = 500 },
    waveAmplitude = { min = 5, max = 50 },
    zigzagAngle = { min = 5, max = 80 },
    textSize = { min = 6, max = 24 },
    xMargin = { min = -20, max = 20 },
    yMargin = { min = -20, max = 20 }
}

GCast.Config = {
    visualSettings = {
        size = { default = 50 },
        opacity = { default = 100 },
        flightDuration = { default = 20 },
        fadeOutDuration = { default = 25 },
    },
    keybindSettings = {
        textSize = { default = 14 },
        xMargin = { default = 4 },
        yMargin = { default = 4 }
    },
    flightEffectTypes = { straight = "Straight", wave = "Wave", zigzag = "Zigzag" }
}

local locale = GetLocale()
GCast.L = {
    ["GCast Settings"] = locale == "zhCN" and "GCast设置" or "GCast Settings",
    ["Visual Effects"] = locale == "zhCN" and "视觉效果" or "Visual Effects",
    ["Toggle Edit Mode"] = locale == "zhCN" and "编辑模式" or "Toggle Edit Mode",
    ["Exit Edit Mode"] = locale == "zhCN" and "退出编辑模式" or "Exit Edit Mode",
    ["Size"] = locale == "zhCN" and "图标尺寸" or "Size",
    ["Opacity"] = locale == "zhCN" and "透明程度" or "Opacity",
    ["Flight Duration"] = locale == "zhCN" and "飞行时间" or "Flight Duration",
    ["Fade-Out Duration"] = locale == "zhCN" and "淡出时间" or "Fade-Out Duration",
    ["Flight Directions"] = locale == "zhCN" and "飞行方向" or "Flight Directions",
    ["Flight Effect"] = locale == "zhCN" and "飞行特效" or "Flight Effect",
    ["Straight Line"] = locale == "zhCN" and "直线" or "Straight Line",
    ["Wave"] = locale == "zhCN" and "波浪" or "Wave",
    ["Wave Amplitude"] = locale == "zhCN" and "波浪幅度" or "Wave Amplitude",
    ["Zigzag"] = locale == "zhCN" and "折线" or "Zigzag",
    ["Zigzag Angle"] = locale == "zhCN" and "折线角度" or "Zigzag Angle",
    ["Visual Settings"] = locale == "zhCN" and "视觉设置" or "Visual Settings",
    ["Vertical"] = locale == "zhCN" and "垂直" or "Vertical",
    ["Horizontal"] = locale == "zhCN" and "水平" or "Horizontal",
    ["Diagonal"] = locale == "zhCN" and "对角" or "Diagonal",
    ["Up"] = locale == "zhCN" and "上" or "Up",
    ["Down"] = locale == "zhCN" and "下" or "Down",
    ["Left"] = locale == "zhCN" and "左" or "Left",
    ["Right"] = locale == "zhCN" and "右" or "Right",
    ["Left Up"] = locale == "zhCN" and "左上" or "Left Up",
    ["Left Down"] = locale == "zhCN" and "左下" or "Left Down",
    ["Right Up"] = locale == "zhCN" and "右上" or "Right Up",
    ["Right Down"] = locale == "zhCN" and "右下" or "Right Down",
    ["Add Spell"] = locale == "zhCN" and "添加技能" or "Add Spell",
    ["Spell List"] = locale == "zhCN" and "技能列表" or "Spell List",
    ["Cooldown Manager Keybinds"] = locale == "zhCN" and "冷却管理器按键" or "Cooldown Manager Keybinds",
    ["Show Keybinds"] = locale == "zhCN" and "显示按键绑定" or "Show Keybinds",
    ["Keybind Text Size"] = locale == "zhCN" and "按键绑定文字大小" or "Keybind Text Size",
    ["No Spells"] = locale == "zhCN" and "无技能" or "No Spells",
    ["Essential"] = locale == "zhCN" and "核心技能" or "Essential",
    ["Utility"] = locale == "zhCN" and "实用技能" or "Utility",
    ["X Margin"] = locale == "zhCN" and "X边距" or "X Margin",
    ["Y Margin"] = locale == "zhCN" and "Y边距" or "Y Margin",
    ["Position"] = locale == "zhCN" and "位置" or "Position",
    ["GCast Loaded. Type /gcast to open settings."] = locale == "zhCN" and "GCast已加载。输入 /gcast 打开设置。" or "GCast Loaded. Type /gcast to open settings.",
}

local defaultDB = {
    global = {
        visual = {
            size = 50,
            opacity = 100,
            flightDuration = 20,
            fadeOutDuration = 25,
            verticalDirections = { UP = false, DOWN = false },
            horizontalDirections = { LEFT = false, RIGHT = true },
            diagonalDirections = { LEFT_UP = false, LEFT_DOWN = false, RIGHT_UP = false, RIGHT_DOWN = false },
            directionOrder = { RIGHT = 1 },
            flightEffectType = "straight",
            waveAmplitude = 20,
            zigzagAngle = 30,
            lastDirectionIndex = 0
        },
        keybinds = {
            essential = { show = true, textSize = 14, xMargin = 4, yMargin = 4 },
            utility = { show = true, textSize = 14, xMargin = 4, yMargin = 4 }
        }
    },
    player = {
        visual = { startPoint = { x = 0, y = 0 }, enabledSpells = {}, editMode = false },
        keybinds = { essential = {}, utility = {}, manual = { essential = {}, utility = {} } }
    }
}

local function MergeConfig(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" then
            target[k] = target[k] or {}
            for k2, v2 in pairs(v) do
                if target[k][k2] == nil then
                    target[k][k2] = v2
                end
            end
        elseif target[k] == nil then
            target[k] = v
        end
    end
end

function GCast.DB:EnsureInitialized()
    if not GCast.db then
        self:Initialize()
    end
    if not GCast.db.global then GCast.db.global = {} end
    if not GCast.db.player then GCast.db.player = { visual = {} } end
    if not GCast.db.player.visual.enabledSpells or type(GCast.db.player.visual.enabledSpells) ~= "table" then
        GCast.db.player.visual.enabledSpells = {}
    end
end

function GCast.DB:Initialize()
    local _, playerClass = UnitClass("player")
    local currentSpec = GetSpecialization() or 0
    local playerKey = string.format("player_%s_%s", playerClass, currentSpec)

    GCastDB = GCastDB or { global = {}, players = {}, migrated = false }
    GCastDB.players[playerKey] = GCastDB.players[playerKey] or {}

    if not GCastDB.migrated and GCastDB.players[playerKey].visual and GCastDB.players[playerKey].visual.enabledSpells then
        local newSpells = {}
        local hasInvalid = false
        for spellID, spellName in pairs(GCastDB.players[playerKey].visual.enabledSpells) do
            if type(spellID) == "string" and type(spellName) == "string" and tonumber(spellID) then
                newSpells[spellID] = spellName
            else
                hasInvalid = true
                GCast.Utils:Log("Removed invalid enabledSpells entry: spellID=" .. tostring(spellID) .. ", spellName=" .. tostring(spellName))
            end
        end
        if hasInvalid then
            GCast.Utils:Log("Migrated enabledSpells")
            GCastDB.players[playerKey].visual.enabledSpells = newSpells
            GCastDB.migrated = true
        end
    end

    if type(GCastDB.players[playerKey].visual and GCastDB.players[playerKey].visual.enabledSpells) == "string" then
        local spells = {}
        for pair in GCastDB.players[playerKey].visual.enabledSpells:gmatch("([^;]+)") do
            local spellID, spellName = pair:match("([^:]+):([^:]+)")
            if spellID and spellName and tonumber(spellID) then
                spells[spellID] = spellName
            end
        end
        GCastDB.players[playerKey].visual.enabledSpells = spells
    end

    MergeConfig(GCastDB.global, defaultDB.global)
    MergeConfig(GCastDB.players[playerKey].visual, defaultDB.player.visual)

    GCast.playerName = UnitName("player") or "Unknown"
    GCast.playerClass = playerClass
    GCast.currentSpec = currentSpec

    GCast.db = {
        global = GCastDB.global,
        player = GCastDB.players[playerKey]
    }

    if not GCast.db.player.visual.enabledSpells or type(GCast.db.player.visual.enabledSpells) ~= "table" then
        GCast.db.player.visual.enabledSpells = {}
    end

    GCast:UpdateDirectionsCache()
    GCast.SettingsUI:InitDottedFrame()
    GCast:InitIconPool()
    local spellsStr = ""
    for k, v in pairs(GCast.db.player.visual.enabledSpells) do
        spellsStr = spellsStr .. k .. "=" .. v .. ", "
    end
    GCast.Utils:Log("Database initialized, enabledSpells=" .. (spellsStr == "" and "empty" or spellsStr))
end

function GCast.DB:SaveSettings()
    GCast.DB:EnsureInitialized()

    local function SaveDiff(target, source, default)
        local diff = {}
        for k, v in pairs(source) do
            if type(v) == "table" then
                local subDiff = SaveDiff(target[k] or {}, v, default[k] or {})
                if next(subDiff) then
                    diff[k] = subDiff
                end
            elseif v ~= default[k] then
                diff[k] = v
            end
        end
        return diff
    end

    GCastDB.global = SaveDiff({}, GCast.db.global, defaultDB.global)
    local playerKey = string.format("player_%s_%s", GCast.playerClass, GCast.currentSpec)
    local spellsStr = ""
    for spellID, spellName in pairs(GCast.db.player.visual.enabledSpells) do
        if type(spellID) == "string" and type(spellName) == "string" and tonumber(spellID) then
            spellsStr = spellsStr .. spellID .. ":" .. spellName .. ";"
        end
    end
    GCastDB.players[playerKey] = SaveDiff({}, GCast.db.player, defaultDB.player)
    GCastDB.players[playerKey].visual.enabledSpells = spellsStr

    GCast.Utils:Log("Saved settings, enabledSpells=" .. (spellsStr == "" and "empty" or spellsStr))
    return true
end

function GCast:UpdateConfig(key, value)
    local range = GCast.ConfigRanges[key]
    if range then
        value = math.max(range.min, math.min(range.max, value))
    end
    GCast.db.global.visual[key] = value
    if key == "size" and GCast.dottedFrame then
        GCast.dottedFrame:SetSize(value, value)
    end
end

function GCast:UpdateDirectionsCache()
    local directions = {}
    local config = GCast.db.global
    local debugStr = ""
    if config.verticalDirections then
        if config.verticalDirections.UP then
            table.insert(directions, { key = "UP", order = config.directionOrder.UP or 999, offset = { x = 0, y = 300 } })
            debugStr = debugStr .. "UP (order=" .. (config.directionOrder.UP or 999) .. "), "
        end
        if config.verticalDirections.DOWN then
            table.insert(directions, { key = "DOWN", order = config.directionOrder.DOWN or 999, offset = { x = 0, y = -300 } })
            debugStr = debugStr .. "DOWN (order=" .. (config.directionOrder.DOWN or 999) .. "), "
        end
    end
    if config.horizontalDirections then
        if config.horizontalDirections.LEFT then
            table.insert(directions, { key = "LEFT", order = config.directionOrder.LEFT or 999, offset = { x = -300, y = 0 } })
            debugStr = debugStr .. "LEFT (order=" .. (config.directionOrder.LEFT or 999) .. "), "
        end
        if config.horizontalDirections.RIGHT then
            table.insert(directions, { key = "RIGHT", order = config.directionOrder.RIGHT or 999, offset = { x = 300, y = 0 } })
            debugStr = debugStr .. "RIGHT (order=" .. (config.directionOrder.RIGHT or 999) .. "), "
        end
    end
    if config.diagonalDirections then
        if config.diagonalDirections.LEFT_UP then
            table.insert(directions, { key = "LEFT_UP", order = config.directionOrder.LEFT_UP or 999, offset = { x = -300, y = 300 } })
            debugStr = debugStr .. "LEFT_UP (order=" .. (config.directionOrder.LEFT_UP or 999) .. "), "
        end
        if config.diagonalDirections.LEFT_DOWN then
            table.insert(directions, { key = "LEFT_DOWN", order = config.directionOrder.LEFT_DOWN or 999, offset = { x = -300, y = -300 } })
            debugStr = debugStr .. "LEFT_DOWN (order=" .. (config.directionOrder.LEFT_DOWN or 999) .. "), "
        end
        if config.diagonalDirections.RIGHT_UP then
            table.insert(directions, { key = "RIGHT_UP", order = config.directionOrder.RIGHT_UP or 999, offset = { x = 300, y = 300 } })
            debugStr = debugStr .. "RIGHT_UP (order=" .. (config.directionOrder.RIGHT_UP or 999) .. "), "
        end
        if config.diagonalDirections.RIGHT_DOWN then
            table.insert(directions, { key = "RIGHT_DOWN", order = config.directionOrder.RIGHT_DOWN or 999, offset = { x = 300, y = -300 } })
            debugStr = debugStr .. "RIGHT_DOWN (order=" .. (config.directionOrder.RIGHT_DOWN or 999) .. "), "
        end
    end
    if #directions == 0 then
        table.insert(directions, { key = "RIGHT", order = 1, offset = { x = 300, y = 0 } })
        debugStr = debugStr .. "RIGHT (default, order=1), "
    end
    table.sort(directions, function(a, b) return a.order < b.order end)
    config.directionsCache = directions
    if GCast.Debug and debugStr ~= "" then
        GCast.Utils:Log("Added directions: " .. debugStr)
    end
end

GCast.AnimTemplates = {
    fadeInOut = function(group)
        local fadeIn = group:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.5)
        fadeIn:SetOrder(1)

        local move = group:CreateAnimation("Translation")
        move:SetSmoothing("OUT")
        move:SetOrder(2)

        local fadeOut = group:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)
        fadeOut:SetOrder(3)

        return { fadeIn = fadeIn, move = move, fadeOut = fadeOut }
    end
}

function GCast:CreateIconFrame()
    local iconCopy = CreateFrame("Frame", nil, UIParent)
    iconCopy:SetFrameStrata("HIGH")
    iconCopy.icon = iconCopy:CreateTexture(nil, "OVERLAY")
    iconCopy.icon:SetAllPoints()
    
    local ag = iconCopy:CreateAnimationGroup()
    local animations = GCast.AnimTemplates.fadeInOut(ag)
    if not animations or not animations.fadeIn or not animations.move or not animations.fadeOut then
        error("Failed to create animations for template: fadeInOut")
    end
    iconCopy.animationGroup = ag
    iconCopy.animations = animations
    
    return iconCopy
end

function GCast:InitIconPool()
    GCast.iconPool = GCast.iconPool or { used = {}, free = {} }
    for i = 1, 10 do
        table.insert(GCast.iconPool.free, self:CreateIconFrame())
    end
end

function GCast:AcquireIcon()
    local iconCopy
    if #GCast.iconPool.free > 0 then
        iconCopy = table.remove(GCast.iconPool.free)
    else
        iconCopy = self:CreateIconFrame()
    end

    if iconCopy.animationGroup:IsPlaying() then
        iconCopy.animationGroup:Stop()
    end

    if not iconCopy.animations or not iconCopy.animations.fadeIn or not iconCopy.animations.move or not iconCopy.animations.fadeOut then
        GCast.Utils:Log("Invalid animation group, recreating...")
        local ag = iconCopy:CreateAnimationGroup()
        local animations = GCast.AnimTemplates.fadeInOut(ag)
        if not animations or not animations.fadeIn or not animations.move or not animations.fadeOut then
            error("Failed to create animations for template: fadeInOut")
        end
        iconCopy.animationGroup = ag
        iconCopy.animations = animations
    end

    table.insert(GCast.iconPool.used, iconCopy)
    GCast.Utils:Log("Acquired icon for animation, used=" .. #GCast.iconPool.used .. ", free=" .. #GCast.iconPool.free, true)
    return iconCopy
end

function GCast:ReleaseIcon(iconCopy)
    iconCopy:Hide()
    iconCopy:ClearAllPoints()
    if iconCopy.animationGroup then
        iconCopy.animationGroup:Stop()
    end
    for i, usedIcon in ipairs(GCast.iconPool.used) do
        if usedIcon == iconCopy then
            table.remove(GCast.iconPool.used, i)
            break
        end
    end
    table.insert(GCast.iconPool.free, iconCopy)
    GCast.Utils:Log("Released icon, used=" .. #GCast.iconPool.used .. ", free=" .. #GCast.iconPool.free, true)
end

function GCast:SelectDirection(config)
    local directions = config.global.directionsCache
    config.global.lastDirectionIndex = (config.global.lastDirectionIndex or 0) % #directions + 1
    local direction = directions[config.global.lastDirectionIndex]
    GCast.Utils:Log("Selected direction: " .. direction.key .. ", order: " .. direction.order .. ", index: " .. config.global.lastDirectionIndex, true)
    return direction
end

function GCast:ApplyFlightEffect(direction, flightEffectType, waveAmplitude, zigzagAngle)
    local offsetX, offsetY = direction.offset.x, direction.offset.y
    if flightEffectType == "wave" then
        local isVertical = (direction.key == "UP" or direction.key == "DOWN")
        local isLeftDirection = (direction.key:find("LEFT") ~= nil)
        local isUpDirection = (direction.key:find("UP") ~= nil)
        local waveX = isVertical and (waveAmplitude * (isLeftDirection and -1 or 1)) or 0
        local waveY = not isVertical and (waveAmplitude * (isUpDirection and 1 or -1)) or 0
        offsetX = offsetX + waveX
        offsetY = offsetY + waveY
        if GCast.Debug then
            GCast.Utils:Log("Applied wave effect: waveX=" .. waveX .. ", waveY=" .. waveY)
        end
    elseif flightEffectType == "zigzag" then
        local rad = math.rad(zigzagAngle)
        local zigX = math.cos(rad) * direction.offset.x - math.sin(rad) * direction.offset.y
        local zigY = math.sin(rad) * direction.offset.x + math.cos(rad) * direction.offset.y
        offsetX = direction.offset.x + (zigX - direction.offset.x) * 0.3
        offsetY = direction.offset.y + (zigY - direction.offset.y) * 0.3
        if GCast.Debug then
            GCast.Utils:Log("Applied zigzag effect: zigX=" .. offsetX .. ", zigY=" .. offsetY)
        end
    end
    return offsetX, offsetY
end

function GCast:SetupIconAnimation(iconCopy, direction, config, spellID)
    local flightDuration = config.global.flightDuration or 20
    local fadeOutDuration = config.global.flightDuration or 25
    local flightEffectType = config.global.flightEffectType or "straight"
    local waveAmplitude = config.global.waveAmplitude or 20
    local zigzagAngle = config.global.zigzagAngle or 30

    local animations = iconCopy.animations
    if not animations or not animations.move or not animations.fadeOut then
        GCast.Utils:Log("Invalid animations for spellID: " .. tostring(spellID))
        local ag = iconCopy:CreateAnimationGroup()
        local newAnimations = GCast.AnimTemplates.fadeInOut(ag)
        if not newAnimations or not newAnimations.fadeIn or not newAnimations.move or not newAnimations.fadeOut then
            error("Failed to create animations for template: fadeInOut")
        end
        iconCopy.animationGroup = ag
        iconCopy.animations = newAnimations
        animations = iconCopy.animations
    end

    local move = animations.move
    local fadeOut = animations.fadeOut

    move:SetDuration(flightDuration / 10)
    local offsetX, offsetY = self:ApplyFlightEffect(direction, flightEffectType, waveAmplitude, zigzagAngle)
    move:SetOffset(offsetX, offsetY)
    fadeOut:SetDuration(fadeOutDuration / 100)
end

function GCast:GenerateFlyingIcon(iconTexture, spellID, config)
    if not iconTexture or not config.global or not config.player then
        GCast.Utils:Log("Invalid parameters for GenerateFlyingIcon")
        return
    end

    local iconCopy = self:AcquireIcon()
    if not iconCopy then
        GCast.Utils:Log("Failed to acquire icon for spell ID " .. tostring(spellID))
        return
    end

    local size = config.global.size or 50
    local opacity = (config.global.opacity or 100) / 100
    local startPoint = config.player.startPoint or { x = 0, y = 0 }

    iconCopy:SetSize(size, size)
    iconCopy:SetPoint("CENTER", UIParent, "CENTER", startPoint.x, startPoint.y)
    iconCopy:SetAlpha(opacity)
    iconCopy.icon:SetTexture(iconTexture)

    local direction = self:SelectDirection(config)
    self:SetupIconAnimation(iconCopy, direction, config, spellID)

    iconCopy:Show()
    if iconCopy.animationGroup:IsPlaying() then
        iconCopy.animationGroup:Stop()
    end
    iconCopy.animationGroup:Play()
    GCast.Utils:Log("Animation started for spell ID " .. tostring(spellID) .. ", effect=" .. config.global.flightEffectType, true)

    iconCopy.animationGroup:SetScript("OnFinished", function()
        GCast.Utils:Log("Animation finished for spell ID " .. tostring(spellID), true)
        self:ReleaseIcon(iconCopy)
    end)
end

local KeybindManager = GCast.Keybinds

function KeybindManager:Initialize()
    local currentSpec = GetSpecialization() or 0
    GCast.DB:EnsureInitialized()
    local playerKey = string.format("player_%s_%s", GCast.playerClass, currentSpec)

    GCastDB.players[playerKey].keybinds = GCastDB.players[playerKey].keybinds or {}
    MergeConfig(GCastDB.players[playerKey].keybinds, defaultDB.player.keybinds)

    self.current = {
        essential = {
            show = GCast.db.global.keybinds.essential.show or true,
            textSize = GCast.db.global.keybinds.essential.textSize or GCast.Config.keybindSettings.textSize.default,
            xMargin = GCast.db.global.keybinds.essential.xMargin or GCast.Config.keybindSettings.xMargin.default,
            yMargin = GCast.db.global.keybinds.essential.yMargin or GCast.Config.keybindSettings.yMargin.default,
            bindings = GCast.db.player.keybinds.essential or {},
            manual = GCast.db.player.keybinds.manual.essential or {}
        },
        utility = {
            show = GCast.db.global.keybinds.utility.show or true,
            textSize = GCast.db.global.keybinds.utility.textSize or GCast.Config.keybindSettings.textSize.default,
            xMargin = GCast.db.global.keybinds.utility.xMargin or GCast.Config.keybindSettings.xMargin.default,
            yMargin = GCast.db.global.keybinds.utility.yMargin or GCast.Config.keybindSettings.yMargin.default,
            bindings = GCast.db.player.keybinds.utility or {},
            manual = GCast.db.player.keybinds.manual.utility or {}
        }
    }

    GCast.currentClassCooldownManager = {
        layoutSettings = {
            essential = {
                showKeybinds = self.current.essential.show,
                keybindTextSize = self.current.essential.textSize,
                xMargin = self.current.essential.xMargin,
                yMargin = self.current.essential.yMargin,
                customKeybinds = self.current.essential.bindings,
                isManual = self.current.essential.manual
            },
            utility = {
                showKeybinds = self.current.utility.show,
                keybindTextSize = self.current.utility.textSize,
                xMargin = self.current.utility.xMargin,
                yMargin = self.current.utility.yMargin,
                customKeybinds = self.current.utility.bindings,
                isManual = self.current.utility.manual
            }
        },
        syncGlobalSettings = function() self:SyncFromDB() end,
        saveGlobalSettings = function() self:SaveToDB() end
    }

    self.cache = {
        bindings = {},
        lastUpdate = GetTime()
    }

    if self.current.essential.bindings then
        for spellID, binding in pairs(self.current.essential.bindings) do
            self.cache.bindings[spellID] = binding
        end
    end

    if self.current.utility.bindings then
        for spellID, binding in pairs(self.current.utility.bindings) do
            self.cache.bindings[spellID] = binding
        end
    end

    return self.current
end

function KeybindManager:SyncFromDB()
    self.current.essential.show = GCast.db.global.keybinds.essential.show or self.current.essential.show
    self.current.essential.textSize = GCast.db.global.keybinds.essential.textSize or self.current.essential.textSize
    self.current.essential.xMargin = GCast.db.global.keybinds.essential.xMargin or self.current.essential.xMargin
    self.current.essential.yMargin = GCast.db.global.keybinds.essential.yMargin or self.current.essential.yMargin

    self.current.utility.show = GCast.db.global.keybinds.utility.show or self.current.utility.show
    self.current.utility.textSize = GCast.db.global.keybinds.utility.textSize or self.current.utility.textSize
    self.current.utility.xMargin = GCast.db.global.keybinds.utility.xMargin or self.current.utility.xMargin
    self.current.utility.yMargin = GCast.db.global.keybinds.utility.yMargin or self.current.utility.yMargin

    GCast.currentClassCooldownManager.layoutSettings.essential.showKeybinds = self.current.essential.show
    GCast.currentClassCooldownManager.layoutSettings.essential.keybindTextSize = self.current.essential.textSize
    GCast.currentClassCooldownManager.layoutSettings.essential.xMargin = self.current.essential.xMargin
    GCast.currentClassCooldownManager.layoutSettings.essential.yMargin = self.current.essential.yMargin

    GCast.currentClassCooldownManager.layoutSettings.utility.showKeybinds = self.current.utility.show
    GCast.currentClassCooldownManager.layoutSettings.utility.keybindTextSize = self.current.utility.textSize
    GCast.currentClassCooldownManager.layoutSettings.utility.xMargin = self.current.utility.xMargin
    GCast.currentClassCooldownManager.layoutSettings.utility.yMargin = self.current.utility.yMargin

    self.cache.lastUpdate = GetTime()
end

function KeybindManager:SaveToDB()
    GCast.db.global.keybinds.essential.show = self.current.essential.show
    GCast.db.global.keybinds.essential.textSize = self.current.essential.textSize
    GCast.db.global.keybinds.essential.xMargin = self.current.essential.xMargin
    GCast.db.global.keybinds.essential.yMargin = self.current.essential.yMargin

    GCast.db.global.keybinds.utility.show = self.current.utility.show
    GCast.db.global.keybinds.utility.textSize = self.current.utility.textSize
    GCast.db.global.keybinds.utility.xMargin = self.current.utility.xMargin
    GCast.db.global.keybinds.utility.yMargin = self.current.utility.yMargin
end

function KeybindManager:SetSpellBinding(spellID, binding, category)
    if not spellID or not binding then return end
    local categoryName = category == 1 and "utility" or "essential"
    local idStr = tostring(spellID)

    self.current[categoryName].bindings[idStr] = binding
    self.current[categoryName].manual[idStr] = true
    self.cache.bindings[idStr] = binding
    self.cache.lastUpdate = GetTime()

    GCast.db.player.keybinds[categoryName][idStr] = binding
    GCast.db.player.keybinds.manual[categoryName][idStr] = true

    local settings = GCast.currentClassCooldownManager.layoutSettings[categoryName]
    settings.customKeybinds[idStr] = binding
    settings.isManual[idStr] = true
end

function KeybindManager:ClearSpellBinding(spellID, category)
    if not spellID then return end
    local categoryName = category == 1 and "utility" or "essential"
    local idStr = tostring(spellID)

    self.current[categoryName].bindings[idStr] = nil
    self.current[categoryName].manual[idStr] = nil
    self.cache.bindings[idStr] = nil
    self.cache.lastUpdate = GetTime()

    if GCast.db.player.keybinds[categoryName] then
        GCast.db.player.keybinds[categoryName][idStr] = nil
    end
    if GCast.db.player.keybinds.manual[categoryName] then
        GCast.db.player.keybinds.manual[categoryName][idStr] = nil
    end

    local settings = GCast.currentClassCooldownManager.layoutSettings[categoryName]
    settings.customKeybinds[idStr] = nil
    settings.isManual[idStr] = nil
end

function KeybindManager:UpdateOverlays(targetCategory)
    if InCombatLockdown() then return end
    self.cache = self.cache or { bindings = {}, lastUpdate = GetTime() }
    GCast:UpdateKeybindOverlays(targetCategory)
    self.cache.lastUpdate = GetTime()
end

function KeybindManager:RefreshAll()
    if InCombatLockdown() then return end
    local viewerTypes = { "EssentialCooldownViewer", "UtilityCooldownViewer" }
    for _, viewerName in ipairs(viewerTypes) do
        local viewer = _G[viewerName]
        if viewer and viewer.RefreshLayout and type(viewer.RefreshLayout) == "function" then
            viewer:RefreshLayout()
        end
    end
    self:UpdateOverlays()
end

function GCast:UpdateKeybindOverlays(targetCategory)
    if not self.currentClassCooldownManager then
        self:InitializeCooldownManager()
    end

    self.keybindOverlays = self.keybindOverlays or {}
    if targetCategory == nil then
        for _, overlay in ipairs(self.keybindOverlays) do
            if overlay then overlay:Hide() end
        end
        self.keybindOverlays = {}
    else
        local newOverlays = {}
        for _, overlay in ipairs(self.keybindOverlays) do
            if overlay and overlay.category ~= targetCategory then
                table.insert(newOverlays, overlay)
            elseif overlay then
                overlay:Hide()
            end
        end
        self.keybindOverlays = newOverlays
    end

    local viewerTypes = { "EssentialCooldownViewer", "UtilityCooldownViewer" }
    for i, viewerName in ipairs(viewerTypes) do
        local viewer = _G[viewerName]
        if viewer then
            local category = i - 1
            if targetCategory == nil or targetCategory == category then
                local categoryName = category == 0 and "essential" or "utility"
                local settings = self.currentClassCooldownManager.layoutSettings[categoryName]
                if not settings then return end

                for _, btn in ipairs({ viewer:GetChildren() }) do
                    local spellID
                    if btn._spellID then
                        spellID = tostring(btn._spellID)
                    elseif btn.GetCooldownID and type(btn.GetCooldownID) == "function" then
                        local cooldownID = btn:GetCooldownID()
                        if cooldownID then
                            local info = C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
                            spellID = info and tostring(info.spellID)
                        end
                    end

                    if spellID and settings.showKeybinds then
                        local keybindText = settings.customKeybinds[spellID]
                        if keybindText and keybindText ~= "" then
                            local overlay = CreateFrame("Frame", nil, UIParent)
                            overlay:SetSize(btn:GetWidth(), btn:GetHeight())
                            overlay:SetPoint("CENTER", btn, "CENTER")
                            overlay:SetFrameStrata("TOOLTIP")
                            overlay.category = category

                            local text = overlay:CreateFontString(nil, "OVERLAY")
                            text:SetPoint("CENTER", overlay, "CENTER", settings.xMargin, settings.yMargin)
                            text:SetFont("Fonts\\FRIZQT__.TTF", settings.keybindTextSize, "OUTLINE")
                            text:SetText(keybindText)
                            text:SetTextColor(1, 1, 1, 1)
                            text:SetShadowColor(0, 0, 0, 1)
                            text:SetShadowOffset(1.5, -1.5)

                            overlay.text = text
                            overlay:Show()
                            table.insert(self.keybindOverlays, overlay)
                        end
                    end
                end
            end
        end
    end
end

function GCast:InitializeCooldownManager()
    GCast.DB:EnsureInitialized()
    if self.Keybinds.Initialize then
        self.Keybinds:Initialize()
    end
    if not self.currentClassCooldownManager then
        self.currentClassCooldownManager = {
            layoutSettings = {
                essential = {
                    showKeybinds = true,
                    keybindTextSize = self.Config.keybindSettings.textSize.default,
                    xMargin = self.Config.keybindSettings.xMargin.default,
                    yMargin = self.Config.keybindSettings.yMargin.default,
                    customKeybinds = {},
                    isManual = {}
                },
                utility = {
                    showKeybinds = true,
                    keybindTextSize = self.Config.keybindSettings.textSize.default,
                    xMargin = self.Config.keybindSettings.xMargin.default,
                    yMargin = self.Config.keybindSettings.yMargin.default,
                    customKeybinds = {},
                    isManual = {}
                }
            },
            syncGlobalSettings = function() self.Keybinds:SyncFromDB() end,
            saveGlobalSettings = function() self.Keybinds:SaveToDB() end
        }
    end
end

function GCast:ProcessCombatLog()
    local _, eventType, _, _, sourceName, _, _, _, _, _, _, eventSpellID = CombatLogGetCurrentEventInfo()
    if eventType == "SPELL_CAST_SUCCESS" and sourceName == GCast.playerName then
        GCast.DB:EnsureInitialized()
        local spellIDStr = tostring(eventSpellID)
        local spellsStr = ""
        for k, v in pairs(GCast.db.player.visual.enabledSpells) do
            spellsStr = spellsStr .. k .. "=" .. v .. ", "
        end
        GCast.Utils:Log("Processing spell ID " .. spellIDStr .. ", enabledSpells=" .. (spellsStr == "" and "empty" or spellsStr), true)
        if GCast.db.player.visual.enabledSpells[spellIDStr] then
            local iconTexture = C_Spell.GetSpellTexture(eventSpellID)
            if iconTexture then
                GCast.Utils:Log("Triggering flying icon for spell ID " .. spellIDStr .. " (" .. GCast.Utils:GetSpellName(eventSpellID) .. ")", true)
                GCast:GenerateFlyingIcon(iconTexture, eventSpellID, { global = GCast.db.global.visual, player = GCast.db.player.visual })
            else
                GCast.Utils:Log("No texture for spell ID " .. spellIDStr)
            end
        else
            GCast.Utils:Log("Spell ID " .. spellIDStr .. " not in enabledSpells", true)
        end
    end
end

GCast.Events = {
    ["ADDON_LOADED"] = function(addon)
        if addon == addonName then
            GCast.DB:Initialize()
            GCast:InitializeCooldownManager()
        end
    end,
    ["PLAYER_LOGIN"] = function()
        GCast:InitializeCooldownManager()
        GCast.Keybinds:UpdateOverlays()
    end,
    ["PLAYER_SPECIALIZATION_CHANGED"] = function()
        GCast:InitializeCooldownManager()
        GCast.Keybinds:UpdateOverlays()
        local content = _G["GCastTabContent2"]
        if content and content.Update then
            content:Update()
        end
    end,
    ["COMBAT_LOG_EVENT_UNFILTERED"] = function() GCast:ProcessCombatLog() end
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, ...)
    local handler = GCast.Events[event]
    if handler then handler(...) end
end)

SLASH_GCAST1 = "/gc"
SlashCmdList["GCAST"] = function(msg)
    if string.lower(msg) == "" then
        if not UIParent then
            GCast.Utils:Log("Delaying settings UI creation until PLAYER_LOGIN")
            return
        end
        GCast.SettingsUI:ToggleSettingsUI()
    end
end
