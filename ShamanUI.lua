wfcShamanFrame = CreateFrame("Frame", "wfcShamanFrame", UIParent)
wfcShamanFrame.icons, wfcShamanFrame.guids, wfcShamanFrame.currentTimers, wfcShamanFrame.buttons = {}, {}, {}, {}
wfcShamanFrame.ixs, wfcShamanFrame.party, wfcShamanFrame.class = {}, {}, {}

local classIcon = {
    ["WARRIOR"] = "Interface\\Icons\\inv_sword_27",
    ["PALADIN"] = "Interface\\Icons\\ability_thunderbolt",
    -- ["HUNTER"] = "Interface\\Icons\\inv_weapon_bow_07",
    ["ROGUE"] = "Interface\\Icons\\inv_throwingknife_04",
}

function wfcShamanFrame:initFrames() -- initialize the frames on screen
    self:SetPoint("CENTER", UIParent, 0, -225)
    --wfcShamanFrame.texture = wfcShamanFrame:CreateTexture(nil, "BACKGROUND")
    --wfcShamanFrame.texture:SetAllPoints()
    --wfcShamanFrame.texture:SetColorTexture(0,0,0,0.3)
    self:EnableMouse(true)
    self:SetMovable(true)
    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            wfcShamanFrame:StartMoving()
        end
    end)
    self:SetScript("OnDragStop", self.StopMovingOrSizing)
    for i = 0, 3 do
        self.buttons[i] = CreateFrame("FRAME", nil, UIParent)
        self.buttons[i].bg = self.buttons[i]:CreateTexture(nil, "BACKGROUND")
        self.buttons[i].bg:SetColorTexture(1, 0, 0)
        self.buttons[i].bg:Hide()
        self.buttons[i].cd = CreateFrame("COOLDOWN", nil, self.buttons[i], "CooldownFrameTemplate")
        self.buttons[i].cd:SetDrawBling(false)
        self.buttons[i].cd:SetDrawEdge(false)
        self.buttons[i].name = self.buttons[i]:CreateFontString(nil, "ARTWORK")
        self.buttons[i].name:SetFont("Fonts\\FRIZQT__.ttf", 9, "OUTLINE")
        self.buttons[i].icon = self.buttons[i]:CreateTexture(nil, "ARTWORK")
        self.buttons[i].icon:SetTexture("Interface\\Icons\\Spell_nature_cyclone")
        self.buttons[i].icon:SetDesaturated(1)
        self.buttons[i].icon:SetAlpha(0.5)
        self.buttons[i]:Hide() -- hide buttons until group is joined
    end
    self:Hide() -- hide frame until group is joined
end

function wfcShamanFrame:modLayout()
    local warnsize = wfcdb.warnsize or 4
    local xsize = wfcdb.size + (wfcdb.size + wfcdb.space) * wfcdb.xspace * 3
    local ysize = wfcdb.size + (wfcdb.size + wfcdb.space) * wfcdb.yspace * 3
    self:SetSize(xsize, ysize)
    for i = 0, 3 do
        local xpoint, ypoint =
        i * (wfcdb.size + wfcdb.space) * wfcdb.xspace, i * (wfcdb.size + wfcdb.space) * wfcdb.yspace
        self.buttons[i]:SetPoint("TOPLEFT", self, "TOPLEFT", xpoint, ypoint)
        self.buttons[i]:SetSize(wfcdb.size, wfcdb.size)
        self.buttons[i].name:SetPoint("CENTER", self.buttons[i], "TOP", 0, 5)
        self.buttons[i].bg:SetSize(wfcdb.size + warnsize * 2, wfcdb.size + warnsize * 2)
        self.buttons[i].bg:SetPoint("TOPLEFT", self, "TOPLEFT", xpoint - warnsize, -ypoint + warnsize)
        self.buttons[i].icon:SetSize(wfcdb.size, wfcdb.size)
        self.buttons[i].icon:SetPoint("TOPLEFT", self, "TOPLEFT", xpoint, -ypoint)
        if warnsize == 0 then
            self.buttons[i].bg:Hide()
        end
    end
end

