#include "HBVehicleCore.h"

/* This is an intentionally small, deterministic 2D arcade vehicle controller.
 * It is NOT a PhysX replacement, a suspension solver or an Unreal native package.
 * It has no heap, threads, callbacks, I/O or OS dependencies.
 */
/* _fltused omitted — bridge links MSVC CRT */

static float hb_abs(float v) { return v < 0.0f ? -v : v; }
static float hb_clamp(float v, float lo, float hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}
static float hb_approach(float from, float to, float step) {
    return from < to ? (from + step < to ? from + step : to) :
           (from - step > to ? from - step : to);
}
static int hb_valid(float n) { return n == n && n < 10000000.0f && n > -10000000.0f; }
static float hb_sqrt(float n) {
    /* Newton iteration avoids an external CRT sqrtf dependency on 32-bit. */
    float x = n > 1.0f ? n : 1.0f;
    int i;
    for (i = 0; i < 9; ++i) x = 0.5f * (x + n/x);
    return x;
}

unsigned int HBV_GetAPIVersion(void) { return HBV_API_VERSION; }

int HBV_DefaultConfig(HBV_Config *p) {
    if (!p) return 0;
    p->wheelbase_m = 2.6f;
    p->wheel_radius_m = 0.34f;
    p->max_steer_rad = 0.49f;
    p->max_forward_mps = 25.0f;
    p->max_reverse_mps = 9.0f;
    p->engine_accel_mps2 = 6.0f;
    p->brake_decel_mps2 = 12.0f;
    p->coast_decel_mps2 = 0.55f;
    p->aero_drag_factor = 0.003f;
    p->steer_response_per_s = 3.8f;
    p->yaw_response_per_s = 7.0f;
    p->lateral_damping_per_s = 6.0f;
    return 1;
}

int HBV_Reset(HBV_State *s) {
    int i;
    if (!s) return 0;
    s->pos_x_m = 0; s->pos_y_m = 0;
    s->forward_x = 1; s->forward_y = 0;
    s->speed_mps = 0; s->lateral_speed_mps = 0;
    s->yaw_rate_radps = 0; s->steering_angle_rad = 0;
    for (i = 0; i < 4; ++i) s->wheel_spin_rad[i] = 0;
    return 1;
}

