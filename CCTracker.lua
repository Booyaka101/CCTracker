-- ======================== INTERRUPT LOCKOUTS ========================

local INTERRUPT_SPELLS = {
    -- [spellName] = { duration, icon, colorR, colorG, colorB }
    ["Counterspell"]        = { 4,   "Interface\\Icons\\Spell_Frost_IceShock", 0.2, 0.6, 1.0 },
    ["Kick"]                = { 5,   "Interface\\Icons\\Ability_Kick", 1.0, 0.7, 0.2 },
    ["Pummel"]              = { 4,   "Interface\\Icons\\Ability_Kick", 1.0, 0.7, 0.2 },
    ["Spell Lock"]          = { 3,   "Interface\\Icons\\Spell_Shadow_MindRot", 0.7, 0.2, 1.0 },
    ["Mind Freeze"]         = { 4,   "Interface\\Icons\\Spell_DeathKnight_MindFreeze", 0.2, 0.8, 1.0 },
    ["Silencing Shot"]      = { 3,   "Interface\\Icons\\Ability_TheBlackArrow", 0.7, 0.3, 1.0 },
    ["Shield Bash"]         = { 6,   "Interface\\Icons\\Ability_Warrior_ShieldBash", 1.0, 0.7, 0.2 },
    ["Earth Shock"]         = { 2,   "Interface\\Icons\\Spell_Nature_EarthShock", 1.0, 0.8, 0.2 },
    ["Wind Shear"]          = { 2,   "Interface\\Icons\\Spell_Nature_Cyclone", 0.2, 1.0, 0.8 },
    ["Arcane Torrent"]      = { 2,   "Interface\\Icons\\Spell_Shadow_Teleport", 0.7, 0.3, 1.0 },
    -- Add more as needed for Ascension
}

local INTERRUPT_FALLBACK_DURATION = 4
local INTERRUPT_FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Interrupt helper functions are declared later, after the frame pool and
-- settings helpers are available. This keeps the lockout path reliable.

-- CCTracker.lua - Lightweight CC/Silence/Interrupt tracker for 3.3.5a Ascension
-- Shows icon + timer bar for each active crowd control effect on the player.
-- Classless-aware: covers all WotLK CC abilities from every class.

-- ======================== SAVED VARIABLES ========================

CCTrackerDB = CCTrackerDB or {}

-- ======================== DEFAULTS ========================

local DEFAULTS = {
    iconSize     = 36,
    barWidth     = 140,
    barHeight    = 14,
    spacing      = 4,
    growUp       = true,
    scale        = 1.0,
    locked       = true,
    showLabels   = true,   -- category text above icon
    showSpiral   = true,   -- cooldown spiral on icon
    showIcons    = true,   -- show/hide spell icons
    showCategory = false,  -- show category label instead of spell name
    -- position (nil = center)
    point    = nil,
    relPoint = nil,
    x        = nil,
    y        = nil,
    -- category toggles (all on by default)
    trackSTUN      = true,
    trackSILENCE   = true,
    trackFEAR      = true,
    trackROOT      = true,
    trackINCAP     = true,
    trackDISARM         = true,
    trackINTERRUPT      = true,
    showDR              = true,
    pvpOnly             = false,
    debug               = false,
    spiralManualDisable = false,
}

local function GetSetting(key)
    local v = CCTrackerDB[key]
    if v == nil then return DEFAULTS[key] end
    return v
end

local function SetSetting(key, value)
    if value == DEFAULTS[key] then
        CCTrackerDB[key] = nil -- save space: nil = default
    else
        CCTrackerDB[key] = value
    end
end

local function IsPvPContext()
    local _, instanceType = IsInInstance()
    return instanceType == "arena" or instanceType == "pvp" or UnitIsPVP("player")
end

local function ShouldTrackNow()
    return not GetSetting("pvpOnly") or IsPvPContext()
end

-- ======================== CC SPELL DATABASE ========================
-- Ascension is classless so any player can have any ability.
-- Format: [spellName] = { category, r, g, b }

