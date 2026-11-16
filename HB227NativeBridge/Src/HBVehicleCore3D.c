#include "HBVehicleCore3D.h"

#include <float.h>
#include <math.h>
#include <string.h>

/* One dynamic rigid body against a static/kinematic world. */

typedef struct HB3_Vec3 { float x, y, z; } HB3_Vec3;
typedef struct HB3_Quat { float w, x, y, z; } HB3_Quat;

typedef struct HB3_SolverContact {
	HB3_Vec3 point;
	HB3_Vec3 normal;
	HB3_Vec3 surface_velocity;
	float penetration;
	float restitution;
	float friction;
	float target_normal_velocity;
	float lambda_normal;
	HB3_Vec3 lambda_tangent;
	unsigned int feature_id;
} HB3_SolverContact;

static float hb3_abs(float v) { return v < 0.f ? -v : v; }
static float hb3_min(float a, float b) { return a < b ? a : b; }
static float hb3_max(float a, float b) { return a > b ? a : b; }
static float hb3_clamp(float v, float lo, float hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}
static int hb3_finite(float v) {
	return v == v && v <= FLT_MAX && v >= -FLT_MAX;
}
static HB3_Vec3 hb3_v(float x, float y, float z) {
	HB3_Vec3 r; r.x = x; r.y = y; r.z = z; return r;
}
static HB3_Vec3 hb3_add(HB3_Vec3 a, HB3_Vec3 b) {
	return hb3_v(a.x + b.x, a.y + b.y, a.z + b.z);
}
static HB3_Vec3 hb3_sub(HB3_Vec3 a, HB3_Vec3 b) {
	return hb3_v(a.x - b.x, a.y - b.y, a.z - b.z);
}
static HB3_Vec3 hb3_mul(HB3_Vec3 a, float s) {
	return hb3_v(a.x * s, a.y * s, a.z * s);
}
static float hb3_dot(HB3_Vec3 a, HB3_Vec3 b) {
	return a.x * b.x + a.y * b.y + a.z * b.z;
}
static HB3_Vec3 hb3_cross(HB3_Vec3 a, HB3_Vec3 b) {
	return hb3_v(a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x);
}
static float hb3_length(HB3_Vec3 a) {
	float scale = hb3_abs(a.x);
	float ay = hb3_abs(a.y), az = hb3_abs(a.z);
	if (ay > scale) scale = ay;
	if (az > scale) scale = az;
	if (scale <= 0.f) return 0.f;
	a = hb3_mul(a, 1.f / scale);
	return scale * sqrtf(hb3_dot(a, a));
}
static int hb3_finite_vec(HB3_Vec3 a) {
	return hb3_finite(a.x) && hb3_finite(a.y) && hb3_finite(a.z);
}
static int hb3_normalize_vec(HB3_Vec3 *a) {
	float length = hb3_length(*a);
	if (!hb3_finite(length) || length < 1.0e-6f) return 0;
	*a = hb3_mul(*a, 1.f / length);
	return 1;
}

static HB3_Quat hb3_quat(float w, float x, float y, float z) {
	HB3_Quat q; q.w = w; q.x = x; q.y = y; q.z = z; return q;
}
static int hb3_normalize_quat(HB3_Quat *q) {
	float n;
	if (!hb3_finite(q->w) || !hb3_finite(q->x) ||
		!hb3_finite(q->y) || !hb3_finite(q->z)) return 0;
	n = sqrtf(q->w*q->w + q->x*q->x + q->y*q->y + q->z*q->z);
	if (!hb3_finite(n) || n < 1.0e-6f) return 0;
	q->w /= n; q->x /= n; q->y /= n; q->z /= n;
	return 1;
}
static HB3_Quat hb3_quat_mul(HB3_Quat a, HB3_Quat b) {
	return hb3_quat(
		a.w*b.w - a.x*b.x - a.y*b.y - a.z*b.z,
		a.w*b.x + a.x*b.w + a.y*b.z - a.z*b.y,
		a.w*b.y - a.x*b.z + a.y*b.w + a.z*b.x,
		a.w*b.z + a.x*b.y - a.y*b.x + a.z*b.w);
}
static HB3_Vec3 hb3_quat_rotate(HB3_Quat q, HB3_Vec3 v) {
	HB3_Vec3 qv = hb3_v(q.x, q.y, q.z);
	HB3_Vec3 t = hb3_mul(hb3_cross(qv, v), 2.f);
	return hb3_add(v, hb3_add(hb3_mul(t, q.w), hb3_cross(qv, t)));
}
static HB3_Vec3 hb3_quat_inv_rotate(HB3_Quat q, HB3_Vec3 v) {
	q.x = -q.x; q.y = -q.y; q.z = -q.z;
	return hb3_quat_rotate(q, v);
}

