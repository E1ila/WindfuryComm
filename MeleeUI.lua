local function registerUptimeReport(wfcLib)
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
        print("LibWFcomm not found!!")
    end
end

function wfcMeleeFrame_SessionButton:toggleSessionView()
    wfcdb.meleeCurrentSession = not wfcdb.meleeCurrentSession
    wfcMeleeFrame:updateSessionViewText()
end

function wfcMeleeFrame:updateSessionViewText()
    if wfcdb.meleeCurrentSession then
        wfcMeleeFrame_Header_Text:SetText("Current Fight")
    else
        wfcMeleeFrame_Header_Text:SetText("Overall")
    end
end

function wfcMeleeFrame:init(wfcLib)
    registerUptimeReport()
    self:updateSessionViewText()
    self:Show()
    C_Timer.After(2, function() registerUptimeReport(wfcLib) end)
end
