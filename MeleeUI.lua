wfcMeleeFrame = CreateFrame("Frame", "wfcMeleeFrame", UIParent)

function wfcMeleeFrame:initFrames() -- initialize the frames on screen
    wfcMeleeFrame:SetPoint("CENTER", UIParent, 0, -125)
    wfcMeleeFrame:EnableMouse(true)
    wfcMeleeFrame:SetMovable(true)
    wfcMeleeFrame:RegisterForDrag("LeftButton")
    wfcMeleeFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            wfcMeleeFrame:StartMoving()
        end
    end)
    wfcMeleeFrame:SetScript("OnDragStop", wfcMeleeFrame.StopMovingOrSizing)
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
    wfcMeleeFrame:Hide() -- hide frame until group is joined
end

function wfcMeleeFrame:modLayout()
    local warnsize = wfcdb.warnsize or 4
    local xsize = wfcdb.size + (wfcdb.size + wfcdb.space) * wfcdb.xspace * 3
    local ysize = wfcdb.size + (wfcdb.size + wfcdb.space) * wfcdb.yspace * 3
    wfcMeleeFrame:SetSize(xsize, ysize)
    for i = 0, 3 do
        local xpoint, ypoint =
        i * (wfcdb.size + wfcdb.space) * wfcdb.xspace, i * (wfcdb.size + wfcdb.space) * wfcdb.yspace
        wfc.buttons[i]:SetPoint("TOPLEFT", wfcMeleeFrame, "TOPLEFT", xpoint, ypoint)
        wfc.buttons[i]:SetSize(wfcdb.size, wfcdb.size)
        wfc.buttons[i].name:SetPoint("CENTER", wfc.buttons[i], "TOP", 0, 5)
        wfc.buttons[i].bg:SetSize(wfcdb.size + warnsize * 2, wfcdb.size + warnsize * 2)
        wfc.buttons[i].bg:SetPoint("TOPLEFT", wfcMeleeFrame, "TOPLEFT", xpoint - warnsize, -ypoint + warnsize)
        wfc.buttons[i].icon:SetSize(wfcdb.size, wfcdb.size)
        wfc.buttons[i].icon:SetPoint("TOPLEFT", wfcMeleeFrame, "TOPLEFT", xpoint, -ypoint)
        if warnsize == 0 then
            wfc.buttons[i].bg:Hide()
        end
    end
end

function wfcMeleeFrame:collectGroupInfo()
    wfcMeleeFrame:Show() -- group joined, show frame
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

function wfcMeleeFrame:resetGroup()
    for j = 0, 3 do
        wfc.buttons[j].name:SetText("")
        wfc.buttons[j].cd:SetCooldown(0, 0)
        wfc.buttons[j].icon:SetTexture("Interface\\ICONS\\Spell_nature_cyclone")
        wfc.buttons[j].icon:SetDesaturated(1)
        wfc.buttons[j].icon:SetAlpha(0.5)
        wfc.buttons[j].bg:Hide()
        wfc.buttons[j]:Hide() -- group reset, hide buttons
    end
    wfcMeleeFrame:Hide() -- group reset, hide frame
end

function wfcMeleeFrame:startTimerButton(gGUID, remain, icon)
    if remain > 0 and wfc.ixs[gGUID] then
        local j = wfc.ixs[gGUID]
        wfc.buttons[j].icon:SetDesaturated(nil)
        wfc.buttons[j].icon:SetAlpha(1)
        wfc.buttons[j].cd:SetCooldown(GetTime() - (10 - remain), 10)
        wfc.buttons[j].bg:Hide()
        wfc.icons[j] = icon
    end
end

function wfcMeleeFrame:setBlockerButton(gGUID, remain, spellID)
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

function wfcMeleeFrame:partyPlayerDead(playerIndex)
    wfc.buttons[playerIndex].icon:SetAlpha(1)
    wfc.buttons[playerIndex].icon:SetDesaturated(1)
    wfc.buttons[playerIndex].cd:SetCooldown(0, 0)
    wfc.buttons[playerIndex].bg:SetAlpha(0)
end

function wfcMeleeFrame:showWarning(playerIndex, combat)
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
