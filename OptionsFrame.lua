local ADDON_NAME, core = ...;


local frame

local FRAME_NAME = "DeathStrikeHealingMeterFrame"
local FRAME_TITLE = "Death Strike Healing Meter"

-- Creates a Float Option with a label and value
local function CreateFloatOption(labelText, key)
    local content = frame.scroll.content
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", content.title, "BOTTOMLEFT", 0, content.y_offset)
    label:SetText(labelText)

    local input = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    input:SetPoint("LEFT", label, "LEFT", 200, 0)
    input:SetSize(70, 30)
    input:SetJustifyH("RIGHT")
    input:SetTextInsets(0, 5, 0, 0)
    input:SetAutoFocus(false)

    input:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or core.GetConfigValue(key)
        core.SetConfigValue(key, core.Round(value, 2))
        self:ClearFocus()
    end)

    input.key = key --debug

    content.y_offset = content.y_offset - 40
    content["option__"..key] = input

    return input
end


-- Creates a String Option with a label and value
local function CreateStringOption(labelText, key)
    local content = frame.scroll.content
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", content.title, "BOTTOMLEFT", 0, content.y_offset)
    label:SetText(labelText)
    content.y_offset = content.y_offset - 40

    local input = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    input:SetPoint("LEFT", label, "LEFT", 200, 0)
    input:SetSize(250, 30)
    input:SetAutoFocus(false)
    input:SetJustifyH("LEFT")

    input:SetScript("OnEnterPressed", function(self)
        core.SetConfigValue(key, self:GetText() or core.GetConfigValue(key))
        self:ClearFocus()
    end)

    content["option__"..key] = input

    return input
end


-- Creates a Checkbox Option with a label and checkbox
local function CreateCheckBoxOption(labelText, key)
    local content = frame.scroll.content
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", content.title, "BOTTOMLEFT", 0, content.y_offset)
    label:SetText(labelText)

    -- Checkbox
    local input = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    input:SetPoint("LEFT", label, "LEFT", 240, 0)
    input:SetChecked(core.GetConfigValue(key))

    input:SetScript("OnClick", function(self)
        core.SetConfigValue(key, self:GetChecked())
    end)

    content.y_offset = content.y_offset - 40
    content["option__"..key] = input

    return input
end


