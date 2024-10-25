local ADDON_NAME, core = ...;

-- Load LibSharedMedia
core.LSM = LibStub("LibSharedMedia-3.0")

core.default_config = {
    UNLOCK_MOVING_BAR = false,
    BAR_POINT_X = -229,
    BAR_POINT_Y = -42,
    BAR_WIDTH = 130,
    BAR_HEIGHT = 30,
    BAR_WIDTH_MAXIMUM_HEALTH = 0.4,
    OUT_OF_COMBAT_ALPHA = 0.5,
    IN_COMBAT_ALPHA = 1,
    LARGE_HEAL_THRESHOLD = 0.22,
    WINDOW_TIME = 5,
    BAR_BACKGROUND_ALPHA = 0.4,
    PREDICTION_TEXT_FONT_SIZE = 16,
    HEAL_TEXT_FONT_SIZE = 20,
    HEAL_TEXT_LARGE_FONT_SIZE = 24,
    BAR_TEXTURE = "DGround",
}
core.config = {}
core.created = false
core.default_texture_path = "Interface/Addons/DeathStrikeHealingMeter/Media/statusbar/bar_background.tga"

local frame

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


-- Helper function to create float edit boxes
local function CreateFloatOption(labelText, configKey)
    local content = frame.scroll.content
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", content.title, "BOTTOMLEFT", 0, content.current_position_y)
    label:SetText(labelText)

    local input = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    input:SetPoint("LEFT", label, "LEFT", 200, 0)
    input:SetSize(70, 30)
    input:SetAutoFocus(false)
    input:SetJustifyH("CENTER")

    input:SetScript("OnEnterPressed", function(self)
        core.config[configKey] = tonumber(self:GetText()) or core.config[configKey]
        self:ClearFocus()
        core.RedrawMeterFrame()
    end)

    content.current_position_y = content.current_position_y - 40
    content["option__"..configKey] = input

    return input
end


-- Helper function to create string edit boxes
local function CreateStringOption(labelText, configKey)
    local content = frame.scroll.content
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", content.title, "BOTTOMLEFT", 0, content.current_position_y)
    label:SetText(labelText)

    local input = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    input:SetPoint("LEFT", label, "LEFT", 200, 0)
    input:SetSize(250, 30)
    input:SetAutoFocus(false)
    input:SetJustifyH("LEFT")

    input:SetScript("OnEnterPressed", function(self)
        core.config[configKey] = self:GetText() or core.config[configKey]
        self:ClearFocus()
        core.RedrawMeterFrame()
    end)

    content.current_position_y = content.current_position_y - 40
    content["option__"..configKey] = input

    return input
end


-- Helper function to create string edit boxes
local function CreateCheckBoxOption(labelText, configKey)
    local content = frame.scroll.content
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", content.title, "BOTTOMLEFT", 0, content.current_position_y)
    label:SetText(labelText)

    -- Checkbox
    local input = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    input:SetPoint("LEFT", label, "LEFT", 200, 0)
    input:SetChecked(core.config.UNLOCK_MOVING_BAR)

    input:SetScript("OnClick", function(self)
        core.config.UNLOCK_MOVING_BAR = self:GetChecked()
        core.unlock_content(core.config.UNLOCK_MOVING_BAR)
    end)

    content.current_position_y = content.current_position_y - 40
    content["option__"..configKey] = input

    return input
end

-- Function to create the options frame
local function CreateOptionsFrame()
    -- Create the main frame for the options
    frame = CreateFrame("Frame", "DeathStrikeHealingOptions", UIParent)
    frame.name = "Death Strike Healing Meter"  -- Title of the frame in the interface options

    -- Scroll Frame Setup
    frame.scroll = CreateFrame("ScrollFrame", "MyAddonScrollFrame", frame, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", 16, -16)
    frame.scroll:SetPoint("BOTTOMRIGHT", -36, 16)

    -- Inner Content Frame
    frame.scroll.content = CreateFrame("Frame", nil, frame.scroll)
    frame.scroll.content:SetSize(1, 1)  -- Content will dynamically adjust size as elements are added
    frame.scroll.content.current_position_y = -40
    frame.scroll:SetScrollChild(frame.scroll.content)

    -- Title for the frame
    frame.scroll.content.title = frame.scroll.content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    frame.scroll.content.title:SetPoint("TOPLEFT", 16, -16)
    frame.scroll.content.title:SetText("Death Strike Healing Options")

    -- OnShow event: When the frame is shown, update the input boxes with the current values
    frame:SetScript("OnShow", function()
        -- Update each input's editbox with the current value from core.config
        for configKey, _ in pairs(core.config) do
            frame.scroll.content["option__"..configKey]:SetText(tostring(core.config[configKey]))
        end
    end)

    -- OnEvent event: reloads the UI on demand
    frame:SetScript("OnEvent", function(self, event, arg1)
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

    -- Create the UI when the entire Addon has finished loading
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_LOGOUT")

    -- Add float options for the configuration variables
    CreateCheckBoxOption("Unlock the Frame (move it):", "UNLOCK_MOVING_BAR")
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

    -- Adjust Content Height for Scrolling
    frame.scroll.content:SetHeight(40 + math.abs(frame.scroll.content.current_position_y))

    -- Register the frame in the Blizzard Interface Options
    local category, _ = Settings.RegisterCanvasLayoutCategory(frame, frame.name)
    Settings.RegisterAddOnCategory(category)
end

-- Call the function to create the options frame
CreateOptionsFrame()


local panel = CreateFrame("Frame", "MyAddonOptionsPanel", UIParent)
panel.name = ADDON_NAME

local config2 = {}

-- Scroll Frame Setup
local scrollFrame = CreateFrame("ScrollFrame", "MyAddonScrollFrame", panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 16, -16)
scrollFrame:SetPoint("BOTTOMRIGHT", -36, 16)

-- Inner Content Frame
local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(1, 1)  -- Content will dynamically adjust size as elements are added
scrollFrame:SetScrollChild(content)

-- Title for the panel
local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("My Addon Options")

-- Example Options: Adding multiple fields to demonstrate scrolling
local options = {}
local numOptions = 20  -- For demonstration, we'll create a large number of options

for i = 1, numOptions do
    -- Example EditBox for float values
    local editBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    editBox:SetSize(200, 25)
    editBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -40 * i)
    editBox:SetAutoFocus(false)
    editBox:SetText(tostring(config2["Option"..i] or 0))

    editBox:SetScript("OnTextChanged", function(self)
        config2["Option"..i] = tonumber(self:GetText())
    end)

    local label = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", editBox, "RIGHT", 10, 0)
    label:SetText("Option " .. i)

    options[i] = { label = label, editBox = editBox }
end

-- Adjust Content Height for Scrolling
local totalHeight = 40 * numOptions + 40  -- Adjust based on option elements
content:SetHeight(totalHeight)
-- Register the panel in the Blizzard Interface Options
local category, _ = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)