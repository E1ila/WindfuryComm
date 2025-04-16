
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

function WFCMeleeFrame:ShowTotems(totemUptimes)
    for i = 1, #totemUptimes do
        local totemName, uptime = totemUptimes[i][1], totemUptimes[i][2]
        if totemFrames[i] == nil then
            self:AddTotemRow()
        end
        local frames = totemFrames[i]
        local color, bgcolor = uptimeColor(uptime)
        frames.root:Show()
        frames.bar:SetValue(uptime)
        frames.bar:SetStatusBarColor(unpack(color))
        frames.icon.icon:SetTexture(ICONS[totemName])
        frames.root:SetBackdropColor(unpack(bgcolor))
        frames.text:SetText(uptimeText(uptime))
    end
    if #totemFrames > #totemUptimes then
        for i = #totemUptimes+1, #totemFrames do
            local frames = totemFrames[i]
            frames.root:Hide()
        end
    end
    if wfcdb.shrink then
        WFCMeleeFrame:SetHeight(#totemUptimes * rowHeight + 40)
    end
end

local function registerUptimeReport(wfcLib)
    if wfcLib then
        wfcLib.UptimeReportHook = function (combatTime, wfTime, shaman, strTime, agiTime, frTime, frrTime, gndTime, reporter, channel)
            if not wfcdbc.shown then return end
            local totemUptimes = {}
            if combatTime > 1 then
                local wfUp = math.floor(wfTime / combatTime * 100)
                local strUp = math.floor(strTime / combatTime * 100)
                local agiUp = math.floor(agiTime / combatTime * 100)
                local frrUp = math.floor(frrTime / combatTime * 100)
                local frUp = math.floor(frTime / combatTime * 100)
                local gndUp = math.floor(gndTime / combatTime * 100)
                table.insert(totemUptimes, { "wf", wfUp })
                table.insert(totemUptimes, { "str", strUp })
                if agiUp > 0 then
                    table.insert(totemUptimes, { "agi", agiUp })
                end
                if gndUp > 0 then
                    table.insert(totemUptimes, { "gnd", gndUp })
                end
                if frUp > 0 then
                    table.insert(totemUptimes, { "fr", frUp })
                end
                if frrUp > 0 then
                    table.insert(totemUptimes, { "frr", frrUp })
                end
            end
            WFCMeleeFrame:ShowTotems(totemUptimes)
            WFCMeleeFrame_Title_Text:SetText("|cff0070DE"..(shaman or "??").."|r")
            WFCMeleeFrame:UpdateSessionViewText(combatTime)
            WFCMeleeFrame:Show()
        end
    else
        print("LibWFcomm not found!!")
    end
end

function WFCMeleeFrame_SessionButton:ToggleSessionView()
    wfcdb.meleeCurrentSession = not wfcdb.meleeCurrentSession
    WFCMeleeFrame:UpdateSessionViewText()
end

function WFCMeleeFrame:UpdateSessionViewText(time)
    local textstr = ""
    if time and time > 0 then
        local minutes = math.floor(time / 60)
        local seconds = time - (minutes * 60)
        textstr = string.format(": %d:%02d", minutes, seconds)
    end
    if wfcdb.meleeCurrentSession then
        WFCMeleeFrame_Header_Text:SetText("Last Fight"..textstr)
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

function WFCMeleeFrame:Init(wfcLib)
    self:UpdateSessionViewText()
    self:AddTotemRow()
    self:AddTotemRow()
    self:Hide()
    registerUptimeReport(wfcLib)
end

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

function WFCMeleeFrame:GROUP_ROSTER_UPDATE()
    if GetNumGroupMembers() == 0 then
        self:HideUI()
    end
end
