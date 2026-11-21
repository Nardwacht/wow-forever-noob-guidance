local _, ING = ...

-- The small always-on panel: where you are and the next few quests.
-- Drag to move (unless locked), click a quest to see it on the map,
-- click the title to open the full window.

local PANEL_WIDTH = 280
local LINE_HEIGHT = 30

local panel
local lines = {}

local function SavePosition()
    local point, _, relativePoint, x, y = panel:GetPoint()
    ING.char.panelPos = { point, relativePoint, x, y }
end

local function RestorePosition()
    panel:ClearAllPoints()
    local pos = ING.char.panelPos
    if pos then
        panel:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        panel:SetPoint("RIGHT", UIParent, "RIGHT", -40, 120)
    end
end

local function GetLine(i)
    local line = lines[i]
    if line then return line end
    line = CreateFrame("Button", nil, panel)
    line:SetHeight(LINE_HEIGHT)
    line:SetPoint("LEFT", 10, 0)
    line:SetPoint("RIGHT", -10, 0)
    line:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    line.title = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    line.title:SetPoint("TOPLEFT", 2, -2)
    line.title:SetPoint("RIGHT", -2, 0)
    line.title:SetJustifyH("LEFT")
    line.title:SetWordWrap(false)
    line.sub = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line.sub:SetPoint("TOPLEFT", line.title, "BOTTOMLEFT", 0, -1)
    line.sub:SetPoint("RIGHT", -2, 0)
    line.sub:SetJustifyH("LEFT")
    line.sub:SetWordWrap(false)
    line:SetScript("OnEnter", function(self) ING.ShowQuestTooltip(self, self.item) end)
    line:SetScript("OnLeave", GameTooltip_Hide)
    line:SetScript("OnClick", function(self) ING.ShowOnMap(self.item) end)
    lines[i] = line
    return line
end

