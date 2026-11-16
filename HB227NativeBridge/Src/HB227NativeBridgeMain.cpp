/*=============================================================================
	HB227NativeBridgeMain.cpp - Unreal 227k native package wrapping HBVehicleCore.
=============================================================================*/

#include "HB227NativeBridgePrivate.h"

extern "C" {
#include "HBVehicleCore.c"
#include "HBVehicleCore3D.c"
}

IMPLEMENT_PACKAGE(HB227NativeBridge);
IMPLEMENT_CLASS(AHBVehicleBridge);
IMPLEMENT_CLASS(AHBVehicleBridge3D);

#define NAMES_ONLY
#define AUTOGENERATE_NAME(name) FName HB227NATIVEBRIDGE_##name=FName(TEXT(#name),FNAME_Intrinsic);
#define AUTOGENERATE_FUNCTION(cls,idx,name) IMPLEMENT_FUNCTION(cls, idx, name)
#include "HB227NativeBridgeClasses.h"
#undef NAMES_ONLY
#undef AUTOGENERATE_NAME
#undef AUTOGENERATE_FUNCTION

static void ClearInput(HBV_Input& In)
{
	INT i;
	appMemzero(&In, sizeof(In));
	In.delta_seconds = 1.f / 60.f;
	for (i = 0; i < 4; ++i)
	{
		In.wheel_contact[i] = 1.f;
		In.wheel_grip[i] = 1.f;
	}
}

static FHBVRuntime* GetRuntime(AHBVehicleBridge* Self)
{
	return Self ? (FHBVRuntime*)Self->NativeRuntime : NULL;
}

static void SyncOutputs(AHBVehicleBridge* Self)
{
	FHBVRuntime* R = GetRuntime(Self);
	if (!R) return;
	Self->OutPosX_m = R->State.pos_x_m;
	Self->OutPosY_m = R->State.pos_y_m;
	Self->OutForwardX = R->State.forward_x;
	Self->OutForwardY = R->State.forward_y;
	Self->OutSpeed_mps = R->State.speed_mps;
	Self->OutLateralSpeed_mps = R->State.lateral_speed_mps;
	Self->OutYawRate_radps = R->State.yaw_rate_radps;
	Self->OutSteerRad = R->State.steering_angle_rad;
	Self->OutContacts = R->Telemetry.grounded_wheels;
	Self->OutTraction = R->Telemetry.mean_traction;
	Self->OutAccel = R->Telemetry.forward_acceleration_mps2;
	Self->OutVelX_mps = R->Telemetry.velocity_x_mps;
	Self->OutVelY_mps = R->Telemetry.velocity_y_mps;
}

void AHBVehicleBridge::Destroy()
{
	guard(AHBVehicleBridge::Destroy);
	if (NativeRuntime)
	{
		delete GetRuntime(this);
		NativeRuntime = NULL;
	}
	bReady = 0;
	Super::Destroy();
	unguard;
}

void AHBVehicleBridge::execNativeInit(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge::execNativeInit);
	P_FINISH;

	UBOOL Ok = 0;
	if (!NativeRuntime)
	{
		FHBVRuntime* R = new FHBVRuntime();
		appMemzero(R, sizeof(*R));
		HBV_DefaultConfig(&R->Config);
		HBV_Reset(&R->State);
		ClearInput(R->Input);
		appMemzero(&R->Telemetry, sizeof(R->Telemetry));
		NativeRuntime = (BYTE*)R;
	}
	if (NativeRuntime)
	{
		bReady = 1;
		SyncOutputs(this);
		Ok = 1;
	}
	*(UBOOL*)Result = Ok;
	unguardexec;
}

void AHBVehicleBridge::execNativeReset(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge::execNativeReset);
	P_FINISH;
	FHBVRuntime* R = GetRuntime(this);
	if (R)
	{
		HBV_Reset(&R->State);
		ClearInput(R->Input);
		appMemzero(&R->Telemetry, sizeof(R->Telemetry));
		SyncOutputs(this);
	}
	unguardexec;
}

