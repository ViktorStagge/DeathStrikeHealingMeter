local ADDON_NAME, core = ...;

-- Load LibSharedMedia
core.LSM = LibStub("LibSharedMedia-3.0")


local function CreateOrderedTable()
    local ordered = {
        _keys = {},
    }

    return setmetatable(ordered, {
        __newindex = function(t, key, value)
            if rawget(t, key) == nil then
                table.insert(t._keys, key)
            end
            rawset(t, key, value)
        end,
        __index = function(t, key)
            return rawget(t, key)
        end,
    })
end

core.defaultConfig = CreateOrderedTable()

core.defaultConfig.LOCK_FRAME = {
    type = "checkbox",
    label = "Lock the Frame",
    default = true,
}
core.defaultConfig.BAR_WIDTH = {
    type = "float",
    label = "Bar Width",
    default = 130,
}
core.defaultConfig.BAR_HEIGHT = {
    type = "float",
    label = "Bar Height",
    default = 30,
}
core.defaultConfig.BAR_WIDTH_MAXIMUM_HEALTH = {
    type = "float",
    label = "Bar Width (Max Health)",
    default = 0.4,
}
core.defaultConfig.OUT_OF_COMBAT_ALPHA = {
    type = "float",
    label = "Out of Combat Alpha",
    default = 0.5,
}
core.defaultConfig.IN_COMBAT_ALPHA = {
    type = "float",
    label = "In Combat Alpha",
    default = 1,
}
core.defaultConfig.LARGE_HEAL_THRESHOLD = {
    type = "float",
    label = "Large Heal Threshold",
    default = 0.22,
}
core.defaultConfig.WINDOW_TIME = {
    type = "float",
    label = "Damage Window (seconds)",
    default = 5,
}
core.defaultConfig.BAR_POINT_X = {
    type = "float",
    label = "Bar Position X",
    default = -229,
}
core.defaultConfig.BAR_POINT_Y = {
    type = "float",
    label = "Bar Position Y",
    default = -42,
}
core.defaultConfig.BAR_BACKGROUND_ALPHA = {
    type = "float",
    label = "Bar Background Alpha",
    default = 0.4,
}
core.defaultConfig.PREDICTION_TEXT_FONT_SIZE = {
    type = "float",
    label = "Text Prediction Size",
    default = 16,
}
core.defaultConfig.HEAL_TEXT_FONT_SIZE = {
    type = "float",
    label = "Text Heal Size",
    default = 20,
}
core.defaultConfig.HEAL_TEXT_LARGE_FONT_SIZE = {
    type = "float",
    label = "Text Large Heal Size",
    default = 24,
}
core.defaultConfig.BAR_TEXTURE = {
    type = "string",
    label = "Bar Texture (or default)",
    default = "DGround",
}
core.defaultConfig.ANIMATION_DIRECTION = {
    type = "dropdown",
    label = "Animation",
    options = { "UP", "DOWN", "RIGHT", "LEFT" },
    default = "RIGHT",
}

core.created = false
core.default_texture_path = "Interface/Addons/DeathStrikeHealingMeter/Media/statusbar/bar_background.tga"


-- If DeathStrikeHealingMeterDB doesn't exist, initialize it with default values
if not DeathStrikeHealingMeterDB then
    DeathStrikeHealingMeterDB = {}
end

-- Function to save the one config value into the SavedVariables table
core.SetConfigValue = function(key, value)
    if value ~= nil then
        DeathStrikeHealingMeterDB[key] = value
        core.config = core.GetConfig()
    elseif core.defaultConfig[key] and core.defaultConfig[key].default then
        DeathStrikeHealingMeterDB[key] = core.defaultConfig[key].default
        core.config = core.GetConfig()
    end
end

core.GetConfigValue = function(key)
    if DeathStrikeHealingMeterDB and DeathStrikeHealingMeterDB[key] ~= nil then
        return DeathStrikeHealingMeterDB[key]
    elseif core.defaultConfig and core.defaultConfig[key] and core.defaultConfig[key].default ~= nil then
        return core.defaultConfig[key].default
    else
        return nil  -- unknown config key
    end
end

-- Function to load the current config as a read-only table
core.GetConfig = function()
    local config = {}
    for key, option in pairs(core.defaultConfig) do
        config[key] = DeathStrikeHealingMeterDB[key] or option.default
    end
    return config
end


core.Round = function(n, decimals)
    if n == nil then
        return
    end

    local mult = 10 ^ (decimals or 0)
    return math.floor(n * mult + 0.5) / mult
end