function wfcShamanFrame:collectGroupInfo()
    self:Show() -- group joined, show frame
    wipe(self.ixs)
    wipe(wfc.version)
    local j = -1
    for index = 1, 4 do
        local pstring = "party" .. index
        local gclass = select(2, UnitClass(pstring))
        self.buttons[index - 1]:Show() -- group joined, show buttons
        if classIcon[gclass] then
            local gGUID, name, color = UnitGUID(pstring), UnitName(pstring), RAID_CLASS_COLORS[gclass]
            j = j + 1
            self.ixs[gGUID], self.party[gGUID], self.class[gGUID], self.guids[j] = j, pstring, gGUID, gclass
            self.buttons[j].name:SetText(strsub(name, 1, 5))
            self.buttons[j].name:SetTextColor(color.r, color.g, color.b)
            self.buttons[j].icon:SetTexture(classIcon[gclass])
            self.buttons[j].icon:SetDesaturated(1)
            self.buttons[j].icon:SetAlpha(0.5)
            self.buttons[j].bg:Hide()
        end
    end
    j = nil
end

function wfcShamanFrame:resetGroup()
    for j = 0, 3 do
        self.buttons[j].name:SetText("")
        self.buttons[j].cd:SetCooldown(0, 0)
        self.buttons[j].icon:SetTexture("Interface\\ICONS\\Spell_nature_cyclone")
        self.buttons[j].icon:SetDesaturated(1)
        self.buttons[j].icon:SetAlpha(0.5)
        self.buttons[j].bg:Hide()
        self.buttons[j]:Hide() -- group reset, hide buttons
    end
    self:Hide() -- group reset, hide frame
end

function wfcShamanFrame:startTimerButton(gGUID, remain)
    icon = self.icons[gGUID]
    if remain > 0 and self.ixs[gGUID] then
        local j = self.ixs[gGUID]
        self.buttons[j].icon:SetDesaturated(nil)
        self.buttons[j].icon:SetAlpha(1)
        self.buttons[j].cd:SetCooldown(GetTime() - (10 - remain), 10)
        self.buttons[j].bg:Hide()
        self.icons[j] = icon
    end
end

function wfcShamanFrame:setBlockerButton(gGUID, remain, spellID)
    _, _, icon, _, _, _, _ = GetSpellInfo(spellID)
    if remain > 0 and self.ixs[gGUID] then
        local j = self.ixs[gGUID]
        self.buttons[j].icon:SetTexture(icon)
        self.buttons[j].icon:SetDesaturated(1)
        self.buttons[j].icon:SetAlpha(1)
        self.buttons[j].cd:SetCooldown(GetTime(), remain)
        self.icons[j] = icon
    end
end

function wfcShamanFrame:partyPlayerDead(playerIndex)
    self.buttons[playerIndex].icon:SetAlpha(1)
    self.buttons[playerIndex].icon:SetDesaturated(1)
    self.buttons[playerIndex].cd:SetCooldown(0, 0)
    self.buttons[playerIndex].bg:SetAlpha(0)
end

function wfcShamanFrame:showWarning(playerIndex, combat)
    self.buttons[playerIndex].icon:SetAlpha(1)
    self.buttons[playerIndex].icon:SetDesaturated(1)
    self.buttons[playerIndex].cd:SetCooldown(0, 0)
    if combat == "0" then
        self.buttons[playerIndex].bg:SetAlpha(0.2)
        self.buttons[playerIndex].bg:SetColorTexture(1, 1, 0)
    else
        self.buttons[playerIndex].bg:SetAlpha(1)
        self.buttons[playerIndex].bg:SetColorTexture(1, 0, 0)
    end
    if wfcdb.warnsize then
        self.buttons[playerIndex].bg:Show()
    end
end

function wfcShamanFrame:updateCurrentTimers()
    wipe(self.currentTimers)
    for j = 0, 3 do
        if self.guids[j] then
            gGUID = self.guids[j]
            self.currentTimers[gGUID] = self.buttons[j].cd:GetCooldownDuration() / 1000
        end
    end
end

function wfcShamanFrame:restartCurrentTimers()
    for gGUID, j in pairs(self.ixs) do
        if self.currentTimers[gGUID] then
            self:startTimerButton(gGUID, self.currentTimers[gGUID], self.icons[gGUID])
        end
    end
    wipe(self.currentTimers)
end
