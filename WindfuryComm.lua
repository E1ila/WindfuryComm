wfc = CreateFrame("Frame", "wfc")
wfc.currentTimers, wfc.buttons = {}, {}
wfc.ixs, wfc.party, wfc.guids, wfc.icons, wfc.class, wfc.version = {}, {}, {}, {}, {}, {}
wfc.eventReg = wfc.eventReg or CreateFrame("Frame")
wfc.eventReg:RegisterEvent("PLAYER_ENTERING_WORLD")
wfc.eventReg:RegisterEvent("GROUP_ROSTER_UPDATE")
wfc.eventReg:RegisterEvent("CHAT_MSG_ADDON")
wfc.eventReg:RegisterEvent("ADDON_LOADED")
wfc.eventReg:RegisterEvent("ENCOUNTER_START")
wfc.eventReg:RegisterEvent("ENCOUNTER_END")

local pClass = select(2, UnitClass("player"))
local isShaman = pClass == "SHAMAN"
local isMelee = pClass == "WARRIOR" or pClass == "ROGUE"
local wfcLib = LibStub("LibWFcomm")
local COMM_PREFIX = "WF_STATUS"
local encounter

C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)

-- https://wowwiki-archive.fandom.com/wiki/EnchantId/Enchant_IDs
local spellTable = { [564] = 'WF3', [563] = 'WF2', [1783] = 'WF1' }

local function out(text, ...)
	print(" |cffff8800{|cffffbb00WFC++|cffff8800}|r "..text, ...)
end

local function debug(text, ...)
	if wfcdb.debug then
		out(text, ...)
	end
end

local function currentTimers()
	wipe(wfc.currentTimers)
	for j = 0, 3 do
		if wfc.guids[j] then
			gGUID = wfc.guids[j]
			wfc.currentTimers[gGUID] = wfc.buttons[j].cd:GetCooldownDuration() / 1000
		end
	end
end

local function restartCurrentTimers()
	for gGUID, j in pairs(wfc.ixs) do
		if wfc.currentTimers[gGUID] then
			wfcShamanFrame:startTimerButton(gGUID, wfc.currentTimers[gGUID], wfc.icons[gGUID])
		end
	end
	wipe(wfc.currentTimers)
end

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

local function registerUptimeReport()
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
				if strTime > 0 then
					msg = msg..' |cffff8800STR|r:'..uptimePercent(math.floor(strTime / combatTime * 100))
				end
				if agiTime > 0 then
					msg = msg..' |cffff8800AGI|r:'..uptimePercent(math.floor(agiTime / combatTime * 100))
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
				out(msg..' by |cff0070DE'..tostring(shaman or '??'))
				encounter = nil
			end
		end
	else
		out("LibWFcomm not found!!")
	end
end

function wfc:GROUP_ROSTER_UPDATE()
	if GetNumGroupMembers() == 0 then
		wfcShamanFrame:resetGroup()
	else
		currentTimers()
		wfcShamanFrame:resetGroup()
		wfcShamanFrame:collectGroupInfo()
		restartCurrentTimers()
	end
end

function wfc:CHAT_MSG_ADDON(event, prefix, message, channel, sender)
	if prefix == COMM_PREFIX then --new API
		local gGUID, spellID, expiration, lag, combat, isdead, version = strsplit(":", message)
		local playerIndex = wfc.ixs[gGUID]
		if not playerIndex then
			return
		end
		spellID, expiration, lagHome = tonumber(spellID), tonumber(expiration), tonumber(lagHome)
		local spellName = spellTable[spellID]

		debug('|c99ff9900'..channel..'|r', '|cffdddddd'..prefix..'|r', '|cff99ff00'..sender..'|r', spellName or spellID or '-', 't'..(expiration and expiration / 1000 or '-'), 'c'..tostring(combat or "-"), 'd'..tostring(isdead or "-"), 'v'..(version or "-"))

		wfc.version[sender] = version or "-"

		if isdead == "1" then
			wfcShamanFrame:partyPlayerDead(playerIndex)
		elseif spellName ~= nil then -- update buffs
			local _, _, lagHome, _ = GetNetStats()
			local remain = (expiration - (lag + lagHome)) / 1000
			wfcShamanFrame:startTimerButton(gGUID, remain, wfc.icons[gGUID])
		else -- addon installed or buff expired
			wfcShamanFrame:showWarning(playerIndex, combat)
		end
	end
end

