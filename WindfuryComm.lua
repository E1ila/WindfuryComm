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

local wfcLib = LibStub("LibWFcomm")

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

function wfc:ShowUI(onload)
	wfcdbc.shown = true
	if isShaman then
		wfcShamanFrame:ShowUI()
	elseif isMelee and not onload then
		wfcMeleeFrame:ShowUI()
	end
end

function wfc:HideUI()
	wfcdbc.shown = false
	if isShaman then
		wfcShamanFrame:HideUI()
	elseif isMelee then
		wfcMeleeFrame:HideUI()
	end
	out("UI hidden, write |cffff8800/wfc show|r to show it again")
end

function wfc:ADDON_LOADED()
	wfc.eventReg:UnregisterEvent("ADDON_LOADED")
	wfcdb = wfcdb or {
		size = 37,
		space = 4,
		yspace = 0,
		xspace = 1,
	}
	wfcdbc = wfcdbc or {
		shown = true,
	}
	if isShaman then
		wfcShamanFrame:Init() -- initiate frames early
	elseif isMelee then
		wfcMeleeFrame:Init(wfcLib)
	end
	if wfcdbc.shown == nil or wfcdbc.shown then
		self:ShowUI(true)
	else
		self:HideUI()
	end
end

local function wfSlashCommands(entry)
	local arg1, arg2 = strsplit(" ", entry)
	if isShaman and arg1 == "orientation" and (arg2 == "horizontal" or arg2 == "vertical") then
		wfcShamanFrame:flipLayout()
	elseif isShaman and arg1 == "spacing" and tonumber(arg2) then
		wfcShamanFrame:setSpacing(arg2)
	elseif isShaman and arg1 == "size" and tonumber(arg2) then
		wfcShamanFrame:setSize(arg2)
	elseif isShaman and arg1 == "warn" and tonumber(arg2) then
		wfcShamanFrame:setWarnSize(arg2)
	elseif arg1 == "debug" then
		wfcdb.debug = not wfcdb.debug
		out("Debug print is now " .. (wfcdb.debug and "enabled" or "disabled"))
	elseif isMelee and arg1 == "shrink" then
		wfcdb.shrink = not wfcdb.shrink
		out("Shrink totem window is now " .. (wfcdb.debug and "enabled" or "disabled"))
	elseif arg1 == "ver" then
		for k, v in pairs(wfc.version) do
			local name = GetUnitName(k)
			if name then
				out(name .. ": " .. v)
			end
		end
	elseif arg1 == "show" then
		wfc:ShowUI()
	elseif arg1 == "hide" then
		wfc:HideUI()
	else
		out("WindfuryComm++ commands:")
		out("/wfc <hide/show> - show or hide UI")
		if isMelee then
			out("/wfc shrink - toggle shrink UI according to totem list")
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
		if  event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
			wfcShamanFrame:GROUP_ROSTER_UPDATE()
		elseif event == "CHAT_MSG_ADDON" then
			wfcShamanFrame:CHAT_MSG_ADDON(prefix, message, channel, sender)
		end
	elseif isMelee then
		if event == "ENCOUNTER_START" then
			wfcMeleeFrame:ENCOUNTER_START(...)
		elseif event == "ENCOUNTER_END" then
			wfcMeleeFrame:ENCOUNTER_END(...)
		elseif event == "GROUP_ROSTER_UPDATE" then
			wfcMeleeFrame:GROUP_ROSTER_UPDATE(...)
		end
	end
end)

SLASH_WFC1 = "/wfc"
SlashCmdList["WFC"] = wfSlashCommands