void AHBVehicleBridge::execNativeSetPose(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge::execNativeSetPose);
	P_GET_FLOAT(PosX);
	P_GET_FLOAT(PosY);
	P_GET_FLOAT(FwdX);
	P_GET_FLOAT(FwdY);
	P_FINISH;

	FHBVRuntime* R = GetRuntime(this);
	if (!R) return;
	HBV_Reset(&R->State);
	R->State.pos_x_m = PosX;
	R->State.pos_y_m = PosY;
	{
		FLOAT n = appSqrt(FwdX * FwdX + FwdY * FwdY);
		if (n > 0.0001f)
		{
			R->State.forward_x = FwdX / n;
			R->State.forward_y = FwdY / n;
		}
		else
		{
			R->State.forward_x = 1.f;
			R->State.forward_y = 0.f;
		}
	}
	SyncOutputs(this);
	unguardexec;
}

void AHBVehicleBridge::execNativeSetControls(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge::execNativeSetControls);
	P_GET_FLOAT(Throttle);
	P_GET_FLOAT(Steering);
	P_GET_FLOAT(Brake);
	P_GET_FLOAT(Handbrake);
	P_FINISH;

	FHBVRuntime* R = GetRuntime(this);
	if (!R) return;
	R->Input.throttle = Throttle;
	R->Input.steering = Steering;
	R->Input.brake = Brake;
	R->Input.handbrake = Handbrake;
	unguardexec;
}

void AHBVehicleBridge::execNativeSetWheelContact(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge::execNativeSetWheelContact);
	P_GET_INT(WheelIndex);
	P_GET_FLOAT(Contact);
	P_GET_FLOAT(Grip);
	P_FINISH;

	FHBVRuntime* R = GetRuntime(this);
	if (!R) return;
	if (WheelIndex < 0 || WheelIndex >= 4) return;
	R->Input.wheel_contact[WheelIndex] = Contact;
	R->Input.wheel_grip[WheelIndex] = Grip;
	unguardexec;
}

void AHBVehicleBridge::execNativeStep(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge::execNativeStep);
	P_GET_FLOAT(DeltaSeconds);
	P_FINISH;

	UBOOL Ok = 0;
	FHBVRuntime* R = GetRuntime(this);
	if (R && bReady)
	{
		R->Input.delta_seconds = DeltaSeconds;
		if (HBV_Step(&R->Config, &R->Input, &R->State, &R->Telemetry))
		{
			SyncOutputs(this);
			Ok = 1;
		}
	}
	*(UBOOL*)Result = Ok;
	unguardexec;
}

/* ----------------------------- HBVehicleBridge3D ----------------------------- */

static FHBV3Runtime* GetRuntime3D(AHBVehicleBridge3D* Self)
{
	return Self ? (FHBV3Runtime*)Self->NativeRuntime : NULL;
}