local function Render(results)
    if not panel or not ING.char.panelShown then return end
    for _, line in ipairs(lines) do line:Hide() end

    local y = 30
    local message
    if not results then
        panel.header:SetText("Noob Guidance")
        message = ING.dependencyProblem and ("|cffff4040" .. ING.dependencyProblem .. "|r") or "Loading quests..."
    else
        local section = results.sections[1]
        if section and section.kind == "current" then
            panel.header:SetText(("%s  |cffffffff(%d quests)|r"):format(section.title, #section.items))
        elseif section then
            panel.header:SetText("Next zone: " .. section.title)
            message = "|cffff8040Nothing left here.|r Go to " .. section.title .. ": " .. (section.via or "")
        else
            panel.header:SetText(results.zoneName)
            local best = results.guideZones[1]
            if best and best.count > 0 then
                message = ("|cffff8040No quests nearby.|r The guide suggests %s (%d quests for you)."):format(best.name, best.count)
            else
                message = "|cffff8040No quests found for your level.|r Open the window for the guide."
            end
        end

        local tips = results.coach
        if ING.db.showCoachInPanel and tips and #tips > 0 then
            local coach = panel.coach
            coach.tip = tips[1]
            coach.text:SetText(ING.CoachTitle(tips[1]) .. (#tips > 1 and ("  |cffaaaaaa+%d|r"):format(#tips - 1) or ""))
            coach:ClearAllPoints()
            coach:SetPoint("TOPLEFT", 10, -y)
            coach:SetPoint("RIGHT", -10, 0)
            coach:Show()
            y = y + 20
        else
            panel.coach:Hide()
        end

        if message then
            panel.message:ClearAllPoints()
            panel.message:SetPoint("TOPLEFT", 12, -y)
            panel.message:SetPoint("RIGHT", -12, 0)
            panel.message:SetText(message)
            panel.message:Show()
            y = y + panel.message:GetStringHeight() + 6
        else
            panel.message:Hide()
        end

        local items = section and section.items or {}
        for i = 1, math.min(#items, ING.db.panelLines) do
            local line = GetLine(i)
            line.item = items[i]
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", 10, -y)
            line:SetPoint("RIGHT", -10, 0)
            line.title:SetText(ING.QuestLine(items[i]))
            line.sub:SetText(ING.StarterLine(items[i]))
            line:Show()
            y = y + LINE_HEIGHT
        end
        if #items > ING.db.panelLines then
            panel.more:SetText(("+ %d more, click the title to see all"):format(#items - ING.db.panelLines))
            panel.more:ClearAllPoints()
            panel.more:SetPoint("TOPLEFT", 12, -y)
            panel.more:Show()
            y = y + 16
        else
            panel.more:Hide()
        end
        panel:SetHeight(y + 10)
        return
    end
    panel.coach:Hide()
    panel.message:ClearAllPoints()
    panel.message:SetPoint("TOPLEFT", 12, -30)
    panel.message:SetPoint("RIGHT", -12, 0)
    panel.message:SetText(message)
    panel.message:Show()
    panel.more:Hide()
    panel:SetHeight(y + panel.message:GetStringHeight() + 16)
end

local function CreatePanel()
    panel = CreateFrame("Frame", "ImpulsNoobGuidancePanel", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    panel:SetSize(PANEL_WIDTH, 80)
    panel:SetFrameStrata("MEDIUM")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self)
        if not ING.char.panelLocked then self:StartMoving() end
    end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    if panel.SetBackdrop then
        panel:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        panel:SetBackdropColor(0, 0, 0, 0.65)
    end
    RestorePosition()

    local titleButton = CreateFrame("Button", nil, panel)
    titleButton:SetPoint("TOPLEFT", 8, -6)
    titleButton:SetPoint("TOPRIGHT", -8, -6)
    titleButton:SetHeight(20)
    titleButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    titleButton:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            ING.char.panelLocked = not ING.char.panelLocked
            ING.Print(ING.char.panelLocked and "panel locked." or "panel unlocked, drag it to move.")
        else
            ING.ToggleWindow()
        end
    end)
    titleButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Impuls Noob Guidance")
        GameTooltip:AddLine("Left-click: open the full list", 1, 1, 1)
        GameTooltip:AddLine("Right-click: lock / unlock the panel", 1, 1, 1)
        GameTooltip:AddLine("/ing panel hides this panel", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    titleButton:SetScript("OnLeave", GameTooltip_Hide)
    -- Dragging the title moves the panel too.
    titleButton:RegisterForDrag("LeftButton")
    titleButton:SetScript("OnDragStart", function() if not ING.char.panelLocked then panel:StartMoving() end end)
    titleButton:SetScript("OnDragStop", function() panel:StopMovingOrSizing(); SavePosition() end)

    panel.header = titleButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.header:SetPoint("LEFT", 2, 0)
    panel.header:SetPoint("RIGHT", -2, 0)
    panel.header:SetJustifyH("LEFT")
    panel.header:SetWordWrap(false)

    panel.message = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.message:SetPoint("TOPLEFT", 12, -30)
    panel.message:SetPoint("RIGHT", -12, 0)
    panel.message:SetJustifyH("LEFT")

    panel.more = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")

    -- The coach's most important tip. Left-click opens the window, right-click hides it.
    local coach = CreateFrame("Button", nil, panel)
    coach:SetHeight(18)
    coach:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    coach:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    coach.text = coach:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    coach.text:SetPoint("LEFT", 2, 0)
    coach.text:SetPoint("RIGHT", -2, 0)
    coach.text:SetJustifyH("LEFT")
    coach.text:SetWordWrap(false)
    coach:SetScript("OnEnter", function(self) ING.ShowCoachTooltip(self, self.tip) end)
    coach:SetScript("OnLeave", GameTooltip_Hide)
    coach:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            GameTooltip:Hide()
            ING.Coach.Dismiss(self.tip)
        else
            ING.ToggleWindow()
        end
    end)
    coach:Hide()
    panel.coach = coach
end

function ING.UpdatePanelVisibility()
    if ING.char.panelShown then
        if not panel then CreatePanel() end
        panel:Show()
        Render(ING.results)
    elseif panel then
        panel:Hide()
    end
end

function ING.TogglePanel()
    ING.char.panelShown = not ING.char.panelShown
    ING.UpdatePanelVisibility()
end

ING.OnResults(function(results)
    Render(results)
end)