static HB3_Vec3 hb3_state_pos(const HBV3_State *s) {
	return hb3_v(s->pos_x_m, s->pos_y_m, s->pos_z_m);
}
static HB3_Vec3 hb3_state_vel(const HBV3_State *s) {
	return hb3_v(s->vel_x_mps, s->vel_y_mps, s->vel_z_mps);
}
static HB3_Vec3 hb3_state_omega(const HBV3_State *s) {
	return hb3_v(s->ang_x_radps, s->ang_y_radps, s->ang_z_radps);
}
static HB3_Quat hb3_state_quat(const HBV3_State *s) {
	return hb3_quat(s->quat_w, s->quat_x, s->quat_y, s->quat_z);
}
static void hb3_put_pos(HBV3_State *s, HB3_Vec3 v) {
	s->pos_x_m = v.x; s->pos_y_m = v.y; s->pos_z_m = v.z;
}
static void hb3_put_vel(HBV3_State *s, HB3_Vec3 v) {
	s->vel_x_mps = v.x; s->vel_y_mps = v.y; s->vel_z_mps = v.z;
}
static void hb3_put_omega(HBV3_State *s, HB3_Vec3 v) {
	s->ang_x_radps = v.x; s->ang_y_radps = v.y; s->ang_z_radps = v.z;
}
static void hb3_put_quat(HBV3_State *s, HB3_Quat q) {
	s->quat_w = q.w; s->quat_x = q.x; s->quat_y = q.y; s->quat_z = q.z;
}

static int hb3_valid_config(const HBV3_Config *c) {
	return c && hb3_finite(c->mass_kg) && c->mass_kg > 1.0e-4f &&
		hb3_finite(c->half_x_m) && c->half_x_m > 0.f &&
		hb3_finite(c->half_y_m) && c->half_y_m > 0.f &&
		hb3_finite(c->half_z_m) && c->half_z_m > 0.f &&
		hb3_finite(c->inertia_x_kgm2) && c->inertia_x_kgm2 > 1.0e-6f &&
		hb3_finite(c->inertia_y_kgm2) && c->inertia_y_kgm2 > 1.0e-6f &&
		hb3_finite(c->inertia_z_kgm2) && c->inertia_z_kgm2 > 1.0e-6f &&
		hb3_finite(c->gravity_x) && hb3_finite(c->gravity_y) &&
		hb3_finite(c->gravity_z) &&
		hb3_finite(c->linear_damping) && c->linear_damping >= 0.f &&
		c->linear_damping <= 20.f &&
		hb3_finite(c->angular_damping) && c->angular_damping >= 0.f &&
		c->angular_damping <= 20.f &&
		hb3_finite(c->penetration_slop_m) && c->penetration_slop_m >= 0.f &&
		hb3_finite(c->penetration_beta) && c->penetration_beta >= 0.f &&
		c->penetration_beta <= 1.f &&
		hb3_finite(c->max_position_correction_m) &&
		c->max_position_correction_m >= 0.f &&
		hb3_finite(c->restitution_velocity_threshold_mps) &&
		c->restitution_velocity_threshold_mps >= 0.f &&
		c->solver_iterations >= 1 &&
		c->solver_iterations <= HBV3_MAX_SOLVER_ITERATIONS;
}

static int hb3_valid_state(const HBV3_State *s) {
	HB3_Quat q;
	if (!s || !hb3_finite_vec(hb3_state_pos(s)) ||
		!hb3_finite_vec(hb3_state_vel(s)) ||
		!hb3_finite_vec(hb3_state_omega(s))) return 0;
	q = hb3_state_quat(s);
	return hb3_normalize_quat(&q);
}

static int hb3_valid_contact(const HBV3_Contact *c) {
	HB3_Vec3 n;
	if (!c || !hb3_finite(c->point_x_m) || !hb3_finite(c->point_y_m) ||
		!hb3_finite(c->point_z_m) || !hb3_finite(c->nx) ||
		!hb3_finite(c->ny) || !hb3_finite(c->nz) ||
		!hb3_finite(c->penetration_m) || c->penetration_m < 0.f ||
		!hb3_finite(c->restitution) || c->restitution < 0.f ||
		c->restitution > 1.f || !hb3_finite(c->friction) ||
		c->friction < 0.f || c->friction > 1.f ||
		!hb3_finite(c->surface_vel_x_mps) ||
		!hb3_finite(c->surface_vel_y_mps) ||
		!hb3_finite(c->surface_vel_z_mps)) return 0;
	n = hb3_v(c->nx, c->ny, c->nz);
	return hb3_normalize_vec(&n);
}

