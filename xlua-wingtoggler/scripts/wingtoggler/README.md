# X-Plane plugin wingtoggler manual

This is an X-Plane XLua plane plugin.

It was born from the limitation of the flight model allowing only rather simple flap effects on a wing.
The flight model currently only allows to set one coefficient of lift, drag
and moment for each of the two possible flap systems and they somehow get applied to the airfoil numbers.

It means that all flap regimes have to be dependant on the "base" airfoil.

That seems to only cater well to wings where the relations of these coefficiants are fairly constant (or not cared
about too much) over all flap deflection angles. That's basically the case if the flaps only move downwards for approach
and landing where the pilot is happy if the stall speed gets lower somehow and some drag is added but if nobody cares
much about the exact performance numbers. As far as I know, reducing drag is not possible at all.

It is hard to use that system for flapped wings with negative and positive useful flap positions
and also when it is really cared about wing the performance of each of these positions, not just the 0° case.

Flapped gliders
naturally make much more use of flaps during a flight, adjusting them permanently to their speed or
even g-load factor (when entering and leaving lift, dolphin style).
To be fair there are also some motor planes making use of negative flaps. It's just that they
usually don't rely on good performance over a bigger speed range but just the data points cruise and takeoff/landing.

It has been tried to find compromises but the possibilities are limited and it is hard to match the outcome to reality.

The approach of this plugin is to apply the properties of Plane Maker wing segments specifically designed for
that flap deflection.

It works in two steps:

1. Calculating how "active" (in %) each configured wing segment is. That can either
   * be linearly interpolated between configured flap deflections or
   * it can "snap" to the closest configured flap deflection.

2. Applying the percentages: That can be either
   * by adjusting the geometry (Plane Maker "semilen") of that segment (switching it "OFF" when the percentage is 0%) or
   * by using the airfoil configuration from another wing segment (possibly mixing between multiple airfoils by percentages).


## Installation

Copy the `xlua-wingtoggler/` folder into your `<Aircraft>/plugins/` folder.

That includes an XLua release that this has been tested with.




## Configuration

The configuration file [config/wingtoggler-config.lua](config/wingtoggler-config.lua) is executed and should call
the method `configure(<configuration>)` if the current plane shall use this plugin.

You can use the convenience function `acfFileName()` in that file to check for the currently loaded .acf.

Example:
```Lua
if acfFileName() == 'Pik-20D.acf' then
    configure(<configuration>)
end
```

### `<configuration>` looks like this:

```Lua
{
    source = {
        mode = sourceModes.INTERPOLATE, -- or sourceModes.SWITCH
        dataRef {
            name = 'sim/cockpit2/controls/flap_system_deploy_ratio',
            min = 0.0,
            max = 1.0,
        }
    },
    apply = {
        mode = applyModes.CHANGE_SEMILEN,  -- or applyModes.SET_AFL
        SET_AFL_settings = {  -- only needed for applyModes.SET_AFL
            targetSegments = {8, 9, 10, 11},
        }
    }
    detents = {
        [0.0] = {
            name = 'Flaps negative, think positive',
            segments = {8, 9, 10, 11},
        },
        [1.0] = {
            name = 'Flaps neutral',
            segments = {20, 21, 22, 23},
        },
    }
}

```

#### source.mode
This controls how we transition from one configuration part to another:
mode can be either of the following:

##### `sourceModes.INTERPOLATE`
"Detents" (see below) are linearly interpolated between configured flap deflections.

That means a) that you do not have to create that many wing variants,
b) that changes in the flightmodel are smooth while flaps are transiting and
c) that the pilot can choose intermediate flap positions between detents.


##### `sourceModes.SWITCH`
It "snaps" to the closest configured "detent" (see below).

That means that you need a configured wing variant for each flap position you want to model.


#### source.dataRef.name
This is the input DataRef. Its value is what drives the "detents" below.
We assume that this is the flaps deflection, but it could be something else that profits from switchable
"wings", for example a "flying in the rain" DataRef.

