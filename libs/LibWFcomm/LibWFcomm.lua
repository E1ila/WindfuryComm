assert(LibStub, "WindfuryComm requires LibStub")

local major, minor = "LibWFcomm", 3
local LibWFcomm = LibStub:NewLibrary(major, minor)
local CTL = _G.ChatThrottleLib
local COMM_PREFIX = "WF_STATUS"
local COMM_PREFIX_CREDIT = "WF_CREDIT"
local WF_ENCHANT_SPELL_ID = { [564] = 'WF3', [563] = 'WF2', [1783] = 'WF1' }
C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX_CREDIT)

pGUID = UnitGUID("player")
pClass = select(2, UnitClass("player"))

local lastExpiration
local hasRefreshed = false
local myShaman
local combatStart
local combatWfStart
local combatUptime

-- new message format C_ChatInfo.SendAddonMessage("WF_STATUS", "<guid>:<id>:<expire>:<lagHome>:additional:stuff", "PARTY")
function windfuryDurationCheck()
	local msg
	local _,_,lagHome,_ = GetNetStats()
	local mh,expiration,_,enchid,_,_,_,_ = GetWeaponEnchantInfo("player")
	local combat = InCombatLockdown() and "1" or "0"
	local isdead = UnitIsDeadOrGhost("player") and "1" or "0"

	--print("combatStart", combatStart, "combatWfStart", combatWfStart, "combatUptime", combatUptime)
	if not combatStart and combat == "1" then
		--print("Combat started")
		combatStart = GetTime()
		combatUptime = 0
	elseif combatStart and combat == "0" then
		if combatWfStart then
			combatUptime = combatUptime + (GetTime() - combatWfStart)
		end
		local creditmsg = format("%d:%s", math.floor(combatUptime + 0.5), myShaman)
		--print("Combat ended, uptime", combatUptime, " credit to", myShaman, ' ', creditmsg)
		CTL:SendAddonMessage("NORMAL", COMM_PREFIX_CREDIT, creditmsg, 'RAID')
		combatStart = nil
		combatWfStart = nil
	end

	if mh then
		msg = format("%s:%d:%d:%d:%s:%s:%d", pGUID, enchid, expiration, lagHome, combat, isdead, minor) -- message: wf active + duration
		local spellName = WF_ENCHANT_SPELL_ID[enchid]
		if spellName then
			if combatStart and not combatWfStart then
				--print("taking WfStart time")
				combatWfStart = GetTime()
			end
		end
		if lastExpiration == nil or expiration > lastExpiration then
			hasRefreshed = true
		end
	else
		msg = format("%s:nil:nil:%s:%s:%s:%d", pGUID, lagHome, combat, isdead, minor) -- message: wf expired
		if combatStart and combatWfStart then
			combatUptime = combatUptime + (GetTime() - combatWfStart)
			--print("WF dropped, so far uptime", combatUptime, " credit to", myShaman)
			combatWfStart = nil
		end
	end
	lastExpiration = expiration

	if CTL and msg and (lastStatus ~= mh or hasRefreshed) then
		CTL:SendAddonMessage("BULK", COMM_PREFIX, msg, 'PARTY')
		lastStatus = mh
	end
end

function checkForShaman()
	myShaman = nil
	for index=1,4 do
		local pstring = "party"..index
		local gclass = select(2, UnitClass(pstring))
		if (gclass == "SHAMAN") then
			myShaman = UnitName(pstring)
		end
	end
	return myShaman
end
		

function LibWFcomm:PLAYER_LOGIN()
	self.eventReg:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:GROUP_ROSTER_UPDATE()
	print( "WindfuryComm++ sender module loaded" )
end

function LibWFcomm:GROUP_ROSTER_UPDATE()
	if( GetNumGroupMembers() ~= 0 and checkForShaman()) then
		LibWFcomm.eventReg:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
		LibWFcomm.eventReg:RegisterEvent("PLAYER_REGEN_DISABLED")
		LibWFcomm.eventReg:RegisterEvent("PLAYER_REGEN_ENABLED")
		LibWFcomm.eventReg:RegisterEvent("PLAYER_DEAD")
		LibWFcomm.eventReg:RegisterEvent("PLAYER_ALIVE")
		C_Timer.After(0.15, function() windfuryDurationCheck() end)
	else
		LibWFcomm.eventReg:UnregisterEvent("UNIT_INVENTORY_CHANGED")
		LibWFcomm.eventReg:UnregisterEvent("PLAYER_REGEN_DISABLED")
		LibWFcomm.eventReg:UnregisterEvent("PLAYER_REGEN_ENABLED")
		LibWFcomm.eventReg:UnregisterEvent("PLAYER_DEAD")
		LibWFcomm.eventReg:UnregisterEvent("PLAYER_ALIVE")
	end
end

function LibWFcomm:UNIT_INVENTORY_CHANGED()
	-- This event fires when:
	-- • You equip or unequip an item.
	-- • An item in your equipment slots is changed or swapped.
	-- • Your durability changes, which may affect certain gear-dependent stats.
	-- • A transmog change is applied (in some cases).
	-- • A trinket or weapon with charges has a state change.
	C_Timer.After(0.15, function() windfuryDurationCheck() end)
end

function LibWFcomm:PLAYER_REGEN_DISABLED()
	C_Timer.After(0.15, function() windfuryDurationCheck() end)
end

function LibWFcomm:PLAYER_REGEN_ENABLED()
	C_Timer.After(0.15, function() windfuryDurationCheck() end)
end

function LibWFcomm:PLAYER_DEAD()
	C_Timer.After(0.15, function() windfuryDurationCheck() end)
end

function LibWFcomm:PLAYER_ALIVE()
	C_Timer.After(0.15, function() windfuryDurationCheck() end)
end

local function OnEvent(self, event, ...)
	LibWFcomm[event](LibWFcomm, ...)
end

if ( pClass == "WARRIOR" or pClass == "ROGUE" or pClass == "PALADIN" or pClass == "HUNTER" ) then
	LibWFcomm.eventReg = LibWFcomm.eventReg or CreateFrame("Frame")
	LibWFcomm.eventReg:SetScript("OnEvent", OnEvent)
	if( not IsLoggedIn() ) then
		LibWFcomm.eventReg:RegisterEvent("PLAYER_LOGIN")
	else
		LibWFcomm:PLAYER_LOGIN()
	end
end
