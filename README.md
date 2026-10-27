# mandelbulb-xr

A **living Mandelbulb** — a continuously-evolving raymarched 3D fractal. One
portable GLSL core, with variants from a paste-into-Shadertoy snippet all the way
to VR streamed onto an Apple Vision Pro.

The "power" parameter doesn't ping-pong on a single sine like most animated
Mandelbulbs — it **wanders quasi-periodically** (two incommensurate sines), so the
shape morphs organically and never obviously reverses or repeats.

> _(Add a GIF/screenshot here — capture the live demo below.)_

## ▶ Try it live (no install)
**[ibrews.github.io/mandelbulb-xr](https://ibrews.github.io/mandelbulb-xr/)** — runs
in your browser, drag to orbit. Works on desktop and mobile (WebGL2).

Or paste [`variants/shadertoy/mandelbulb.glsl`](variants/shadertoy/mandelbulb.glsl)
into [shadertoy.com/new](https://www.shadertoy.com/new) and hit ▶.

## Things to Try

1. **Open the [live demo](https://ibrews.github.io/mandelbulb-xr/) — or `index.html` straight from the checkout — and drag across the canvas** — the bulb stops auto-orbiting and follows your drag; the "drag to orbit" hint sits at the top of the page.
2. **Leave it alone for a minute** — the lobes keep morphing and never visibly reverse: `power` is the sum of two incommensurate sines (the `float power=` line in `index.html`), not a single ping-pong.
3. **Paste [`variants/shadertoy/mandelbulb.glsl`](variants/shadertoy/mandelbulb.glsl) into [shadertoy.com/new](https://www.shadertoy.com/new) and press ▶** — same fractal; hold the mouse button and move it to steer the yaw (`iMouse.z > 0.5` in `mainImage`).
4. **Edit `index.html`: change `#define ITERS 10` to `4` and reload** — detail drops, because `ITERS` is the distance-estimator iteration count; raise `#define MAX_STEPS 150` instead to clean up holes on grazing rays. [`core/PARAMETERS.md`](core/PARAMETERS.md) explains every knob.
5. **Run the LÖVR variant in a headset with `FRACTAL_QUALITY=3`** — follow [`variants/lovr/README.md`](variants/lovr/README.md) to drop `fractal.lua` next to a `main.lua`; the env var is read at launch (`os.getenv("FRACTAL_QUALITY")`, default `2`), so quality 3 costs visibly more GPU.

## Variants
| Variant | Runs on | Reach |
|---|---|---|
| [**Shadertoy**](variants/shadertoy/) | any browser, paste-and-go | widest — zero install |
| [**Web / WebGL**](variants/web/) | any browser (+ WebXR headsets) | zero install, embeddable |
| [**LÖVR**](variants/lovr/) | Windows / macOS / Linux / Quest standalone | a real VR scene you walk around |
| [**OpenXR / D3D11**](variants/openxr-d3d11/) | SteamVR / WMR / Oculus PC, or CloudXR → Apple Vision Pro | PCVR + streaming |

All share one algorithm and one set of knobs:
- [`core/mandelbulb.glsl`](core/mandelbulb.glsl) — the canonical implementation
- [`core/PARAMETERS.md`](core/PARAMETERS.md) — every knob and what it does
- [`core/ALGORITHM.md`](core/ALGORITHM.md) — how the fractal + evolution work

## Structure
```
core/        the shared GLSL + docs (fork this to add a platform)
variants/    thin per-platform wrappers around the core
```
GLSL is the common denominator (Shadertoy, WebGL, and LÖVR use it directly); the
D3D11 variant is a line-for-line HLSL port. To add a platform, wire your camera
(`ro`/`rd`) and a `main()` around `core/mandelbulb.glsl`.

## License
MIT — see [LICENSE](LICENSE). Distance-estimator + orbit-trap technique follows
[Inigo Quilez](https://iquilezles.org)'s Mandelbulb work; this repo adds the
portable core, the quasi-periodic "living" evolution, and the XR/streaming variants.

## Support

If you like seeing this kind of thing get built and shared, [donations are always welcome](https://www.alexcoulombepresents.com/support) — they buy hardware, render time, and the freedom to keep giving most of this away.

## Credits

Built by **Alex Coulombe Presents** ([ibrews](https://github.com/ibrews)). House style: [acp-style-guide](https://github.com/ibrews/acp-style-guide).