static int hb3_valid_suspension_config(const HBV3_SuspensionConfig *c) {
	HB3_Vec3 axis;
	if (!c || !hb3_finite(c->attachment_x_m) ||
		!hb3_finite(c->attachment_y_m) || !hb3_finite(c->attachment_z_m) ||
		!hb3_finite(c->axis_x_down) || !hb3_finite(c->axis_y_down) ||
		!hb3_finite(c->axis_z_down) || !hb3_finite(c->rest_length_m) ||
		!hb3_finite(c->min_length_m) || !hb3_finite(c->max_length_m) ||
		c->min_length_m < 0.f || c->rest_length_m < c->min_length_m ||
		c->max_length_m < c->rest_length_m ||
		!hb3_finite(c->spring_n_per_m) || c->spring_n_per_m < 0.f ||
		!hb3_finite(c->damper_compression_ns_per_m) ||
		c->damper_compression_ns_per_m < 0.f ||
		!hb3_finite(c->damper_rebound_ns_per_m) ||
		c->damper_rebound_ns_per_m < 0.f ||
		!hb3_finite(c->bump_stop_n_per_m) || c->bump_stop_n_per_m < 0.f ||
		!hb3_finite(c->min_normal_alignment) ||
		c->min_normal_alignment < 0.f || c->min_normal_alignment > 1.f)
		return 0;
	axis = hb3_v(c->axis_x_down, c->axis_y_down, c->axis_z_down);
	return hb3_normalize_vec(&axis);
}

static HB3_Vec3 hb3_inv_inertia_mul(const HBV3_Config *cfg,
	const HBV3_State *s, HB3_Vec3 world) {
	HB3_Quat q = hb3_state_quat(s);
	HB3_Vec3 body = hb3_quat_inv_rotate(q, world);
	body.x /= cfg->inertia_x_kgm2;
	body.y /= cfg->inertia_y_kgm2;
	body.z /= cfg->inertia_z_kgm2;
	return hb3_quat_rotate(q, body);
}

static HB3_Vec3 hb3_inertia_mul(const HBV3_Config *cfg,
	const HBV3_State *s, HB3_Vec3 world) {
	HB3_Quat q = hb3_state_quat(s);
	HB3_Vec3 body = hb3_quat_inv_rotate(q, world);
	body.x *= cfg->inertia_x_kgm2;
	body.y *= cfg->inertia_y_kgm2;
	body.z *= cfg->inertia_z_kgm2;
	return hb3_quat_rotate(q, body);
}

static void hb3_apply_impulse(const HBV3_Config *cfg, HBV3_State *s,
	HB3_Vec3 impulse, HB3_Vec3 point) {
	HB3_Vec3 r = hb3_sub(point, hb3_state_pos(s));
	HB3_Vec3 vel = hb3_add(hb3_state_vel(s), hb3_mul(impulse, 1.f / cfg->mass_kg));
	HB3_Vec3 omega = hb3_add(hb3_state_omega(s),
		hb3_inv_inertia_mul(cfg, s, hb3_cross(r, impulse)));
	hb3_put_vel(s, vel);
	hb3_put_omega(s, omega);
}

static HB3_Vec3 hb3_contact_velocity(const HBV3_State *s,
	const HB3_SolverContact *c) {
	HB3_Vec3 r = hb3_sub(c->point, hb3_state_pos(s));
	return hb3_sub(hb3_add(hb3_state_vel(s), hb3_cross(hb3_state_omega(s), r)),
		c->surface_velocity);
}

static float hb3_effective_mass_k(const HBV3_Config *cfg,
	const HBV3_State *s, HB3_Vec3 point, HB3_Vec3 direction) {
	HB3_Vec3 r = hb3_sub(point, hb3_state_pos(s));
	HB3_Vec3 angular = hb3_cross(
		hb3_inv_inertia_mul(cfg, s, hb3_cross(r, direction)), r);
	return 1.f / cfg->mass_kg + hb3_dot(direction, angular);
}

static int hb3_compare_float(float a, float b) {
	return a < b ? -1 : (a > b ? 1 : 0);
}
static int hb3_contact_compare(const HB3_SolverContact *a,
	const HB3_SolverContact *b) {
	int c;
	if (a->feature_id != b->feature_id) {
		if (a->feature_id == 0) return 1;
		if (b->feature_id == 0) return -1;
		return a->feature_id < b->feature_id ? -1 : 1;
	}
	c = hb3_compare_float(a->point.x, b->point.x); if (c) return c;
	c = hb3_compare_float(a->point.y, b->point.y); if (c) return c;
	c = hb3_compare_float(a->point.z, b->point.z); if (c) return c;
	c = hb3_compare_float(a->normal.x, b->normal.x); if (c) return c;
	c = hb3_compare_float(a->normal.y, b->normal.y); if (c) return c;
	return hb3_compare_float(a->normal.z, b->normal.z);
}
static int hb3_same_contact(const HB3_SolverContact *a,
	const HB3_SolverContact *b) {
	HB3_Vec3 dp;
	if (a->feature_id != 0 && a->feature_id == b->feature_id) return 1;
	dp = hb3_sub(a->point, b->point);
	return hb3_dot(dp, dp) <= 1.0e-8f && hb3_dot(a->normal, b->normal) >= 0.9999f;
}

