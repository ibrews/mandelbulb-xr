# OpenXR / D3D11 variant — PCVR + CloudXR streaming

An HLSL/Direct3D 11 port of the core, running as a standard **OpenXR** content
app. Because it's plain OpenXR, it routes to whatever OpenXR runtime is active —
SteamVR / WMR / Oculus on a PC headset, **or** NVIDIA CloudXR to stream it to an
**Apple Vision Pro** (that's what it was built for).

## Where the code lives
This variant grew out of the CloudXR Foveated-Streaming work and currently lives
in a separate repo (it carries CloudXR host/deploy scaffolding that doesn't belong
in this cross-platform repo):

- **`StreamingSession-OpenXRSample/main.cpp`** — the HLSL shader (a line-for-line
  port of `core/mandelbulb.glsl`) + the OpenXR render loop.
- Env-var knobs mirror the others: `FRACTAL_MIXED` (passthrough vs opaque),
  `FRACTAL_EVOLVE`, `FRACTAL_SPEED`, `FRACTAL_SPIN`, `FRACTAL_POS`, `FRACTAL_SCALE`,
  `FRACTAL_QUALITY`, `FRACTAL_DEBUG`.
- Includes a standalone `shader_test.cpp` that compiles the HLSL with the app's
  exact flags (no GPU/headset needed) — handy when porting the shader.

## Making it standalone (to add here properly)
The OpenXR core is portable; the only things tying the current app to CloudXR are
thin: the optional `XR_NVX1_opaque_data_channel` extension (already gated on
availability) and the default `ALPHA_BLEND` environment blend mode (set
`FRACTAL_MIXED=0` for the `OPAQUE` mode desktop runtimes expect). Stripping those
two + the CloudXR deploy scaffolding yields a clean SteamVR/WMR/Oculus sample —
a good "good first PR."

> Mixed-mode passthrough (the fractal floating in your real room) needs the
> `XR_COMPOSITION_LAYER_BLEND_TEXTURE_SOURCE_ALPHA_BIT` projection-layer flag +
> premultiplied alpha + a `(0,0,0,0)` clear — see the source. That's specific to
> passthrough-capable runtimes (CloudXR/AVP), not classic PCVR.
