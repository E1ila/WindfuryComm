assert(LibStub, "WindfuryComm requires LibStub")

local major, minor = "LibWFcomm", 3
local LibWFcomm = LibStub:NewLibrary(major, minor)
local CTL = _G.ChatThrottleLib
local COMM_PREFIX = "WF_STATUS"
local COMM_PREFIX_RAID = "WF_RAID_STATUS"
C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)

pGUID = UnitGUID("player")
pClass = select(2, UnitClass("player"))

local lastExpiration
local hasRefreshed = false

-- new message format C_ChatInfo.SendAddonMessage("WF_STATUS", "<guid>:<id>:<expire>:<lagHome>:additional:stuff", "PARTY")
function windfuryDurationCheck()
	msg = nil
	local _,_,lagHome,_ = GetNetStats()
	local mh,expiration,_,enchid,_,_,_,_ = GetWeaponEnchantInfo("player")
	local combat = InCombatLockdown() and "1" or "0"
	local isdead = UnitIsDeadOrGhost("player") and "1" or "0"

	if mh then
		msg = format("%s:%d:%d:%d:%s:%s:%d", pGUID, enchid, expiration, lagHome, combat, isdead, minor) -- message: wf active + duration
		if lastExpiration == nil or expiration > lastExpiration then
			hasRefreshed = true
		end
	else
		msg = format("%s:nil:nil:%s:%s:%s:%d", pGUID, lagHome, combat, isdead, minor) -- message: wf expired
	end
	lastExpiration = expiration
	--print('LibWFcomm', mh, expiration, lastStatus, hasRefreshed)

	if CTL and msg and (lastStatus ~= mh or hasRefreshed) then
		CTL:SendAddonMessage("BULK", COMM_PREFIX, msg, 'PARTY')
		if lastStatus ~= mh then
			-- not sending refresh msgs to raid to reduce spam
			CTL:SendAddonMessage("BULK", COMM_PREFIX_RAID, msg, 'RAID')
		end
		--print("LibWFcomm - ", msg)
		lastStatus = mh
	end
	msg = nil
end

function checkForShaman()
	local shamanPresent = nil
	for index=1,4 do
		local pstring = "party"..index
		local gclass = select(2, UnitClass(pstring))
		if (gclass == "SHAMAN") then
			shamanPresent = true
		end
	end
	return shamanPresent
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
