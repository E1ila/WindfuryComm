wfc = CreateFrame("Frame", "wfc")
wfc.currentTimers, wfc.buttons = {}, {}
wfc.UptimeReportHook = nil
wfc.ixs, wfc.party, wfc.guids, wfc.icons, wfc.class, wfc.version = {}, {}, {}, {}, {}, {}
wfc.eventReg = wfc.eventReg or CreateFrame("Frame")
wfc.eventReg:RegisterEvent("PLAYER_ENTERING_WORLD")
wfc.eventReg:RegisterEvent("GROUP_ROSTER_UPDATE")
wfc.eventReg:RegisterEvent("CHAT_MSG_ADDON")
wfc.eventReg:RegisterEvent("ADDON_LOADED")

local pClass = select(2, UnitClass("player"))
local wfcLib = LibStub("LibWFcomm")
local COMM_PREFIX = "WF_STATUS"

C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)

local classIcon = {
	["WARRIOR"] = "Interface\\Icons\\inv_sword_27",
	["PALADIN"] = "Interface\\Icons\\ability_thunderbolt",
	-- ["HUNTER"] = "Interface\\Icons\\inv_weapon_bow_07",
	["ROGUE"] = "Interface\\Icons\\inv_throwingknife_04",
}
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

local function initFrames() -- initialize the frames on screen
	wfcBgFrame = CreateFrame("Frame", "wfcBgFrame", UIParent)
	wfcBgFrame:SetPoint("CENTER", UIParent, 0, -225)
	--wfcBgFrame.texture = wfcBgFrame:CreateTexture(nil, "BACKGROUND")
	--wfcBgFrame.texture:SetAllPoints()
	--wfcBgFrame.texture:SetColorTexture(0,0,0,0.3)
	wfcBgFrame:EnableMouse(true)
	wfcBgFrame:SetMovable(true)
	wfcBgFrame:RegisterForDrag("LeftButton")
	wfcBgFrame:SetScript("OnDragStart", function(self)
		if IsShiftKeyDown() then
			wfcBgFrame:StartMoving()
		end
	end)
	wfcBgFrame:SetScript("OnDragStop", wfcBgFrame.StopMovingOrSizing)
	for i = 0, 3 do
		wfc.buttons[i] = CreateFrame("FRAME", nil, UIParent)
		wfc.buttons[i].bg = wfc.buttons[i]:CreateTexture(nil, "BACKGROUND")
		wfc.buttons[i].bg:SetColorTexture(1, 0, 0)
		wfc.buttons[i].bg:Hide()
		wfc.buttons[i].cd = CreateFrame("COOLDOWN", nil, wfc.buttons[i], "CooldownFrameTemplate")
		wfc.buttons[i].cd:SetDrawBling(false)
		wfc.buttons[i].cd:SetDrawEdge(false)
		wfc.buttons[i].name = wfc.buttons[i]:CreateFontString(nil, "ARTWORK")
		wfc.buttons[i].name:SetFont("Fonts\\FRIZQT__.ttf", 9, "OUTLINE")
		wfc.buttons[i].icon = wfc.buttons[i]:CreateTexture(nil, "ARTWORK")
		wfc.buttons[i].icon:SetTexture("Interface\\Icons\\Spell_nature_cyclone")
		wfc.buttons[i].icon:SetDesaturated(1)
		wfc.buttons[i].icon:SetAlpha(0.5)
		wfc.buttons[i]:Hide() -- hide buttons until group is joined
	end
	wfcBgFrame:Hide() -- hide frame until group is joined
end

