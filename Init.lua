local _, ING = ...

-- Events, refresh timing and the /ing command.

local refreshPending = false

function ING.Refresh()
    if not ING.Scanner.IsIndexed() then
        ING.FireResults()
        return
    end
    local ok, results = pcall(ING.Scanner.Compute)
    if not ok then
        geterrorhandler()(results)
        return
    end
    local okCoach, tips = pcall(ING.Coach.Evaluate, results)
    if okCoach then
        results.coach = tips
    else
        geterrorhandler()(tips)
    end
    ING.results = results
    ING.FireResults()
end

-- Many events fire together (accepting a quest, levelling up); wait a moment
-- so the quest log and Questie have caught up, and refresh once.
function ING.RequestRefresh(delay)
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(delay or 1, function()
        refreshPending = false
        ING.Refresh()
    end)
end

-- Questie needs a few seconds after login before its data is ready.
local function WaitForQuestie()
    local waited = 0
    local ticker
    ticker = C_Timer.NewTicker(1, function()
        waited = waited + 1
        if ING.Scanner.IsQuestieReady() or waited >= 90 then
            ticker:Cancel()
            ING.Scanner.StartIndex()
        end
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ING.LoadSettings()
        ING.playerLevel = UnitLevel("player")
        ING.UpdateMinimapButton()
        ING.UpdatePanelVisibility()
        ING.Coach.Start()
        WaitForQuestie()
        self:RegisterEvent("PLAYER_LEVEL_UP")
        self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        self:RegisterEvent("QUEST_ACCEPTED")
        self:RegisterEvent("QUEST_TURNED_IN")
        self:RegisterEvent("QUEST_REMOVED")
        self:RegisterEvent("SKILL_LINES_CHANGED")
        -- Moving changes the distance to quest givers; re-sort while visible.
        C_Timer.NewTicker(5, function()
            local window = _G.ImpulsNoobGuidanceWindow
            if ING.Scanner.IsIndexed() and (ING.char.panelShown or (window and window:IsShown())) then
                ING.Refresh()
            end
        end)
    elseif event == "PLAYER_LEVEL_UP" then
        -- UnitLevel can still return the old level during this event.
        ING.playerLevel = ...
        ING.RequestRefresh(1)
    elseif event == "QUEST_TURNED_IN" then
        -- Questie marks the quest complete shortly after this event.
        ING.RequestRefresh(2)
    else
        ING.RequestRefresh(1)
    end
end)

local function HelpLines()
    return {
        "/ing - open or close the quest list",
        "/ing panel - show or hide the small panel",
        "/ing lock - lock or unlock the panel",
        ("/ing below <n> - show quests down to <n> levels below you (now %d)"):format(ING.db.levelsBelow),
        ("/ing above <n> - show quests up to <n> levels above you (now %d)"):format(ING.db.levelsAbove),
        ("/ing lines <n> - quests shown in the panel (now %d)"):format(ING.db.panelLines),
        "/ing tips - check everything again and list the coach tips in chat",
        "/ing gear - list your gear with item levels in chat",
        "/ing coach - show or hide the coach tip in the panel",
        "/ing coach reset - show every coach tip you hid again",
        "/ing minimap - show or hide the minimap button",
        "/ing refresh - search again",
    }
end

SLASH_IMPULSNOOBGUIDANCE1 = "/ing"
SLASH_IMPULSNOOBGUIDANCE2 = "/noob"
SlashCmdList.IMPULSNOOBGUIDANCE = function(msg)
    local cmd, arg = strtrim(msg or ""):lower():match("^(%S*)%s*(.-)$")
    local number = tonumber(arg)
    if cmd == "" then
        ING.ToggleWindow()
    elseif cmd == "panel" then
        ING.TogglePanel()
    elseif cmd == "lock" then
        ING.char.panelLocked = not ING.char.panelLocked
        ING.Print(ING.char.panelLocked and "panel locked." or "panel unlocked.")
    elseif cmd == "below" and number then
        ING.db.levelsBelow = math.max(0, math.min(20, math.floor(number)))
        ING.Print("showing quests down to", ING.db.levelsBelow, "levels below you.")
        ING.Refresh()
    elseif cmd == "above" and number then
        ING.db.levelsAbove = math.max(0, math.min(5, math.floor(number)))
        ING.Print("showing quests up to", ING.db.levelsAbove, "levels above you.")
        ING.Refresh()
    elseif cmd == "lines" and number then
        ING.db.panelLines = math.max(1, math.min(15, math.floor(number)))
        ING.Refresh()
    elseif cmd == "gear" then
        ING.Coach.MarkDirty("gear")
        local gear = ING.Coach.GetGear()
        local level = ING.playerLevel or UnitLevel("player")
        local verdict, behind = ING.Coach.GearVerdict(gear, level)
        if gear and gear.average then
            local severity = verdict == "good" and "good" or verdict == "behind" and "warn" or "urgent"
            local word = verdict == "good" and "good" or verdict == "behind" and "a little behind" or "far behind"
            ING.Print(("gear: average item level %d at level %d, %s."):format(gear.average, level,
                ING.Colorize(severity, ("%s (%d levels)"):format(word, behind))))
        else
            ING.Print("gear: no item levels known yet" .. (gear and gear.unknown > 0 and (" (%d still loading)"):format(gear.unknown) or "") .. ".")
        end
        for _, entry in ipairs(gear and gear.all or {}) do
            if entry.link or entry.core then
                local severity, label = ING.Coach.SlotStatus(entry, level)
                print(("  %s %s  %s%s  %s"):format(ING.Colorize(severity, entry.name .. ":"),
                    entry.link or "|cff808080nothing equipped|r",
                    entry.link and ("ilvl " .. (entry.level or "?")) or "",
                    entry.durability and ("  %d%%"):format(entry.durability) or "",
                    ING.Colorize(severity, "[" .. label .. "]")))
            end
        end
    elseif cmd == "coach" and arg == "reset" then
        ING.Coach.Reset()
        ING.Print("all coach tips are back.")
    elseif cmd == "coach" then
        ING.db.showCoachInPanel = not ING.db.showCoachInPanel
        ING.Print(ING.db.showCoachInPanel and "coach tip shown in the panel." or "coach tip hidden from the panel (still in the window).")
        ING.Refresh()
    elseif cmd == "minimap" then
        ING.db.hideMinimap = not ING.db.hideMinimap
        ING.UpdateMinimapButton()
    elseif cmd == "refresh" then
        ING.Coach.MarkDirty()
        ING.Refresh()
    elseif cmd == "tips" then
        -- Re-check gear, bags and spells now and list the coach tips in chat.
        ING.Coach.MarkDirty()
        ING.Refresh()
        local tips = ING.results and ING.results.coach
        if not ING.results then
            ING.Print("still reading the Questie database, try again in a few seconds.")
        elseif not tips or #tips == 0 then
            ING.Print("no tips right now, you're doing great. (/ing coach reset shows hidden tips again)")
        else
            ING.Print(("%d tip%s:"):format(#tips, #tips > 1 and "s" or ""))
            for _, tip in ipairs(tips) do
                local severity = ING.SEVERITY[tip.kind] and tip.kind or "tip"
                print("  " .. ING.Colorize(severity, "[" .. ING.SEVERITY[severity].label .. "]") .. " "
                    .. ING.CoachTitle(tip) .. " - " .. tip.detail)
            end
        end
    else
        ING.Print("commands:")
        for _, line in ipairs(HelpLines()) do
            print("  " .. line)
        end
    end
end
