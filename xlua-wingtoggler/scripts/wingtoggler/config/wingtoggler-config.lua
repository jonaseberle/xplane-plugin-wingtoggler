--[[
    This is the per-plane configuration for wingtoggler.

    See README.md for an annotated example.
]]

if acfFileName() == 'Pik-20D.acf' then
    configure(
        {
            source = {
                mode = sourceModes.INTERPOLATE,
                dataRef = {
                    name = 'sim/cockpit2/controls/flap_system_deploy_ratio',
                    min = 0.0,
                    max = 1.0,
                }
            },
            apply = {
                mode = applyModes.SET_AFL,
                SET_AFL_settings = {
                    targetSegments = {8, 9, 10, 11},
                }
            },
            detents = {
                [0.0] = {
                    name = 'Flaps neg. ',
                    segments = {8, 9, 10, 11},
                },
                [1.0] = {
                    name = 'Flaps neut.',
                    segments = {20, 21, 22, 23},
                },
                -- These are all flap positions
--                 [0.0] = {
--                     name = 'Flaps -12',
--                     egments = {8, 9},
--                 },
--                 [0.167] = {
--                     -- this detent is currently between -8 and -4
--                     name = 'Flaps -4/-8',
--                     segments = {20, 21},
--                 },
--                 [0.333] = {
--                     name = 'Flaps 0',
--                     segments = {22, 23},
--                 },
--                 [0.5] = {
--                     name = 'Flaps 4',
--                     segments = {24, 25},
--                 },
--                 [0.667] = {
--                     name = 'Flaps 8',
--                     segments = {26, 27},
--                 },
--                 [0.833] = {
--                     name = 'Flaps 12',
--                     segments = {28, 29},
--                 },
--                 [1.0] = {
--                     name = 'Flaps 16',
--                     segments = {30, 31},
--                 },
            }
        }
    )
end