local function modLayout()
	local warnsize = wfcdb.warnsize or 4
	local xsize = wfcdb.size + (wfcdb.size + wfcdb.space) * wfcdb.xspace * 3
	local ysize = wfcdb.size + (wfcdb.size + wfcdb.space) * wfcdb.yspace * 3
	wfcBgFrame:SetSize(xsize, ysize)
	for i = 0, 3 do
		local xpoint, ypoint =
			i * (wfcdb.size + wfcdb.space) * wfcdb.xspace, i * (wfcdb.size + wfcdb.space) * wfcdb.yspace
		wfc.buttons[i]:SetPoint("TOPLEFT", wfcBgFrame, "TOPLEFT", xpoint, ypoint)
		wfc.buttons[i]:SetSize(wfcdb.size, wfcdb.size)
		wfc.buttons[i].name:SetPoint("CENTER", wfc.buttons[i], "TOP", 0, 5)
		wfc.buttons[i].bg:SetSize(wfcdb.size + warnsize * 2, wfcdb.size + warnsize * 2)
		wfc.buttons[i].bg:SetPoint("TOPLEFT", wfcBgFrame, "TOPLEFT", xpoint - warnsize, -ypoint + warnsize)
		wfc.buttons[i].icon:SetSize(wfcdb.size, wfcdb.size)
		wfc.buttons[i].icon:SetPoint("TOPLEFT", wfcBgFrame, "TOPLEFT", xpoint, -ypoint)
		if warnsize == 0 then
			wfc.buttons[i].bg:Hide()
		end
	end
end

local function registerWfComm()
	if wfcLib then
		wfcLib.UptimeReportHook = function (combatTime, combatUptime, shaman, reporter, channel)
			debug("Combat uptime of", tostring(math.floor(combatUptime / combatTime * 100))..'%', 'by', '|cff0070DE'..shaman)
			if wfc.UptimeReportHook then
				wfc.UptimeReportHook(combatTime, combatUptime, shaman, reporter, channel)
			end
		end
	else
		out("LibWFcomm not found!!")
	end
end

local function collectGroupInfo()
	wfcBgFrame:Show() -- group joined, show frame
	wipe(wfc.ixs)
	wipe(wfc.version)
	local j = -1
	for index = 1, 4 do
		local pstring = "party" .. index
		local gclass = select(2, UnitClass(pstring))
		wfc.buttons[index - 1]:Show() -- group joined, show buttons
		if classIcon[gclass] then
			local gGUID, name, color = UnitGUID(pstring), UnitName(pstring), RAID_CLASS_COLORS[gclass]
			j = j + 1
			wfc.ixs[gGUID], wfc.party[gGUID], wfc.class[gGUID], wfc.guids[j] = j, pstring, gGUID, gclass
			wfc.buttons[j].name:SetText(strsub(name, 1, 5))
			wfc.buttons[j].name:SetTextColor(color.r, color.g, color.b)
			wfc.buttons[j].icon:SetTexture(classIcon[gclass])
			wfc.buttons[j].icon:SetDesaturated(1)
			wfc.buttons[j].icon:SetAlpha(0.5)
			wfc.buttons[j].bg:Hide()
		end
	end
	j = nil
end

local function resetGroup()
	for j = 0, 3 do
		wfc.buttons[j].name:SetText("")
		wfc.buttons[j].cd:SetCooldown(0, 0)
		wfc.buttons[j].icon:SetTexture("Interface\\ICONS\\Spell_nature_cyclone")
		wfc.buttons[j].icon:SetDesaturated(1)
		wfc.buttons[j].icon:SetAlpha(0.5)
		wfc.buttons[j].bg:Hide()
		wfc.buttons[j]:Hide() -- group reset, hide buttons
	end
	wfcBgFrame:Hide() -- group reset, hide frame
end

local function startTimerButton(gGUID, remain, icon)
	if remain > 0 and wfc.ixs[gGUID] then
		local j = wfc.ixs[gGUID]
		wfc.buttons[j].icon:SetDesaturated(nil)
		wfc.buttons[j].icon:SetAlpha(1)
		wfc.buttons[j].cd:SetCooldown(GetTime() - (10 - remain), 10)
		wfc.buttons[j].bg:Hide()
		wfc.icons[j] = icon
	end
end

local function setBlockerButton(gGUID, remain, spellID)
	_, _, icon, _, _, _, _ = GetSpellInfo(spellID)
	if remain > 0 and wfc.ixs[gGUID] then
		local j = wfc.ixs[gGUID]
		wfc.buttons[j].icon:SetTexture(icon)
		wfc.buttons[j].icon:SetDesaturated(1)
		wfc.buttons[j].icon:SetAlpha(1)
		wfc.buttons[j].cd:SetCooldown(GetTime(), remain)
		wfc.icons[j] = icon
	end