local CC_SPELLS = {
    -- ====== STUNS ======
    ["Hammer of Justice"]       = { "STUN", 1.0, 0.3, 0.3 },
    ["Kidney Shot"]             = { "STUN", 1.0, 0.3, 0.3 },
    ["Cheap Shot"]              = { "STUN", 1.0, 0.3, 0.3 },
    ["Bash"]                    = { "STUN", 1.0, 0.3, 0.3 },
    ["Maim"]                    = { "STUN", 1.0, 0.3, 0.3 },
    ["Pounce"]                  = { "STUN", 1.0, 0.3, 0.3 },
    ["Intercept"]               = { "STUN", 1.0, 0.3, 0.3 },
    ["Charge Stun"]             = { "STUN", 1.0, 0.3, 0.3 },
    ["Concussion Blow"]         = { "STUN", 1.0, 0.3, 0.3 },
    ["Shockwave"]               = { "STUN", 1.0, 0.3, 0.3 },
    ["Shadowfury"]              = { "STUN", 1.0, 0.3, 0.3 },
    ["Impact"]                  = { "STUN", 1.0, 0.3, 0.3 },
    ["Intimidation"]            = { "STUN", 1.0, 0.3, 0.3 },
    ["War Stomp"]               = { "STUN", 1.0, 0.3, 0.3 },
    ["Gnaw"]                    = { "STUN", 1.0, 0.3, 0.3 },
    ["Holy Wrath"]              = { "STUN", 1.0, 0.3, 0.3 },
    ["Stoneclaw Stun"]          = { "STUN", 1.0, 0.3, 0.3 },
    ["Deep Freeze"]             = { "STUN", 1.0, 0.3, 0.3 },

    -- ====== SILENCES ======
    ["Silencing Shot"]          = { "SILENCE", 0.7, 0.3, 1.0 },
    ["Counterspell - Silenced"] = { "SILENCE", 0.7, 0.3, 1.0 },
    ["Spell Lock"]              = { "SILENCE", 0.7, 0.3, 1.0 },
    ["Silence"]                 = { "SILENCE", 0.7, 0.3, 1.0 },
    ["Strangulate"]             = { "SILENCE", 0.7, 0.3, 1.0 },
    ["Arcane Torrent"]          = { "SILENCE", 0.7, 0.3, 1.0 },
    ["Garrote - Silence"]       = { "SILENCE", 0.7, 0.3, 1.0 },
    ["Nether Shock"]            = { "SILENCE", 0.7, 0.3, 1.0 },
    ["Improved Counterspell"]   = { "SILENCE", 0.7, 0.3, 1.0 },
    ["Improved Kick"]           = { "SILENCE", 0.7, 0.3, 1.0 },
    ["Shield of the Templar"]   = { "SILENCE", 0.7, 0.3, 1.0 },

    -- ====== FEARS ======
    ["Fear"]                    = { "FEAR", 1.0, 0.8, 0.2 },
    ["Psychic Scream"]          = { "FEAR", 1.0, 0.8, 0.2 },
    ["Intimidating Shout"]      = { "FEAR", 1.0, 0.8, 0.2 },
    ["Howl of Terror"]          = { "FEAR", 1.0, 0.8, 0.2 },
    ["Death Coil"]              = { "FEAR", 1.0, 0.8, 0.2 },
    ["Turn Evil"]               = { "FEAR", 1.0, 0.8, 0.2 },
    ["Scare Beast"]             = { "FEAR", 1.0, 0.8, 0.2 },

    -- ====== ROOTS ======
    ["Entangling Roots"]        = { "ROOT", 0.3, 0.8, 0.3 },
    ["Frost Nova"]              = { "ROOT", 0.3, 0.8, 0.3 },
    ["Frostbite"]               = { "ROOT", 0.3, 0.8, 0.3 },
    ["Earthbind"]               = { "ROOT", 0.3, 0.8, 0.3 },
    ["Shattered Barrier"]       = { "ROOT", 0.3, 0.8, 0.3 },
    ["Pin"]                     = { "ROOT", 0.3, 0.8, 0.3 },
    ["Web"]                     = { "ROOT", 0.3, 0.8, 0.3 },
    ["Freeze"]                  = { "ROOT", 0.3, 0.8, 0.3 },
    ["Chains of Ice"]           = { "ROOT", 0.3, 0.8, 0.3 },
    ["Desecration"]             = { "ROOT", 0.3, 0.8, 0.3 },

    -- ====== INCAPACITATES (Poly/Sap/Blind/etc) ======
    ["Polymorph"]               = { "INCAP", 0.4, 0.7, 1.0 },
    ["Polymorph: Sheep"]        = { "INCAP", 0.4, 0.7, 1.0 },
    ["Polymorph: Pig"]          = { "INCAP", 0.4, 0.7, 1.0 },
    ["Polymorph: Turtle"]       = { "INCAP", 0.4, 0.7, 1.0 },
    ["Hex"]                     = { "INCAP", 0.4, 0.7, 1.0 },
    ["Sap"]                     = { "INCAP", 0.4, 0.7, 1.0 },
    ["Gouge"]                   = { "INCAP", 0.4, 0.7, 1.0 },
    ["Blind"]                   = { "INCAP", 0.4, 0.7, 1.0 },
    ["Repentance"]              = { "INCAP", 0.4, 0.7, 1.0 },
    ["Wyvern Sting"]            = { "INCAP", 0.4, 0.7, 1.0 },
    ["Freezing Trap Effect"]    = { "INCAP", 0.4, 0.7, 1.0 },
    ["Freezing Arrow Effect"]   = { "INCAP", 0.4, 0.7, 1.0 },
    ["Cyclone"]                 = { "INCAP", 0.4, 0.7, 1.0 },
    ["Hibernate"]               = { "INCAP", 0.4, 0.7, 1.0 },
    ["Shackle Undead"]          = { "INCAP", 0.4, 0.7, 1.0 },
    ["Hungering Cold"]          = { "INCAP", 0.4, 0.7, 1.0 },

    -- ====== DISARMS ======
    ["Disarm"]                  = { "DISARM", 1.0, 0.6, 0.2 },
    ["Dismantle"]               = { "DISARM", 1.0, 0.6, 0.2 },
    ["Psychic Horror"]          = { "DISARM", 1.0, 0.6, 0.2 },
    ["Snatch"]                  = { "DISARM", 1.0, 0.6, 0.2 },
}

-- Category labels for display
local CATEGORY_LABELS = {
    STUN      = "STUNNED",
    SILENCE   = "SILENCED",
    FEAR      = "FEARED",
    ROOT      = "ROOTED",
    INCAP     = "INCAP",
    DISARM    = "DISARMED",
    INTERRUPT = "LOCKOUT",
    DR        = "DIMINISHING",
}

-- Category colors for the config UI swatches
local CATEGORY_COLORS = {
    STUN      = { 1.0, 0.3, 0.3 },
    SILENCE   = { 0.7, 0.3, 1.0 },
    FEAR      = { 1.0, 0.8, 0.2 },
    ROOT      = { 0.3, 0.8, 0.3 },
    INCAP     = { 0.4, 0.7, 1.0 },
    DISARM    = { 1.0, 0.6, 0.2 },
    INTERRUPT = { 0.2, 1.0, 1.0 },
    DR        = { 1.0, 0.82, 0.2 },
}

-- ======================== FRAME POOL ========================

local anchor          -- main anchor frame (draggable)
local timerFrames = {} -- recycled frame pool
local activeTimers = {} -- currently shown: { [spellName] = frameRef }
local pendingScan = false
local configFrame = nil -- settings panel
local isTestMode = false

-- Forward-declare functions that reference each other
local LayoutTimers, RebuildTimerFrames, ScanAuras, ApplyScale, OnUpdate