static void SyncOutputs3D(AHBVehicleBridge3D* Self)
{
	FHBV3Runtime* R = GetRuntime3D(Self);
	FLOAT Yaw = 0.f, Pitch = 0.f, Roll = 0.f;
	if (!R) return;
	HBV3_GetOrientationEuler(&R->State, &Yaw, &Pitch, &Roll);
	Self->OutPosX_m = R->State.pos_x_m;
	Self->OutPosY_m = R->State.pos_y_m;
	Self->OutPosZ_m = R->State.pos_z_m;
	Self->OutVelX_mps = R->State.vel_x_mps;
	Self->OutVelY_mps = R->State.vel_y_mps;
	Self->OutVelZ_mps = R->State.vel_z_mps;
	Self->OutYaw_rad = Yaw;
	Self->OutPitch_rad = Pitch;
	Self->OutRoll_rad = Roll;
	Self->OutQuatW = R->State.quat_w;
	Self->OutQuatX = R->State.quat_x;
	Self->OutQuatY = R->State.quat_y;
	Self->OutQuatZ = R->State.quat_z;
	Self->OutAngX_radps = R->State.ang_x_radps;
	Self->OutAngY_radps = R->State.ang_y_radps;
	Self->OutAngZ_radps = R->State.ang_z_radps;
	Self->OutSpeed_mps = R->Telemetry.speed_mps;
	Self->OutContacts = R->Telemetry.contact_count;
	Self->OutUniqueContacts = R->Telemetry.unique_contact_count;
	Self->OutSolverIterations = R->Telemetry.solver_iterations;
	Self->OutAngularSpeed_radps = R->Telemetry.angular_speed_radps;
	Self->OutMaxPen_m = R->Telemetry.max_penetration_m;
	Self->OutOverload = R->Telemetry.overload_substeps;
	Self->OutAPIVersion = (FLOAT)HBV3_GetAPIVersion();
	Self->OutWheel0Length_m = R->SuspensionOutputs[0].length_m;
	Self->OutWheel0Compression_m = R->SuspensionOutputs[0].compression_m;
	Self->OutWheel0Spring_N = R->SuspensionOutputs[0].spring_force_n;
	Self->OutWheel0Damper_N = R->SuspensionOutputs[0].damper_force_n;
	Self->OutWheel0NormalLoad_N = R->SuspensionOutputs[0].normal_load_n;
	Self->OutWheel0Status = (FLOAT)R->SuspensionOutputs[0].status;
	Self->OutWheel1Length_m = R->SuspensionOutputs[1].length_m;
	Self->OutWheel1Compression_m = R->SuspensionOutputs[1].compression_m;
	Self->OutWheel1Spring_N = R->SuspensionOutputs[1].spring_force_n;
	Self->OutWheel1Damper_N = R->SuspensionOutputs[1].damper_force_n;
	Self->OutWheel1NormalLoad_N = R->SuspensionOutputs[1].normal_load_n;
	Self->OutWheel1Status = (FLOAT)R->SuspensionOutputs[1].status;
	Self->OutWheel2Length_m = R->SuspensionOutputs[2].length_m;
	Self->OutWheel2Compression_m = R->SuspensionOutputs[2].compression_m;
	Self->OutWheel2Spring_N = R->SuspensionOutputs[2].spring_force_n;
	Self->OutWheel2Damper_N = R->SuspensionOutputs[2].damper_force_n;
	Self->OutWheel2NormalLoad_N = R->SuspensionOutputs[2].normal_load_n;
	Self->OutWheel2Status = (FLOAT)R->SuspensionOutputs[2].status;
	Self->OutWheel3Length_m = R->SuspensionOutputs[3].length_m;
	Self->OutWheel3Compression_m = R->SuspensionOutputs[3].compression_m;
	Self->OutWheel3Spring_N = R->SuspensionOutputs[3].spring_force_n;
	Self->OutWheel3Damper_N = R->SuspensionOutputs[3].damper_force_n;
	Self->OutWheel3NormalLoad_N = R->SuspensionOutputs[3].normal_load_n;
	Self->OutWheel3Status = (FLOAT)R->SuspensionOutputs[3].status;
}

void AHBVehicleBridge3D::Destroy()
{
	guard(AHBVehicleBridge3D::Destroy);
	if (NativeRuntime)
	{
		delete GetRuntime3D(this);
		NativeRuntime = NULL;
	}
	bReady = 0;
	Super::Destroy();
	unguard;
}

