-- Raymarched Mandelbulb — CloudXR AVP streaming stress demo (Agile Lens)
-- Pure Lua + GLSL, no rebuild needed. Bounded volume: the fractal floats in
-- passthrough with the room visible around it. Walk around it.
--
-- The bulb EVOLVES: its power parameter morphs 6.5..9.5 on a ~80s cycle so the
-- shape continuously reshapes, plus a slow ±4% breathing pulse and palette drift.
--
-- QUALITY presets are the GPU benchmark knob (RTX 4090 vs 5090 comparison):
--   1 = safe/light, 2 = 4090-heavy, 3 = 5090 flex
-- Override without editing: set env var FRACTAL_QUALITY before run.bat.
-- Benchmark readout: "render fps | quality" text floats under the bulb in the
-- headset; a "FRACTAL fps=" line also prints to stdout every 5s (unbuffered).

pcall(function() io.stdout:setvbuf('no') end)

local Fractal = {}

local QUALITY = tonumber(os.getenv("FRACTAL_QUALITY") or "") or 2
local PRESETS = {
    [1] = { steps = 96,  iters = 8,  shadow = 0  },
    [2] = { steps = 160, iters = 11, shadow = 32 },
    [3] = { steps = 240, iters = 14, shadow = 64 },
}

local CENTER = { 0.0, 1.5, -2.2 }   -- eye height, 2.2 m in front of spawn
local RADIUS = 0.85                 -- nominal bulb radius (meters)

local shader = nil
local shaderErr = nil
local lastPrint = 0

-- %d slots: MAX_STEPS, ITERS, SHADOW_STEPS
local FRAG_TEMPLATE = [[
uniform float t;
uniform float power;
uniform vec3 bulbCenter;
uniform float bulbRadius;

#define MAX_STEPS %d
#define ITERS %d
#define SHADOW_STEPS %d

mat3 rotY(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c, 0.0, s,  0.0, 1.0, 0.0,  -s, 0.0, c);
}

// Power-N Mandelbulb distance estimator with orbit traps (iq-style).
// power is a uniform -> the fractal continuously reshapes.
float bulbDE(vec3 p, out vec4 trap) {
    vec3 w = p;
    float m = dot(w, w);
    vec4 tr = vec4(abs(w), m);
    float dz = 1.0;
    for (int i = 0; i < ITERS; i++) {
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
    return 0.25 * log(m) * sqrt(m) / dz;
}

// world space -> fractal space: slow spin + breathing pulse, scaled to bulbRadius
float map(vec3 pw, out vec4 trap) {
    float pulse = 1.0 + 0.04 * sin(t * 0.85);           // +/-4%% breath
    float s = 1.2 / (bulbRadius * pulse);
    vec3 p = rotY(t * 0.25) * ((pw - bulbCenter) * s);
    return bulbDE(p, trap) / s;
}

vec3 calcNormal(vec3 p) {
    vec4 tr;
    vec2 e = vec2(1.0, -1.0) * 0.00035;
    return normalize(e.xyy * map(p + e.xyy, tr) + e.yyx * map(p + e.yyx, tr) +
                     e.yxy * map(p + e.yxy, tr) + e.xxx * map(p + e.xxx, tr));
}

float softShadow(vec3 ro, vec3 rd, float k) {
#if SHADOW_STEPS == 0
    return 1.0;
#else
    float res = 1.0;
    float tt = 0.003;
    vec4 tr;
    for (int i = 0; i < SHADOW_STEPS; i++) {
        float h = map(ro + rd * tt, tr);
        res = min(res, k * h / tt);
        tt += clamp(h, 0.0015, 0.05);
        if (res < 0.005 || tt > 1.5) break;
    }
    return clamp(res, 0.0, 1.0);
#endif
}

vec3 palette(float u) {
    return 0.5 + 0.5 * cos(6.28318 * (u + vec3(0.0, 0.33, 0.67)));
}

vec4 lovrmain() {
    vec3 ro = CameraPositionWorld;
    vec3 rd = normalize(PositionWorld - ro);

    // analytic ray vs bounding sphere (6%% margin for the breathing pulse)
    float br = bulbRadius * 1.06;
    vec3 oc = ro - bulbCenter;
    float bq = dot(oc, rd);
    float cq = dot(oc, oc) - br * br;
    float h = bq * bq - cq;
    if (h < 0.0) discard;
    h = sqrt(h);
    float t0 = max(-bq - h, 0.0);
    float t1 = -bq + h;

    float tt = t0;
    vec4 trap = vec4(0.0);
    bool hit = false;
    int steps = 0;
    for (int i = 0; i < MAX_STEPS; i++) {
        float d = map(ro + rd * tt, trap);
        if (d < 0.0002 * max(tt, 0.3)) { hit = true; break; }
        tt += d;
        steps = i;
        if (tt > t1) break;
    }

    float dense = float(steps) / float(MAX_STEPS);
    if (!hit) {
        // soft glow on near-misses, transparent elsewhere (passthrough shows)
        if (dense > 0.4) {
            float g = (dense - 0.4) * 0.6;
            return vec4(palette(0.58 + 0.04 * sin(t * 0.13)) * g, g);
        }
        discard;
    }

    vec3 p = ro + rd * tt;
    vec3 n = calcNormal(p);

    // orbit-trap albedo (classic blue/rust bulb) with slow palette drift
    float drift = 0.5 + 0.5 * sin(t * 0.05);
    vec3 albedo = vec3(0.02);
    albedo = mix(albedo, mix(vec3(0.10, 0.20, 0.30), vec3(0.25, 0.10, 0.30), drift),
                 clamp(trap.y, 0.0, 1.0));
    albedo = mix(albedo, vec3(0.02, 0.10, 0.30), clamp(trap.z * trap.z, 0.0, 1.0));
    albedo = mix(albedo, mix(vec3(0.30, 0.10, 0.02), vec3(0.05, 0.30, 0.15), drift),
                 clamp(pow(trap.w, 6.0), 0.0, 1.0));
    albedo *= 0.5;

    vec3 lightDir = normalize(vec3(0.6, 0.9, 0.4));
    float dif = clamp(dot(n, lightDir), 0.0, 1.0);
    float sha = softShadow(p + n * 0.002, lightDir, 24.0);
    float amb = (0.5 + 0.5 * n.y) * (1.0 - dense * 0.7);
    vec3 hal = normalize(lightDir - rd);
    float spe = pow(clamp(dot(n, hal), 0.0, 1.0), 32.0) * dif * sha;
    float rim = pow(1.0 - clamp(dot(n, -rd), 0.0, 1.0), 3.0);

    vec3 col = albedo * (0.5 * amb + 1.8 * dif * sha * vec3(1.0, 0.95, 0.85));
    col += 0.7 * spe * vec3(1.0);
    col += rim * 0.12 * palette(0.6 + 0.04 * sin(t * 0.13));
    col = 1.0 - exp(-2.2 * col);   // soft filmic-ish rolloff, stays in linear

    return vec4(col, 1.0);
}
]]

