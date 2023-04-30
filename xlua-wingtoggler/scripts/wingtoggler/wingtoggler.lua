--[[
    Author: flightwusel

    current state:

    I am missing a DataRef for lat/long/vert arm


    Changes to .acf
        set flap Cl/Cd/Cm to 0
            that seems to not be saved. The effect is still noticable in the flight model.
            Only when the flap deflection angles for each detent are set to 0 it is removed. -> but this means that the flaps do not move in the visual model.
            So I set all flap chord ratoios to 0.

    float indices in tables: should be ok since we never do any calculations on them (no need for fuzzy float compare)
]]



--[[
    imports
]]

dofile('lib/acfFileName.lua')
dofile('lib/tableHelpers.lua')
dofile('lib/log.lua')
-- Prefix all our log entries with this aircraft to let people know where log entries are coming from:
log_setLogPrefix(acfDirName())
-- Set DataRef 'wingtoggler/logLevel' to 7 for DEBUG messages ...
log_addWritableLogLevelDataRef('wingtoggler/logLevel')
-- ... or launch X-Plane with an environment variable WINGTOGGLER_LOGLEVEL=7
log_setLogLevel(tonumber(os.getenv('WINGTOGGLER_LOGLEVEL')))

--[[
    runtime variables
]]

local isActive = false
local logWhenSourceStable = nil
local logWhenSourceStable_ = nil
local source_

--[[
    local functions
]]

local function do_configure(_config)
    configuration = _config
    log(
        string.format(
            'Activated %d detent configurations, and we are going to %s between them. We are using %s to apply the changes.',
            count(configuration.detents),
            configuration.source.mode.name,
            configuration.apply.mode.name
        ),
        logLevels.NOTICE
    )
    isActive = true

    simDR_source = find_dataref(configuration.source.dataRef.name)

    -- ordered detent keys:
    configuration.detents_idxs = {}
    for detent_idx in pairs(configuration.detents) do table.insert(configuration.detents_idxs, detent_idx) end
    table.sort(configuration.detents_idxs)

    -- used wing segments (as a Lua pseudo "set"):
    configuration.detentSegments_set = {}
    for detent_idx in pairs(configuration.detents) do
        for _, segment_idx in pairs(configuration.detents[detent_idx].segments) do
            configuration.detentSegments_set[segment_idx] = true
        end
    end
end

local function runConfigFile()
    dofile('lib/applyModes/changeSemilen.lua')
    dofile('lib/applyModes/setAfl.lua')

    local configFilePath = 'config/wingtoggler-config.lua'
    if not pcall(function() dofile(configFilePath) end) then
        log(
            string.format(
                'Could not load configuration file %s. This could mean that it is just not there or that it has a syntax error and cannot be read and executed as Lua script.',
                configFilePath
            ),
            logLevels.ERROR
        )
    end
end

local function logState(activeDetentRatios, logString)
    -- we are called again with nil, logString to output only relevant values in lower log levels
    if logString ~= nil then
        log(logString, logLevels.NOTICE)
        return
    end

    local logEntries = {}
    for _, detent_idx in pairs(configuration.detents_idxs) do
        if activeDetentRatios[detent_idx] ~= nil then
            table.insert(
                logEntries,
                string.format(
                    '‹%s›(%3d%%)',
                    configuration.detents[detent_idx].name,
                    activeDetentRatios[detent_idx] * 100.
                )
            )
        end
    end

    -- remember for outputting only relevant values in lower log levels
    logWhenSourceStable = table.concat(logEntries, ' | ')
    log(logWhenSourceStable, logLevels.INFO)
end

local function activeDetentRatios(source)
    log(string.format('source: %s', source))

    if #configuration.detents_idxs == 0 then
        return {}
    end

    local lower_idx = configuration.source.dataRef.min - 1.
    local upper_idx = configuration.source.dataRef.max + 1.
    local lowerRatio = 0.
    local upperRatio = 0.

    for _, detent_idx in pairs(configuration.detents_idxs) do
        if detent_idx <= source then
            lower_idx = detent_idx
        else
            upper_idx = detent_idx

            range = upper_idx - lower_idx
            if range == 0 then
                log('distance between 2 detents is 0 !?', logLevels.ERROR)
                break
            end
            upperRatio = (simDR_source - lower_idx) / range
            if configuration.source.mode == sourceModes.SWITCH then
                upperRatio = upperRatio > .5 and 1. or 0.
            end

            lowerRatio = 1 - upperRatio

            break
        end
    end
    if lower_idx < configuration.source.dataRef.min then
        lowerRatio = 0.
        upperRatio = 1.
        lower_idx = configuration.detents_idxs[1]
    end
    if upper_idx > configuration.source.dataRef.max then
        lowerRatio = 1.
        upperRatio = 0.
        upper_idx = configuration.detents_idxs[#configuration.detents_idxs]
    end

    -- make into compact table
    local activeDetentRatios = {}
    if lower_idx >= configuration.source.dataRef.min and lowerRatio ~= 0. then
        activeDetentRatios[lower_idx] = lowerRatio
    end
    if upper_idx <= configuration.source.dataRef.max and upperRatio ~= 0. then
        activeDetentRatios[upper_idx] = upperRatio
    end

    logState(activeDetentRatios)

    return activeDetentRatios
end

--

local function do_aircraft_load()
    runConfigFile()
    if isActive then
        configuration.apply.mode.aircraft_load()
    end
end

local function do_aircraft_unload()
    -- This gets also called when we do "XLua reload scripts" so we use it to reset the DataRefs we have written
    -- in order to be able to reinitialize them to the .acf values in aircraft_load().
    log('resetting to original .acf values')
    if isActive then
        configuration.apply.mode.aircraft_unload()
    end
    isActive = false
end

local function do_before_physics()
    if isActive and source_ ~= simDR_source then
        local source = math.max(
            configuration.source.dataRef.min,
            math.min(configuration.source.dataRef.max, simDR_source)
        )
        configuration.apply.mode.apply(
            activeDetentRatios(source)
        )
        source_ = simDR_source
    elseif logWhenSourceStable and logLevel == logLevels.NOTICE and logWhenSourceStable_ ~= logWhenSourceStable then
        -- we log the state for every step for logLevel INFO, but for NOTICE only when the flaps are not moving any more
        logState(nil, logWhenSourceStable)
        logWhenSourceStable_ = logWhenSourceStable
        logWhenSourceStable = nil
    end
end

--[[
    global
]]

raw_table('configuration')
configuration = {}

raw_table('sourceModes')
sourceModes = {
    INTERPOLATE = { name = 'INTERPOLATE' },
    SWITCH = { name = 'SWITCH' },
}

configure = do_configure

raw_table('applyModes')
applyModes = {}

-- XLua callbacks
function aircraft_load() do_aircraft_load() end
function before_physics() do_before_physics() end
function aircraft_unload() do_aircraft_unload() end