void AHBVehicleBridge3D::execNativeInit(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeInit);
	P_GET_FLOAT(MassKg);
	P_GET_FLOAT(HalfX);
	P_GET_FLOAT(HalfY);
	P_GET_FLOAT(HalfZ);
	P_FINISH;

	UBOOL Ok = 0;
	OutAPIVersion = (FLOAT)HBV3_GetAPIVersion();
	bReady = 0;
	if (HBV3_GetAPIVersion() != 3u)
	{
		*(UBOOL*)Result = 0;
		return;
	}
	if (!NativeRuntime)
	{
		FHBV3Runtime* R = new FHBV3Runtime();
		appMemzero(R, sizeof(*R));
		HBV3_DefaultConfig(&R->Config);
		HBV3_Reset(&R->State);
		R->SuspensionPrepared = 0;
		R->ContactCount = 0;
		R->ContactOverflow = 0;
		appMemzero(R->SuspensionConfigs, sizeof(R->SuspensionConfigs));
		appMemzero(R->SuspensionHits, sizeof(R->SuspensionHits));
		appMemzero(R->SuspensionOutputs, sizeof(R->SuspensionOutputs));
		appMemzero(R->SuspensionConfigured, sizeof(R->SuspensionConfigured));
		NativeRuntime = (BYTE*)R;
	}
	{
		FHBV3Runtime* R = GetRuntime3D(this);
		if (R)
		{
			R->SuspensionPrepared = 0;
			if (HBV3_ConfigureBox(&R->Config, MassKg, HalfX, HalfY, HalfZ))
			{
				bReady = 1;
				SyncOutputs3D(this);
				Ok = 1;
			}
		}
	}
	*(UBOOL*)Result = Ok;
	unguardexec;
}

void AHBVehicleBridge3D::execNativeReset(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeReset);
	P_FINISH;
	FHBV3Runtime* R = GetRuntime3D(this);
	if (R)
	{
		HBV3_Reset(&R->State);
		R->SuspensionPrepared = 0;
		R->ContactCount = 0;
		R->ContactOverflow = 0;
		appMemzero(R->SuspensionHits, sizeof(R->SuspensionHits));
		appMemzero(R->SuspensionOutputs, sizeof(R->SuspensionOutputs));
		appMemzero(&R->Telemetry, sizeof(R->Telemetry));
		SyncOutputs3D(this);
	}
	unguardexec;
}

void AHBVehicleBridge3D::execNativeSetGravity(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeSetGravity);
	P_GET_FLOAT(Gx);
	P_GET_FLOAT(Gy);
	P_GET_FLOAT(Gz);
	P_FINISH;
	FHBV3Runtime* R = GetRuntime3D(this);
	if (!R) return;
	R->Config.gravity_x = Gx;
	R->Config.gravity_y = Gy;
	R->Config.gravity_z = Gz;
	unguardexec;
}

void AHBVehicleBridge3D::execNativeSetState(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeSetState);
	P_GET_FLOAT(Px);
	P_GET_FLOAT(Py);
	P_GET_FLOAT(Pz);
	P_GET_FLOAT(Vx);
	P_GET_FLOAT(Vy);
	P_GET_FLOAT(Vz);
	P_GET_FLOAT(Yaw);
	P_GET_FLOAT(Pitch);
	P_GET_FLOAT(Roll);
	P_FINISH;
	FHBV3Runtime* R = GetRuntime3D(this);
	HBV3_State Candidate;
	if (!R) return;
	Candidate = R->State;
	Candidate.pos_x_m = Px;
	Candidate.pos_y_m = Py;
	Candidate.pos_z_m = Pz;
	Candidate.vel_x_mps = Vx;
	Candidate.vel_y_mps = Vy;
	Candidate.vel_z_mps = Vz;
	if (HBV3_SetOrientationEuler(&Candidate, Yaw, Pitch, Roll) &&
		HBV3_SetStateValidated(&R->State, &Candidate))
	{
		R->SuspensionPrepared = 0;
		SyncOutputs3D(this);
	}
	unguardexec;
}

void AHBVehicleBridge3D::execNativeSetRigidState(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeSetRigidState);
	P_GET_FLOAT(Px); P_GET_FLOAT(Py); P_GET_FLOAT(Pz);
	P_GET_FLOAT(Vx); P_GET_FLOAT(Vy); P_GET_FLOAT(Vz);
	P_GET_FLOAT(Qw); P_GET_FLOAT(Qx); P_GET_FLOAT(Qy); P_GET_FLOAT(Qz);
	P_GET_FLOAT(Wx); P_GET_FLOAT(Wy); P_GET_FLOAT(Wz);
	P_FINISH;
	UBOOL Ok = 0;
	FHBV3Runtime* R = GetRuntime3D(this);
	if (R)
	{
		HBV3_State Candidate = R->State;
		Candidate.pos_x_m = Px; Candidate.pos_y_m = Py; Candidate.pos_z_m = Pz;
		Candidate.vel_x_mps = Vx; Candidate.vel_y_mps = Vy; Candidate.vel_z_mps = Vz;
		Candidate.quat_w = Qw; Candidate.quat_x = Qx;
		Candidate.quat_y = Qy; Candidate.quat_z = Qz;
		Candidate.ang_x_radps = Wx; Candidate.ang_y_radps = Wy;
		Candidate.ang_z_radps = Wz;
		if (HBV3_SetStateValidated(&R->State, &Candidate))
		{
			R->SuspensionPrepared = 0;
			SyncOutputs3D(this);
			Ok = 1;
		}
	}
	*(UBOOL*)Result = Ok;
	unguardexec;
}

