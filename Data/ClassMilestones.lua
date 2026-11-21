local _, ING = ...

-- Class abilities that come from a class quest (not from the trainer), so
-- new players easily miss them. spell = the ability you have once the quest
-- is done; level = when the quest becomes available. These are the Classic
-- quests; the coach only mentions one when this client knows the spell.
ING.ClassMilestones = {
    HUNTER = {
        { spell = 1515, level = 10, text = "Your hunter pet quests start at level 10. Finish them to learn Tame Beast and get a pet that fights for you." },
    },
    WARLOCK = {
        { spell = 697, level = 10, text = "Your warlock trainer has a quest for the Voidwalker, a tough demon that takes hits for you." },
    },
    DRUID = {
        { spell = 5487, level = 10, text = "Your druid trainer has a quest for Bear Form, a form that can take a lot of damage." },
        { spell = 1066, level = 16, text = "Your druid trainer has a quest for Aquatic Form: breathe underwater and swim fast." },
    },
    WARRIOR = {
        { spell = 71, level = 10, text = "Your warrior trainer has a quest for Defensive Stance, which helps you survive and tank." },
        { spell = 2458, level = 30, text = "Your warrior trainer has a quest for Berserker Stance and new abilities that come with it." },
    },
    SHAMAN = {
        { spell = 8071, level = 4, text = "Your shaman trainer has a quest for your Earth Totem. Totems are a big part of the shaman." },
        { spell = 3599, level = 10, text = "Your shaman trainer has a quest for your Fire Totem." },
        { spell = 5394, level = 20, text = "Your shaman trainer has a quest for your Water Totem (healing over time)." },
    },
    PALADIN = {
        { spell = 7328, level = 12, text = "Your paladin trainer has a quest for Redemption, which brings dead players back to life." },
    },
    ROGUE = {
        { spell = 8681, level = 20, text = "Rogues learn poisons through a quest at level 20. Poisons add a lot of damage to your weapons." },
    },
}