static int hb3_build_manifold(const HBV3_State *s, const HBV3_Config *cfg,
	const HBV3_Contact *input, int count, HB3_SolverContact *out) {
	int i, j, unique = 0;
	for (i = 0; i < count; ++i) {
		HB3_SolverContact c;
		memset(&c, 0, sizeof(c));
		c.point = hb3_v(input[i].point_x_m, input[i].point_y_m, input[i].point_z_m);
		c.normal = hb3_v(input[i].nx, input[i].ny, input[i].nz);
		hb3_normalize_vec(&c.normal);
		c.surface_velocity = hb3_v(input[i].surface_vel_x_mps,
			input[i].surface_vel_y_mps, input[i].surface_vel_z_mps);
		c.penetration = input[i].penetration_m;
		c.restitution = input[i].restitution;
		c.friction = input[i].friction;
		c.feature_id = input[i].feature_id;
		out[i] = c;
	}
	for (i = 1; i < count; ++i) {
		HB3_SolverContact key = out[i];
		j = i - 1;
		while (j >= 0 && hb3_contact_compare(&key, &out[j]) < 0) {
			out[j + 1] = out[j];
			--j;
		}
		out[j + 1] = key;
	}
	for (i = 0; i < count; ++i) {
		HB3_SolverContact current = out[i];
		int duplicate = -1;
		for (j = 0; j < unique; ++j) {
			if (hb3_same_contact(&out[j], &current)) {
				duplicate = j;
				break;
			}
		}
		if (duplicate >= 0) {
			out[duplicate].penetration = hb3_max(out[duplicate].penetration,
				current.penetration);
			out[duplicate].restitution = hb3_max(out[duplicate].restitution,
				current.restitution);
			out[duplicate].friction = hb3_max(out[duplicate].friction,
				current.friction);
		} else {
			out[unique++] = current;
		}
	}
	for (i = 0; i < unique; ++i) {
		float vn = hb3_dot(hb3_contact_velocity(s, &out[i]), out[i].normal);
		out[i].target_normal_velocity =
			vn < -cfg->restitution_velocity_threshold_mps
			? -out[i].restitution * vn : 0.f;
	}
	return unique;
}

static void hb3_solve_manifold(const HBV3_Config *cfg, HBV3_State *s,
	HB3_SolverContact *contacts, int count) {
	int iteration, i;
	for (iteration = 0; iteration < cfg->solver_iterations; ++iteration) {
		for (i = 0; i < count; ++i) {
			HB3_SolverContact *c = &contacts[i];
			HB3_Vec3 vrel = hb3_contact_velocity(s, c);
			float vn = hb3_dot(vrel, c->normal);
			float k = hb3_effective_mass_k(cfg, s, c->point, c->normal);
			float old_lambda = c->lambda_normal;
			float new_lambda;
			if (!hb3_finite(k) || k <= 1.0e-8f) continue;
			new_lambda = hb3_max(0.f, old_lambda +
				(c->target_normal_velocity - vn) / k);
			c->lambda_normal = new_lambda;
			hb3_apply_impulse(cfg, s,
				hb3_mul(c->normal, new_lambda - old_lambda), c->point);

			vrel = hb3_contact_velocity(s, c);
			vn = hb3_dot(vrel, c->normal);
			{
				HB3_Vec3 tangent_velocity = hb3_sub(vrel, hb3_mul(c->normal, vn));
				float tangent_speed = hb3_length(tangent_velocity);
				float friction_limit = c->friction * c->lambda_normal;
				HB3_Vec3 candidate = c->lambda_tangent;
				if (tangent_speed > 1.0e-6f && friction_limit > 0.f) {
					HB3_Vec3 tangent = hb3_mul(tangent_velocity, 1.f / tangent_speed);
					float kt = hb3_effective_mass_k(cfg, s, c->point, tangent);
					if (hb3_finite(kt) && kt > 1.0e-8f)
						candidate = hb3_add(candidate,
							hb3_mul(tangent, -tangent_speed / kt));
				}
				{
					float candidate_length = hb3_length(candidate);
					if (candidate_length > friction_limit && candidate_length > 0.f)
						candidate = hb3_mul(candidate, friction_limit / candidate_length);
				}
				hb3_apply_impulse(cfg, s,
					hb3_sub(candidate, c->lambda_tangent), c->point);
				c->lambda_tangent = candidate;
			}
		}
	}
}