void AHBVehicleBridge3D::execNativeClearContacts(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeClearContacts);
	P_FINISH;
	FHBV3Runtime* R = GetRuntime3D(this);
	if (!R) return;
	R->ContactCount = 0;
	R->ContactOverflow = 0;
	unguardexec;
}

void AHBVehicleBridge3D::execNativeAddContact(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeAddContact);
	P_GET_FLOAT(Nx);
	P_GET_FLOAT(Ny);
	P_GET_FLOAT(Nz);
	P_GET_FLOAT(Pen);
	P_GET_FLOAT(Rest);
	P_GET_FLOAT(Fric);
	P_FINISH;
	FHBV3Runtime* R = GetRuntime3D(this);
	if (!R) return;
	if (R->ContactCount >= HBV3_MAX_CONTACTS)
	{
		R->ContactOverflow = 1;
		return;
	}
	{
		HBV3_Contact& C = R->Contacts[R->ContactCount++];
		appMemzero(&C, sizeof(C));
		C.point_x_m = R->State.pos_x_m;
		C.point_y_m = R->State.pos_y_m;
		C.point_z_m = R->State.pos_z_m;
		C.nx = Nx; C.ny = Ny; C.nz = Nz;
		C.penetration_m = Pen;
		C.restitution = Rest;
		C.friction = Fric;
		C.feature_id = (unsigned int)R->ContactCount;
	}
	unguardexec;
}

void AHBVehicleBridge3D::execNativeAddContactAtPoint(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeAddContactAtPoint);
	P_GET_FLOAT(Px); P_GET_FLOAT(Py); P_GET_FLOAT(Pz);
	P_GET_FLOAT(Nx); P_GET_FLOAT(Ny); P_GET_FLOAT(Nz);
	P_GET_FLOAT(Pen); P_GET_FLOAT(Rest); P_GET_FLOAT(Fric);
	P_GET_FLOAT(SurfaceVx); P_GET_FLOAT(SurfaceVy); P_GET_FLOAT(SurfaceVz);
	P_GET_INT(FeatureId);
	P_FINISH;
	FHBV3Runtime* R = GetRuntime3D(this);
	if (!R) return;
	if (R->ContactCount >= HBV3_MAX_CONTACTS)
	{
		R->ContactOverflow = 1;
		return;
	}
	{
		HBV3_Contact& C = R->Contacts[R->ContactCount++];
		appMemzero(&C, sizeof(C));
		C.point_x_m = Px; C.point_y_m = Py; C.point_z_m = Pz;
		C.nx = Nx; C.ny = Ny; C.nz = Nz;
		C.penetration_m = Pen; C.restitution = Rest; C.friction = Fric;
		C.surface_vel_x_mps = SurfaceVx;
		C.surface_vel_y_mps = SurfaceVy;
		C.surface_vel_z_mps = SurfaceVz;
		C.feature_id = FeatureId > 0 ? (unsigned int)FeatureId : 0u;
	}
	unguardexec;
}

