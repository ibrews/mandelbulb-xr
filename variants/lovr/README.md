# LOVR variant — cross-platform VR

[LÖVR](https://lovr.org) runs the same fractal as an immersive VR scene on
Windows, macOS, Linux, and Quest standalone (it's OpenXR under the hood), from
one small Lua + GLSL file — no rebuild, LÖVR loads Lua from source.

`fractal.lua` is a self-contained LÖVR module: a raymarched Mandelbulb floating
at eye height that you can walk around, with the continuous "living" evolution.

## Run it
1. Install LÖVR (lovr.org) — or use the NVIDIA CloudXR LÖVR sample checkout.
2. Drop `fractal.lua` next to your `main.lua` and, in `main.lua`:
   ```lua
   local Fractal = require('fractal')   -- near your other requires
   -- ...and inside lovr.draw(pass):
   Fractal.draw(pass)
   ```
3. `lovr .` (or your project's run script) with a headset connected.

## Knobs (env vars, read at launch)
- `FRACTAL_QUALITY=1|2|3` — GPU load (steps/iters/shadow).
- `FRACTAL_EVOLVE=pingpong` — original single-sine sweep instead of continuous.

The GLSL shader is inlined in `fractal.lua`; it mirrors `../../core/mandelbulb.glsl`.
