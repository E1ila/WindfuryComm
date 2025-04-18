wfc = CreateFrame("Frame", "wfc")
wfc.version = {}

wfc.eventReg = wfc.eventReg or CreateFrame("Frame")
wfc.eventReg:RegisterEvent("PLAYER_ENTERING_WORLD")
wfc.eventReg:RegisterEvent("GROUP_ROSTER_UPDATE")
wfc.eventReg:RegisterEvent("CHAT_MSG_ADDON")
wfc.eventReg:RegisterEvent("ADDON_LOADED")
wfc.eventReg:RegisterEvent("ENCOUNTER_START")
wfc.eventReg:RegisterEvent("ENCOUNTER_END")

local version = "2.1.0"
local numericalVersion = 20100
local newVersionAlerted = false
local pClass = select(2, UnitClass("player"))
local isShaman = pClass == "SHAMAN"
local isMelee = pClass == "WARRIOR" or pClass == "ROGUE"

local wfcLib = LibStub("LibWFcomm")
local CTL = _G.ChatThrottleLib

local COMM_PREFIX_VERSION = "WFC_VERSION"
C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX_VERSION)

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

local wasInGroup = IsInGroup()
local function broadcastVersionIfNeeded()
	local inGroup = IsInGroup()
	if inGroup and not wasInGroup and CTL then
		CTL:SendAddonMessage("BULK", COMM_PREFIX_VERSION, tostring(numericalVersion), 'RAID')
	end
	wasInGroup = inGroup
end

function wfc:ShowUI(onload)
	wfcdbc.shown = true
	if isShaman then
		WFCShamanFrame:ShowUI()
	elseif isMelee and not onload then
		WFCMeleeFrame:ShowUI()
	end
end

function wfc:HideUI()
	wfcdbc.shown = false
	if isShaman then
		WFCShamanFrame:HideUI()
	elseif isMelee then
		WFCMeleeFrame:HideUI()
	end
	out("UI hidden, write |cffff8800/wfc show|r to show it again")
end

function wfc:InitSavedVariables()
	wfcdb = wfcdb or {
		version = numericalVersion,
		size = 37,
		space = 4,
		yspace = 0,
		xspace = 1,
	}
	wfcdbc = wfcdbc or {
		version = numericalVersion,
		shown = true,
	}
	if not wfcdb.version then wfcdb.version = numericalVersion end
	if not wfcdbc.version then wfcdbc.version = numericalVersion end
end

function wfc:InitUI()
	if isShaman then
		WFCShamanFrame:Init() -- initiate frames early
	elseif isMelee then
		WFCMeleeFrame:Init(wfcLib)
	end
	if wfcdbc.shown == nil or wfcdbc.shown then
		self:ShowUI(true)
	else
		self:HideUI()
	end
end

function wfc:ADDON_LOADED()
	self.eventReg:UnregisterEvent("ADDON_LOADED")
	self:InitSavedVariables()
	self:InitUI()
	out("WindfuryComm++ v"..version.." loaded")
end

function wfc:CHAT_MSG_ADDON(prefix, message, channel, sender)
	if prefix == COMM_PREFIX_VERSION then
		local otherVersion = tonumber(message)
		if not newVersionAlerted and otherVersion and otherVersion > numericalVersion then
			newVersionAlerted = true
			out("|cff00bbffThere's a newer version of WindfuryComm++, please update.|r")
		end
	elseif isShaman then
		WFCShamanFrame:CHAT_MSG_ADDON(prefix, message, channel, sender)
	end
end

local function WFCSlashCommands(entry)
	local arg1, arg2 = strsplit(" ", entry)
	if isShaman and arg1 == "orientation" and (arg2 == "horizontal" or arg2 == "vertical") then
		WFCShamanFrame:FlipLayout()
	elseif isShaman and arg1 == "spacing" and tonumber(arg2) then
		WFCShamanFrame:SetSpacing(arg2)
	elseif isShaman and arg1 == "size" and tonumber(arg2) then
		WFCShamanFrame:SetScale(arg2)
	elseif isShaman and arg1 == "warn" and tonumber(arg2) then
		WFCShamanFrame:SetWarnSize(arg2)
	elseif isMelee and arg1 == "reset" then
		WFCMeleeFrame:ResetStats()
	elseif arg1 == "resetpos" then
		if isShaman then
			WFCShamanFrame:ResetPos()
		elseif isMelee then
			WFCMeleeFrame:ResetPos()
		end
	elseif arg1 == "debug" then
		wfcdb.debug = not wfcdb.debug
		out("Debug print is now " .. (wfcdb.debug and "enabled" or "disabled"))
	elseif arg1 == "ver" then
		for k, v in pairs(wfc.version) do
			local name = GetUnitName(k)
			if name then
				out(name .. ": " .. v)
			end
		end
	elseif arg1 == "show" then
		wfc:ShowUI()
	elseif arg1 == "lock" then
		wfcdbc.locked = not wfcdbc.locked
		wfc.out("Window is now " .. (wfcdbc.locked and "locked" or "unlocked"))
	elseif arg1 == "hide" then
		wfc:HideUI()
	else
		out("|cffff8800WindfuryComm++|r v"..version.." commands:")
		out("/wfc <hide/show> - show or hide UI")
		if isMelee then
			out("/wfc reset - reset stats")
		end
		out("/wfc resetpos - reset window position")
		out("/wfc lock - toggle lock/unlock window position ("..(wfcdbc.locked and "locked" or "unlocked")..")")
		if isShaman then
			out("/wfc orientation <horizontal/vertical> - layout of icons")
			out("/wfc size <integer> - set size of icons (" .. wfcdb.size .. ")")
			out("/wfc spacing <integer> - set spacing between icons (" .. wfcdb.space .. ")")
			out("/wfc warn <integer> (" .. wfcdb.warnsize .. ") - size of warning border")
		end
	end
end

wfc.eventReg:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		wfc:ADDON_LOADED(...)
	end
	if event == "GROUP_ROSTER_UPDATE" then
		broadcastVersionIfNeeded()
		if isShaman then
			WFCShamanFrame:GROUP_ROSTER_UPDATE(...)
		elseif isMelee then
			WFCMeleeFrame:GROUP_ROSTER_UPDATE(...)
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		if isShaman then
			WFCShamanFrame:GROUP_ROSTER_UPDATE(...)
		end
	elseif event == "CHAT_MSG_ADDON" then
		wfc:CHAT_MSG_ADDON(...)
	elseif event == "ENCOUNTER_START" then
		if isMelee then
			WFCMeleeFrame:ENCOUNTER_START(...)
		end
	elseif event == "ENCOUNTER_END" then
		if isMelee then
			WFCMeleeFrame:ENCOUNTER_END(...)
		end
	end
end)

SLASH_WFC1 = "/wfc"
SlashCmdList["WFC"] = WFCSlashCommands