static void hb3_correct_penetration(const HBV3_Config *cfg, HBV3_State *s,
	const HB3_SolverContact *contacts, int count) {
	HB3_Vec3 correction = hb3_v(0.f, 0.f, 0.f);
	int iteration, i;
	for (iteration = 0; iteration < 4; ++iteration) {
		for (i = 0; i < count; ++i) {
			float depth = hb3_max(0.f, contacts[i].penetration - cfg->penetration_slop_m);
			float target = cfg->penetration_beta * depth;
			float residual;
			target = hb3_min(target, cfg->max_position_correction_m);
			residual = target - hb3_dot(correction, contacts[i].normal);
			if (residual > 0.f)
				correction = hb3_add(correction,
					hb3_mul(contacts[i].normal, residual));
		}
	}
	{
		float length = hb3_length(correction);
		if (length > cfg->max_position_correction_m && length > 0.f)
			correction = hb3_mul(correction,
				cfg->max_position_correction_m / length);
	}
	hb3_put_pos(s, hb3_add(hb3_state_pos(s), correction));
}

static void hb3_integrate_orientation(HBV3_State *s, float dt) {
	HB3_Vec3 omega = hb3_state_omega(s);
	float speed = hb3_length(omega);
	HB3_Quat q = hb3_state_quat(s);
	if (speed > 1.0e-8f) {
		float half_angle = 0.5f * speed * dt;
		float scale = sinf(half_angle) / speed;
		HB3_Quat delta = hb3_quat(cosf(half_angle),
			omega.x * scale, omega.y * scale, omega.z * scale);
		q = hb3_quat_mul(delta, q);
		hb3_normalize_quat(&q);
		hb3_put_quat(s, q);
	}
}

unsigned int HBV3_GetAPIVersion(void) { return HBV3_API_VERSION; }

int HBV3_ValidateSuspensionConfig(const HBV3_SuspensionConfig *config) {
	return hb3_valid_suspension_config(config);
}

int HBV3_ConfigureBox(HBV3_Config *c,
	float mass, float hx, float hy, float hz) {
	float ix, iy, iz;
	if (!c || !hb3_finite(mass) || !hb3_finite(hx) || !hb3_finite(hy) ||
		!hb3_finite(hz) || mass <= 1.0e-4f || hx <= 0.f || hy <= 0.f || hz <= 0.f)
		return 0;
	ix = mass * (hy*hy + hz*hz) / 3.f;
	iy = mass * (hx*hx + hz*hz) / 3.f;
	iz = mass * (hx*hx + hy*hy) / 3.f;
	if (!hb3_finite(ix) || !hb3_finite(iy) || !hb3_finite(iz) ||
		ix <= 1.0e-6f || iy <= 1.0e-6f || iz <= 1.0e-6f) return 0;
	c->mass_kg = mass;
	c->half_x_m = hx; c->half_y_m = hy; c->half_z_m = hz;
	c->inertia_x_kgm2 = ix;
	c->inertia_y_kgm2 = iy;
	c->inertia_z_kgm2 = iz;
	return 1;
}

int HBV3_DefaultConfig(HBV3_Config *c) {
	if (!c) return 0;
	memset(c, 0, sizeof(*c));
	if (!HBV3_ConfigureBox(c, 200.f, 0.40f, 0.40f, 0.40f)) return 0;
	c->gravity_z = -9.81f;
	c->linear_damping = 0.02f;
	c->angular_damping = 0.05f;
	c->penetration_slop_m = 0.001f;
	c->penetration_beta = 0.2f;
	c->max_position_correction_m = 0.05f;
	c->restitution_velocity_threshold_mps = 1.0f;
	c->solver_iterations = 12;
	return 1;
}

int HBV3_Reset(HBV3_State *s) {
	if (!s) return 0;
	memset(s, 0, sizeof(*s));
	s->quat_w = 1.f;
	return 1;
}

int HBV3_SetStateValidated(HBV3_State *state, const HBV3_State *new_state) {
	HBV3_State candidate;
	HB3_Quat q;
	if (!state || !new_state || !hb3_valid_state(new_state)) return 0;
	candidate = *new_state;
	q = hb3_state_quat(&candidate);
	hb3_normalize_quat(&q);
	hb3_put_quat(&candidate, q);
	*state = candidate;
	return 1;
}

