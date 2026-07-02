# Parameters

Every variant exposes the same conceptual knobs (as `#define`s, uniforms, env
vars, or UI — depending on the platform). Names differ per host; the meanings don't.

| Concept | Typical default | What it does |
|---|---|---|
| **power** | wanders ~5.2–9.8 | The Mandelbulb exponent — the single most dramatic shape control. Low (≈2) is blobby; high (≈8+) grows the classic bulbous lobes. Driven by `mb_power(t, speed)` for the living evolution. |
| **evolve** | `continuous` | `continuous` = power via two incommensurate sines (organic, never obviously reverses). `pingpong` = a single sine sweep (visibly back-and-forth). |
| **speed** | `1.0` | Evolution rate multiplier — how fast the shape morphs. |
| **spin** | `1.0` | Rotation/orbit rate (`0` = frozen, negative = reverse). |
| **iters** (`MB_ITERS`) | `11` | Distance-estimator iterations = fractal detail. More = crisper filigree, more cost. |
| **steps** (`MB_MAX_STEPS`) | `160` | Raymarch steps. More = fewer holes/artifacts on grazing rays, more cost. |
| **shadow** (`MB_SHADOW_STEPS`) | `24` | Soft-shadow samples. `0` disables (cheap, flatter). |
| **quality preset** | `2` | Convenience bundle of {steps, iters, shadow}: `1`=light, `2`=medium, `3`=heavy. |
| **palette** | orbit-trap | Coloring comes from the closest-approach orbit trap; `mb_palette()` is a cosine palette you can retune. |
| **pos / scale** | scene-dependent | Where the bulb sits and how big (VR variants place it in the room; Shadertoy centers it at the origin and orbits the camera). |

## The evolution, specifically
A single `sin` makes `power` sweep up then back down — visibly a **ping-pong**.
Summing two sines whose frequencies are an irrational-ish ratio (here `0.11` and
`0.063`) makes `power` **quasi-periodic**: it wanders through the range and the
combined motion never lines up to repeat or cleanly reverse, so it reads as
continuous, organic evolution. Add a third incommensurate term for even less
repetition.