void AHBVehicleBridge3D::execNativeApplyImpulseAtPoint(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeApplyImpulseAtPoint);
	P_GET_FLOAT(Jx); P_GET_FLOAT(Jy); P_GET_FLOAT(Jz);
	P_GET_FLOAT(Px); P_GET_FLOAT(Py); P_GET_FLOAT(Pz);
	P_FINISH;
	UBOOL Ok = 0;
	FHBV3Runtime* R = GetRuntime3D(this);
	if (R && HBV3_ApplyImpulseAtPoint(&R->Config, &R->State,
		Jx, Jy, Jz, Px, Py, Pz))
	{
		SyncOutputs3D(this);
		Ok = 1;
	}
	*(UBOOL*)Result = Ok;
	unguardexec;
}

void AHBVehicleBridge3D::execNativeConfigureSuspensionPoint(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeConfigureSuspensionPoint);
	P_GET_INT(WheelIndex);
	P_GET_FLOAT(Ax); P_GET_FLOAT(Ay); P_GET_FLOAT(Az);
	P_GET_FLOAT(AxisX); P_GET_FLOAT(AxisY); P_GET_FLOAT(AxisZ);
	P_GET_FLOAT(RestLength); P_GET_FLOAT(MinLength); P_GET_FLOAT(MaxLength);
	P_GET_FLOAT(Spring); P_GET_FLOAT(DamperCompression);
	P_GET_FLOAT(DamperRebound); P_GET_FLOAT(BumpStop);
	P_GET_FLOAT(MinNormalAlignment);
	P_FINISH;
	UBOOL Ok = 0;
	FHBV3Runtime* R = GetRuntime3D(this);
	if (R && WheelIndex >= 0 && WheelIndex < HBV3_SUSPENSION_POINTS)
	{
		HBV3_SuspensionConfig C;
		appMemzero(&C, sizeof(C));
		C.attachment_x_m = Ax; C.attachment_y_m = Ay; C.attachment_z_m = Az;
		C.axis_x_down = AxisX; C.axis_y_down = AxisY; C.axis_z_down = AxisZ;
		C.rest_length_m = RestLength; C.min_length_m = MinLength;
		C.max_length_m = MaxLength; C.spring_n_per_m = Spring;
		C.damper_compression_ns_per_m = DamperCompression;
		C.damper_rebound_ns_per_m = DamperRebound;
		C.bump_stop_n_per_m = BumpStop;
		C.min_normal_alignment = MinNormalAlignment;
		if (HBV3_ValidateSuspensionConfig(&C))
		{
			R->SuspensionPrepared = 0;
			R->SuspensionConfigs[WheelIndex] = C;
			R->SuspensionConfigured[WheelIndex] = 1;
			appMemzero(&R->SuspensionHits[WheelIndex],
				sizeof(R->SuspensionHits[WheelIndex]));
			appMemzero(&R->SuspensionOutputs[WheelIndex],
				sizeof(R->SuspensionOutputs[WheelIndex]));
			Ok = 1;
		}
	}
	*(UBOOL*)Result = Ok;
	unguardexec;
}

void AHBVehicleBridge3D::execNativeClearSuspensionHits(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeClearSuspensionHits);
	P_FINISH;
	FHBV3Runtime* R = GetRuntime3D(this);
	if (R)
	{
		R->SuspensionPrepared = 0;
		appMemzero(R->SuspensionHits, sizeof(R->SuspensionHits));
	}
	unguardexec;
}

void AHBVehicleBridge3D::execNativeSetSuspensionHit(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeSetSuspensionHit);
	P_GET_INT(WheelIndex); P_GET_INT(ContactActive); P_GET_FLOAT(Length);
	P_GET_FLOAT(PointX); P_GET_FLOAT(PointY); P_GET_FLOAT(PointZ);
	P_GET_FLOAT(Nx); P_GET_FLOAT(Ny); P_GET_FLOAT(Nz);
	P_GET_FLOAT(SurfaceVx); P_GET_FLOAT(SurfaceVy); P_GET_FLOAT(SurfaceVz);
	P_GET_INT(FeatureId);
	P_FINISH;
	UBOOL Ok = 0;
	FHBV3Runtime* R = GetRuntime3D(this);
	if (R && WheelIndex >= 0 && WheelIndex < HBV3_SUSPENSION_POINTS &&
		(ContactActive == 0 || ContactActive == 1))
	{
		HBV3_SuspensionHit H;
		appMemzero(&H, sizeof(H));
		H.has_contact = ContactActive;
		H.length_m = Length;
		H.point_x_m = PointX; H.point_y_m = PointY; H.point_z_m = PointZ;
		H.nx = Nx; H.ny = Ny; H.nz = Nz;
		H.surface_vel_x_mps = SurfaceVx;
		H.surface_vel_y_mps = SurfaceVy;
		H.surface_vel_z_mps = SurfaceVz;
		H.feature_id = FeatureId > 0 ? (unsigned int)FeatureId : 0u;
		R->SuspensionPrepared = 0;
		R->SuspensionHits[WheelIndex] = H;
		Ok = 1;
	}
	*(UBOOL*)Result = Ok;
	unguardexec;
}

