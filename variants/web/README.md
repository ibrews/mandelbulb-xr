# Web / WebGL variant

_Planned._ A minimal self-contained HTML page that runs `core/mandelbulb.glsl`
in a WebGL2 canvas (and optionally enters VR via WebXR — works in the Quest
browser). Zero install, embeddable in a page or tweet.

Good first contribution: wrap the core in a full-screen WebGL2 quad with an
orbit camera (mirror the Shadertoy variant's camera + evolution). The Shadertoy
`.glsl` is ~90% of it — it mostly needs the boilerplate WebGL host + a
`requestAnimationFrame` loop feeding `iTime`/`iResolution`/`iMouse`.
