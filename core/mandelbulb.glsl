// mandelbulb-xr — canonical core (GLSL).
//
// This is the reference implementation the variants derive from: distance
// estimator, raymarch, normals, soft shadow, orbit-trap palette, and the
// continuous "living" evolution. It's platform-agnostic — each variant supplies
// the camera (ro/rd) and a wrapper main(). Shadertoy/WebGL/LOVR use this GLSL
// directly; the D3D11/OpenXR variant is a line-for-line HLSL port.
//
// Parameters (see core/PARAMETERS.md) are passed in, not hardcoded, so a host
// can drive them from uniforms / env vars / UI.
// MIT licensed.  github.com/ibrews/mandelbulb-xr

#define MB_ITERS       11    // distance-estimator iterations (fractal detail)
#define MB_MAX_STEPS   160   // raymarch steps
#define MB_SHADOW_STEPS 24   // soft-shadow samples (0 disables)

// Power-N Mandelbulb distance estimator with orbit traps (iq-style).
// `trap` returns the closest-approach orbit trap, used for coloring.
float mb_de(vec3 p, float power, out vec4 trap) {
    vec3 w = p;
    float m = dot(w, w);
    vec4 tr = vec4(abs(w), m);
    float dz = 1.0;
    for (int i = 0; i < MB_ITERS; i++) {
        dz = power * pow(m, (power - 1.0) * 0.5) * dz + 1.0;
        float r = length(w);
        float b = power * acos(clamp(w.y / max(r, 1e-6), -1.0, 1.0));
        float a = power * atan(w.x, w.z);
        w = p + pow(r, power) * vec3(sin(b) * sin(a), cos(b), sin(b) * cos(a));
        tr = min(tr, vec4(abs(w), m));
        m = dot(w, w);
        if (m > 256.0) break;
    }
    trap = tr;
    return 0.25 * log(m) * sqrt(m) / dz;   // Koebe / DE estimate
}

// The "living" power: two incommensurate sines → the shape morphs organically
// and never obviously reverses or repeats (vs. a single sine that ping-pongs).
// `t` is time in seconds, `speed` a rate multiplier.
float mb_power(float t, float speed) {
    float e = t * speed;
    return 7.5 + 1.4 * sin(e * 0.11) + 0.9 * sin(e * 0.063 + 1.7);
}

vec3 mb_calcNormal(vec3 p, float power) {
    vec4 tr; vec2 e = vec2(1.0, -1.0) * 0.0007;
    return normalize(
        e.xyy * mb_de(p + e.xyy, power, tr) + e.yyx * mb_de(p + e.yyx, power, tr) +
        e.yxy * mb_de(p + e.yxy, power, tr) + e.xxx * mb_de(p + e.xxx, power, tr));
}

float mb_softShadow(vec3 ro, vec3 rd, float power) {
#if MB_SHADOW_STEPS == 0
    return 1.0;
#else
    float res = 1.0, t = 0.02; vec4 tr;
    for (int i = 0; i < MB_SHADOW_STEPS; i++) {
        float h = mb_de(ro + rd * t, power, tr);
        res = min(res, 12.0 * h / t);
        t += clamp(h, 0.01, 0.25);
        if (res < 0.004 || t > 6.0) break;
    }
    return clamp(res, 0.0, 1.0);
#endif
}

vec3 mb_palette(float u) {
    return 0.5 + 0.5 * cos(6.28318 * (u + vec3(0.0, 0.33, 0.67)));
}

// Full shade for a hit point, using the orbit trap for albedo. `t` = time (for
// slow palette drift), `rd` = view ray.
vec3 mb_shade(vec3 p, vec3 n, vec4 trap, vec3 rd, float t) {
    float drift = 0.5 + 0.5 * sin(t * 0.05);
    vec3 albedo = vec3(0.02);
    albedo = mix(albedo, mix(vec3(0.10, 0.20, 0.30), vec3(0.25, 0.10, 0.30), drift), clamp(trap.y, 0.0, 1.0));
    albedo = mix(albedo, vec3(0.02, 0.10, 0.30), clamp(trap.z * trap.z, 0.0, 1.0));
    albedo = mix(albedo, mix(vec3(0.30, 0.10, 0.02), vec3(0.05, 0.30, 0.15), drift), clamp(pow(trap.w, 6.0), 0.0, 1.0));
    vec3 lightDir = normalize(vec3(0.6, 0.9, 0.4));
    float dif = clamp(dot(n, lightDir), 0.0, 1.0);
    float sha = mb_softShadow(p + n * 0.01, lightDir, /*power*/ 8.0);
    float amb = 0.5 + 0.5 * n.y;
    vec3 hal = normalize(lightDir - rd);
    float spe = pow(clamp(dot(n, hal), 0.0, 1.0), 32.0) * dif * sha;
    float rim = pow(1.0 - clamp(dot(n, -rd), 0.0, 1.0), 3.0);
    vec3 col = albedo * (0.5 * amb + 1.9 * dif * sha * vec3(1.0, 0.95, 0.85));
    col += 0.7 * spe;
    col += rim * 0.15 * mb_palette(0.6 + 0.04 * sin(t * 0.13));
    return 1.0 - exp(-2.2 * col); // filmic-ish rolloff
}