-- ======================== ANCHOR FRAME ========================

local function SaveAnchorPos()
    if not anchor then return end
    local point, _, relPoint, x, y = anchor:GetPoint(1)
    SetSetting("point", point)
    SetSetting("relPoint", relPoint)
    SetSetting("x", x)
    SetSetting("y", y)
end

local function CreateAnchor()
    local f = CreateFrame("Frame", "CCTrackerAnchor", UIParent)
    local iconSize = GetSetting("iconSize")
    local barWidth = GetSetting("barWidth")
    local spacing  = GetSetting("spacing")
    f:SetWidth(iconSize + barWidth + spacing)
    f:SetHeight(iconSize)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not GetSetting("locked") then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveAnchorPos()
    end)

    -- Restore saved position or default to center
    local pt = GetSetting("point")
    if pt then
        f:SetPoint(pt, UIParent, GetSetting("relPoint"), GetSetting("x"), GetSetting("y"))
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    end

    -- Lock state
    f:EnableMouse(not GetSetting("locked"))

    -- Drag handle background (visible when unlocked)
    local handleBg = f:CreateTexture(nil, "BACKGROUND")
    handleBg:SetAllPoints()
    handleBg:SetTexture(0, 0, 0, 0) -- invisible by default
    f._handleBg = handleBg

    -- Label shown when unlocked
    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText("|cff888888CC Tracker - drag to move|r")
    label:Hide()
    f._label = label

    f:Hide() -- hidden when no CCs active

    return f
end

-- ======================== TIMER FRAME CREATION ========================