int HBV3_SetOrientationEuler(HBV3_State *s,
	float yaw, float pitch, float roll) {
	float cy, sy, cp, sp, cr, sr;
	HB3_Quat q;
	if (!s || !hb3_valid_state(s) || !hb3_finite(yaw) ||
		!hb3_finite(pitch) || !hb3_finite(roll)) return 0;
	cy = cosf(yaw * 0.5f); sy = sinf(yaw * 0.5f);
	cp = cosf(pitch * 0.5f); sp = sinf(pitch * 0.5f);
	cr = cosf(roll * 0.5f); sr = sinf(roll * 0.5f);
	q = hb3_quat(cr*cp*cy + sr*sp*sy,
		sr*cp*cy - cr*sp*sy,
		cr*sp*cy + sr*cp*sy,
		cr*cp*sy - sr*sp*cy);
	hb3_normalize_quat(&q);
	hb3_put_quat(s, q);
	return 1;
}

int HBV3_GetOrientationEuler(const HBV3_State *s,
	float *yaw, float *pitch, float *roll) {
	HB3_Quat q;
	float sin_pitch;
	if (!s || !yaw || !pitch || !roll || !hb3_valid_state(s)) return 0;
	q = hb3_state_quat(s);
	hb3_normalize_quat(&q);
	*roll = atan2f(2.f * (q.w*q.x + q.y*q.z),
		1.f - 2.f * (q.x*q.x + q.y*q.y));
	sin_pitch = hb3_clamp(2.f * (q.w*q.y - q.z*q.x), -1.f, 1.f);
	*pitch = asinf(sin_pitch);
	*yaw = atan2f(2.f * (q.w*q.z + q.x*q.y),
		1.f - 2.f * (q.y*q.y + q.z*q.z));
	return 1;
}

int HBV3_EvaluateSuspension(const HBV3_State *s,
	const HBV3_SuspensionConfig configs[HBV3_SUSPENSION_POINTS],
	const HBV3_SuspensionHit hits[HBV3_SUSPENSION_POINTS],
	HBV3_SuspensionOutput outputs[HBV3_SUSPENSION_POINTS],
	HBV3_SuspensionTotals *totals) {
	HBV3_SuspensionOutput next_outputs[HBV3_SUSPENSION_POINTS];
	HBV3_SuspensionTotals next_totals;
	HB3_Quat q;
	HB3_Vec3 body_pos, body_vel, body_omega;
	int i;
	if (!s || !configs || !hits || !outputs || !totals || !hb3_valid_state(s))
		return 0;
	q = hb3_state_quat(s);
	if (!hb3_normalize_quat(&q)) return 0;
	body_pos = hb3_state_pos(s);
	body_vel = hb3_state_vel(s);
	body_omega = hb3_state_omega(s);
	memset(next_outputs, 0, sizeof(next_outputs));
	memset(&next_totals, 0, sizeof(next_totals));

	for (i = 0; i < HBV3_SUSPENSION_POINTS; ++i) {
		const HBV3_SuspensionConfig *c = &configs[i];
		const HBV3_SuspensionHit *h = &hits[i];
		HBV3_SuspensionOutput *o = &next_outputs[i];
		HB3_Vec3 r, attachment, axis, up, normal, wheel_lever, relative;
		HB3_Vec3 force, torque;
		float regular_travel, damping, raw_force, alignment;
		if (!hb3_valid_suspension_config(c) ||
			(h->has_contact != 0 && h->has_contact != 1)) return 0;
		r = hb3_quat_rotate(q,
			hb3_v(c->attachment_x_m, c->attachment_y_m, c->attachment_z_m));
		attachment = hb3_add(body_pos, r);
		axis = hb3_quat_rotate(q,
			hb3_v(c->axis_x_down, c->axis_y_down, c->axis_z_down));
		if (!hb3_normalize_vec(&axis)) return 0;
		up = hb3_mul(axis, -1.f);
		o->attachment_x_m = attachment.x;
		o->attachment_y_m = attachment.y;
		o->attachment_z_m = attachment.z;
		o->axis_x_down = axis.x;
		o->axis_y_down = axis.y;
		o->axis_z_down = axis.z;
		o->feature_id = h->feature_id;
		if (!h->has_contact) {
			o->status = HBV3_SUSPENSION_NO_HIT;
			continue;
		}
		if (!hb3_finite(h->length_m) || h->length_m < 0.f ||
			!hb3_finite(h->point_x_m) || !hb3_finite(h->point_y_m) ||
			!hb3_finite(h->point_z_m) || !hb3_finite(h->nx) ||
			!hb3_finite(h->ny) || !hb3_finite(h->nz) ||
			!hb3_finite(h->surface_vel_x_mps) ||
			!hb3_finite(h->surface_vel_y_mps) ||
			!hb3_finite(h->surface_vel_z_mps)) return 0;
		o->length_m = h->length_m;
		if (h->length_m > c->max_length_m) {
			o->status = HBV3_SUSPENSION_OUT_OF_REACH;
			continue;
		}
		normal = hb3_v(h->nx, h->ny, h->nz);
		if (!hb3_normalize_vec(&normal)) return 0;
		alignment = hb3_dot(up, normal);
		if (alignment <= 1.0e-4f || alignment < c->min_normal_alignment) {
			o->status = HBV3_SUSPENSION_BAD_ALIGNMENT;
			continue;
		}

		regular_travel = c->rest_length_m - c->min_length_m;
		o->compression_m = hb3_clamp(c->rest_length_m - h->length_m,
			0.f, regular_travel);
		o->bump_compression_m = h->length_m < c->min_length_m
			? c->min_length_m - h->length_m : 0.f;
		/* Differentiate the wheel centre's plane constraint along the
		   suspension axis, including the motion from axis rotation. */
		wheel_lever = hb3_add(r, hb3_mul(axis, h->length_m));
		relative = hb3_sub(hb3_add(body_vel, hb3_cross(body_omega, wheel_lever)),
			hb3_v(h->surface_vel_x_mps, h->surface_vel_y_mps,
				h->surface_vel_z_mps));
		o->compression_rate_mps = -hb3_dot(relative, normal) / alignment;
		o->spring_force_n = c->spring_n_per_m * o->compression_m;
		damping = o->compression_rate_mps >= 0.f
			? c->damper_compression_ns_per_m : c->damper_rebound_ns_per_m;
		o->damper_force_n = damping * o->compression_rate_mps;
		o->bump_force_n = c->bump_stop_n_per_m * o->bump_compression_m;
		raw_force = o->spring_force_n + o->damper_force_n + o->bump_force_n;
		if (!hb3_finite(raw_force)) return 0;
		o->force_scalar_n = hb3_max(0.f, raw_force);
		force = hb3_mul(up, o->force_scalar_n);
		torque = hb3_cross(r, force);
		o->normal_load_n = hb3_dot(force, normal);
		if (!hb3_finite_vec(force) || !hb3_finite_vec(torque) ||
			!hb3_finite(o->normal_load_n)) return 0;
		o->force_x_n = force.x; o->force_y_n = force.y; o->force_z_n = force.z;
		o->torque_x_nm = torque.x; o->torque_y_nm = torque.y;
		o->torque_z_nm = torque.z;
		o->status = HBV3_SUSPENSION_ACTIVE;
		next_totals.force_x_n += force.x;
		next_totals.force_y_n += force.y;
		next_totals.force_z_n += force.z;
		next_totals.torque_x_nm += torque.x;
		next_totals.torque_y_nm += torque.y;
		next_totals.torque_z_nm += torque.z;
		++next_totals.active_points;
		if (!hb3_finite(next_totals.force_x_n) ||
			!hb3_finite(next_totals.force_y_n) ||
			!hb3_finite(next_totals.force_z_n) ||
			!hb3_finite(next_totals.torque_x_nm) ||
			!hb3_finite(next_totals.torque_y_nm) ||
			!hb3_finite(next_totals.torque_z_nm)) return 0;
	}
	memcpy(outputs, next_outputs, sizeof(next_outputs));
	*totals = next_totals;
	return 1;
}

