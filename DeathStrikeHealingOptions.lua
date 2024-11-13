local ADDON_NAME, core = ...;

-- Load LibSharedMedia
core.LSM = LibStub("LibSharedMedia-3.0")

core.config = {
    UNLOCK_MOVING_BAR = { type = "checkbox", label = "Unlock the Frame (move it)", default = true },
    BAR_WIDTH = { type = "float", label = "Bar Width", default = 130 },
    BAR_HEIGHT = { type = "float", label = "Bar Height", default = 30 },
    BAR_WIDTH_MAXIMUM_HEALTH = { type = "float", label = "Bar Width (Max Health)", default = 0.4 },
    OUT_OF_COMBAT_ALPHA = { type = "float", label = "Out of Combat Alpha", default = 0.5 },
    IN_COMBAT_ALPHA = { type = "float", label = "In Combat Alpha", default = 1 },
    LARGE_HEAL_THRESHOLD = { type = "float", label = "Large Heal Threshold", default = 0.22 },
    WINDOW_TIME = { type = "float", label = "Damage Window (seconds)", default = 5 },
    BAR_POINT_X = { type = "float", label = "Bar Position X", default = -229 },
    BAR_POINT_Y = { type = "float", label = "Bar Position Y", default = -42 },
    BAR_BACKGROUND_ALPHA = { type = "float", label = "Bar Background Alpha", default = 0.4 },
    PREDICTION_TEXT_FONT_SIZE = { type = "float", label = "Text Prediction Size", default = 16 },
    HEAL_TEXT_FONT_SIZE = { type = "float", label = "Text Heal Size", default = 20 },
    HEAL_TEXT_LARGE_FONT_SIZE = { type = "float", label = "Text Large Heal Size", default = 24 },
    BAR_TEXTURE = { type = "string", label = "Bar Texture (or default)", default = "DGround" },
    ANIMATION_DIRECTION = { type = "dropdown", label = "Animation", options = { "UP", "DOWN", "RIGHT", "LEFT" }, default = "RIGHT" },
}

core.created = false
core.default_texture_path = "Interface/Addons/DeathStrikeHealingMeter/Media/statusbar/bar_background.tga"

local frame

-- Function to load or initialize the configuration
local function LoadConfig()
    -- If DeathStrikeHealingMeterDB doesn't exist, initialize it with default values
    if not DeathStrikeHealingMeterDB then
        print("DeathStrikeHealingMeter: No Existing Database")
        DeathStrikeHealingMeterDB = {}
    end

    -- Load saved values into core.config, falling back to defaults for missing values
    for key, option in pairs(core.config) do
        option.value = DeathStrikeHealingMeterDB[key] or option.default
    end

end

-- Function to save the current config into the SavedVariables table
local function SaveConfig()
    for key, option in pairs(core.config) do
        DeathStrikeHealingMeterDB[key] = option.value or option.default
    end
end

-- Function to save the one config value into the SavedVariables table
local function SaveConfigKey(key)
    local option = core.config[key]
    DeathStrikeHealingMeterDB[key] = option.value or option.default
end


-- Function to load the current config as a read-only table
core.GetConfig = function()
    local config = {}
    for key, option in pairs(core.config) do
        config[key] = option.value
    end
    return config
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
        core.config[configKey].value = tonumber(self:GetText()) or core.config[configKey].value
        SaveConfigKey(configKey)
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
    content.current_position_y = content.current_position_y - 40

    local input = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    input:SetPoint("LEFT", label, "LEFT", 200, 0)
    input:SetSize(250, 30)
    input:SetAutoFocus(false)
    input:SetJustifyH("LEFT")

    input:SetScript("OnEnterPressed", function(self)
        core.config[configKey].value = self:GetText() or core.config[configKey].value
        SaveConfigKey(configKey)
        self:ClearFocus()
        core.RedrawMeterFrame()
    end)

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
    input:SetChecked(core.config[configKey].value)

    input:SetScript("OnClick", function(self)
        core.config[configKey].value = self:GetChecked()
        SaveConfigKey(configKey)
        core.unlock_frame(core.config[configKey].value)
    end)

    content.current_position_y = content.current_position_y - 40
    content["option__"..configKey] = input

    return input
end


-- Create a dropdown menu function
    local function CreateDropdownOption(labelText, configKey, items)
        local content = frame.scroll.content

        -- Label for the dropdown
        local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", content.title, "BOTTOMLEFT", 0, content.current_position_y)
        label:SetText(labelText)

        -- Create the dropdown
        local dropdown = CreateFrame("Frame", "DeathStrikeHealingOptionsDropdown_"..configKey, content, "UIDropDownMenuTemplate")
        dropdown:SetPoint("LEFT", label, "LEFT", 200, 0)

        UIDropDownMenu_SetWidth(dropdown, 150)
        UIDropDownMenu_SetSelectedName(dropdown, core.config[configKey].value or "Select an option")

        -- Initialize the dropdown menu
        UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
            local info = UIDropDownMenu_CreateInfo()
            for _, item in ipairs(items) do
                info.text = item
                info.checked = (core.config[configKey].value == item)  -- Mark the currently selected option as checked
                info.func = function()
                    UIDropDownMenu_SetSelectedName(dropdown, item)
                    core.config[configKey].value = item  -- Save selection to config
                    SaveConfigKey(configKey)  -- Save selection to database
                    core.RedrawMeterFrame()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)

        -- Adjust position for the next item
        content.current_position_y = content.current_position_y - 50
        content["option__"..configKey] = dropdown
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
        -- Update each input's editbox with the current value from config
        for configKey, option in pairs(core.config) do
            local subframe = frame.scroll.content["option__"..configKey]
            if subframe.SetText then
                subframe:SetText(tostring(option.value))
            elseif option.type == "dropdown" then
                --UIDropDownMenu_SetText(subframe, core.config[configKey] or "Select an option")
                --UIDropDownMenu_SetSelectedName(subframe, core.config[configKey])
            end
        end
    end)

    frame:SetScript("OnHide", function()
        if core.config.BAR_WIDTH.value then
            SaveConfig()
        end
    end)

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
    CreateDropdownOption("Animation:", "ANIMATION_DIRECTION", { "UP", "DOWN", "RIGHT", "LEFT" })

    -- Adjust Content Height for Scrolling
    frame.scroll.content:SetHeight(40 + math.abs(frame.scroll.content.current_position_y))

    -- Register the frame in the Blizzard Interface Options
    local category, _ = Settings.RegisterCanvasLayoutCategory(frame, frame.name)
    Settings.RegisterAddOnCategory(category)
end

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
            LoadConfig()
            CreateOptionsFrame()
            core.CreateMeterFrame()
        end

    elseif event == "PLAYER_LOGOUT" then
        if core.created then
            SaveConfig()
        end
    end
end)

-- Create the UI when the entire Addon has finished loading
loadFrame:RegisterEvent("ADDON_LOADED")
loadFrame:RegisterEvent("PLAYER_LOGOUT")