local function CreateTimerFrame(parent)
    local iconSize = GetSetting("iconSize")
    local barWidth = GetSetting("barWidth")
    local barHeight = GetSetting("barHeight")
    local spacing  = GetSetting("spacing")
    local showIcons = GetSetting("showIcons")

    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(iconSize + barWidth + spacing)
    f:SetHeight(iconSize)

    local rowBg = f:CreateTexture(nil, "BACKGROUND")
    rowBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    rowBg:SetVertexColor(0.03, 0.03, 0.04, 0.72)
    rowBg:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
    rowBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -2)
    f.rowBg = rowBg

    -- Icon
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(iconSize)
    icon:SetHeight(iconSize)
    icon:SetPoint("LEFT", f, "LEFT", 0, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.icon = icon
    if not showIcons then icon:Hide() end

    -- Icon border (colored by category)
    local border = f:CreateTexture(nil, "OVERLAY")
    border:SetWidth(iconSize + 2)
    border:SetHeight(iconSize + 2)
    border:SetPoint("CENTER", icon, "CENTER")
    border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    f.border = border
    if not showIcons then border:Hide() end

    -- Cooldown spiral overlay
    local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    cd:SetAllPoints(icon)
    cd:SetReverse(true)
    if not GetSetting("showSpiral") or not showIcons then cd:Hide() end
    f.cooldown = cd

    -- Timer bar background
    local barBg = f:CreateTexture(nil, "BACKGROUND")
    barBg:SetWidth(barWidth)
    barBg:SetHeight(barHeight + 2)
    if showIcons then
        barBg:SetPoint("LEFT", icon, "RIGHT", spacing, 0)
    else
        barBg:SetPoint("LEFT", f, "LEFT", 0, 0)
    end
    barBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    barBg:SetVertexColor(0.10, 0.10, 0.12, 0.95)
    f.barBg = barBg

    -- Timer bar fill
    local bar = f:CreateTexture(nil, "ARTWORK")
    bar:SetWidth(barWidth)
    bar:SetHeight(barHeight)
    bar:SetPoint("LEFT", barBg, "LEFT", 1, 0)
    bar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.bar = bar

    -- Spell name text
    local nameText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", barBg, "LEFT", 5, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWidth(barWidth - 36)
    nameText:SetHeight(barHeight)
    f.nameText = nameText

    -- Duration text
    local timeText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timeText:SetPoint("RIGHT", barBg, "RIGHT", -5, 0)
    timeText:SetJustifyH("RIGHT")
    timeText:SetTextColor(1, 0.82, 0.25)
    f.timeText = timeText

    -- Category label (above icon)
    local catLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    catLabel:SetPoint("BOTTOM", icon, "TOP", 0, 2)
    catLabel:Hide()
    f.catLabel = catLabel

    -- Metadata
    f.spellName = nil
    f.expirationTime = 0
    f.duration = 0
    f.category = nil
    f.timerType = nil
    f.drCategory = nil

    f:Hide()
    return f
end

-- Get or create a timer frame from the pool
local function AcquireTimerFrame()
    for _, frame in ipairs(timerFrames) do
        if not frame._inUse then
            frame._inUse = true
            return frame
        end
    end
    local frame = CreateTimerFrame(anchor)
    frame._inUse = true
    timerFrames[#timerFrames + 1] = frame
    return frame
end

local function ReleaseTimerFrame(frame)
    frame._inUse = false
    frame:Hide()
    frame.spellName = nil
    frame.expirationTime = 0
    frame.duration = 0
    frame.category = nil
    frame.timerType = nil
    frame.drCategory = nil
end

local function ReleaseAllTimers()
    for name, frame in pairs(activeTimers) do
        ReleaseTimerFrame(frame)
    end
    activeTimers = {}
end

-- Destroy all pooled frames and rebuild (after settings change)
RebuildTimerFrames = function()
    ReleaseAllTimers()
    for _, frame in ipairs(timerFrames) do
        frame:Hide()
        frame:SetParent(nil)
    end
    timerFrames = {}
    if anchor then
        local iconSize = GetSetting("iconSize")
        local barWidth = GetSetting("barWidth")
        local spacing  = GetSetting("spacing")
        anchor:SetWidth(iconSize + barWidth + spacing)
        anchor:SetHeight(iconSize)
    end
    -- Re-scan to repopulate
    if not isTestMode then
        ScanAuras()
    end
end

-- ======================== LAYOUT ========================

LayoutTimers = function()
    local count = 0
    local sorted = {}
    for name, frame in pairs(activeTimers) do
        sorted[#sorted + 1] = frame
    end
    table.sort(sorted, function(a, b)
        return a.expirationTime < b.expirationTime
    end)

    local iconSize = GetSetting("iconSize")
    local spacing  = GetSetting("spacing")
    local growUp   = GetSetting("growUp")

    for i, frame in ipairs(sorted) do
        frame:ClearAllPoints()
        local yOff = (i - 1) * (iconSize + spacing)
        if growUp then
            frame:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, yOff)
        else
            frame:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -yOff)
        end
        frame:Show()
        count = count + 1
    end

    if count > 0 then
        anchor:SetHeight(count * (iconSize + spacing))
        anchor:Show()
    else
        if not isTestMode then anchor:Hide() end
    end
end

-- ======================== SCALE ========================

ApplyScale = function()
    if anchor then
        anchor:SetScale(GetSetting("scale"))
    end
end

-- ======================== INTERRUPT HELPERS ========================

local lastInterruptKey = nil
local DR_RESET_TIME = 15
local DR_TRACKED_CATEGORIES = {
    STUN = true,
    SILENCE = true,
    FEAR = true,
    ROOT = true,
    INCAP = true,
    DISARM = true,
}
local DR_ICONS = {
    STUN = "Interface\\Icons\\Spell_Frost_Stun",
    SILENCE = "Interface\\Icons\\Spell_Shadow_ImpPhaseShift",
    FEAR = "Interface\\Icons\\Spell_Shadow_Possession",
    ROOT = "Interface\\Icons\\Spell_Frost_FrostNova",
    INCAP = "Interface\\Icons\\Spell_Nature_Polymorph",
    DISARM = "Interface\\Icons\\Ability_Warrior_Disarm",
}
local drState = {}

local function DebugPrint(msg)
    if GetSetting("debug") then
        print("|cff33ccff[CC Tracker Debug]|r " .. msg)
    end
end

local function GetCombatLogPayload(...)
    if type(CombatLogGetCurrentEventInfo) == "function" then
        return CombatLogGetCurrentEventInfo()
    end
    return ...
end

local function LogUnknownInterrupt(spellId, spellName)
    if not INTERRUPT_SPELLS[spellName] then
        DebugPrint("Unknown interrupt seen: " .. tostring(spellName) .. " (ID: " .. tostring(spellId) .. ")")
    end
end

local function RegisterDRHit(category)
    if not DR_TRACKED_CATEGORIES[category] or not IsPvPContext() then return end

    local now = GetTime()
    local state = drState[category]
    if not state or state.expiresAt <= now then
        state = { count = 1, expiresAt = now + DR_RESET_TIME }
        drState[category] = state
    else
        state.count = math.min(state.count + 1, 3)
        state.expiresAt = now + DR_RESET_TIME
    end
end

local function ShowDRTimer(category)
    if not GetSetting("showDR") or not DR_TRACKED_CATEGORIES[category] or not IsPvPContext() then return end
    if not anchor then
        anchor = CreateAnchor()
        anchor:SetScript("OnUpdate", OnUpdate)
        ApplyScale()
    end

    local state = drState[category]
    if not state then return end

    local key = "DR_" .. category
    local frame = activeTimers[key] or AcquireTimerFrame()
    local r, g, b = 1.0, 0.82, 0.2
    local nextText = "50%"

    if state.count == 2 then
        r, g, b = 1.0, 0.55, 0.2
        nextText = "25%"
    elseif state.count >= 3 then
        r, g, b = 1.0, 0.2, 0.2
        nextText = "IMMUNE"
    end

    frame.spellName = key
    frame.category = "DR"
    frame.timerType = "DR"
    frame.drCategory = category
    frame.icon:SetTexture(DR_ICONS[category] or INTERRUPT_FALLBACK_ICON)
    frame.border:SetVertexColor(r, g, b)
    frame.bar:SetVertexColor(r, g, b, 0.85)

    if GetSetting("showCategory") then
        frame.nameText:SetText("DR")
    else
        frame.nameText:SetText("DR: " .. (CATEGORY_LABELS[category] or category) .. " " .. nextText)
    end

    frame.duration = DR_RESET_TIME
    frame.expirationTime = state.expiresAt

    if GetSetting("showSpiral") and GetSetting("showIcons") then
        frame.cooldown:Show()
        frame.cooldown:SetCooldown(state.expiresAt - DR_RESET_TIME, DR_RESET_TIME)
    else
        frame.cooldown:Hide()
    end

    if GetSetting("showLabels") then
        frame.catLabel:SetText("|cffffcc00DIMINISHING|r")
        frame.catLabel:Show()
    else
        frame.catLabel:Hide()
    end

    if not GetSetting("showIcons") then
        frame.icon:Hide()
        frame.border:Hide()
    else
        frame.icon:Show()
        frame.border:Show()
    end

    activeTimers[key] = frame
    LayoutTimers()
end

local function ShowInterruptTimer(spellName, extraSpellName)
    if not GetSetting("trackINTERRUPT") or not ShouldTrackNow() then return end
    if not anchor then
        anchor = CreateAnchor()
        anchor:SetScript("OnUpdate", OnUpdate)
        ApplyScale()
    end

    local info = INTERRUPT_SPELLS[spellName]
    local duration, icon, r, g, b

    if info then
        duration, icon, r, g, b = unpack(info)
    else
        duration = INTERRUPT_FALLBACK_DURATION
        icon = INTERRUPT_FALLBACK_ICON
        if GetSpellTexture and spellName then
            icon = GetSpellTexture(spellName) or icon
        end
        r, g, b = 0.2, 1.0, 1.0
    end

    local frame = AcquireTimerFrame()
    local now = GetTime()
    local label = extraSpellName or spellName or "Interrupted"
    local key = "INTERRUPT_" .. tostring(spellName or "Unknown") .. "_" .. math.floor(now * 100)

    frame.spellName = key
    frame.timerType = "INTERRUPT"
    frame.drCategory = nil
    frame.icon:SetTexture(icon)
    frame.border:SetVertexColor(r, g, b)
    frame.bar:SetVertexColor(r, g, b, 0.85)
    frame.category = "INTERRUPT"

    if GetSetting("showCategory") then
        frame.nameText:SetText("LOCKOUT")
    else
        frame.nameText:SetText("Locked: " .. label)
    end

    frame.duration = duration
    frame.expirationTime = now + duration

    if GetSetting("showSpiral") and GetSetting("showIcons") then
        frame.cooldown:Show()
        frame.cooldown:SetCooldown(now, duration)
    else
        frame.cooldown:Hide()
    end

    if GetSetting("showLabels") then
        frame.catLabel:SetText("|cff00ffffLOCKOUT|r")
        frame.catLabel:Show()
    else
        frame.catLabel:Hide()
    end

    if not GetSetting("showIcons") then
        frame.icon:Hide()
        frame.border:Hide()
    else
        frame.icon:Show()
        frame.border:Show()
    end

    activeTimers[key] = frame
    LayoutTimers()
end

local function ShowInterruptAlert(sourceName, spellId, spellName, extraSpellName)
    local msg
    if extraSpellName then
        msg = string.format("Interrupted by %s: %s (%s)", sourceName or "Unknown", spellName or "Unknown", extraSpellName)
    else
        msg = string.format("Interrupted by %s: %s", sourceName or "Unknown", spellName or "Unknown")
    end

    DebugPrint(msg)
    ShowInterruptTimer(spellName, extraSpellName)

    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and ChatTypeInfo["RAID_WARNING"] then
        RaidNotice_AddMessage(RaidWarningFrame, "|cffff3333" .. msg .. "|r", ChatTypeInfo["RAID_WARNING"])
    end
end

-- ======================== LOCK / UNLOCK ========================

local function SetLocked(locked)
    SetSetting("locked", locked)
    if not anchor then return end
    anchor:EnableMouse(not locked)
    if locked then
        anchor._label:Hide()
        anchor._handleBg:SetTexture(0, 0, 0, 0)
    else
        anchor._label:Show()
        anchor._handleBg:SetTexture(0, 0, 0, 0.4)
        anchor:Show() -- show even if no CCs
    end
end

-- ======================== TIMER UPDATE ========================

local function FormatTime(remaining)
    if remaining >= 60 then
        return string.format("%d:%02d", remaining / 60, remaining % 60)
    elseif remaining >= 10 then
        return string.format("%.0f", remaining)
    else
        return string.format("%.1f", remaining)
    end
end

local elapsed_acc = 0
OnUpdate = function(self, elapsed)
    elapsed_acc = elapsed_acc + elapsed
    if elapsed_acc < 0.05 then return end
    elapsed_acc = 0

    local now = GetTime()
    local dirty = false
    local barWidth = GetSetting("barWidth")

    for name, frame in pairs(activeTimers) do
        local remaining = frame.expirationTime - now
        if remaining <= 0 then
            if frame.timerType == "AURA" and frame.drCategory then
                ShowDRTimer(frame.drCategory)
            end
            activeTimers[name] = nil
            ReleaseTimerFrame(frame)
            dirty = true
        else
            local pct = remaining / frame.duration
            if pct < 0 then pct = 0 end
            if pct > 1 then pct = 1 end
            frame.bar:SetWidth(math.max(1, barWidth * pct))
            frame.timeText:SetText(FormatTime(remaining))

            -- Flash red under 2s
            if remaining < 2 then
                local flash = math.sin(now * 6) * 0.3 + 0.7
                frame.bar:SetVertexColor(flash, 0.1, 0.1, 0.9)
            end
        end
    end

    if dirty then
        LayoutTimers()
        -- If test mode and all expired, clear test
        if isTestMode then
            local any = false
            for _ in pairs(activeTimers) do any = true; break end
            if not any then
                isTestMode = false
            end
        end
    end
end

-- ======================== AURA SCANNING ========================

ScanAuras = function()
    if isTestMode then return end -- don't overwrite test display

    if not ShouldTrackNow() then
        local hadTimers = next(activeTimers) ~= nil
        ReleaseAllTimers()
        if hadTimers then LayoutTimers() end
        return
    end

    local now = GetTime()
    local found = {}

    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime =
            UnitAura("player", i, "HARMFUL")
        if not name then break end

        local ccInfo = CC_SPELLS[name]
        if ccInfo and duration and duration > 0 and expirationTime and expirationTime > now then
            -- Check if category is enabled
            local cat = ccInfo[1]
            if GetSetting("track" .. cat) then
                found[name] = {
                    icon = icon,
                    duration = duration,
                    expirationTime = expirationTime,
                    category = cat,
                    r = ccInfo[2],
                    g = ccInfo[3],
                    b = ccInfo[4],
                }
            end
        end
    end

    -- Remove timers for aura-based CCs no longer active
    for name, frame in pairs(activeTimers) do
        if frame.timerType == "AURA" and not found[name] then
            if frame.drCategory then
                ShowDRTimer(frame.drCategory)
            end
            activeTimers[name] = nil
            ReleaseTimerFrame(frame)
        end
    end

    -- Add or update timers
    local changed = false
    for name, info in pairs(found) do
        local frame = activeTimers[name]
        if not frame then
            frame = AcquireTimerFrame()
            activeTimers[name] = frame
            changed = true

            frame.spellName = name
            frame.timerType = "AURA"
            frame.drCategory = info.category
            frame.icon:SetTexture(info.icon)
            frame.border:SetVertexColor(info.r, info.g, info.b)
            frame.bar:SetVertexColor(info.r, info.g, info.b, 0.85)
            frame.category = info.category
            RegisterDRHit(info.category)
            if GetSetting("showCategory") then
                frame.nameText:SetText(CATEGORY_LABELS[info.category] or info.category)
            else
                frame.nameText:SetText(name)
            end
            if GetSetting("showLabels") then
                local catText = CATEGORY_LABELS[info.category] or info.category
                frame.catLabel:SetText("|cffff0000" .. catText .. "|r")
                frame.catLabel:Show()
            else
                frame.catLabel:Hide()
            end
            if GetSetting("showSpiral") and GetSetting("showIcons") then
                frame.cooldown:Show()
                frame.cooldown:SetCooldown(info.expirationTime - info.duration, info.duration)
            else
                frame.cooldown:Hide()
            end
            if not GetSetting("showIcons") then
                frame.icon:Hide()
                frame.border:Hide()
            else
                frame.icon:Show()
                frame.border:Show()
            end
        end

        frame.duration = info.duration
        frame.expirationTime = info.expirationTime
    end

    if changed then
        LayoutTimers()
    end
end

-- ======================== TEST MODE ========================

local TEST_ICONS = {
    STUN      = "Interface\\Icons\\Spell_Holy_SealOfMight",
    SILENCE   = "Interface\\Icons\\Spell_Shadow_Impphaseshift",
    ROOT      = "Interface\\Icons\\Spell_Frost_FrostNova",
    FEAR      = "Interface\\Icons\\Spell_Shadow_Possession",
    INTERRUPT = "Interface\\Icons\\Ability_Kick",
    DR        = "Interface\\Icons\\Ability_Creature_Cursed_03",
}

local function ShowTestTimers()
    if not anchor then return end
    ReleaseAllTimers()
    isTestMode = true

    local testSpells = {
        { name = "Hammer of Justice", cat = "STUN",      r = 1,   g = 0.3, b = 0.3, dur = 8 },
        { name = "Counterspell",      cat = "SILENCE",   r = 0.7, g = 0.3, b = 1,   dur = 5 },
        { name = "Kick",              cat = "INTERRUPT", r = 0.2, g = 1.0, b = 1.0, dur = 5 },
        { name = "DR: STUN",          cat = "DR",        r = 1.0, g = 0.82, b = 0.2, dur = 15 },
        { name = "Frost Nova",        cat = "ROOT",      r = 0.3, g = 0.8, b = 0.3, dur = 10 },
        { name = "Fear",              cat = "FEAR",      r = 1,   g = 0.8, b = 0.2, dur = 6 },
        { name = "Disarm",            cat = "DISARM",    r = 1,   g = 0.6, b = 0.2, dur = 7 },
    }
    local now = GetTime()
    for _, t in ipairs(testSpells) do
        local isEnabled = (t.cat == "DR" and GetSetting("showDR")) or GetSetting("track" .. t.cat)
        if isEnabled then
            local frame = AcquireTimerFrame()
            activeTimers[t.name] = frame
            frame.spellName = t.name
            frame.timerType = (t.cat == "INTERRUPT" and "INTERRUPT") or (t.cat == "DR" and "DR") or "AURA"
            frame.drCategory = (t.cat ~= "INTERRUPT" and t.cat ~= "DR") and t.cat or nil
            frame.icon:SetTexture(TEST_ICONS[t.cat] or "Interface\\Icons\\INV_Misc_QuestionMark")
            frame.border:SetVertexColor(t.r, t.g, t.b)
            frame.bar:SetVertexColor(t.r, t.g, t.b, 0.85)
            frame.category = t.cat
            if GetSetting("showCategory") then
                frame.nameText:SetText(CATEGORY_LABELS[t.cat] or t.cat)
            else
                frame.nameText:SetText(t.name)
            end
            frame.duration = t.dur
            frame.expirationTime = now + t.dur
            if GetSetting("showSpiral") and GetSetting("showIcons") then
                frame.cooldown:Show()
                frame.cooldown:SetCooldown(now, t.dur)
            else
                frame.cooldown:Hide()
            end
            if GetSetting("showLabels") then
                local catText = CATEGORY_LABELS[t.cat] or t.cat
                frame.catLabel:SetText("|cffff0000" .. catText .. "|r")
                frame.catLabel:Show()
            else
                frame.catLabel:Hide()
            end
            if not GetSetting("showIcons") then
                frame.icon:Hide()
                frame.border:Hide()
            else
                frame.icon:Show()
                frame.border:Show()
            end
        end
    end
    LayoutTimers()
end

-- ======================== CONFIG PANEL ========================

-- Helper: create a slider row
local function CreateSlider(parent, label, min, max, step, settingKey, x, y, onChange)
    local s = CreateFrame("Slider", "CCT_Slider_" .. settingKey, parent, "OptionsSliderTemplate")
    s:SetWidth(160)
    s:SetHeight(16)
    s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)
    -- s:SetObeyStepOnDrag(true) -- Not available in WoW 3.3.5a

    local low = getglobal(s:GetName() .. "Low")
    local high = getglobal(s:GetName() .. "High")
    local text = getglobal(s:GetName() .. "Text")
    if low then low:SetText(tostring(min)) end
    if high then high:SetText(tostring(max)) end

    local function UpdateText(val)
        if text then
            if step < 1 then
                text:SetText(label .. ": " .. string.format("%.1f", val))
            else
                text:SetText(label .. ": " .. tostring(math.floor(val)))
            end
        end
    end

    s:SetValue(GetSetting(settingKey))
    UpdateText(GetSetting(settingKey))

    s:SetScript("OnValueChanged", function(self, value)
        SetSetting(settingKey, value)
        UpdateText(value)
        if onChange then onChange(value) end
    end)

    return s
