local ADDON_NAME, core = ...;

-- Create UI Elements
local frame
local bar

-- Create internal states
local damage_taken = 0
local heal = 0
local min_heal = 0
local max_heal = 1
local max_health = UnitHealthMax("player")

-- Create healing modifiers
local ds_modifier = 1
local vampiric_blood = 1
local name, _, _, _, rank, _, _, _, _, _ = GetTalentInfo(1, 12)
if name and name == "Improved Death Strike" then
    ds_modifier = rank * 0.15 + 1
end

-- functions:
local function update_player_health()
    max_health = UnitHealthMax("player")
    min_heal = max_health * 0.07
    max_heal = max_health * core.config.BAR_WIDTH_MAXIMUM_HEALTH

    return true
end

local function get_heal_modifier()
    return ds_modifier * vampiric_blood
end

local function get_min_heal_modifier()
    return vampiric_blood
end


local function RedrawHealFrame()
    if frame.text then

        frame.text:SetFont("Fonts/FRIZQT__.TTF", core.config.HEAL_TEXT_FONT_SIZE, "OUTLINE")
        frame.text:SetTextColor(0.1765, 0.9765, 0)
        frame.text:SetPoint("LEFT", bar, "RIGHT", -15, 0)
        frame.text:SetJustifyH("LEFT")

        -- Create an Animation Group
        frame.text.animations = frame.text:CreateAnimationGroup()

        -- Create the Animation
        local animation = frame.text.animations:CreateAnimation("Translation")
        animation:SetOrder(1)
        animation:SetDuration(0.2)           -- Duration of the animation in seconds
        animation:SetOffset(30, 0)
        --animation:SetSmoothing("NONE")    -- No smoothing for a linear motion

        -- Create a Pause Animation
        local pause = frame.text.animations:CreateAnimation("Animation")
        pause:SetDuration(1)               -- Duration of the pause (0.8 seconds)
        pause:SetOrder(2)                    -- Ensure this runs after the move animation
    end
end


local function RedrawBar()
    -- Here, you can put all the code that rebuilds or updates your addon’s UI elements
    -- Example of redrawing bars or frames based on new config values:
    if bar then

        bar:SetSize(core.config.BAR_WIDTH, core.config.BAR_HEIGHT)

        -- Set the status bar texture
        local texture_path = core.default_texture_path
        if core.config.BAR_TEXTURE ~= "default" then
            texture_path = core.LSM:Fetch("statusbar", core.config.BAR_TEXTURE)
        end
        bar:SetStatusBarTexture(texture_path)
        bar:GetStatusBarTexture():SetHorizTile(false)
        bar:GetStatusBarTexture():SetVertTile(false)
        bar:SetStatusBarColor(1, 0, 0)  -- Colour of the Bar
        bar:SetMinMaxValues(0, max_health)  -- Damage will be between 0 and player's maximum health
        bar:SetValue(0)

        -- Set the position of the bar
        bar:SetPoint("CENTER", UIParent, "CENTER", core.config.BAR_POINT_X, core.config.BAR_POINT_Y)

        -- Background for the bar
        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints(true)
        bar.bg:SetColorTexture(0, 0, 0, core.config.BAR_BACKGROUND_ALPHA)

        -- Predicted Heal text
        bar.text:SetFont("Fonts/FRIZQT__.TTF", core.config.PREDICTION_TEXT_FONT_SIZE, "OUTLINE")
        bar.text:SetTextColor(0.1765, 0.9765, 0)
        bar.text:SetPoint("RIGHT", bar, "RIGHT", -2, 0)
        bar.text:SetJustifyH("RIGHT")

        -- Minimum Bar
        bar.min_text:SetFont("Fonts/ARIALN.TTF", core.config.BAR_HEIGHT, "NONE")
        bar.min_text:SetTextColor(0.6, 0.6, 0.6)
        bar.min_text:SetPoint("TOPLEFT", bar, "TOPLEFT", math.floor(core.config.BAR_WIDTH*0.07/core.config.BAR_WIDTH_MAXIMUM_HEALTH) - 2, 3)
        bar.min_text:SetText("|")
        bar.min_text:SetShadowOffset(0,0)
    end
end

local function format_number(value)
    local text = string.format("%d", value)
    if value > 1000 then
        text = string.format("%dk", value / 1000)
    end
    return text
end


