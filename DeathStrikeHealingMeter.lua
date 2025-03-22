local ADDON_NAME, core = ...;

-- Create UI Elements
local frame
local bar

local True = true


local function RedrawHealFrame()
    local config = core.GetConfig()
    if frame.text then

        frame.text:ClearAllPoints()
        frame.text:SetFont("Fonts/FRIZQT__.TTF", config.HEAL_TEXT_FONT_SIZE, "OUTLINE")
        frame.text:SetTextColor(0.1765, 0.9765, 0)

        -- Clear existing animations if they already exist to avoid overlapping
        if frame.text.animations then
            frame.text.animations:Stop()           -- Stop the current animation
            frame.text.animations:Finish()         -- Clear the animation state
            frame.text.animations = nil            -- Reset to avoid recreating
        end

        -- Create an Animation Group only if it doesn't exist
        frame.text.animations = frame.text.animations or frame.text:CreateAnimationGroup()

        -- Create the Animation
        local animation = frame.text.animations:CreateAnimation("Translation")
        animation:SetOrder(1)
        animation:SetDuration(0.2)           -- Duration of the animation in seconds

        -- Set Position and Offset based on the selected animation direction
        if config.ANIMATION_DIRECTION == "RIGHT" then
            frame.text:SetPoint("LEFT", bar, "RIGHT", -15, 0)
            frame.text:SetJustifyH("LEFT")
            frame.text:SetWidth(config.BAR_WIDTH + 50)  -- Increase width to accommodate text moving to the right
            animation:SetOffset(18, 0)
        elseif config.ANIMATION_DIRECTION == "UP" then
            frame.text:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
            frame.text:SetJustifyH("LEFT")
            animation:SetOffset(0, config.BAR_HEIGHT)
        elseif config.ANIMATION_DIRECTION == "DOWN" then
            frame.text:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
            frame.text:SetJustifyH("LEFT")
            animation:SetOffset(0, -config.BAR_HEIGHT)
        elseif config.ANIMATION_DIRECTION == "LEFT" then
            frame.text:SetPoint("LEFT", bar, "RIGHT", 0, 0)
            frame.text:SetJustifyH("LEFT")
            frame.text:SetWidth(config.BAR_WIDTH + 50)  -- Width adjustment for leftward animation
            animation:SetOffset(-config.BAR_WIDTH - 40, 0)
        end

        -- Create a Pause Animation
        local pause = frame.text.animations:CreateAnimation("Animation")
        pause:SetDuration(1)               -- Duration of the pause (0.8 seconds)
        pause:SetOrder(2)                    -- Ensure this runs after the move animation
    end
end


local function RedrawBar()
    -- Here, you can put all the code that rebuilds or updates your addon’s UI elements
    -- Example of redrawing bars or frames based on new config values:
    if not bar then return end

    bar:UpdatePlayerHealth()
    bar:UpdateHealingModifiers()

    local config = core.GetConfig()

    bar:SetSize(config.BAR_WIDTH, config.BAR_HEIGHT)

    -- Set the status bar texture
    local texture_path = core.default_texture_path
    if config.BAR_TEXTURE ~= "default" then
        texture_path = core.LSM:Fetch("statusbar", config.BAR_TEXTURE)
    end
    bar:SetStatusBarTexture(texture_path)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:GetStatusBarTexture():SetVertTile(false)
    bar:SetStatusBarColor(1, 0, 0)  -- Colour of the Bar
    bar:SetMinMaxValues(0, bar.max_health)  -- Damage will be between 0 and player's maximum health
    bar:SetValue(0)

    -- Set the position of the bar
    bar:SetPoint("CENTER", UIParent, "CENTER", config.BAR_POINT_X, config.BAR_POINT_Y)

    -- Background for the bar
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints(true)
    bar.bg:SetColorTexture(0, 0, 0, config.BAR_BACKGROUND_ALPHA)

    -- Predicted Heal text
    bar.text:SetFont("Fonts/FRIZQT__.TTF", config.PREDICTION_TEXT_FONT_SIZE, "OUTLINE")
    bar.text:SetTextColor(0.1765, 0.9765, 0)
    bar.text:SetPoint("RIGHT", bar, "RIGHT", -2, 0)
    bar.text:SetJustifyH("RIGHT")

    -- Minimum Bar
    bar.min_text:SetFont("Fonts/ARIALN.TTF", config.BAR_HEIGHT, "NONE")
    bar.min_text:SetTextColor(0.6, 0.6, 0.6)
    bar.min_text:SetPoint("TOPLEFT", bar, "TOPLEFT", math.floor(config.BAR_WIDTH*0.07/config.BAR_WIDTH_MAXIMUM_HEALTH) - 2, 3)
    bar.min_text:SetText("|")
    bar.min_text:SetShadowOffset(0,0)
    
