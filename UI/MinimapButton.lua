local _, ING = ...

-- A plain minimap button (no libraries). Drag it around the minimap edge.

local button

local function UpdatePosition()
    local angle = math.rad(ING.db.minimapAngle or 220)
    local radius = (Minimap:GetWidth() / 2) + 6
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function OnDragUpdate()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    ING.db.minimapAngle = math.deg(math.atan2(cy - my, cx - mx)) % 360
    UpdatePosition()
end

local function CreateButton()
    button = CreateFrame("Button", "ImpulsNoobGuidanceMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 7, -5)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then
            ING.TogglePanel()
        else
            ING.ToggleWindow()
        end
    end)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", OnDragUpdate) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Impuls Noob Guidance")
        GameTooltip:AddLine("Left-click: quest list", 1, 1, 1)
        GameTooltip:AddLine("Right-click: show / hide the panel", 1, 1, 1)
        GameTooltip:AddLine("Drag: move this button", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    UpdatePosition()
end

function ING.UpdateMinimapButton()
    if ING.db.hideMinimap then
        if button then button:Hide() end
        return
    end
    if not button then CreateButton() end
    button:Show()
end
