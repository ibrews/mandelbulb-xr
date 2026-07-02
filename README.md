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
