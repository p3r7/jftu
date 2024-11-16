-- fjtu.
-- @eigen

-- https://www.youtube.com/watch?v=HKndhxGO_pI
-- https://github.com/whimsicalraps/Just-Friends/blob/main/Just-Type.md
-- https://synthmodes.com/modules/just_friends/

-- jf in plume mode (sound/sustain/run)
-- randomize RUN value (to modulate lpg)


-- ------------------------------------------------------------------------
-- deps

local ControlSpec = require "controlspec"
local lattice = require 'lattice'


-- ------------------------------------------------------------------------
-- consts

VOICES = 6

SCREEN_W = 128
SCREEN_H = 64

OFF_RECT_W     = 4
ON_RECT_W      = 8
TRIGGED_RECT_W = 10

local TRIG_TICK = 1/16
-- local RUN_UPDATE_TICK = 0.01
local RUN_UPDATE_TICK = 0.1


-- ------------------------------------------------------------------------
-- state

local s_lattice

local patterns = {}
local triggered = {}
local active = {}

local counter = 1


-- ------------------------------------------------------------------------

function pulse_off(i, delay)
  clock.sleep(delay)
  crow.ii.jf.trigger(i, 0)
  active[i] = false
  redraw()
end

function advance_patterns()
  for i, steps in ipairs(patterns) do
    local step_index = util.wrap(counter, 1, #steps)
    local step_value = steps[step_index]

    if step_value == 1 and math.random(1, 10) > 7 then
      step_value = 0
    end

    crow.ii.jf.trigger(i, step_value)
    triggered[i] = (step_value == 1)
    active[i]    = triggered[i]

    if triggered[i]  then
      clock.run(pulse_off, i, params:get("pulse_length") * clock.get_beat_sec())
    end
  end

  redraw()

  counter = counter + 1
end

function randomize_patterns()
  for i=1,VOICES do
    local length = math.random(4, 16)
    local steps = {}
    local chance = math.random(1, 10)
    for j = 1, length do
      steps[j] = math.random(0, chance) == 0 and 1 or 0
    end
    patterns[i] = steps
  end
end

function init()
  screen.aa(0)
  crow.ii.jf.run_mode(1)

  randomize_patterns()
  for i=1,VOICES do
    triggered[i] = false
    active[i] = false
  end

  params:add_separator("jftu_main", "jftu")

  params:add { type = "control", id = "pulse_length", name = "pulse length",
               controlspec = controlspec.new(0.01, 1, 'lin', 0.01, 0.1, "") }
  params:add{ type = "control", id = "run_min_v", name = "RUN min",
              controlspec = controlspec.new(-5, 0, "lin", 0, 0, "") }
  params:add{ type = "control", id = "run_max_v", name = "RUN max",
              controlspec = controlspec.new(0, 5, "lin", 0, 5, "") }

  s_lattice = lattice:new{}

  local sprocket = s_lattice:new_sprocket{
    action = advance_patterns,
    division = TRIG_TICK,
    enabled = true
  }
  s_lattice:start()

  clock.run(advance_patterns)

  -- update run jack value
  clock.run(function()
      while true do
        clock.sleep(RUN_UPDATE_TICK)
        local run_volts = math.random( util.round(params:get("run_min_v") * 100),
                                       util.round(params:get("run_max_v") * 100)) / 100
        -- print(run_volts)
        crow.ii.jf.run(run_volts)
      end
  end)
end

function cleanup()
  crow.ii.jf.run_mode(0)
end

function redraw()
  screen.clear()

  screen.level(15)
  for i=1,VOICES do
    local x = i * SCREEN_W/VOICES - (SCREEN_W/VOICES)/2
    local y = SCREEN_H/2

    local w = 0

    if active[i] then
      w = ON_RECT_W
    elseif triggered[i] then
      w = TRIGGED_RECT_W
    else
      w = OFF_RECT_W
    end

    screen.rect(x - w/2, y - w/2,
                w, w)
    screen.fill()
  end

  screen.update()
end


-- ------------------------------------------------------------------------
-- controls

local k1 = false
local k2 = false
local k3 = false

function key(n, v)
  if n == 1 then
    k1 = (v == 1)
  end

  if n == 2 then
    k2 = (v == 1)
  end

  if n == 3 then
    k3 = (v == 1)
  end

  if k1 and k3 then
    randomize_patterns()
  end

end

function enc(n, d)
  if n == 1 then
    params:set("clock_tempo", params:get("clock_tempo") + d)
  end
end
