#ifndef HB_VEHICLE_CORE_H
#define HB_VEHICLE_CORE_H

/* Public C ABI. No Unreal headers, heap allocation or OS API needed.
 * Fields are 32-bit IEEE floats; structs must use 4-byte alignment.
 * Coordinates are metres and seconds, not Unreal Units.
 */
#ifndef HBV_EXPORT
#  define HBV_EXPORT
#endif

#if defined(__cplusplus)
extern "C" {
#endif

#define HBV_API_VERSION 1
#define HBV_WHEEL_COUNT 4

typedef struct HBV_Config {
    float wheelbase_m;
    float wheel_radius_m;
    float max_steer_rad;
    float max_forward_mps;
    float max_reverse_mps;
    float engine_accel_mps2;
    float brake_decel_mps2;
    float coast_decel_mps2;
    float aero_drag_factor;
    float steer_response_per_s;
    float yaw_response_per_s;
    float lateral_damping_per_s;
} HBV_Config;

typedef struct HBV_Input {
    float delta_seconds;     /* 0 < dt <= 0.05, fixed 60 Hz preferred */
    float throttle;          /* -1 reverse, +1 forward */
    float steering;          /* -1 left, +1 right */
    float brake;             /* 0..1 */
    float handbrake;         /* 0..1 */
    float wheel_contact[4];  /* 0 (airborne) to 1 (grounded) */
    float wheel_grip[4];     /* 0 (ice) to 1 (grippy surface) */
} HBV_Input;

typedef struct HBV_State {
    float pos_x_m;
    float pos_y_m;
    float forward_x;         /* normalized world-space forward axis */
    float forward_y;
    float speed_mps;         /* signed along forward */
    float lateral_speed_mps;
    float yaw_rate_radps;
    float steering_angle_rad;
    float wheel_spin_rad[4];
} HBV_State;

typedef struct HBV_Telemetry {
    float grounded_wheels;
    float mean_traction;
    float forward_acceleration_mps2;
    float target_yaw_rate_radps;
    float speed_mps;
    float velocity_x_mps;
    float velocity_y_mps;
    float yaw_rate_radps;
} HBV_Telemetry;

HBV_EXPORT unsigned int HBV_GetAPIVersion(void);
HBV_EXPORT int HBV_DefaultConfig(HBV_Config *config);
HBV_EXPORT int HBV_Reset(HBV_State *state);
HBV_EXPORT int HBV_Step(const HBV_Config *config, const HBV_Input *input,
                        HBV_State *state, HBV_Telemetry *out_telemetry);

#if defined(__cplusplus)
}
#endif
#endif