#### source.dataRef.min, source.dataRef.max
Set the range that this DataRef can have.

#### apply.mode
This controls how we apply the active detent(s) to X-Plane.

applyMode can be either of the follwing:

##### applyModes.CHANGE_SEMILEN
We change the length (semilen) of each wing segment. With semilen=0 a wing is aerodynamically not active for X-Plane.

The idea was to splice together a wing dynamically from multiple segments so that the parts are interweaving when we
are INTERPOLATEing. We could adjust chords so that we basically have a perfect wing, just with different
airfoils interweaving.

That is Currently not possible because I have not found a DataRef to change lat/long/vert of a wing segment.

Current state: This works well with `sourceModes.SWITCH`.

##### applyModes.SET_AFL
We copy the airfoil of the active wing(s) from the "detents" to the target.

On aircraft load, we will first use CHANGE_SEMILEN to deactivate all wings that are used in `detents`.`...`.`segments`.

Then we take the airfoil data from `detents`.`...`.`segments`, possibly interpolate between detents it if we are in `sourceModes.INTERPOLATE`
and apply it to the target wings.

Configuration: Set `SET_AFL_settings` (see below).

Limitations: The wings we work on as sources or targets needs to
* only have 1 Re number in the airfoil
* not use the tip airfoil (only root/mid are possible)

These limitations come from what is exposed in the DataRefs.

Current state: If you are fine with the limitations, this seems to work well with `sourceModes.SWITCH` and `sourceModes.INTERPOLATE`.

#### apply.SET_AFL_settings.targetSegments: {}
Add this when using `applyModes.SET_AFL`: It defines which wings' airfoils get changed.
The order is important: The first one in here is set from the first one in `detents`.`<sourceValue>`.`segments` and so on.

#### detents: { sourceValue => detent }

These are the configurations by input value: If the source DataRef has this value, this configuration will
be active. In animation terms these are "key frames".
The values do not have to be exact flap handle positions.
In `sourceModes.INTERPOLATE` intermediate positions will linearly be assigned with a weight, in `sourceModes.SWITCH` only the closest position
will be active.
The current state is written to Log.txt with log level NOTICE and higher (see "Debugging" below).

#### detents.<sourceValue>.name
Give it a name. It is used in the log output.

#### detents.<sourceValue>.segments: {}
This is a list of X-Plane wing segments IDs (usually at least 2 for left and right wing) that will be
active when this configuration is active.
See the table below for Plane Maker -> X-Plane segment ID.



### Known X-Plane wing segment IDs

```
8 = Wing 1 R
9 = Wing 1 L (the second side of Wings 1-4 are added by X-Plane as a mirror of the first side)
..
14 = Wing 4 R
15 = Wing 4 L

16 = Horiz. Stab R
17 = Horiz. Stab L

18 = Vert Stab 1
19 = Vert Stab 2

20 = Misc Wing 1 (use as R)
21 = Misc Wing 2 (use as L)
..
..
55 = Misc Wing 36
```

## Debugging

By default the X-Plane log contains a message when the plugin has loaded its configuration and
when a new state has been activated (with some debouncing - so when you move the flap handle only
the value when you stop moving is logged). That is log level 5 (NOTICE).

You can increase the log level to 6 (INFO some more output) or 7 (DEBUG) or 8 (EXTREME) by

* changing the DataRef `wingtoggler/logLevel`
* starting X-Plane with the environment variable `WINGTOGGLER_LOGLEVEL`, for example with `WINGTOGGLER_LOGLEVEL=7 ./X-Plane-x86_64`

## Get in touch

Code, issues, pull requests regarding this plugin: https://github.com/jonaseberle/xplane-plugin-wingtoggler

"Glider flaps" discussion: https://forums.x-plane.org/index.php?/forums/topic/187969-glider-flaps/

Personal: https://forums.x-plane.org/index.php?/profile/68881-flightwusel/

*"Think positive, flaps negative"*
