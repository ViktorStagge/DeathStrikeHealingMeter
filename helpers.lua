local ADDON_NAME, core = ...;


core.print_table = function(table, prefix)

    for k, v in pairs(table) do
        if type(v) == "table" then
            if not prefix then prefix = "  " end
            print(prefix .. k .. ":")
            core.print_table(v, prefix .. "  ")
        elseif prefix then
            print(prefix, k, v)
        else
            print(k, v)
        end
    end
end


core.GetUnitAura = function(auraName)
    local auraInfo = nil

    -- Use a for loop with an upper limit to avoid infinite loops
    for i = 1, 50 do -- WoW typically has a maximum of 40 buffs per unit
        local name, icon, stacks, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = UnitAura("player", i, "HELPFUL")
        -- Stop the loop if no more auras are found

        if not name then
            break
        end

        --print(name)
        -- Check if this is the "Vampiric Blood" aura
        if name == auraName then
            auraInfo = {
                name = name,
                icon = icon,
                stacks = stacks,
                duration = duration,
                expirationTime = expirationTime,
                spellId = spellId,
                tooltipValue = nil,
            }

            -- Use the spell ID to fetch specific spell info
            local spellName, _, _, _, _, _, tooltipValue1, _, _ = GetSpellInfo(spellId)
            --core.print_table({GetSpellInfo(spellId)})
            if tooltipValue1 then
                auraInfo.tooltipValue1 = tonumber(tooltipValue1) -- spellDescription:match("%d+")  -- Extract the first numeric value from description
            end

            --core.print_table(auraInfo)

            break -- Exit the loop once found
        end
    end

    return auraInfo -- Return the aura information if found, or nil if not found
end
