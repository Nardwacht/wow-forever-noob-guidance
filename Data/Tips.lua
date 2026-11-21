local _, ING = ...

-- Beginner tips, written for this addon from the same guide research as
-- Data/Zones.lua. min/max limit a tip to the levels where it is useful.
ING.Tips = {
    { min = 1,  max = 60, text = "A yellow ! above an NPC means a quest you can take. A yellow ? means you can hand a quest in there." },
    { min = 1,  max = 60, text = "Grey quests give almost no experience. This list skips them by only showing quests near your level." },
    { min = 1,  max = 10, text = "Visit your class trainer every even level to learn new spells." },
    { min = 1,  max = 20, text = "Talk to the flight master in each new town you reach, even if you can't fly anywhere yet. It unlocks that flight path." },
    { min = 5,  max = 30, text = "Pick two gathering professions (for example Herbalism and Mining) early: they earn money while you quest." },
    { min = 6,  max = 20, text = "Camping is a new Forever profession. At skill 20 you can place camp structures that buff your party." },
    { min = 10, max = 60, text = "Set your hearthstone at the inn of the town you are questing from, so you can always get back." },
    { min = 10, max = 60, text = "Out of quests in a zone? Look at the neighbouring zones this addon shows, or the zones the guide suggests for your level." },
    { min = 12, max = 25, text = "Dungeons give great gear and quests. Use the Looking For Group tool or ask in chat for a group." },
    { min = 20, max = 30, text = "Get the City of Dalaran attunement in your 20s (Southshore for Alliance, Tarren Mill for Horde) so the dungeon is open at 28." },
    { min = 20, max = 60, text = "Forever has no flying mounts. Plan your trips with boats, zeppelins, airships and flight paths." },
    { min = 30, max = 60, text = "Gold-coloured (elite) quests are made for a group. Ask nearby players: they often need the same quest." },
    { min = 38, max = 45, text = "Riding becomes available around level 40. Save some gold for it." },
    { min = 40, max = 50, text = "The Steamwheedle boat links Tanaris with Powderfuse Port in Riverglades." },
}

function ING.PickTip(level)
    local candidates = {}
    for _, tip in ipairs(ING.Tips) do
        if level >= tip.min and level <= tip.max then
            table.insert(candidates, tip.text)
        end
    end
    if #candidates == 0 then return nil end
    -- Change the tip every few minutes, not on every redraw.
    local slot = math.floor(GetTime() / 180)
    return candidates[(slot % #candidates) + 1]
end