-- Creates a Dropdown Option with a label and a dropdown menu
local function CreateDropdownOption(labelText, key, items)
    local content = frame.scroll.content

    -- Label for the dropdown
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", content.title, "BOTTOMLEFT", 0, content.y_offset)
    label:SetText(labelText)

    -- Create the dropdown
    local dropdown = CreateFrame("Frame", "DeathStrikeHealingOptionsDropdown_"..key, content, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", label, "LEFT", 200, 0)

    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_SetSelectedName(dropdown, core.GetConfigValue(key) or "Select an option")

    -- Initialize the dropdown menu
    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for _, item in ipairs(items) do
            info.text = item
            info.checked = (core.GetConfigValue(key) == item)  -- Mark the currently selected option as checked
            info.func = function()
                UIDropDownMenu_SetSelectedName(dropdown, item)
                core.SetConfigValue(key, item)  -- Save selection to database
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Adjust position for the next item
    content.y_offset = content.y_offset - 50
    content["option__"..key] = dropdown
end

local function CreateColorOption(labelText, key)
    local content = frame.scroll.content

    -- Label
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", content.title, "BOTTOMLEFT", 0, content.y_offset)
    label:SetText(labelText)

    -- Color value updater
    local function UpdateColorPreview(swatch, color)
        swatch:SetColorTexture(color[1], color[2], color[3])
    end

    -- Function to create one input box
    local function CreateColorBox(xOffset, colorIndex)
        local box = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
        box:SetSize(40, 20)
        box:SetAutoFocus(false)
        box:SetJustifyH("CENTER")
        box:SetPoint("LEFT", label, "LEFT", xOffset, 0)
        return box
    end

    -- Create RGB boxes
    local boxes = {
        CreateColorBox(200, 1), -- R
        CreateColorBox(255, 2), -- G
        CreateColorBox(310, 3), -- B
    }

    -- Create swatch preview box
    local swatch = content:CreateTexture(nil, "OVERLAY")
    swatch:SetSize(40, 20)
    swatch:SetPoint("LEFT", label, "LEFT", 380, 0)
    swatch:SetColorTexture(1, 1, 1) -- Initial white

    -- Save on EnterPressed for all boxes
    for i = 1, 3 do
        boxes[i]:SetScript("OnEnterPressed", function(self)
            local color = { unpack(core.GetConfigValue(key)) }
            local val = tonumber(self:GetText())

            if not val or val < 0 or val > 1 then
                return
            end

            color[i] = val
            core.SetConfigValue(key, color)
            UpdateColorPreview(swatch, color)

            self:SetText(string.format("%.2f", val))
            self:ClearFocus()
        end)
    end

    -- Custom SetText wrapper to update all three boxes + swatch
    boxes.SetColorTexts = function(self, color)
        for i = 1, 3 do
            self[i]:SetText(string.format("%.2f", color[i] or 0))
        end
        UpdateColorPreview(swatch, color)
    end

    -- Store it for OnShow refresh
    content["option__"..key] = boxes

    content.y_offset = content.y_offset - 40
end


local function CreateHeaderOption(labelText)
    local content = frame.scroll.content

    local label = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    label:SetPoint("TOPLEFT", content.title, "BOTTOMLEFT", -10, content.y_offset)
    label:SetText(labelText)

    content.y_offset = content.y_offset - 30
end


-- Function to create the options frame
core.CreateOptionsFrame = function()
    -- Create the main frame for the options
    frame = CreateFrame("Frame", FRAME_NAME, UIParent)
    frame.name = FRAME_TITLE  -- Title of the frame in the interface options

    -- Scroll Frame Setup
    frame.scroll = CreateFrame("ScrollFrame", "MyAddonScrollFrame", frame, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", 16, -16)
    frame.scroll:SetPoint("BOTTOMRIGHT", -36, 16)

    -- Inner Content Frame
    local content = CreateFrame("Frame", nil, frame.scroll)
    frame.scroll.content = content
    content:SetSize(1, 1)  -- Content will dynamically adjust size as elements are added
    content.y_offset = -40
    frame.scroll:SetScrollChild(content)
    -- Title for the frame
    content.title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    content.title:SetPoint("TOPLEFT", 16, -16)
    content.title:SetText(FRAME_TITLE)

    -- Reload Notice
    local reloadNotice = frame.scroll.content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    reloadNotice:SetPoint("TOPLEFT", frame.scroll.content.title, "BOTTOMLEFT", 0, -5)
    reloadNotice:SetText("Some changes may require a /reload to take effect")

    for _, key in pairs(core.defaultConfig._keys) do
        local option = core.defaultConfig[key]
        if option.type == 'float' then
            CreateFloatOption(option.label, key)
        elseif option.type == 'string' then
            CreateStringOption(option.label, key)
        elseif option.type == 'checkbox' then
            CreateCheckBoxOption(option.label, key)
        elseif option.type == 'dropdown' then
            CreateDropdownOption(option.label, key, option.options)
        elseif option.type == 'color' then
            CreateColorOption(option.label, key)
        elseif option.type == 'header' then
            CreateHeaderOption(option.label)
        end
    end

    -- OnShow event: When the frame is shown, update the input boxes with the current values
    frame:SetScript("OnShow", function()
        -- Update each input's editbox with the current value from config
        for key, option in pairs(core.defaultConfig) do
            local inputFrame = content["option__"..key]
            local value = core.GetConfigValue(key)

            if inputFrame then
                if option.type == "color" then
                    if inputFrame.SetColorTexts then
                        inputFrame:SetColorTexts(value)
                    end
                elseif option.type == "checkbox" then
                    inputFrame:SetChecked(value)
                elseif option.type == "float" then
                    inputFrame:SetText(tostring(core.Round(value, 2)))
                elseif option.type == "string" then
                    inputFrame:SetText(tostring(value))
                elseif option.type == "dropdown" then
                    --UIDropDownMenu_SetText(subframe, core.config[configKey] or "Select an option")
                    --UIDropDownMenu_SetSelectedName(subframe, core.config[configKey])
                end
            end
        end
    end)

    content["option__LOCK_FRAME"]:SetScript("OnClick", function(self)
        local key = "LOCK_FRAME"
        core.SetConfigValue(key, self:GetChecked())

        local is_movable = not self:GetChecked()
        core.frame:SetMovable(is_movable)
        core.frame:EnableMouse(is_movable)
        if is_movable then
            core.frame:RegisterForDrag("LeftButton")
        else
            core.frame:RegisterForDrag()
        end
    end)


    -- Adjust Content Height for Scrolling
    content:SetHeight(40 + math.abs(content.y_offset))

    -- Register the frame in the Blizzard Interface Options
    local category, _ = Settings.RegisterCanvasLayoutCategory(frame, frame.name)
    Settings.RegisterAddOnCategory(category)

end