end

-- Helper: create a checkbox row
local function CreateCheckbox(parent, label, settingKey, x, y, onChange)
    local cb = CreateFrame("CheckButton", "CCT_Check_" .. settingKey, parent, "UICheckButtonTemplate")
    cb:SetWidth(26)
    cb:SetHeight(26)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetChecked(GetSetting(settingKey))

    local cbText = getglobal(cb:GetName() .. "Text")
    if cbText then
        cbText:SetText(label)
        cbText:SetFontObject("GameFontNormalSmall")
    end

    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked() == 1
        SetSetting(settingKey, checked)
        if onChange then onChange(checked, self) end
    end)

    return cb
end

local function SyncSpiralControlState()
    local spiralCB = getglobal("CCT_Check_showSpiral")
    if not spiralCB then return end

    spiralCB:SetChecked(GetSetting("showSpiral"))

    if GetSetting("showIcons") then
        spiralCB:Enable()
    else
        spiralCB:Disable()
    end
end

local function CreateSectionHeader(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText("|cff9fd3ff" .. text .. "|r")

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    line:SetVertexColor(0.2, 0.55, 0.85, 0.55)
    line:SetHeight(1)
    line:SetPoint("LEFT", label, "RIGHT", 8, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -24, 0)

    return label
end

local function CreateConfigPanel()
    if configFrame then
        if configFrame:IsShown() then
            configFrame:Hide()
            -- Hide anchor/timers if not in test mode and no CCs
            if not isTestMode then
                ScanAuras()
                if anchor and not next(activeTimers) then anchor:Hide() end
            end
            -- Save all settings (position, size, toggles)
            SaveAnchorPos()
            return
        else
            configFrame:Show()
            -- Show anchor and timer frames for setup
            if anchor then anchor:Show() end
            if not isTestMode then ShowTestTimers() end
            return
        end
    end

    local f = CreateFrame("Frame", "CCTrackerConfigFrame", UIParent)
    f:SetWidth(420)
    f:SetHeight(575)
    f:SetPoint("CENTER", UIParent, "CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.04, 0.05, 0.08, 0.96)
    f:SetBackdropBorderColor(0.3, 0.55, 0.85, 0.9)

    local inset = CreateFrame("Frame", nil, f)
    inset:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -42)
    inset:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 18)
    inset:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    inset:SetBackdropColor(0.02, 0.02, 0.03, 0.72)
    inset:SetBackdropBorderColor(0.16, 0.18, 0.22, 0.85)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -14)
    title:SetText("|cff5fd3ffCC Tracker|r")

    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
    subtitle:SetText("Arena-ready crowd control and interrupt tracker")
    subtitle:SetTextColor(0.78, 0.82, 0.9)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
        -- Hide anchor/timers if not in test mode and no CCs
        if not isTestMode then
            ScanAuras()
            if anchor and not next(activeTimers) then anchor:Hide() end
        end
        -- Save all settings (position, size, toggles)
        SaveAnchorPos()
    end)

    local yOff = -44
    local col1 = 20
    local col2 = 180

    -- ---- SIZE SLIDERS ----
    local sectionLabel = CreateSectionHeader(f, "Size & Layout", col1, yOff)
    yOff = yOff - 30

    CreateSlider(f, "Icon Size", 20, 64, 2, "iconSize", col1, yOff, function()
        RebuildTimerFrames()
        if isTestMode then ShowTestTimers() end
    end)
    yOff = yOff - 40

    CreateSlider(f, "Bar Width", 60, 250, 5, "barWidth", col1, yOff, function()
        RebuildTimerFrames()
        if isTestMode then ShowTestTimers() end
    end)
    yOff = yOff - 40

    CreateSlider(f, "Bar Height", 8, 30, 1, "barHeight", col1, yOff, function()
        RebuildTimerFrames()
        if isTestMode then ShowTestTimers() end
    end)
    yOff = yOff - 40

    CreateSlider(f, "Spacing", 0, 12, 1, "spacing", col1, yOff, function()
        RebuildTimerFrames()
        if isTestMode then ShowTestTimers() end
    end)
    yOff = yOff - 40

    CreateSlider(f, "Scale", 0.5, 2.0, 0.1, "scale", col1, yOff, function()
        ApplyScale()
    end)
    yOff = yOff - 40

    -- ---- DISPLAY OPTIONS ----
    local dispLabel = CreateSectionHeader(f, "Display", col1, yOff)
    yOff = yOff - 6

    CreateCheckbox(f, "Grow upward", "growUp", col1, yOff, function()
        LayoutTimers()
    end)

    CreateCheckbox(f, "Show labels", "showLabels", col2, yOff, function()
        RebuildTimerFrames()
        if isTestMode then ShowTestTimers() end
    end)
    yOff = yOff - 26

    CreateCheckbox(f, "Show cooldown spiral", "showSpiral", col1, yOff, function(checked)
        SetSetting("spiralManualDisable", not checked)
        SyncSpiralControlState()
        RebuildTimerFrames()
        if isTestMode then ShowTestTimers() end
    end)

    CreateCheckbox(f, "Show spell icons", "showIcons", col2, yOff, function(checked)
        if checked then
            if not GetSetting("spiralManualDisable") then
                SetSetting("showSpiral", true)
            end
        else
            SetSetting("showSpiral", false)
        end

        SyncSpiralControlState()
        RebuildTimerFrames()
        if isTestMode then ShowTestTimers() end
    end)

    SyncSpiralControlState()
    yOff = yOff - 32

    CreateCheckbox(f, "Show category label", "showCategory", col1, yOff, function()
        RebuildTimerFrames()
        if isTestMode then ShowTestTimers() end
    end)

    CreateCheckbox(f, "Show DR timer", "showDR", col2, yOff, function()
        RebuildTimerFrames()
        if isTestMode then ShowTestTimers() end
    end)
    yOff = yOff - 32

    CreateCheckbox(f, "PvP / Arena only", "pvpOnly", col1, yOff, function()
        if not isTestMode then
            ReleaseAllTimers()
            ScanAuras()
        end
    end)
    yOff = yOff - 32

    -- ---- CATEGORY TOGGLES ----
    local catLabel = CreateSectionHeader(f, "Categories to Track", col1, yOff)
    yOff = yOff - 6

    local categories = { "STUN", "SILENCE", "FEAR", "ROOT", "INCAP", "DISARM", "INTERRUPT" }
    for i, cat in ipairs(categories) do
        local xPos = (i <= 3) and col1 or col2
        local yPos = yOff - ((i <= 3) and ((i - 1) * 24) or ((i - 4) * 24))
        local c = CATEGORY_COLORS[cat]
        local colorStr = string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
        CreateCheckbox(f, colorStr .. CATEGORY_LABELS[cat] .. "|r", "track" .. cat, xPos, yPos, function()
            if isTestMode then ShowTestTimers() else ScanAuras() end
        end)
    end
    yOff = yOff - 100

    -- ---- BUTTONS ----
    local lockBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    lockBtn:SetWidth(110)
    lockBtn:SetHeight(24)
    lockBtn:SetPoint("TOPLEFT", f, "TOPLEFT", col1, yOff)
    lockBtn:SetText("Lock / Unlock")
    lockBtn:SetScript("OnClick", function()
        local locked = GetSetting("locked")
        SetLocked(not locked)
        print("|cff00ff00[CC Tracker]|r " .. (GetSetting("locked") and "Locked." or "Unlocked - drag to move."))
    end)

    local testBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    testBtn:SetWidth(110)
    testBtn:SetHeight(24)
    testBtn:SetPoint("LEFT", lockBtn, "RIGHT", 8, 0)
    testBtn:SetText("Preview")
    testBtn:SetScript("OnClick", function()
        ShowTestTimers()
    end)

    local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetBtn:SetWidth(110)
    resetBtn:SetHeight(24)
    resetBtn:SetPoint("LEFT", testBtn, "RIGHT", 8, 0)
    resetBtn:SetText("Reset Position")
    resetBtn:SetScript("OnClick", function()
        if anchor then
            anchor:ClearAllPoints()
            anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
            SetSetting("point", nil)
            SetSetting("relPoint", nil)
            SetSetting("x", nil)
            SetSetting("y", nil)
            print("|cff00ff00[CC Tracker]|r Position reset.")
        end
    end)

    local footer = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    footer:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    footer:SetText("Use /cct unlock to move • /cct debug for live logging")
    footer:SetTextColor(0.65, 0.72, 0.8)

    configFrame = f
    f:Show()
    -- Show anchor and timer frames for setup
    if anchor then anchor:Show() end
    if not isTestMode then ShowTestTimers() end
