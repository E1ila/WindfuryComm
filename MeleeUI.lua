
local COLOR_GOOD = {0, 1, 0, 1}
local COLOR_WELL = {.5, 1, .5, 1}
local COLOR_MED = {1, 1, 0, 1}
local COLOR_LOW = {1, .6, 0, 1}
local COLOR_BAD = {1, .2, 0, 1}
local COLOR_NONE = {1, .2, 0, 1}
local COLOR_BG = {0.1, 0.1, 0.1, 0.8}

local ICONS = {
    none = "Interface\\ICONS\\Spell_nature_cyclone",
    wf = "Interface\\ICONS\\Spell_Nature_Windfury",
    str = "Interface\\ICONS\\Spell_Nature_EarthBindTotem",
    agi = "Interface\\ICONS\\Spell_Nature_InvisibilityTotem",
    fr = "Interface\\ICONS\\Spell_FireResistanceTotem_01",
    frr = "Interface\\ICONS\\Spell_FrostResistanceTotem_01",
    gnd = "Interface\\ICONS\\Spell_Nature_GroundingTotem",
}
local TOTEMS = {
    [1] = "wf",
    [2] = "str",
    [3] = "agi",
    [4] = "fr",
    [5] = "frr",
    [6] = "gnd",
}

local totemFrames = {}
local rowHeight = 28
local encounter

local function uptimeText(uptime)
    local color = '|cffff0000'
    if uptime > 90 then
        color = '|cff00ff00'
    elseif uptime > 80 then
        color = '|cffb9f542'
    elseif uptime > 60 then
        color = '|cfff5ef42'
    elseif uptime > 40 then
        color = '|cfff5a142'
    end
    return color..tostring(uptime)..'%|r'
end

local function uptimeColor(uptime)
    local color, bgcolor = nil, COLOR_NONE
    uptime = uptime or 0
    if uptime > 90 then
        color = COLOR_GOOD
    elseif uptime > 80 then
        color = COLOR_WELL
    elseif uptime > 60 then
        color = COLOR_MED
    elseif uptime > 40 then
        color = COLOR_LOW
    else
        color = COLOR_BAD
        bgcolor = COLOR_NONE
    end
    return color, bgcolor
end

-- hook when LibWF sends a report
local function uptimeReport(combatTime, wfTime, shaman, strTime, agiTime, frTime, frrTime, gndTime, reporter, reportType)
    -- stats collection
    if not wfcdbc then return end
    if not wfcdbc.stats then wfcdbc.stats = {} end
    local stats = wfcdbc.stats
    if stats.shaman ~= shaman then
        stats.shaman = shaman
    end
    if combatTime > 1 then
        stats.last.time = combatTime
        stats.last.wf = wfTime or 0
        stats.last.str = strTime or 0
        stats.last.agi = agiTime or 0
        stats.last.frr = frrTime or 0
        stats.last.fr = frTime or 0
        stats.last.gnd = gndTime or 0
        if (reportType == 'FINAL') then
            stats.overall.time = (stats.overall.time or 0) + combatTime
            stats.overall.wf = (stats.overall.wf or 0) + (wfTime or 0)
            stats.overall.str = (stats.overall.str or 0) + (strTime or 0)
            stats.overall.agi = (stats.overall.agi or 0) + (agiTime or 0)
            stats.overall.gnd = (stats.overall.gnd or 0) + (gndTime or 0)
            stats.overall.fr = (stats.overall.fr or 0) + (frTime or 0)
            stats.overall.frr = (stats.overall.frr or 0) + (frrTime or 0)
        end
    end
    -- update UI
    WFCMeleeFrame_Title_Text:SetText("|cff0070DE"..(shaman or "??").."|r")
    WFCMeleeFrame:UpdateTotemStats()
    if wfcdbc and wfcdbc.shown then
        WFCMeleeFrame:Show()
    end
end

function WFCMeleeFrame:UpdateTotemStats()
    local lookup = wfcdb.meleeCurrentSession and wfcdbc.stats.last or wfcdbc.stats.overall
    local frameIndex = 0
    for i = 1, #TOTEMS do
        local totemName = TOTEMS[i]
        local totemUptime = lookup[totemName] or 0
        local combatTime = lookup.time
        if i <= 2 or totemUptime > 0 then
            frameIndex = frameIndex + 1
            if totemFrames[frameIndex] == nil then
                self:AddTotemRow()
            end
            local frames = totemFrames[frameIndex]
            local uptime = 0
            if combatTime and combatTime > 0 then
                uptime = math.floor(totemUptime / combatTime * 100)
            end
            local color, bgcolor = uptimeColor(uptime)
            frames.root:Show()
            frames.bar:SetValue(uptime)
            frames.bar:SetStatusBarColor(unpack(color))
            frames.icon.icon:SetTexture(ICONS[totemName])
            frames.root:SetBackdropColor(unpack(bgcolor))
            frames.text:SetText(uptimeText(uptime))
        end
    end
    for i = frameIndex+1, #totemFrames do
        local frames = totemFrames[i]
        frames.root:Hide()
    end
    WFCMeleeFrame:SetHeight(frameIndex * rowHeight + 40)
    WFCMeleeFrame:UpdateSessionViewText()