int HBV_Step(const HBV_Config *cfg, const HBV_Input *in,
             HBV_State *s, HBV_Telemetry *out) {
    float dt, traction = 0, front_traction = 0, rear_traction = 0;
    float throttle, brake, handbrake, steering, acceleration, drag;
    float steer_target, yaw_target, d_angle, sn, cs, new_x, new_y, norm;
    float vel_x, vel_y, contacts = 0;
    int i;
    if (!cfg || !in || !s || !out) return 0;
    dt = in->delta_seconds;
    if (!hb_valid(dt) || dt <= 0.0f || dt > 0.05f ||
        cfg->wheelbase_m <= 0.0f || cfg->wheel_radius_m <= 0.0f ||
        cfg->max_forward_mps <= 0.0f || cfg->max_reverse_mps <= 0.0f ||
        !hb_valid(s->speed_mps) || !hb_valid(s->forward_x) || !hb_valid(s->forward_y) ||
        !hb_valid(in->throttle) || !hb_valid(in->steering)) return 0;

    throttle = hb_clamp(in->throttle, -1, 1);
    steering = hb_clamp(in->steering, -1, 1);
    brake = hb_clamp(in->brake, 0, 1);
    handbrake = hb_clamp(in->handbrake, 0, 1);
    for (i = 0; i < 4; ++i) {
        float c, g;
        if (!hb_valid(in->wheel_contact[i]) || !hb_valid(in->wheel_grip[i])) return 0;
        c = hb_clamp(in->wheel_contact[i], 0, 1);
        g = c * hb_clamp(in->wheel_grip[i], 0, 1);
        contacts += c;
        traction += g;
        if (i < 2) front_traction += g; else rear_traction += g;
    }
    traction *= 0.25f;
    front_traction *= 0.5f;
    rear_traction *= 0.5f;

    acceleration = throttle * hb_clamp(cfg->engine_accel_mps2, 0, 100) * traction;
    s->speed_mps += acceleration * dt;

    /* Brake never inadvertently drives a stopped car in reverse. */
    if (brake > 0 || handbrake > 0) {
        float decel = (brake + 0.7f*handbrake) *
                      hb_clamp(cfg->brake_decel_mps2, 0, 100) * traction * dt;
        s->speed_mps = hb_approach(s->speed_mps, 0, decel);
    } else if (traction > 0.0f && hb_abs(throttle) < 0.01f) {
        s->speed_mps = hb_approach(s->speed_mps, 0,
                         hb_clamp(cfg->coast_decel_mps2, 0, 100)*traction*dt);
    }
    drag = cfg->aero_drag_factor * s->speed_mps * hb_abs(s->speed_mps)*dt;
    if (drag > 0 && drag > s->speed_mps) s->speed_mps = 0;
    else if (drag < 0 && drag < s->speed_mps) s->speed_mps = 0;
    else s->speed_mps -= drag;
    s->speed_mps = hb_clamp(s->speed_mps, -cfg->max_reverse_mps, cfg->max_forward_mps);

    steer_target = steering * hb_clamp(cfg->max_steer_rad, 0, 0.8f);
    s->steering_angle_rad = hb_approach(s->steering_angle_rad, steer_target,
                              hb_clamp(cfg->steer_response_per_s, 0, 100)*dt);
    /* Bicycle-model small-angle approximation tan(x) ~= x + x^3/3. */
    {
        float a = s->steering_angle_rad;
        float approximate_tan = a + (a*a*a)/3.0f;
        yaw_target = (s->speed_mps / cfg->wheelbase_m) * approximate_tan;
    }
    /* Rear traction limits yaw control under handbrake. */
    yaw_target *= front_traction * (1.0f - 0.35f*handbrake);
    if (traction < 0.01f) yaw_target = 0;
    s->yaw_rate_radps = hb_approach(s->yaw_rate_radps, yaw_target,
                         hb_clamp(cfg->yaw_response_per_s, 0, 100)*dt);

    /* Rotate forward basis without libc sin/cos; normalize to avoid drift. */
    d_angle = s->yaw_rate_radps * dt;
    sn = d_angle - d_angle*d_angle*d_angle/6.0f;
    cs = 1.0f - d_angle*d_angle/2.0f;
    new_x = s->forward_x * cs - s->forward_y * sn;
    new_y = s->forward_x * sn + s->forward_y * cs;
    norm = hb_sqrt(new_x*new_x + new_y*new_y);
    if (norm < 0.0001f) return 0;
    s->forward_x = new_x/norm;
    s->forward_y = new_y/norm;

    s->lateral_speed_mps = hb_approach(s->lateral_speed_mps, 0,
                  hb_clamp(cfg->lateral_damping_per_s, 0, 100) * traction * dt);
    vel_x = s->forward_x * s->speed_mps - s->forward_y * s->lateral_speed_mps;
    vel_y = s->forward_y * s->speed_mps + s->forward_x * s->lateral_speed_mps;
    s->pos_x_m += vel_x * dt;
    s->pos_y_m += vel_y * dt;
    for (i = 0; i < 4; ++i) {
        s->wheel_spin_rad[i] += s->speed_mps * dt / cfg->wheel_radius_m;
        if (s->wheel_spin_rad[i] > 6.28318530718f) s->wheel_spin_rad[i] -= 6.28318530718f;
        if (s->wheel_spin_rad[i] < -6.28318530718f) s->wheel_spin_rad[i] += 6.28318530718f;
    }
    out->grounded_wheels = contacts;
    out->mean_traction = traction;
    out->forward_acceleration_mps2 = acceleration;
    out->target_yaw_rate_radps = yaw_target;
    out->speed_mps = s->speed_mps;
    out->velocity_x_mps = vel_x;
    out->velocity_y_mps = vel_y;
    out->yaw_rate_radps = s->yaw_rate_radps;
    return 1;
}
