local ADDON_NAME, core = ...;

-- Load LibSharedMedia
core.LSM = LibStub("LibSharedMedia-3.0")

core.default_config = {
    BAR_WIDTH = 130,
    BAR_HEIGHT = 30,
    BAR_WIDTH_MAXIMUM_HEALTH = 0.4,
    OUT_OF_COMBAT_ALPHA = 0.5,
    IN_COMBAT_ALPHA = 1,
    LARGE_HEAL_THRESHOLD = 0.22,
    WINDOW_TIME = 5,
    BAR_POINT_X = -229,
    BAR_POINT_Y = -42,
    BAR_BACKGROUND_ALPHA = 0.4,
    PREDICTION_TEXT_FONT_SIZE = 16,
    HEAL_TEXT_FONT_SIZE = 20,
    HEAL_TEXT_LARGE_FONT_SIZE = 24,
    BAR_TEXTURE = "DGround",
}
core.config = {}
core.created = false
core.default_texture_path = "Interface/Addons/DeathStrikeHealingMeter/Media/statusbar/bar_background.tga"

-- Function to load or initialize the configuration
local function LoadConfig()
    -- If DeathStrikeHealingMeterDB doesn't exist, initialize it with default values
    if not DeathStrikeHealingMeterDB then
        DeathStrikeHealingMeterDB = {}
    end

    -- Load saved values into core.config, falling back to defaults for missing values
    core.config = {}
    for key, value in pairs(core.default_config) do
        core.config[key] = DeathStrikeHealingMeterDB[key] or value
    end
end

-- Function to save the current config into the SavedVariables table
local function SaveConfig()
    for key, value in pairs(core.config) do
        DeathStrikeHealingMeterDB[key] = value
    end
end

-- Function to create the options frame
local function CreateOptionsFrame()
    -- Create the main frame for the options
    local frame = CreateFrame("Frame", "DeathStrikeHealingOptions", UIParent)
    frame.name = "Death Strike Healing Meter"  -- Title of the frame in the interface options
    frame.current_position_y = -40

    -- Title for the frame
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Death Strike Healing Options")

    -- Helper function to create float edit boxes
    local function CreateFloatOption(labelText, configKey)
        local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, frame.current_position_y)
        label:SetText(labelText)

        local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        input:SetPoint("LEFT", label, "LEFT", 200, 0)
        input:SetSize(70, 30)
        input:SetAutoFocus(false)
        input:SetJustifyH("CENTER")

        input:SetScript("OnEnterPressed", function(self)
            core.config[configKey] = tonumber(self:GetText()) or core.config[configKey]
            self:ClearFocus()
            core.RedrawMeterFrame()
        end)

        frame.current_position_y = frame.current_position_y - 40
        frame["option__"..configKey] = input

        return input
    end

    -- Helper function to create string edit boxes
    local function CreateStringOption(labelText, configKey)
        local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, frame.current_position_y)
        label:SetText(labelText)

        local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        input:SetPoint("LEFT", label, "LEFT", 200, 0)
        input:SetSize(250, 30)
        input:SetAutoFocus(false)
        input:SetJustifyH("LEFT")

        input:SetScript("OnEnterPressed", function(self)
            core.config[configKey] = self:GetText() or core.config[configKey]
            self:ClearFocus()
            core.RedrawMeterFrame()
        end)

        frame.current_position_y = frame.current_position_y - 40
        frame["option__"..configKey] = input

        return input
    end

    -- Add float options for the configuration variables
    CreateFloatOption("Bar Width:", "BAR_WIDTH")
    CreateFloatOption("Bar Height:", "BAR_HEIGHT")
    CreateFloatOption("Bar Width (Max Health):", "BAR_WIDTH_MAXIMUM_HEALTH")
    CreateFloatOption("Out of Combat Alpha:", "OUT_OF_COMBAT_ALPHA")
    CreateFloatOption("In Combat Alpha:", "IN_COMBAT_ALPHA")
    CreateFloatOption("Large Heal Threshold:", "LARGE_HEAL_THRESHOLD")
    CreateFloatOption("Damage Window (seconds):", "WINDOW_TIME")
    CreateFloatOption("Bar Position X:", "BAR_POINT_X")
    CreateFloatOption("Bar Position Y:", "BAR_POINT_Y")
    CreateFloatOption("Bar Background Alpha:", "BAR_BACKGROUND_ALPHA")
    CreateFloatOption("Text Prediction Size:", "PREDICTION_TEXT_FONT_SIZE")
    CreateFloatOption("Text Heal Size:", "HEAL_TEXT_FONT_SIZE")
    CreateFloatOption("Text Large Heal Size:", "HEAL_TEXT_LARGE_FONT_SIZE")
    CreateStringOption("Bar Texture (or default):", "BAR_TEXTURE")

    -- OnShow event: When the frame is shown, update the input boxes with the current values
    frame:SetScript("OnShow", function()
        -- Update each input's editbox with the current value from core.config
        for configKey, _ in pairs(core.config) do
            frame["option__"..configKey]:SetText(tostring(core.config[configKey]))
        end
    end)

    -- Register the frame in the Blizzard Interface Options
    local category, _ = Settings.RegisterCanvasLayoutCategory(frame, frame.name)
    Settings.RegisterAddOnCategory(category)
end

-- Register event to load config on login and save config on logout or reload
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then

        local texture_path = core.LSM:Fetch("statusbar", core.config.BAR_TEXTURE)  -- Fetch the texture path from LibSharedMedia
        if not core.texture_path then
            core.texture_path = texture_path
        end

        if core.texture_path ~= texture_path and core.created then
            core.texture_path = texture_path
            core.RedrawMeterFrame()
        end

        if arg1 == ADDON_NAME then
            LoadConfig()
            core.CreateMeterFrame()
        end

    elseif event == "PLAYER_LOGOUT" then
        SaveConfig()
    end
end)

-- Call the function to create the options frame
CreateOptionsFrame()
