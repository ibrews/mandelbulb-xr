# How it works

A short tour of the pieces, so you can port or remix it.

## 1. The Mandelbulb
The Mandelbulb is the 3D cousin of the Mandelbrot set. You iterate
`w → w^power + p` where the "power" operation is done in spherical coordinates:
convert `w` to `(r, θ, φ)`, raise `r` to the power and multiply the angles by it,
convert back, add the original point `p`. Points that stay bounded are "inside."

## 2. Distance estimation (why it's fast)
We don't test every point — we **raymarch** with a *distance estimator* (DE): a
function that returns a safe lower bound on the distance to the surface, so each
step jumps as far as possible. The classic Koebe/derivative estimate
`0.25 * log(m) * sqrt(m) / dz` (where `m` is the escaped magnitude and `dz` the
running derivative) is what makes real-time Mandelbulbs possible. See `mb_de()`.

## 3. Orbit-trap coloring
While iterating, we track the closest the orbit ever comes to a set of features
(`min(tr, ...)`). Those trap values become the albedo — that's where the
blue/rust banding comes from. Cheap, and it ties color to the fractal's internal
structure instead of just its surface. See the `trap` out-param and `mb_shade()`.

## 4. The "living" evolution
`power` is animated. A single sine makes it sweep up and down — a visible
**ping-pong**. Instead we sum two sines at incommensurate frequencies, so the
value is **quasi-periodic**: it wanders the range and never lines up to repeat or
cleanly reverse. The result reads as continuous, organic morphing. See
`mb_power(t, speed)`. (More incommensurate terms → even less repetition.)

## 5. Shading
Standard raymarch shading: gradient normal (4 DE taps), a key light with soft
shadows (a second, cheaper march toward the light), ambient from the up-facing
normal, a specular highlight, a Fresnel rim, then a filmic-ish `1 - exp(-k*c)`
rolloff and gamma. Nothing fractal-specific — swap in your own lighting freely.

## 6. Bounding + performance
The bulb lives inside a unit-ish sphere, so we intersect the camera ray with a
bounding sphere first and only march the segment that's inside it — the rest of
the screen costs nothing. Tune `MB_MAX_STEPS` / `MB_ITERS` / `MB_SHADOW_STEPS`
for your GPU (see `PARAMETERS.md`).

## Credits
Distance-estimator + orbit-trap approach follows Inigo Quilez's Mandelbulb work
(iquilezles.org). This repo's contribution is the portable core + the
quasi-periodic "living" evolution + the XR/streaming variants.
