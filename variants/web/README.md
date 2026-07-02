# Web / WebGL variant

**Live: [ibrews.github.io/mandelbulb-xr](https://ibrews.github.io/mandelbulb-xr/)**

A self-contained WebGL2 page that runs the fractal in any modern browser (desktop
or mobile) — drag to orbit. The source is [`../../index.html`](../../index.html) at
the repo root (root so GitHub Pages serves it as the site's front door).

It's a single file: a full-screen fragment shader (the same raymarch as
`core/mandelbulb.glsl`, adapted to GLSL ES 3.00), a tiny WebGL2 host, and a
`requestAnimationFrame` loop feeding `u_time` / `u_resolution` / `u_mouse`. No
build step, no dependencies.

Next: a WebXR "Enter VR" button (works in the Quest browser) — the render loop is
already there; it needs an `XRSession` + per-eye view matrices driving the camera.
