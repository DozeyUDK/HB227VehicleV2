//=============================================================================
// HBVehicleBridge - UnrealScript to HBVehicleCore C ABI bridge (227k native).
// Isolated POC. Does not touch Hellbender227 / PhysX / Engine.dll.
//=============================================================================
class HBVehicleBridge expands Info
	native
	NoUserCreate;

// Opaque heap runtime (HBV_Config/State/Input/Telemetry). Freed in Destroy.
var pointer<BYTE*> NativeRuntime;

// Telemetry mirrored out of the native core after each successful NativeStep.
var float OutPosX_m;
var float OutPosY_m;
var float OutForwardX;
var float OutForwardY;
var float OutSpeed_mps;
var float OutLateralSpeed_mps;
var float OutYawRate_radps;
var float OutSteerRad;
var float OutContacts;
var float OutTraction;
var float OutAccel;
var float OutVelX_mps;
var float OutVelY_mps;
var bool  bReady;

native final function bool NativeInit();
native final function NativeReset();
native final function NativeSetPose(float PosX_m, float PosY_m, float FwdX, float FwdY);
native final function NativeSetControls(float Throttle, float Steering, float Brake, float Handbrake);
native final function NativeSetWheelContact(int WheelIndex, float Contact, float Grip);
native final function bool NativeStep(float DeltaSeconds);

cpptext
{
	void Destroy();
}

defaultproperties
{
	bHidden=True
	bReady=False
	OutForwardX=1.0
	OutForwardY=0.0
}