end

function WFCMeleeFrame_SessionButton:ToggleSessionView()
    wfcdb.meleeCurrentSession = not wfcdb.meleeCurrentSession
    WFCMeleeFrame:UpdateTotemStats()
end

function WFCMeleeFrame:ResetPos()
    wfc.out("Resetting position")
    WFCMeleeFrame:ClearAllPoints()
    WFCMeleeFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -100)
end

function WFCMeleeFrame:ResetStats()
    wfcdbc.stats.overall = {}
    wfcdbc.stats.last = {}
    wfcdbc.stats.shaman = nil
    WFCMeleeFrame_Title_Text:SetText("Totems")
    WFCMeleeFrame:UpdateTotemStats()
end

function WFCMeleeFrame:UpdateSessionViewText()
    local textstr = ""
    local time = wfcdb.meleeCurrentSession and wfcdbc.stats.last.time or wfcdbc.stats.overall.time
    if time and time > 0 then
        local minutes = math.floor(time / 60)
        local seconds = time - (minutes * 60)
        textstr = string.format(": %d:%02d", minutes, seconds)
    end
    if wfcdb.meleeCurrentSession then
        WFCMeleeFrame_Header_Text:SetText("Current Fight"..textstr)
    else
        WFCMeleeFrame_Header_Text:SetText("Overall"..textstr)
    end
end

function WFCMeleeFrame:AddTotemRow()
    local index = #totemFrames + 1

    local root = CreateFrame("FRAME", "WFCTotem"..tostring(index), WFCMeleeFrame, "WFCTotemTemplate");
    root:ClearAllPoints()
    root:SetPoint("TOPLEFT", WFCMeleeFrame, "TOPLEFT", 3, -rowHeight * index - 10)
    root:SetPoint("TOPRIGHT", WFCMeleeFrame, "TOPRIGHT", -3, -rowHeight * index - 10)

    WFCMeleeFrame:SetHeight(index * rowHeight + 40)

    local barElement = _G["WFCTotem"..tostring(index).."_Uptime_Bar"]
    local iconElement = _G["WFCTotem"..tostring(index).."_Icon"]
    local textElement = _G["WFCTotem"..tostring(index).."_Uptime_Bar_Text"]
    totemFrames[index] = {
        root = root,
        bar = barElement,
        text = textElement,
        icon = iconElement,
    }
    root:SetBackdropColor(unpack(COLOR_BG))
    iconElement.icon:SetTexture(ICONS.none)
    barElement:SetMinMaxValues(0, 100)
    barElement:SetValue(0)
    textElement:SetText("--")
end

function WFCMeleeFrame:ShowUI()
    WFCMeleeFrame:Show()
end

function WFCMeleeFrame:HideUI()
    WFCMeleeFrame:Hide()
end

function WFCMeleeFrame:RegisterUptimeReport(wfcLib)
    if wfcLib then
        wfcLib.UptimeReportHook = uptimeReport
    else
        wfc.out("LibWFcomm not found!")
    end
end

function WFCMeleeFrame:Init(wfcLib)
    wfcdbc.stats = wfcdbc.stats or {
        overall = {},
        last = {},
        shaman = nil,
    }
    C_Timer.After(0.5, function()
        -- anchor to top, required because the "movable" feature changes anchor
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self:GetLeft(), self:GetTop() - UIParent:GetTop())
    end)

    self:UpdateSessionViewText()
    self:AddTotemRow()
    self:AddTotemRow()
    self:Hide() -- shows only when receiving uptime report
    self:RegisterUptimeReport(wfcLib)
end

-- Event Handlers ------------------------------------------------------

function WFCMeleeFrame:ENCOUNTER_START(encounterId, encounterName)
    wfc.debug("ENCOUNTER_START", encounterId, encounterName)
    encounter = {
        id = encounterId,
        name = encounterName,
        start = GetTime(),
    }
end

function WFCMeleeFrame:ENCOUNTER_END(encounterId)
    wfc.debug("ENCOUNTER_END", encounterId)
    if encounter then
        if encounterId == encounter.id then
            encounter.finish = GetTime()
        end
    end
end

function WFCMeleeFrame:GROUP_ROSTER_UPDATE(joinedParty)
    if joinedParty then
        wfc.debug("Joined party, resetting stats")
        self:ResetStats()
    elseif GetNumGroupMembers() == 0 then
        self:HideUI()
    end
end
