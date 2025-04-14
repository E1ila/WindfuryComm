wfc = CreateFrame("Frame", "wfc")
wfc.version = {}

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
local encounter

local wfcLib = LibStub("LibWFcomm")

local COMM_PREFIX = "WF_STATUS"
C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)

local function out(text, ...)
	print(" |cffff8800{|cffffbb00WFC++|cffff8800}|r "..text, ...)
end
wfc.out = out

local function debug(text, ...)
	if wfcdb.debug then
		out(text, ...)
	end
end
wfc.debug = debug

function wfc:GROUP_ROSTER_UPDATE()
	wfcShamanFrame:GROUP_ROSTER_UPDATE()
end

function wfc:CHAT_MSG_ADDON(prefix, message, channel, sender)
	wfcShamanFrame:CHAT_MSG_ADDON(prefix, message, channel, sender)
end

function wfc:PLAYER_ENTERING_WORLD()
	wfcShamanFrame:GROUP_ROSTER_UPDATE()
end

function wfc:ADDON_LOADED()
	wfc.eventReg:UnregisterEvent("ADDON_LOADED")
	wfcdb = wfcdb or {
		size = 37,
		space = 4,
		yspace = 0,
		xspace = 1,
	}
	if isShaman then
		wfcShamanFrame:initFrames() -- initiate frames early
		wfcShamanFrame:modLayout()
	elseif isMelee then
		wfcMeleeFrame:init(wfcLib)
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
				wfcShamanFrame.buttons[i]:Show()
			end
		end
	elseif arg1 == "hide" then
		if isShaman then
			wfcShamanFrame:Hide()
			for i = 0, 3 do
				wfcShamanFrame.buttons[i]:Hide()
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
	if event == "ADDON_LOADED" then
		wfc:ADDON_LOADED(...)
	end
	if isShaman then
		if 	event == "PLAYER_ENTERING_WORLD" or
			event == "CHAT_MSG_ADDON" or
			event == "GROUP_ROSTER_UPDATE"
		then
			return wfc[event](self, ...)
		end
	elseif isMelee then
		if event == "ENCOUNTER_START" then
			wfcMeleeFrame:ENCOUNTER_START(...)
		elseif event == "ENCOUNTER_END" then
			wfcMeleeFrame:ENCOUNTER_END(...)
		end
	end
end)

SLASH_WFC1 = "/wfc"
SlashCmdList["WFC"] = wfSlashCommands