end

local function format_number(value)
    local text = string.format("%d", value)
    if value > 1000 then
        text = string.format("%dk", value / 1000)
    end
    return text
end


core.RedrawMeterFrame = function()
    RedrawBar()
    RedrawHealFrame()
end

core.CreateMeterFrame = function()
    local config = core.GetConfig()

    frame = CreateFrame("Frame", "DeathStrikeTrackerFrame", UIParent)
    frame.bar = CreateFrame("StatusBar", "DamageBar", frame)
    frame.text = frame:CreateFontString(nil, "OVERLAY")

    bar = frame.bar
    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.min_text = bar:CreateFontString(nil, "OVERLAY")

    -- Create internal states
    bar.damage_taken = 0
    bar.heal = 0
    bar.min_heal = 0
    bar.max_heal = 1
    bar.max_health = UnitHealthMax("player")

    -- Create healing modifiers
    bar.ds_modifier = 1
    bar.vampiric_blood = 1
    bar.luck_of_the_draw = 1
    local name, _, _, _, rank, _, _, _, _, _ = GetTalentInfo(1, 12)
    if name and name == "Improved Death Strike" then
        bar.ds_modifier = rank * 0.15 + 1
    end

    -- function to update the player's health stored:
    bar.UpdatePlayerHealth = function(self)
        self.max_health = UnitHealthMax("player")
        self.min_heal = self.max_health * 0.07
        self.max_heal = self.max_health * core.config.BAR_WIDTH_MAXIMUM_HEALTH.value

        return true
    end

    -- Update all modifiers that increase healing received
    bar.UpdateHealingModifiers = function(self)

        -- Vamp Blood
        if core.GetUnitAura("Vampiric Blood") then
            self.vampiric_blood = 1.25
        else
            self.vampiric_blood = 1
        end

        -- RDF buff
        local auraInfo = core.GetUnitAura("Luck of the Draw")
        if auraInfo then
            self.luck_of_the_draw = 1 + 0.05 * (auraInfo.stacks or 0)
        end

    end

    -- Function to update the damage bar
    bar.UpdateBar = function(self)

        local heal_from_damage = self.damage_taken * 0.2 * self.ds_modifier * self.vampiric_blood * self.luck_of_the_draw
        local heal = self.min_heal * self.vampiric_blood * self.luck_of_the_draw

        if heal_from_damage > heal then
            heal = heal_from_damage
        end
        self.heal = heal

        local progress = floor(heal_from_damage)
        local max_progress = floor(self.max_heal)

        self:SetMinMaxValues(0, max_progress)
        self:SetValue(progress)

        -- Update the text on the bar
        self.text:SetText(format_number(self.heal))
    end

    bar.UpdateDamage = function(self, event)
        local eventInfo = {CombatLogGetCurrentEventInfo()}
        local subEvent = eventInfo[2]
        local destGUID = eventInfo[8]
        local damage

        if destGUID ~= UnitGUID("player") then
            return false
        end

        self.lastModifierCheck = self.lastModifierCheck or GetTime()
        if GetTime() > self.lastModifierCheck + 60 then
            self:UpdateHealingModifiers()
        end

        if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REMOVED" then
            if "Vampiric Blood" == eventInfo[13] or "Luck of the Draw" == eventInfo[13] then
                self:UpdateHealingModifiers()
            end

        elseif subEvent == "SPELL_HEAL" then
            if "Death Strike" == eventInfo[13] then
                frame.text:UpdateHealText(eventInfo[15])

                C_Timer.After(1, function() frame.text:UpdateHealText(nil) end)
            end
        elseif subEvent == "SWING_DAMAGE" then
            damage = eventInfo[12]
        elseif subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE" or subEvent == "RANGE_DAMAGE" then
            damage = eventInfo[15]
        end

        if damage then
            self.damage_taken = self.damage_taken + damage
            C_Timer.After(config.WINDOW_TIME,
                function()
                    self.damage_taken = self.damage_taken - damage
                    bar:UpdateBar()
            end)
        end
    end


    frame.text.UpdateHealText = function(self, value)
        if not value then
            self:SetText("")
            self:Hide()
            self.animations:Stop()
            self:SetFont("Fonts/FRIZQT__.TTF", config.HEAL_TEXT_FONT_SIZE, "OUTLINE")
            return
        end
        self.animations:Play()
        self:SetText(format_number(value))
        if frame.bar.heal > config.LARGE_HEAL_THRESHOLD * frame.bar.max_health then
            self:SetFont("Fonts/FRIZQT__.TTF", config.HEAL_TEXT_LARGE_FONT_SIZE, "OUTLINE")
        end
        self:Show()
    end

    core.RedrawMeterFrame()
    bar:UpdateBar()

    -- Event handler for when buffs are updated
    frame:SetScript("OnEvent", function(self, event, ...)

        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            self.bar:UpdateDamage(event)

        elseif event == "UNIT_MAXHEALTH" then
            self.bar:UpdatePlayerHealth()

        elseif event == "PLAYER_ENTERING_WORLD" then
            self.bar:UpdatePlayerHealth()
            self.bar.damage_taken = 0
            self:SetAlpha(config.OUT_OF_COMBAT_ALPHA)

        elseif event == "PLAYER_REGEN_ENABLED" then
            self:SetAlpha(config.OUT_OF_COMBAT_ALPHA)

        elseif event == "PLAYER_REGEN_DISABLED" then
            self:SetAlpha(config.IN_COMBAT_ALPHA)

        end

        self.bar:UpdateBar()

        return true
    end)

    -- OnUpdate script to update buff durations in real-time
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.lastUpdate = self.lastUpdate or GetTime()
        if self.lastUpdate + 0.03 < GetTime() then
            self.bar:UpdateBar()
        end
    end)

    -- Drag functionality
    bar:SetScript("OnDragStart", function(self)

        if not core.config.UNLOCK_MOVING_BAR.value then
            return
        end

        self:StartMoving()
    end)

    bar:SetScript("OnDragStop", function(self)

        if not core.config.UNLOCK_MOVING_BAR.value then
            return
        end

        self:StopMovingOrSizing()
        -- Optionally save the new position for future use
        local point, parent, relativePoint, xOffset, yOffset = self:GetPoint()
        core.config.BAR_POINT_X.value = xOffset
        core.config.BAR_POINT_Y.value = yOffset
    end)

    -- Register events to track buffs
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")

    core.created = true
