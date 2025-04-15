
local COLOR_GOOD = {0, 1, 0, 1}
local COLOR_WELL = {.5, 1, .5, 1}
local COLOR_MED = {1, 1, 0, 1}
local COLOR_LOW = {1, .6, 0, 1}
local COLOR_BAD = {1, .2, 0, 1}
local COLOR_NONE = {1, .2, 0, 1}
local COLOR_BG = {0.1, 0.1, 0.1, 0.8}

local ICONS = {
    wf = "Interface\\ICONS\\Spell_Nature_Windfury",
    str = "Interface\\ICONS\\Spell_Nature_EarthBindTotem",
    agi = "Interface\\ICONS\\Spell_Nature_InvisibilityTotem",
}

local totemFrames = {}

local function uptimePercent(uptime)
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

local function setUptime(totemName, uptime)
    local color, bgcolor = nil, COLOR_BG
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
    local totems = totemFrames[totemName]
    totems.bar:SetValue(uptime)
    totems.bar:SetStatusBarColor(unpack(color))
    totems.root:SetBackdropColor(unpack(bgcolor))
    totems.text:SetText(uptimePercent(uptime))
end

local function registerUptimeReport(wfcLib)
    if wfcLib then
        local db = wfcdb
        wfcLib.UptimeReportHook = function (combatTime, wfTime, shaman, strTime, agiTime, frTime, frrTime, gndTime, reporter, channel)
            if combatTime > 1 and (encounter or db and db.alwaysReport) then
                local wfUP = math.floor(wfTime / combatTime * 100)
                local msg
                if encounter and (not encounter.finish or GetTime() - encounter.finish < 5) then
                    msg = 'Encounter |cff00ff00'..encounter.name..'|r ended with uptime of |cffff8800WF|r:'..uptimePercent(wfUP)
                else
                    msg = 'Combat ended with uptime of |cffff8800WF|r:'..uptimePercent(wfUP)
                end
                setUptime("wf", wfUP)
                local strUp = math.floor(strTime / combatTime * 100)
                setUptime("str", strUp)
                local agiUp = math.floor(agiTime / combatTime * 100)
                setUptime("agi", agiUp)
                if strTime > 0 then
                    msg = msg..' |cffff8800STR|r:'..uptimePercent(strUp)
                end
                if agiTime > 0 then
                    msg = msg..' |cffff8800AGI|r:'..uptimePercent(agiUp)
                end
                if frTime > 0 then
                    msg = msg..' |cffff8800FR|r:'..uptimePercent(math.floor(frTime / combatTime * 100))
                end
                if frrTime > 0 then
                    msg = msg..' |cffff8800FrR|r:'..uptimePercent(math.floor(frrTime / combatTime * 100))
                end
                if gndTime > 0 then
                    msg = msg..' |cffff8800GND|r:'..uptimePercent(math.floor(gndTime / combatTime * 100))
                end
                wfc.out(msg..' by |cff0070DE'..tostring(shaman or '??'))
                encounter = nil
            end
        end
    else
        print("LibWFcomm not found!!")
    end
end

function wfcMeleeFrame_SessionButton:toggleSessionView()
    wfcdb.meleeCurrentSession = not wfcdb.meleeCurrentSession
    wfcMeleeFrame:updateSessionViewText()
end

function wfcMeleeFrame:updateSessionViewText()
    if wfcdb.meleeCurrentSession then
        wfcMeleeFrame_Header_Text:SetText("Current Fight")
    else
        wfcMeleeFrame_Header_Text:SetText("Overall")
    end
end

function wfcMeleeFrame:initTotem(name, parentElement, barElement, textElement, iconElement)
    totemFrames[name] = {
        root = parentElement,
        bar = barElement,
        text = textElement,
        icon = iconElement,
    }
    parentElement:SetBackdropColor(unpack(COLOR_BG))
    iconElement:SetTexture(ICONS[name])
    barElement:SetMinMaxValues(0, 100)
    barElement:SetValue(0)
    textElement:SetText("--")
end

function wfcMeleeFrame:init(wfcLib)
    self:updateSessionViewText()
    self:Show()
    registerUptimeReport(wfcLib)

    self:initTotem("wf", WFCTotem1_Uptime, WFCTotem1_Uptime_Bar, WFCTotem1_Uptime_Bar_Text, WFCTotem1_Icon.icon)
    self:initTotem("str", WFCTotem2_Uptime, WFCTotem2_Uptime_Bar, WFCTotem2_Uptime_Bar_Text, WFCTotem2_Icon.icon)
    self:initTotem("agi", WFCTotem3_Uptime, WFCTotem3_Uptime_Bar, WFCTotem3_Uptime_Bar_Text, WFCTotem3_Icon.icon)

    --("wf", 91)
    --setUptime("str", 41)
    --setUptime("agi", 1)
end

function wfcMeleeFrame:ENCOUNTER_START(encounterId, encounterName)
    wfc.debug("ENCOUNTER_START", encounterId, encounterName)
    encounter = {
        id = encounterId,
        name = encounterName,
        start = GetTime(),
    }
end

function wfcMeleeFrame:ENCOUNTER_END(encounterId)
    if encounter then
        wfc.debug("ENCOUNTER_END", encounterId)
        if encounterId == encounter.id then
            encounter.finish = GetTime()
        end
    end
end
