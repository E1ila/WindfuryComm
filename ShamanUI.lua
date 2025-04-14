wfcBgFrame = CreateFrame("Frame", "wfcBgFrame", UIParent)

local classIcon = {
    ["WARRIOR"] = "Interface\\Icons\\inv_sword_27",
    ["PALADIN"] = "Interface\\Icons\\ability_thunderbolt",
    -- ["HUNTER"] = "Interface\\Icons\\inv_weapon_bow_07",
    ["ROGUE"] = "Interface\\Icons\\inv_throwingknife_04",
}

function wfcBgFrame:initFrames() -- initialize the frames on screen
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

function wfcBgFrame:modLayout()
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

function wfcBgFrame:collectGroupInfo()
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

function wfcBgFrame:resetGroup()
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

function wfcBgFrame:startTimerButton(gGUID, remain, icon)
    if remain > 0 and wfc.ixs[gGUID] then
        local j = wfc.ixs[gGUID]
        wfc.buttons[j].icon:SetDesaturated(nil)
        wfc.buttons[j].icon:SetAlpha(1)
        wfc.buttons[j].cd:SetCooldown(GetTime() - (10 - remain), 10)
        wfc.buttons[j].bg:Hide()
        wfc.icons[j] = icon
    end
end

function wfcBgFrame:setBlockerButton(gGUID, remain, spellID)
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

function wfcBgFrame:partyPlayerDead(playerIndex)
    wfc.buttons[playerIndex].icon:SetAlpha(1)
    wfc.buttons[playerIndex].icon:SetDesaturated(1)
    wfc.buttons[playerIndex].cd:SetCooldown(0, 0)
    wfc.buttons[playerIndex].bg:SetAlpha(0)
end

function wfcBgFrame:showWarning(playerIndex, combat)
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