end

local function partyPlayerDead(playerIndex)
	wfc.buttons[playerIndex].icon:SetAlpha(1)
	wfc.buttons[playerIndex].icon:SetDesaturated(1)
	wfc.buttons[playerIndex].cd:SetCooldown(0, 0)
	wfc.buttons[playerIndex].bg:SetAlpha(0)
end

local function showWarning(playerIndex, combat)
	wfc.buttons[playerIndex].icon:SetAlpha(1)
	wfc.buttons[playerIndex].icon:SetDesaturated(1)
	wfc.buttons[playerIndex].cd:SetCooldown(0, 0)
	if combat == "0" then
		wfc.buttons[playerIndex].bg:SetAlpha(0.2)
		wfc.buttons[playerIndex].bg:SetColorTexture(1, 1, 0)
	else
		wfc.buttons[playerIndex].bg:SetAlpha(1)
		wfc.buttons[playerIndex].bg:SetColorTexture(1, 0, 0)
	end
	if wfcdb.warnsize then
		wfc.buttons[playerIndex].bg:Show()
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
			startTimerButton(gGUID, wfc.currentTimers[gGUID], wfc.icons[gGUID])
		end
	end
	wipe(wfc.currentTimers)
end

function wfc:GROUP_ROSTER_UPDATE()
	if GetNumGroupMembers() == 0 then
		resetGroup()
	else
		currentTimers()
		resetGroup()
		collectGroupInfo()
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
			partyPlayerDead(playerIndex)
		elseif spellName ~= nil then -- update buffs
			local _, _, lagHome, _ = GetNetStats()
			local remain = (expiration - (lag + lagHome)) / 1000
			startTimerButton(gGUID, remain, wfc.icons[gGUID])
		else -- addon installed or buff expired
			showWarning(playerIndex, combat)
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
	initFrames() -- initiate frames early
	modLayout()
end

local function wfSlashCommands(entry)
	local arg1, arg2 = strsplit(" ", entry)
	if arg1 == "orientation" and (arg2 == "horizontal" or arg2 == "vertical") then
		if arg2 == "horizontal" then
			wfcdb.yspace = 0
			wfcdb.xspace = 1
			modLayout()
		elseif arg2 == "vertical" then
			wfcdb.yspace = 1
			wfcdb.xspace = 0
			modLayout()
		end
	elseif arg1 == "spacing" and tonumber(arg2) then
		wfcdb.space = tonumber(arg2)
		modLayout()
	elseif arg1 == "size" and tonumber(arg2) then
		-- If not handled above, display some sort of help message
		wfcdb.size = tonumber(arg2)
		modLayout()
	elseif arg1 == "warn" and tonumber(arg2) then
		-- If not handled above, display some sort of help message
		wfcdb.warnsize = tonumber(arg2)
		modLayout()
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
		wfcBgFrame:Show()
		for i = 0, 3 do
			wfc.buttons[i]:Show()
		end
	elseif arg1 == "hide" then
		wfcBgFrame:Hide()
		for i = 0, 3 do
			wfc.buttons[i]:Hide()
		end
	else
		out("WindfuryComm++ commands:")
		out("/wfc orientation <horizontal/vertical>")
		out("/wfc size <integer> (" .. wfcdb.size .. ")")
		out("/wfc warn <integer> (" .. wfcdb.warnsize .. ")")
		out("/wfc spacing <integer> (" .. wfcdb.space .. ")")
		out("/wfc <hide/show>")
	end
end

if pClass == "SHAMAN" then
	SLASH_WFC1 = "/wfc"
	SlashCmdList["WFC"] = wfSlashCommands
	wfc.eventReg:SetScript("OnEvent", function(self, event, ...)
		return wfc[event](self, event, ...)
	end)
end

C_Timer.After(2, function() registerWfComm() end)