static UBOOL SuspensionConfigured(const FHBV3Runtime* R)
{
	for (INT i = 0; i < HBV3_SUSPENSION_POINTS; ++i)
		if (!R->SuspensionConfigured[i]) return 0;
	return 1;
}

void AHBVehicleBridge3D::execNativePrepareSuspension(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativePrepareSuspension);
	P_FINISH;
	FHBV3Runtime* R = GetRuntime3D(this);
	UBOOL Ok = 0;
	if (R && bReady)
	{
		R->SuspensionPrepared = SuspensionConfigured(R) &&
			HBV3_EvaluateSuspension(&R->State, R->SuspensionConfigs,
				R->SuspensionHits, R->SuspensionOutputs, &R->PreparedSuspension);
		Ok = R->SuspensionPrepared;
		if (Ok) SyncOutputs3D(this);
	}
	*(UBOOL*)Result = Ok;
	unguardexec;
}

void AHBVehicleBridge3D::execNativeStepSuspended(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeStepSuspended);
	P_GET_FLOAT(DeltaSeconds);
	P_FINISH;
	UBOOL Ok = 0;
	FHBV3Runtime* R = GetRuntime3D(this);
	if (R && bReady)
	{
		UBOOL StepOk = 0;
		if (!R->ContactOverflow)
		{
			// Tyre and anti-roll impulses are applied between preparation and
			// integration. Both use the same pre-impulse suspension sample.
			if (R->SuspensionPrepared)
				StepOk = hb3_step_with_suspension(&R->Config, &R->State,
					R->Contacts, R->ContactCount, DeltaSeconds, &R->Telemetry,
					&R->PreparedSuspension);
			else if (SuspensionConfigured(R))
				StepOk = HBV3_StepSuspended(&R->Config, &R->State,
					R->Contacts, R->ContactCount, R->SuspensionConfigs,
					R->SuspensionHits, DeltaSeconds, &R->Telemetry,
					R->SuspensionOutputs);
		}
		R->SuspensionPrepared = 0;
		R->ContactCount = 0;
		R->ContactOverflow = 0;
		appMemzero(R->SuspensionHits, sizeof(R->SuspensionHits));
		if (StepOk)
		{
			SyncOutputs3D(this);
			Ok = 1;
		}
	}
	*(UBOOL*)Result = Ok;
	unguardexec;
}

void AHBVehicleBridge3D::execNativeStep(FFrame& Stack, RESULT_DECL)
{
	guard(AHBVehicleBridge3D::execNativeStep);
	P_GET_FLOAT(DeltaSeconds);
	P_FINISH;
	UBOOL Ok = 0;
	FHBV3Runtime* R = GetRuntime3D(this);
	if (R && bReady)
	{
		R->SuspensionPrepared = 0;
		UBOOL StepOk = !R->ContactOverflow &&
			HBV3_Step(&R->Config, &R->State,
				R->Contacts, R->ContactCount, DeltaSeconds, &R->Telemetry);
		R->ContactCount = 0;
		R->ContactOverflow = 0;
		if (StepOk)
		{
			SyncOutputs3D(this);
			Ok = 1;
		}
	}
	*(UBOOL*)Result = Ok;
	unguardexec;
}
