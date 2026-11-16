//=============================================================================
// HBVehicleBridge3D — UnrealScript ↔ HBVehicleCore3D (metres/kg/s).
// Keeps HBVehicleBridge (2D) untouched. No PhysX.
//=============================================================================
class HBVehicleBridge3D expands Info
	native
	NoUserCreate;

var pointer<BYTE*> NativeRuntime;

var float OutPosX_m, OutPosY_m, OutPosZ_m;
var float OutVelX_mps, OutVelY_mps, OutVelZ_mps;
var float OutYaw_rad, OutPitch_rad, OutRoll_rad;
var float OutQuatW, OutQuatX, OutQuatY, OutQuatZ;
var float OutAngX_radps, OutAngY_radps, OutAngZ_radps;
var float OutSpeed_mps;
var float OutContacts;
var float OutUniqueContacts;
var float OutSolverIterations;
var float OutAngularSpeed_radps;
var float OutMaxPen_m;
var float OutOverload;
var bool  bReady;
// Appended in P0.6 so legacy field offsets remain stable; NativeInit requires 2.
var float OutAPIVersion;
// P1 per-wheel telemetry. Kept as explicit scalars for stable 227k native layout.
var float OutWheel0Length_m, OutWheel0Compression_m, OutWheel0Spring_N;
var float OutWheel0Damper_N, OutWheel0NormalLoad_N, OutWheel0Status;
var float OutWheel1Length_m, OutWheel1Compression_m, OutWheel1Spring_N;
var float OutWheel1Damper_N, OutWheel1NormalLoad_N, OutWheel1Status;
var float OutWheel2Length_m, OutWheel2Compression_m, OutWheel2Spring_N;
var float OutWheel2Damper_N, OutWheel2NormalLoad_N, OutWheel2Status;
var float OutWheel3Length_m, OutWheel3Compression_m, OutWheel3Spring_N;
var float OutWheel3Damper_N, OutWheel3NormalLoad_N, OutWheel3Status;

native final function bool NativeInit(float MassKg, float HalfX_m, float HalfY_m, float HalfZ_m);
native final function NativeReset();
native final function NativeSetGravity(float Gx, float Gy, float Gz);
native final function NativeSetState(
	float Px, float Py, float Pz,
	float Vx, float Vy, float Vz,
	float Yaw, float Pitch, float Roll);
native final function bool NativeSetRigidState(
	float Px, float Py, float Pz,
	float Vx, float Vy, float Vz,
	float Qw, float Qx, float Qy, float Qz,
	float Wx, float Wy, float Wz);
native final function NativeClearContacts();
native final function NativeAddContact(
	float Nx, float Ny, float Nz,
	float Penetration_m, float Restitution, float Friction);
native final function NativeAddContactAtPoint(
	float Px, float Py, float Pz,
	float Nx, float Ny, float Nz,
	float Penetration_m, float Restitution, float Friction,
	float SurfaceVx_mps, float SurfaceVy_mps, float SurfaceVz_mps,
	int FeatureId);
native final function bool NativeApplyImpulseAtPoint(
	float Jx_Ns, float Jy_Ns, float Jz_Ns,
	float Px_m, float Py_m, float Pz_m);
native final function bool NativeStep(float DeltaSeconds);
native final function bool NativeConfigureSuspensionPoint(
	int WheelIndex,
	float Ax_m, float Ay_m, float Az_m,
	float AxisXDown, float AxisYDown, float AxisZDown,
	float RestLength_m, float MinLength_m, float MaxLength_m,
	float Spring_Npm, float DamperCompression_Nspm,
	float DamperRebound_Nspm, float BumpStop_Npm,
	float MinNormalAlignment);
native final function NativeClearSuspensionHits();
native final function bool NativeSetSuspensionHit(
	int WheelIndex, int ContactActive, float Length_m,
	float PointX_m, float PointY_m, float PointZ_m,
	float Nx, float Ny, float Nz,
	float SurfaceVx_mps, float SurfaceVy_mps, float SurfaceVz_mps,
	int FeatureId);
native final function bool NativePrepareSuspension();
native final function bool NativeStepSuspended(float DeltaSeconds);

cpptext
{
	void Destroy();
}

defaultproperties
{
	bHidden=True
	bReady=False
}
