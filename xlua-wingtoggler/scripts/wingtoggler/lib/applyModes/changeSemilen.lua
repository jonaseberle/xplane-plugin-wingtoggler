--[[
    runtime variables
]]

local simDR_acf_semilen_SEG = find_dataref('sim/aircraft/parts/acf_semilen_SEG')
-- local simDR_acf_semilen_JND = find_dataref('sim/aircraft/parts/acf_semilen_JND')
-- local simDR_acf_Croot = find_dataref('sim/aircraft/parts/acf_Croot')
-- local simDR_acf_Ctip = find_dataref('sim/aircraft/parts/acf_Ctip')

-- this gets populated on aircraft_load() with what is defined in Plane Maker
local acf = {
    acf_semilen_SEG = {},
    --     acf_semilen_JND = {},
    --     acf_Croot = {},
    --     acf_Ctip = {},
}

local function detentRatios(activeDetentRatios)
    log(ratios)

    local ratios = {}
    for _, detent_idx in pairs(configuration.detents_idxs) do
        if activeDetentRatios[detent_idx] ~= nil then
            ratios[detent_idx] = activeDetentRatios[detent_idx]
        else
            ratios[detent_idx] = 0.
        end
    end

    return ratios
end

local function segmentRatios(detentRatios)
    local ratios = {}
    for detent_idx, ratio in pairs(detentRatios) do
        wing = configuration.detents[detent_idx]
        for _, segment_idx in pairs(wing.segments) do
            ratios[segment_idx] = ratio
        end
    end

    return ratios
end

local function setSegmentRatios(segmentRatios)
    log(segmentRatios)

    for segment_idx, segmentRatio in pairs(segmentRatios) do
        simDR_acf_semilen_SEG[segment_idx] = acf.acf_semilen_SEG[segment_idx] * segmentRatio
        --         simDR_acf_Croot[segment_idx] = acf.acf_Croot[segment_idx]
        --         simDR_acf_Ctip[segment_idx] = acf.acf_Ctip[segment_idx]
    end
end

local function do_aircraft_load()
    -- save initial values
    for i = 0, simDR_acf_semilen_SEG.len do
         acf.acf_semilen_SEG[i] = simDR_acf_semilen_SEG[i]
    end
    --     log({'SEG', acf.acf_semilen_SEG})

    --     for i = 0, simDR_acf_semilen_JND.len do
    --          acf.acf_semilen_JND[i] = simDR_acf_semilen_JND[i]
    --     end
    --     log({'JND', acf.acf_semilen_JND})

    --     for i = 0, simDR_acf_Croot.len do
    --          acf.acf_Croot[i] = simDR_acf_Croot[i]
    --     end
    --     log({'acf_Croot', acf.acf_Croot})

    --     for i = 0, simDR_acf_Ctip.len do
    --          acf.acf_Ctip[i] = simDR_acf_Ctip[i]
    --     end
    --     log({'acf_Ctip', acf.acf_Ctip})
end

local function do_aircraft_unload()
    -- reset to initial values
    for i = 0, simDR_acf_semilen_SEG.len do
         simDR_acf_semilen_SEG[i] = acf.acf_semilen_SEG[i]
    end

    --     for i = 0, simDR_acf_semilen_JND.len do
    --          simDR_acf_semilen_JND[i] = acf.acf_semilen_JND[i]
    --     end
    --
    --     for i = 0, simDR_acf_Croot.len do
    --          simDR_acf_Croot[i] = acf.acf_Croot[i]
    --     end
    --
    --     for i = 0, simDR_acf_Ctip.len do
    --          simDR_acf_Ctip[i] = acf.acf_Ctip[i]
    --     end
end

local function do_apply(activeDetentRatios)
    setSegmentRatios(
        segmentRatios(
            detentRatios(activeDetentRatios)
        )
    )
end

--[[
    global
]]

-- add us to wingtoggler applyModes
applyModes.CHANGE_SEMILEN = {
    name = 'CHANGE_SEMILEN',
    aircraft_load = do_aircraft_load,
    aircraft_unload = do_aircraft_unload,
    apply = do_apply,
}