end

-- Make the frame draggable
core.unlock_frame = function(enabled)

    bar:SetMovable(enabled)
    bar:EnableMouse(enabled)
    if enabled then
        bar:RegisterForDrag("LeftButton")
    else
        bar:RegisterForDrag()
    end
end

local _, class_id = UnitClassBase("player");
if class_id == 6 then

    local loadFrame = CreateFrame("Frame")

    -- OnEvent event: reloads the UI on demand
    loadFrame:SetScript("OnEvent", function(self, event, arg1)
        if event == "ADDON_LOADED" then

            local texture_path = core.LSM:Fetch("statusbar", core.config.BAR_TEXTURE.value)  -- Fetch the texture path from LibSharedMedia
            if not core.texture_path then
                core.texture_path = texture_path
            end

            if core.texture_path ~= texture_path and core.created then
                core.texture_path = texture_path
                core.RedrawMeterFrame()
            end

            if arg1 == ADDON_NAME then
                core.LoadConfig()
                core.CreateOptionsFrame()
                core.CreateMeterFrame()
            end

        elseif event == "PLAYER_LOGOUT" then
            if core.created then
                core.SaveConfig()
            end
        end
    end)

    -- Create the UI when the entire Addon has finished loading
    loadFrame:RegisterEvent("ADDON_LOADED")
    loadFrame:RegisterEvent("PLAYER_LOGOUT")
end