end

-- ======================== EVENT HANDLER ========================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if not anchor then
            anchor = CreateAnchor()
            anchor:SetScript("OnUpdate", OnUpdate)
            ApplyScale()
        end
        ScanAuras()
    elseif event == "UNIT_AURA" then
        if select(1, ...) == "player" then
            if not pendingScan then
                pendingScan = true
                eventFrame:SetScript("OnUpdate", function(self2)
                    self2:SetScript("OnUpdate", nil)
                    pendingScan = false
                    ScanAuras()
                end)
            end
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_FLAGS_CHANGED" then
        ScanAuras()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
            destGUID, destName, destFlags, destRaidFlags,
            spellId, spellName, spellSchool,
            extraSpellId, extraSpellName, extraSpellSchool = GetCombatLogPayload(...)

        if subevent == "SPELL_INTERRUPT" and destGUID == UnitGUID("player") then
            local interruptKey = tostring(timestamp) .. ":" .. tostring(sourceGUID) .. ":" .. tostring(spellId)
            if interruptKey ~= lastInterruptKey then
                lastInterruptKey = interruptKey
                ShowInterruptAlert(sourceName, spellId, spellName, extraSpellName)
                LogUnknownInterrupt(spellId, spellName)
            end
        end
    end
end)

-- ======================== SLASH COMMANDS ========================