int HBV3_ApplyImpulseAtPoint(const HBV3_Config *cfg, HBV3_State *s,
	float jx, float jy, float jz, float px, float py, float pz) {
	HBV3_State next;
	HB3_Quat q;
	HB3_Vec3 impulse = hb3_v(jx, jy, jz), point = hb3_v(px, py, pz);
	if (!hb3_valid_config(cfg) || !hb3_valid_state(s) ||
		!hb3_finite_vec(impulse) || !hb3_finite_vec(point)) return 0;
	next = *s;
	q = hb3_state_quat(&next); hb3_normalize_quat(&q); hb3_put_quat(&next, q);
	hb3_apply_impulse(cfg, &next, impulse, point);
	if (!hb3_valid_state(&next)) return 0;
	*s = next;
	return 1;
}

static int hb3_step_external(const HBV3_Config *cfg, HBV3_State *s,
	const HBV3_Contact *contacts, int contact_count,
	float delta_seconds, HBV3_Telemetry *out,
	HB3_Vec3 external_force, HB3_Vec3 external_torque) {
	HBV3_State next;
	HBV3_Telemetry telemetry;
	HB3_SolverContact manifold[HBV3_MAX_CONTACTS];
	HB3_Vec3 vel, omega, angular_momentum, gyro, angular_accel;
	HB3_Quat q;
	float dt, linear_factor, angular_factor, max_pen = 0.f;
	int i, unique, overload = 0;
	if (!cfg || !s || !out || !hb3_finite(delta_seconds) || delta_seconds <= 0.f ||
		!hb3_finite_vec(external_force) || !hb3_finite_vec(external_torque))
		return 0;
	if (!hb3_valid_config(cfg) || !hb3_valid_state(s)) return 0;
	if (contact_count < 0 || contact_count > HBV3_MAX_CONTACTS) return 0;
	if (contact_count > 0 && !contacts) return 0;
	for (i = 0; i < contact_count; ++i)
		if (!hb3_valid_contact(&contacts[i])) return 0;

	next = *s;
	q = hb3_state_quat(&next); hb3_normalize_quat(&q); hb3_put_quat(&next, q);
	dt = delta_seconds;
	if (dt > 0.05f) { dt = 0.05f; overload = 1; }

	vel = hb3_state_vel(&next);
	linear_factor = expf(-cfg->linear_damping * dt);
	vel = hb3_mul(vel, linear_factor);
	vel = hb3_add(vel, hb3_mul(hb3_add(
		hb3_v(cfg->gravity_x, cfg->gravity_y, cfg->gravity_z),
		hb3_mul(external_force, 1.f / cfg->mass_kg)), dt));
	hb3_put_vel(&next, vel);

	omega = hb3_state_omega(&next);
	angular_momentum = hb3_inertia_mul(cfg, &next, omega);
	gyro = hb3_cross(omega, angular_momentum);
	angular_accel = hb3_inv_inertia_mul(cfg, &next,
		hb3_sub(external_torque, gyro));
	omega = hb3_add(omega, hb3_mul(angular_accel, dt));
	angular_factor = expf(-cfg->angular_damping * dt);
	omega = hb3_mul(omega, angular_factor);
	hb3_put_omega(&next, omega);

	hb3_put_pos(&next, hb3_add(hb3_state_pos(&next), hb3_mul(vel, dt)));
	hb3_integrate_orientation(&next, dt);

	unique = hb3_build_manifold(&next, cfg, contacts, contact_count, manifold);
	hb3_solve_manifold(cfg, &next, manifold, unique);
	hb3_correct_penetration(cfg, &next, manifold, unique);

	for (i = 0; i < contact_count; ++i)
		if (contacts[i].penetration_m > max_pen) max_pen = contacts[i].penetration_m;
	if (!hb3_valid_state(&next)) return 0;
	memset(&telemetry, 0, sizeof(telemetry));
	telemetry.speed_mps = hb3_length(hb3_state_vel(&next));
	telemetry.contact_count = (float)contact_count;
	telemetry.max_penetration_m = max_pen;
	telemetry.overload_substeps = overload ? 1.f : 0.f;
	telemetry.unique_contact_count = (float)unique;
	telemetry.solver_iterations = (float)cfg->solver_iterations;
	telemetry.angular_speed_radps = hb3_length(hb3_state_omega(&next));
	if (!hb3_finite(telemetry.speed_mps) ||
		!hb3_finite(telemetry.angular_speed_radps)) return 0;
	*s = next;
	*out = telemetry;
	return 1;
}