local function ensureShader()
    if shader or shaderErr then return shader end
    local p = PRESETS[QUALITY] or PRESETS[2]
    local src = string.format(FRAG_TEMPLATE, p.steps, p.iters, p.shadow)
    local ok, result = pcall(lovr.graphics.newShader, 'unlit', src)
    if ok then
        shader = result
        print(string.format("FRACTAL shader compiled (quality %d: steps=%d iters=%d shadow=%d)",
            QUALITY, p.steps, p.iters, p.shadow))
    else
        shaderErr = tostring(result)
        print("FRACTAL SHADER COMPILE FAILED: " .. shaderErr)
    end
    return shader
end

function Fractal.draw(pass)
    local t = lovr.timer.getTime()
    local s = ensureShader()

    if not s then
        -- fallback: keep the proven spinning cube so the stream still shows content
        pass:setColor(1, 0.4, 0, 1)
        local mat = lovr.math.mat4()
        mat:translate(CENTER[1], CENTER[2], CENTER[3])
        mat:rotate(t, 0, 1, 0)
        mat:scale(0.4)
        pass:cube(mat)
        pass:setColor(1, 1, 1, 1)
        return
    end

    -- Continuous "living" evolution: two incommensurate sines so power wanders
    -- organically and never obviously ping-pongs. Set FRACTAL_EVOLVE=pingpong
    -- for the original single-sine sweep. See ../../core/PARAMETERS.md.
    local power
    if os.getenv("FRACTAL_EVOLVE") == "pingpong" then
        power = 8.0 + 1.8 * math.sin(t * 0.3)
    else
        power = 7.5 + 1.4 * math.sin(t * 0.11) + 0.9 * math.sin(t * 0.063 + 1.7)
    end

    pass:setShader(s)
    pass:send('t', t)
    pass:send('power', power)
    pass:send('bulbCenter', CENTER)
    pass:send('bulbRadius', RADIUS)
    -- draw back faces of a box around the volume so it renders even when you
    -- step inside; the shader does its own analytic sphere bound + discard
    pass:setCullMode('front')
    local d = RADIUS * 2.2
    pass:box(CENTER[1], CENTER[2], CENTER[3], d, d, d)
    pass:setCullMode('none')
    pass:setShader()

    -- fps readout: in-headset + stdout every 5s (remote monitoring / benchmarking)
    local fps = lovr.timer.getFPS()
    pass:setColor(1, 1, 1, 1)
    pass:text(string.format("render fps: %d  |  quality %d  |  power %.1f", fps, QUALITY, power),
        0, CENTER[2] - RADIUS - 0.25, CENTER[3] + 0.4, 0.1)
    if t - lastPrint > 5 then
        lastPrint = t
        print(string.format("FRACTAL fps=%d quality=%d power=%.2f", fps, QUALITY, power))
    end
end

return Fractal