SLASH_CCTRACKER1 = "/cctracker"
SLASH_CCTRACKER2 = "/cct"
SlashCmdList["CCTRACKER"] = function(msg)
    msg = strtrim((msg or ""):lower())

    if msg == "lock" then
        SetLocked(true)
        print("|cff00ff00[CC Tracker]|r Locked.")
    elseif msg == "unlock" then
        SetLocked(false)
        print("|cff00ff00[CC Tracker]|r Unlocked - drag to move. /cct lock when done.")
    elseif msg == "test" then
        if not anchor then
            anchor = CreateAnchor()
            anchor:SetScript("OnUpdate", OnUpdate)
            ApplyScale()
        end
        ShowTestTimers()
        print("|cff00ff00[CC Tracker]|r Showing test timers.")
    elseif msg == "reset" then
        if anchor then
            anchor:ClearAllPoints()
            anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
            SetSetting("point", nil)
            SetSetting("relPoint", nil)
            SetSetting("x", nil)
            SetSetting("y", nil)
            print("|cff00ff00[CC Tracker]|r Position reset.")
        end
    elseif msg == "debug" then
        SetSetting("debug", not GetSetting("debug"))
        print("|cff00ff00[CC Tracker]|r Debug mode " .. (GetSetting("debug") and "enabled." or "disabled."))
    elseif msg == "config" or msg == "options" or msg == "settings" or msg == "" then
        CreateConfigPanel()
    else
        print("|cff00ff00[CC Tracker]|r Commands:")
        print("  /cct          - Open settings panel")
        print("  /cct unlock   - Unlock for dragging")
        print("  /cct lock     - Lock position")
        print("  /cct test     - Show test timers")
        print("  /cct reset    - Reset position")
        print("  /cct debug    - Toggle interrupt debug logging")
    end
end
