#ifndef HB_VEHICLE_CORE_3D_H
#define HB_VEHICLE_CORE_3D_H

/* Minimal single-rigid-body 3D solver for HB227VehicleV2.
 * Complements (does not replace) HBVehicleCore 2D.
 * Units: metres, seconds, kilograms, radians, newtons and N*s.
 * World contacts are static/kinematic. No Unreal headers, heap, threads or OS.
 */
#ifndef HBV3_EXPORT
#  define HBV3_EXPORT
#endif

#if defined(__cplusplus)
extern "C" {
#endif

/* API v2 was the P0.5 point-contact rigid body. API v3 adds the P1
 * four-point suspension records and atomic suspended step. */
#define HBV3_API_VERSION 3
#define HBV3_MAX_CONTACTS 16
#define HBV3_MAX_SOLVER_ITERATIONS 32
#define HBV3_SUSPENSION_POINTS 4

typedef struct HBV3_Config {
	float mass_kg;
	float half_x_m;
	float half_y_m;
	float half_z_m;
	float inertia_x_kgm2;       /* body-space principal moments */
	float inertia_y_kgm2;
	float inertia_z_kgm2;
	float gravity_x;
	float gravity_y;
	float gravity_z;
	float linear_damping;       /* exponential damping, 1/s */
	float angular_damping;      /* exponential damping, 1/s */
	float penetration_slop_m;
	float penetration_beta;     /* 0..1 fraction corrected per step */
	float max_position_correction_m;
	float restitution_velocity_threshold_mps;
	int solver_iterations;
} HBV3_Config;

typedef struct HBV3_State {
	float pos_x_m, pos_y_m, pos_z_m;             /* centre of mass */
	float vel_x_mps, vel_y_mps, vel_z_mps;
	float quat_w, quat_x, quat_y, quat_z;         /* world-from-body */
	float ang_x_radps, ang_y_radps, ang_z_radps; /* world space */
} HBV3_State;

typedef struct HBV3_Contact {
	float point_x_m, point_y_m, point_z_m;       /* world point on surface */
	float nx, ny, nz;                            /* surface -> body */
	float penetration_m;                         /* >= 0 along normal */
	float restitution;                           /* 0..1 */
	float friction;                              /* 0..1 */
	float surface_vel_x_mps, surface_vel_y_mps, surface_vel_z_mps;
	unsigned int feature_id;                     /* stable ID; 0 if unavailable */
} HBV3_Contact;

typedef struct HBV3_Telemetry {
	float speed_mps;
	float contact_count;          /* validated input count */
	float max_penetration_m;
	float overload_substeps;      /* 1 if dt was clamped, else 0 */
	float unique_contact_count;   /* post-dedup manifold size */
	float solver_iterations;
	float angular_speed_radps;
} HBV3_Telemetry;

typedef enum HBV3_SuspensionStatus {
	HBV3_SUSPENSION_NO_HIT = 0,
	HBV3_SUSPENSION_OUT_OF_REACH,
	HBV3_SUSPENSION_BAD_ALIGNMENT,
	HBV3_SUSPENSION_ACTIVE
} HBV3_SuspensionStatus;

typedef struct HBV3_SuspensionConfig {
	float attachment_x_m, attachment_y_m, attachment_z_m; /* body from COM */
	float axis_x_down, axis_y_down, axis_z_down;           /* body-space unit */
	float rest_length_m;
	float min_length_m;
	float max_length_m;
	float spring_n_per_m;
	float damper_compression_ns_per_m;
	float damper_rebound_ns_per_m;
	float bump_stop_n_per_m;
	float min_normal_alignment;
} HBV3_SuspensionConfig;

typedef struct HBV3_SuspensionHit {
	int has_contact;
	float length_m; /* attachment to wheel centre; radius already removed */
	float point_x_m, point_y_m, point_z_m;
	float nx, ny, nz;
	float surface_vel_x_mps, surface_vel_y_mps, surface_vel_z_mps;
	unsigned int feature_id;
} HBV3_SuspensionHit;

typedef struct HBV3_SuspensionOutput {
	int status;
	float length_m;
	float compression_m;
	float bump_compression_m;
	float compression_rate_mps;
	float spring_force_n;
	float damper_force_n;
	float bump_force_n;
	float force_scalar_n;
	float normal_load_n;
	float attachment_x_m, attachment_y_m, attachment_z_m;
	float axis_x_down, axis_y_down, axis_z_down;
	float force_x_n, force_y_n, force_z_n;
	float torque_x_nm, torque_y_nm, torque_z_nm;
	unsigned int feature_id;
} HBV3_SuspensionOutput;

typedef struct HBV3_SuspensionTotals {
	float force_x_n, force_y_n, force_z_n;
	float torque_x_nm, torque_y_nm, torque_z_nm;
	int active_points;
} HBV3_SuspensionTotals;

HBV3_EXPORT unsigned int HBV3_GetAPIVersion(void);
HBV3_EXPORT int HBV3_DefaultConfig(HBV3_Config *config);
HBV3_EXPORT int HBV3_ConfigureBox(HBV3_Config *config,
	float mass_kg, float half_x_m, float half_y_m, float half_z_m);
HBV3_EXPORT int HBV3_Reset(HBV3_State *state);
HBV3_EXPORT int HBV3_SetStateValidated(HBV3_State *state,
	const HBV3_State *new_state);
HBV3_EXPORT int HBV3_SetOrientationEuler(HBV3_State *state,
	float yaw_rad, float pitch_rad, float roll_rad);
HBV3_EXPORT int HBV3_GetOrientationEuler(const HBV3_State *state,
	float *yaw_rad, float *pitch_rad, float *roll_rad);
HBV3_EXPORT int HBV3_ApplyImpulseAtPoint(const HBV3_Config *config,
	HBV3_State *state,
	float impulse_x_ns, float impulse_y_ns, float impulse_z_ns,
	float point_x_m, float point_y_m, float point_z_m);
HBV3_EXPORT int HBV3_EvaluateSuspension(const HBV3_State *state,
	const HBV3_SuspensionConfig configs[HBV3_SUSPENSION_POINTS],
	const HBV3_SuspensionHit hits[HBV3_SUSPENSION_POINTS],
	HBV3_SuspensionOutput outputs[HBV3_SUSPENSION_POINTS],
	HBV3_SuspensionTotals *totals);
HBV3_EXPORT int HBV3_ValidateSuspensionConfig(
	const HBV3_SuspensionConfig *config);
HBV3_EXPORT int HBV3_Step(const HBV3_Config *config, HBV3_State *state,
	const HBV3_Contact *contacts, int contact_count,
	float delta_seconds, HBV3_Telemetry *out_telemetry);
HBV3_EXPORT int HBV3_StepSuspended(const HBV3_Config *config,
	HBV3_State *state, const HBV3_Contact *contacts, int contact_count,
	const HBV3_SuspensionConfig suspension_configs[HBV3_SUSPENSION_POINTS],
	const HBV3_SuspensionHit suspension_hits[HBV3_SUSPENSION_POINTS],
	float delta_seconds, HBV3_Telemetry *out_telemetry,
	HBV3_SuspensionOutput suspension_outputs[HBV3_SUSPENSION_POINTS]);

#if defined(__cplusplus)
}
#endif
#endif