int HBV3_Step(const HBV3_Config *cfg, HBV3_State *s,
	const HBV3_Contact *contacts, int contact_count,
	float delta_seconds, HBV3_Telemetry *out) {
	return hb3_step_external(cfg, s, contacts, contact_count, delta_seconds, out,
		hb3_v(0.f, 0.f, 0.f), hb3_v(0.f, 0.f, 0.f));
}

static int hb3_step_with_suspension(const HBV3_Config *cfg, HBV3_State *s,
	const HBV3_Contact *contacts, int contact_count, float delta_seconds,
	HBV3_Telemetry *out, const HBV3_SuspensionTotals *totals) {
	return hb3_step_external(cfg, s, contacts, contact_count, delta_seconds, out,
		hb3_v(totals->force_x_n, totals->force_y_n, totals->force_z_n),
		hb3_v(totals->torque_x_nm, totals->torque_y_nm, totals->torque_z_nm));
}

int HBV3_StepSuspended(const HBV3_Config *cfg, HBV3_State *s,
	const HBV3_Contact *contacts, int contact_count,
	const HBV3_SuspensionConfig suspension_configs[HBV3_SUSPENSION_POINTS],
	const HBV3_SuspensionHit suspension_hits[HBV3_SUSPENSION_POINTS],
	float delta_seconds, HBV3_Telemetry *out,
	HBV3_SuspensionOutput suspension_outputs[HBV3_SUSPENSION_POINTS]) {
	HBV3_SuspensionOutput next_outputs[HBV3_SUSPENSION_POINTS];
	HBV3_SuspensionTotals totals;
	if (!suspension_outputs || !HBV3_EvaluateSuspension(s, suspension_configs,
		suspension_hits, next_outputs, &totals)) return 0;
	if (!hb3_step_with_suspension(cfg, s, contacts, contact_count, delta_seconds,
		out, &totals)) return 0;
	memcpy(suspension_outputs, next_outputs, sizeof(next_outputs));
	return 1;
}