function wfc:PLAYER_ENTERING_WORLD()
	wfc:GROUP_ROSTER_UPDATE()
end

function wfc:ADDON_LOADED()
	wfc.eventReg:UnregisterEvent("ADDON_LOADED")
	wfcdb = wfcdb or {
		size = 37,
		space = 4,
		yspace = 0,
		xspace = 1,
	}
	wfcShamanFrame:initFrames() -- initiate frames early
	wfcShamanFrame:modLayout()
end

function wfc:ENCOUNTER_START(encounterId, encounterName)
	debug("ENCOUNTER_START", encounterId, encounterName)
	encounter = {
		id = encounterId,
		name = encounterName,
		start = GetTime(),
	}
end

function wfc:ENCOUNTER_END(encounterId)
	if encounter then
		debug("ENCOUNTER_END", encounterId)
		if encounterId == encounter.id then
			encounter.finish = GetTime()
		end
	end
end

local function wfSlashCommands(entry)
	local arg1, arg2 = strsplit(" ", entry)
	if isShaman and arg1 == "orientation" and (arg2 == "horizontal" or arg2 == "vertical") then
		if arg2 == "horizontal" then
			wfcdb.yspace = 0
			wfcdb.xspace = 1
			wfcShamanFrame:modLayout()
		elseif arg2 == "vertical" then
			wfcdb.yspace = 1
			wfcdb.xspace = 0
			wfcShamanFrame:modLayout()
		end
	elseif isShaman and arg1 == "spacing" and tonumber(arg2) then
		wfcdb.space = tonumber(arg2)
		wfcShamanFrame:modLayout()
	elseif isShaman and arg1 == "size" and tonumber(arg2) then
		-- If not handled above, display some sort of help message
		wfcdb.size = tonumber(arg2)
		wfcShamanFrame:modLayout()
	elseif isShaman and arg1 == "warn" and tonumber(arg2) then
		-- If not handled above, display some sort of help message
		wfcdb.warnsize = tonumber(arg2)
		wfcShamanFrame:modLayout()
	elseif arg1 == "debug" then
		wfcdb.debug = not wfcdb.debug
		out("Debug print is now " .. (wfcdb.debug and "enabled" or "disabled"))
	elseif pClass ~= "SHAMAN" and arg1 == "ar" then
		if wfcdb.alwaysReport then
			wfcdb.alwaysReport = false
			out("Will only report Windfury uptime after boss fights")
		else
			wfcdb.alwaysReport = true
			out("Will report Windfury uptime after each fight")
		end
	elseif arg1 == "ver" then
		for k, v in pairs(wfc.version) do
			local name = GetUnitName(k)
			if name then
				out(name .. ": " .. v)
			end
		end
	elseif arg1 == "show" then
		if isShaman then
			wfcShamanFrame:Show()
			for i = 0, 3 do
				wfc.buttons[i]:Show()
			end
		end
	elseif arg1 == "hide" then
		if isShaman then
			wfcShamanFrame:Hide()
			for i = 0, 3 do
				wfc.buttons[i]:Hide()
			end
		end
	else
		out("WindfuryComm++ commands:")
		if pClass ~= "SHAMAN" then
			out("/wfc <hide/show> - show or hide party icons")
			out("/wfc ar - always report wf uptime, after each fight")
		end
		if isShaman then
			out("/wfc orientation <horizontal/vertical> - layout of icons")
			out("/wfc size <integer> (" .. wfcdb.size .. ") - scale of icons")
			out("/wfc spacing <integer> (" .. wfcdb.space .. ") - spacing between icons")
			out("/wfc ver - print version")
			out("/wfc warn <integer> (" .. wfcdb.warnsize .. ") - size of warning border")
		end
	end
end

wfc.eventReg:SetScript("OnEvent", function(self, event, ...)
	if isShaman then
		if 	event == "ADDON_LOADED" or
			event == "PLAYER_ENTERING_WORLD" or
			event == "CHAT_MSG_ADDON" or
			event == "GROUP_ROSTER_UPDATE"
		then
			return wfc[event](self, event, ...)
		end
	elseif isMelee then
		if event == "ENCOUNTER_START" then
			wfc:ENCOUNTER_START(...)
		elseif event == "ENCOUNTER_END" then
			wfc:ENCOUNTER_END(...)
		end
	end
end)

SLASH_WFC1 = "/wfc"
SlashCmdList["WFC"] = wfSlashCommands

if isMelee then
	C_Timer.After(2, function() registerUptimeReport() end)
end
