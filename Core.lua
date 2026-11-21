local ADDON_NAME, ING = ...

-- Shared namespace. Every file receives this same table through `...`.
_G.ImpulsNoobGuidance = ING
ING.ADDON_NAME = ADDON_NAME

ING.COLOR = "|cff33ccff"
ING.TITLE = ING.COLOR .. "Impuls Noob Guidance|r"

-- Default settings. Account-wide values live in ImpulsNoobGuidanceDB, the
-- panel/window positions per character in ImpulsNoobGuidanceCharDB.
ING.DEFAULTS = {
    levelsBelow = 5,      -- oldest quest level still shown (player level - N)
    levelsAbove = 0,      -- newest quest level shown (player level + N)
    showDungeon = true,
    showElite = true,
    showClassProf = true,
    showCoach = true,         -- coach tips in the window
    showCoachInPanel = true,  -- most important coach tip in the panel
    gearExpanded = false,     -- gear section lists every slot, not only weak ones
    panelLines = 5,
    minimapAngle = 220,
    hideMinimap = false,
}

ING.CHAR_DEFAULTS = {
    panelShown = true,
    panelLocked = false,
}

local function ApplyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = value
        end
    end
    return target
end

function ING.LoadSettings()
    ImpulsNoobGuidanceDB = ApplyDefaults(type(ImpulsNoobGuidanceDB) == "table" and ImpulsNoobGuidanceDB or {}, ING.DEFAULTS)
    ImpulsNoobGuidanceCharDB = ApplyDefaults(type(ImpulsNoobGuidanceCharDB) == "table" and ImpulsNoobGuidanceCharDB or {}, ING.CHAR_DEFAULTS)
    ING.db = ImpulsNoobGuidanceDB
    ING.char = ImpulsNoobGuidanceCharDB
end

function ING.Print(...)
    print(ING.COLOR .. "Noob Guidance:|r", ...)
end

-- Faction letter used by the guide data and by QuestieDB's friendlyToFaction.
function ING.PlayerFactionLetter()
    local faction = UnitFactionGroup("player")
    if faction == "Alliance" then return "A" end
    if faction == "Horde" then return "H" end
    return nil
end

-- One colour code for every message: how urgent is it?
ING.SEVERITY = {
    urgent = { color = "|cffff4040", label = "Act now" },        -- red
    warn   = { color = "|cffff9933", label = "Soon" },           -- orange
    tip    = { color = "|cffffd100", label = "Tip" },            -- yellow
    good   = { color = "|cff33ff33", label = "OK" },             -- green
    info   = { color = "|cffaaaaaa", label = "" },               -- grey
}

function ING.Colorize(severity, text)
    local s = ING.SEVERITY[severity] or ING.SEVERITY.info
    return s.color .. text .. "|r"
end

-- Small callback list so the window and the panel redraw after each scan.
ING.listeners = {}

function ING.OnResults(callback)
    table.insert(ING.listeners, callback)
end

function ING.FireResults()
    for _, callback in ipairs(ING.listeners) do
        local ok, err = pcall(callback, ING.results)
        if not ok then
            geterrorhandler()(err)
        end
    end
end