local function update_damage(event)
    local event_list = {CombatLogGetCurrentEventInfo()}
    local sub_event = event_list[2]
    local dest_GUID = event_list[8]

    if dest_GUID ~= UnitGUID("player") then
        return false
    end

    local damage
    if sub_event == "SPELL_AURA_APPLIED" then
        if "Vampiric Blood" == event_list[13] then
            vampiric_blood = 1.25
        end
    elseif sub_event == "SPELL_AURA_REMOVED" then
        if "Vampiric Blood" == event_list[13] then
            vampiric_blood = 1
        end
    elseif sub_event == "SPELL_HEAL" then
        if "Death Strike" == event_list[13] then
            frame.text:UpdateHealText(event_list[15])

            C_Timer.After(1, function() 
                frame.text:UpdateHealText(nil)
            end)
        end
    elseif sub_event == "SWING_DAMAGE" then
        damage = event_list[12]
    elseif sub_event == "SPELL_DAMAGE" or sub_event == "SPELL_PERIODIC_DAMAGE" then
        damage = event_list[15]
    end

    if damage then
        damage_taken = damage_taken + damage
        C_Timer.After(core.config.WINDOW_TIME,
            function()
                damage_taken = damage_taken - damage
                bar:UpdateBar()
        end)
    end

    return true
end


local function update_on_event(self, event, ...)

    local changed = true
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        changed = update_damage(event)

    elseif event == "UNIT_MAXHEALTH" then
        update_player_health()

    elseif event == "PLAYER_ENTERING_WORLD" then
        update_player_health()
        damage_taken = 0
        frame:SetAlpha(core.config.OUT_OF_COMBAT_ALPHA)

    elseif event == "PLAYER_REGEN_ENABLED" then
        frame:SetAlpha(core.config.OUT_OF_COMBAT_ALPHA)

    elseif event == "PLAYER_REGEN_DISABLED" then
        frame:SetAlpha(core.config.IN_COMBAT_ALPHA)

    end

    if changed then
        bar:UpdateBar()
    end

    return changed
end

core.RedrawMeterFrame = function()
    update_player_health()
    RedrawBar()
    RedrawHealFrame()
end

core.CreateMeterFrame = function()

    frame = CreateFrame("Frame", "DeathStrikeTrackerFrame", UIParent)
    frame.bar = CreateFrame("StatusBar", "DamageBar", frame)
    frame.text = frame:CreateFontString(nil, "OVERLAY")

    bar = frame.bar
    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.min_text = bar:CreateFontString(nil, "OVERLAY")

    core.RedrawMeterFrame()

    -- Event handler for when buffs are updated
    frame:SetScript("OnEvent", update_on_event)

    -- OnUpdate script to update buff durations in real-time
    frame:SetScript("OnUpdate", function(self, elapsed)
          -- Call the update function every frame
    end)

    -- Drag functionality
    bar:SetScript("OnDragStart", function(self)

        if not core.config.UNLOCK_MOVING_BAR then
            return
        end

        bar:StartMoving()
    end)

    bar:SetScript("OnDragStop", function(self)

        if not core.config.UNLOCK_MOVING_BAR then
            return
        end

        bar:StopMovingOrSizing()
        -- Optionally save the new position for future use
        local point, parent, relativePoint, xOffset, yOffset = self:GetPoint()
        core.config.BAR_POINT_X = xOffset
        core.config.BAR_POINT_Y = yOffset
    end)

    -- Register events to track buffs
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")

    -- Function to update the progress values of the bar
    bar.UpdateProgress = function(self)
        if not damage_taken then return end

        local heal_from_damage = damage_taken * 0.2 * get_heal_modifier()
        local _heal = min_heal * get_min_heal_modifier()

        if heal_from_damage > _heal then
            _heal = heal_from_damage
        end
        heal = _heal

        local progress = floor(heal_from_damage)
        local max_progress = floor(max_heal)

        self:SetMinMaxValues(0, max_progress)
        self:SetValue(progress)
    end

    bar.UpdatePredictionText = function(self)
        self.text:SetText(format_number(heal))
    end

    -- Function to update the damage bar
    bar.UpdateBar = function(self)

        -- Update the progress of the bar
        bar:UpdateProgress()

        -- Update the text on the bar
        bar:UpdatePredictionText()

        bar:Show()
    end

    frame.text.UpdateHealText = function(self, value)
        if not value then
            self:SetText("")
            self:Hide()
            self.animations:Stop()
            self:SetFont("Fonts/FRIZQT__.TTF", core.config.HEAL_TEXT_FONT_SIZE, "OUTLINE")
            return
        end
        self.animations:Play()
        self:SetText(format_number(value))
        if heal > core.config.LARGE_HEAL_THRESHOLD * max_health then
            self:SetFont("Fonts/FRIZQT__.TTF", core.config.HEAL_TEXT_LARGE_FONT_SIZE, "OUTLINE")
        end
        self:Show()
    end

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
