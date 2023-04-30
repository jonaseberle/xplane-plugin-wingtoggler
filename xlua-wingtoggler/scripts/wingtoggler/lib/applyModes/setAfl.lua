--[[
    The DataRefs only exposes
        2 airfoils (root/mid, no tip)
        1 Re number set
]]

--[[
    runtime variables
]]

local simDR_acf_semilen_SEG = find_dataref('sim/aircraft/parts/acf_semilen_SEG')
local afl = {
    simDR_cl = find_dataref('sim/airfoils/afl_cl'), -- float[56][2][2][721]
    simDR_cd = find_dataref('sim/airfoils/afl_cd'), -- float[56][2][2][721]
    simDR_cm = find_dataref('sim/airfoils/afl_cm'), -- float[56][2][2][721]
    --     simDR_clB = find_dataref('sim/airfoils/afl_clB'), -- float[56][2][2]
    --     simDR_almin = find_dataref('sim/airfoils/afl_almin_array'), -- float[56][2][2]
    --     simDR_almax = find_dataref('sim/airfoils/afl_almax_array'), -- float[56][2][2]
    --     simDR_re = find_dataref('sim/airfoils/afl_re_num'), -- float[56][2][2]
    --     simDR_t = find_dataref('sim/airfoils/afl_t_rat'), -- float[56][2][2]
    --     simDR_mach_div = find_dataref('sim/airfoils/afl_mach_div'), -- float[56][2][2]
    --     simDR_clM = find_dataref('sim/airfoils/afl_clM'), -- float[56][2][2]
}

local nWingSegments = 56
local nAirfoils = 2 -- 0: root, 1: mid
local nSides = 2
local nAlphas = 721

local coefficient_types = {'cl', 'cd', 'cm'}

-- this gets populated on aircraft_load() with what is defined in Plane + Airfoil Maker
local acf = {
    acf_semilen_SEG = {},
    afl = {
        cl = {},
        cd = {},
        cm = {},
    }
}

local function aflIdxExplode(idx)
    local alpha = idx % nAlphas
    idx = (idx - alpha) / nAlphas
    local side = idx % nSides
    idx = (idx - side) / nSides
    local airfoil = idx % nAirfoils
    idx = (idx - airfoil) / nAirfoils
    local wingSegment = idx

    return {
        wingSegment_idx = wingSegment,
        airfoil_idx = airfoil,
        side_idx = side,
        alpha_idx = alpha,
    }
end

local function aflIdxToStr(idx)
    local ex = aflIdxExplode(idx)
    return string.format('%2d %d %d %3d', ex.wingSegment_idx, ex.airfoil_idx, ex.side_idx, ex.alpha_idx)
end

local function afl_idx(wingSegment_idx, airfoil_idx, side_idx, alpha_idx)
    return wingSegment_idx * nAirfoils * nSides * nAlphas
                         + airfoil_idx * nSides * nAlphas
                                     + side_idx * nAlphas
                                              + alpha_idx
end

local function saveSemilen()
    for wingSegment_idx in pairs(configuration.detentSegments_set) do
         acf.acf_semilen_SEG[wingSegment_idx] = simDR_acf_semilen_SEG[wingSegment_idx]
    end
end

local function saveAfl()
    for _, coefficient_type in pairs(coefficient_types) do
        for wingSegment_idx in pairs(configuration.detentSegments_set) do
            for airfoil_idx = 0, nAirfoils - 1 do
                for side_idx = 0, nSides - 1 do
                    for alpha_idx = 0, nAlphas - 1 do
                        local idx = afl_idx(wingSegment_idx, airfoil_idx, side_idx, alpha_idx)
                        local value = afl['simDR_' .. coefficient_type][idx]
                        log(
                            string.format('afl[%s][%s] == %8.5f', coefficient_type, aflIdxToStr(idx), value)
                        )
                        acf.afl[coefficient_type][idx] = value
                    end
                end
            end
        end
    end
end

local function disableDetentSegments()
    for wingSegment_idx in pairs(configuration.detentSegments_set) do
        -- but not those that are targets
        if keyOf(configuration.apply.SET_AFL_settings.targetSegments, wingSegment_idx) == nil then
            simDR_acf_semilen_SEG[wingSegment_idx] = 0.
            log(string.format('semilen[%2d] == %f', wingSegment_idx, 0.))
        end
    end
end

--

local function do_aircraft_load()
    -- save initial values
    saveSemilen()
    saveAfl()

    -- disable the source wing segments that we just use for their airfoil data
    disableDetentSegments()
end

local function do_aircraft_unload()
    -- reset to initial values
    for _, coefficient_type in pairs(coefficient_types) do
        for wingSegment_idx in pairs(configuration.detentSegments_set) do
            for airfoil_idx = 0, nAirfoils - 1 do
                for side_idx = 0, nSides -1 do
                    for alpha_idx = 0, nAlphas -1 do
                        local idx = afl_idx(wingSegment_idx, airfoil_idx, side_idx, alpha_idx)
                        local value = acf.afl[coefficient_type][idx]
                        log(
                            string.format('simDR[%s][%s] = %8.5f', coefficient_type, aflIdxToStr(idx), value),
                            logLevels.EXTREME
                        )
                        afl['simDR_' .. coefficient_type][idx] = value
                    end
                end
            end
        end
    end

    for wingSegment_idx in pairs(configuration.detentSegments_set) do
        local value = acf.acf_semilen_SEG[wingSegment_idx]
        simDR_acf_semilen_SEG[wingSegment_idx] = value
        log(
            string.format('semilen[%2d] = %f', wingSegment_idx, value),
            logLevels.EXTREME
        )
    end
end

local function do_apply(activeDetentRatios)
    local logEach = 1
    if logLevel <= logLevels.DEBUG then
        logEach = 10000
        log(string.format('Only outputting each %dth value. Raise logLevel to see more.', logEach))
    end

    local count = 0
    -- segment_idx is the index in the configuration, so usually 1-4
    for segment_idx, targetSegment in pairs(configuration.apply.SET_AFL_settings.targetSegments) do
        for airfoil_idx = 0, nAirfoils -1 do
            for side_idx = 0, nSides -1 do
                for alpha_idx = 0, nAlphas -1 do

                    -- just output some few entries to check plausibility
                    local isLog = count % logEach == 0

                    target_idx = afl_idx(targetSegment, airfoil_idx, side_idx, alpha_idx)
                    for _, coefficient_type in pairs(coefficient_types) do
                        local aflCoefficient_idx = 'simDR_' .. coefficient_type
                        local value = 0.
                        for detent_idx, ratio in pairs(activeDetentRatios) do
                            local sourceSegment = configuration.detents[detent_idx].segments[segment_idx]
                            local source_idx = afl_idx(sourceSegment, airfoil_idx, side_idx, alpha_idx)
                            local _value = acf.afl[coefficient_type][source_idx]
                            if isLog then
                                log(string.format('(%3d%%) [%s] == %s', ratio * 100, sourceSegment, _value))
                            end
                            value = value + _value * ratio
                            count = count + 1
                        end

                        if isDebug then
                            log(string.format('%s[%s] = %s', aflCoefficient_idx, aflIdxToStr(target_idx), value))
                        end
                        afl[aflCoefficient_idx][target_idx] = value
                    end
                end
            end
        end
    end
    log(string.format('%d values processed', count), logLevels.INFO)
end

--[[
    global
]]

-- add us to wingtoggler applyModes
applyModes.SET_AFL = {
    name = 'SET_AFL',
    aircraft_load = do_aircraft_load,
    aircraft_unload = do_aircraft_unload,
    apply = do_apply,
}
