-- Default log level is NOTICE.
-- Use log_setLogLevel(logLevel) to change it from your code.
-- Call log_addWritableLogLevelDataRef(dataRefName) to create a writable DataRef to make it easy to change within X-Plane.

-- We use rfc5424 log levels (numerical).
raw_table('logLevels')
logLevels = {
    EMER = 0,
    ALER = 1,
    CRIT = 2,
    ERROR = 3,
    WARN = 4,
    NOTICE = 5,
    INFO = 6,
    DEBUG = 7,
    EXTREME = 8, -- one more for outputting 100k lines of airfoil data...
}

logLevel = logLevels.NOTICE

dofile('lib/tableHelpers.lua')
--[[
    local
]]

local logLevelsLookup = {}
for k, v in pairs(logLevels) do
    logLevelsLookup[v] = k
end

local indentTablesSpaces = 2
local prefix = ''

-- @see https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
local function dump(o, indentLevel)
    local indentLevel = indentLevel or 0
    if type(o) == 'table' then
        local s = string.rep(' ', indentLevel * indentTablesSpaces) .. '{ \n'
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. string.rep(' ', (indentLevel + 1)  * indentTablesSpaces) .. k .. ': ' .. dump(v, indentLevel + 1) .. '\n'
        end
        return s .. string.rep(' ', indentLevel * indentTablesSpaces) .. '} '
    else
        return tostring(o)
    end
end

--[[
    global
]]

function log(msg, level)
    -- default is DEBUG
    local level = level or 7
    if logLevel < level then
        return
    end

    local msg = msg or ''
    local filePath = debug.getinfo(2, 'S').source
    local relevantFilePath = filePath:match('([^/\\]+[.]lua)$')
    local functionName = debug.getinfo(2, 'n').name
    print(
        string.format(
            '%s:%s%s %s %s',
            prefix,
            relevantFilePath,
            functionName and '::' .. functionName .. '()' or '',
            level ~= logLevel and logLevelsLookup[level] or '',
            dump(msg)
        )
    )
end

function log_setLogPrefix(_prefix)
    prefix = _prefix
end

function log_addWritableLogLevelDataRef(logLevelDataRefName)
    -- promote our variable (which is global for that purpose) to a DataRef
    local _logLevel = logLevel
    logLevel = create_dataref(logLevelDataRefName, 'number', logLevel_DRhandler)
    logLevel = _logLevel
end

function log_setLogLevel(level)
    if level == nil then
        return
    end
    logLevel = level
end

--[[
    dataref callbacks
]]

function logLevel_DRhandler()
    logLevel = math.min(math.max(logLevel, 0), 8)
    log(string.format('LogLevel set to: %s', keyOf(logLevels, logLevel)), logLevel)
end

--[[
    writable datarefs
]]
-- we create one dynamically in log_addWritableLogLevelDataRef()
