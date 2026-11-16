//=============================================================================
// HB2Driver — spawn + follow body (pattern from Raycast backup Driver).
//=============================================================================
class HB2Driver expands PlayerPawn;

var HB2Body Body;
var HB2Input DriveIX;
var bool bEntered;
var() bool bInvertThrottleAxis;
var() bool bInvertSteerAxis;

// P1.1 authoritative chase camera. Yaw is stored as a float in Unreal
// rotator units so smoothing does not quantize each frame.
var() float CameraDistanceUU;
var() float CameraHeightUU;
var() float CameraTargetHeightUU;
var() float CameraYawFollowRate;
var() float CameraMaxYawRateUU;
var() float CameraTargetFollowRate;
var() float CameraCollisionReleaseRate;
var() float CameraCollisionPaddingUU;
var() float CameraCollisionHoldSeconds;
var() float CameraMinArmUU;
var() float CameraTeleportDistanceUU;
var bool bCameraInitialized;
var float CameraYawUU;
var float CameraArmUU;
var float CameraLastUpdateTime;
var float CameraCollisionHoldUntil;
var float NextCameraLogTime;
var vector CameraTargetUU;
var vector CameraLastBodyLocation;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0.25, True);
}

function Timer()
{
	if (Body == None)
		FindOrSpawnBody();
	if (Body != None && !bEntered)
		EnterBody();
}

function bool TryFloorSpawn(vector ProbeXY, out vector SpawnLoc)
{
	local vector Start, End, HitLoc, HitNorm, Delta;
	local Actor Hit;

	Start = ProbeXY + vect(0,0,280);
	End = ProbeXY - vect(0,0,500);
	Hit = Trace(HitLoc, HitNorm, End, Start, False);
	if (Hit == None)
		return False;
	if (HitNorm.Z <= 0.7)
		return False;
	Delta = HitLoc - ProbeXY;
	Delta.Z = 0;
	if (VSize(Delta) > 250)
		return False;
	SpawnLoc = HitLoc + HitNorm * 90;
	return True;
}

function FindOrSpawnBody()
{
	local HB2Body B;
	local vector SpawnLoc, Fwd, Probe;
	local rotator SpawnRot;
	local int i;
	local float Dist;
	local string Path;

	foreach AllActors(class'HB2Body', B)
	{
		Body = B;
		return;
	}

	Fwd = vector(Rotation);
	Fwd.Z = 0;
	if (VSize(Fwd) < 0.1)
		Fwd = vect(1,0,0);
	else
		Fwd = Normal(Fwd);

	SpawnLoc = vect(0,0,0);
	Path = "none";
	for (i = 0; i < 4; ++i)
	{
		if (i == 0) Dist = 280;
		else if (i == 1) Dist = 160;
		else if (i == 2) Dist = 80;
		else Dist = 0;
		Probe = Location + Fwd * Dist;
		Probe.Z = Location.Z;
		if (TryFloorSpawn(Probe, SpawnLoc))
		{
			Path = "floor";
			break;
		}
	}
	if (Path == "none")
	{
		SpawnLoc = Location + Fwd * 180;
		SpawnLoc.Z = Location.Z + 160;
		Path = "player_offset";
	}

	SpawnRot.Yaw = Rotation.Yaw;
	Body = Spawn(class'HB2Body',,, SpawnLoc, SpawnRot);
	if (Body == None)
		Warn("HB2: body spawn FAILED");
	else
		Log("HB2: spawned body="$Body$" path="$Path$" at="$Body.Location);
}

function EnterBody()
{
	if (Body == None)
		return;
	bEntered = True;
	bHidden = True;
	bBehindView = True;
	SetCollision(False, False, False);
	bCollideWorld = False;
	SetPhysics(PHYS_None);
	Health = 9999;
	ReducedDamageType = 'God';
	Body.SetCrushDriver(Self);
	DriveIX = HB2Input(AddInteraction(class'HB2Input', True));
	if (DriveIX != None)
		DriveIX.AttachToBody(Body, Self);
	else
		Warn("HB2: AddInteraction(HB2Input) FAILED — WASD will not work");
	FitCameraToChassis();
	ResetBodyCamera("enter");
	Log("HB2: player entered "$Body$" input="$DriveIX$" bEntered="$bEntered
		$" crushInstigator="$Body.Instigator);
}

function float WrapCameraYaw(float YawUU)
{
	while (YawUU < 0.0)
		YawUU += 65536.0;
	while (YawUU >= 65536.0)
		YawUU -= 65536.0;
	return YawUU;
}

function float ShortestCameraYawDelta(float TargetYawUU, float FromYawUU)
{
	local float Delta;
	Delta = WrapCameraYaw(TargetYawUU) - WrapCameraYaw(FromYawUU);
	if (Delta > 32768.0)
		Delta -= 65536.0;
	else if (Delta < -32768.0)
		Delta += 65536.0;
	return Delta;
}

function FitCameraToChassis()
{
	if (Body == None)
		return;
	CameraDistanceUU = FMax(280.0, Body.ChassisHalfUU.X * 2.6 + 90.0);
	CameraHeightUU = FMax(80.0, Body.ChassisHalfUU.Z * 2.8 + 50.0);
	CameraTargetHeightUU = FMax(60.0, Body.ChassisHalfUU.Z * 1.8);
	CameraMinArmUU = FMax(45.0, Body.ChassisHalfUU.Z + 24.0);
	Log("HB2_CAMERA fit dist="$CameraDistanceUU$" height="$CameraHeightUU
		$" targetZ="$CameraTargetHeightUU$" half="$Body.ChassisHalfUU);
}

function ResetBodyCamera(optional string Reason)
{
	bCameraInitialized = False;
	CameraLastUpdateTime = Level.TimeSeconds;
	CameraCollisionHoldUntil = 0.0;
	NextCameraLogTime = 0.0;
	if (Body != None)
		CameraLastBodyLocation = Body.Location;
	Log("HB2_CAMERA reset reason="$Reason);
}

function CalcBodyCamera(out vector CameraLocation, out rotator CameraRotation)
{
	local vector X, Y, Z, RawTarget, DesiredOffset, ArmDir, HitLoc, HitNorm;
	local Actor Hit;
	local rotator Flat;
	local float Now, Dt, Alpha, YawDelta, YawStep, MaxYawStep;
	local float FullArmUU, BlockedArmUU, BodyYawUU;
	local bool bBlocked, bTeleported;

	if (Body == None)
		return;

	Now = Level.TimeSeconds;
	Dt = FClamp(Now - CameraLastUpdateTime, 0.0, 0.1);
	bTeleported = bCameraInitialized
		&& VSize(Body.Location - CameraLastBodyLocation) > CameraTeleportDistanceUU;
	if (bTeleported)
	{
		Log("HB2_CAMERA teleport_snap deltaUU="
			$VSize(Body.Location - CameraLastBodyLocation));
		bCameraInitialized = False;
	}

	RawTarget = Body.Location + vect(0,0,1) * CameraTargetHeightUU;
	BodyYawUU = WrapCameraYaw(Body.Rotation.Yaw);
	if (!bCameraInitialized)
	{
		CameraYawUU = BodyYawUU;
		CameraTargetUU = RawTarget;
		CameraArmUU = VSize(vect(-1,0,0) * CameraDistanceUU
			+ vect(0,0,1) * CameraHeightUU);
		bCameraInitialized = True;
		Log("HB2_CAMERA init yawUU="$CameraYawUU$" target="$CameraTargetUU);
	}
	else
	{
		YawDelta = ShortestCameraYawDelta(BodyYawUU, CameraYawUU);
		Alpha = FClamp(CameraYawFollowRate * Dt, 0.0, 1.0);
		YawStep = YawDelta * Alpha;
		MaxYawStep = CameraMaxYawRateUU * Dt;
		YawStep = FClamp(YawStep, -MaxYawStep, MaxYawStep);
		CameraYawUU = WrapCameraYaw(CameraYawUU + YawStep);

		Alpha = FClamp(CameraTargetFollowRate * Dt, 0.0, 1.0);
		CameraTargetUU += (RawTarget - CameraTargetUU) * Alpha;
	}

	Flat.Yaw = int(CameraYawUU);
	Flat.Pitch = 0;
	Flat.Roll = 0;
	GetAxes(Flat, X, Y, Z);
	DesiredOffset = -X * CameraDistanceUU + vect(0,0,1) * CameraHeightUU;
	FullArmUU = VSize(DesiredOffset);
	if (FullArmUU < 1.0)
		FullArmUU = 1.0;
	ArmDir = DesiredOffset / FullArmUU;

	Hit = Trace(HitLoc, HitNorm,
		CameraTargetUU + ArmDir * FullArmUU, CameraTargetUU, False);
	if (Hit != None)
	{
		bBlocked = True;
		BlockedArmUU = FClamp(VSize(HitLoc - CameraTargetUU)
			- CameraCollisionPaddingUU, CameraMinArmUU, FullArmUU);
		// Contract immediately to remain in front of geometry. Keeping the
		// camera on ArmDir avoids sideways jumps from changing surface normals.
		if (BlockedArmUU < CameraArmUU)
			CameraArmUU = BlockedArmUU;
		CameraCollisionHoldUntil = Now + CameraCollisionHoldSeconds;
	}
	else if (Now >= CameraCollisionHoldUntil)
	{
		// Release slowly after an obstruction so one-frame trace changes do not
		// throw the camera back to full distance.
		Alpha = FClamp(CameraCollisionReleaseRate * Dt, 0.0, 1.0);
		CameraArmUU += (FullArmUU - CameraArmUU) * Alpha;
	}
	CameraArmUU = FClamp(CameraArmUU, CameraMinArmUU, FullArmUU);
	CameraLocation = CameraTargetUU + ArmDir * CameraArmUU;
	CameraRotation = rotator(CameraTargetUU - CameraLocation);
	CameraRotation.Roll = 0;

	if (Abs(Body.LastSteer) > 0.05 && Now >= NextCameraLogTime)
	{
		NextCameraLogTime = Now + 0.5;
		Log("HB2_CAMERA t="$Now$" bodyYawUU="$BodyYawUU
			$" cameraYawUU="$CameraYawUU
			$" shortestDeltaUU="$ShortestCameraYawDelta(BodyYawUU, CameraYawUU)
			$" armUU="$CameraArmUU$" blocked="$bBlocked);
	}

	CameraLastUpdateTime = Now;
	CameraLastBodyLocation = Body.Location;
}

function bool NeedBody()
{
	if (Body == None || Body.bDeleteMe)
	{
		ClientMessage("HB2: no body");
		return False;
	}
	return True;
}

exec function HB2Help()
{
	ClientMessage("HB2: HB2Dump HB2Reset HB2Physics HB2Collision HB2Impulse HB2SteerMode HB2Wheels HB2Test HB2Obstacles");
	ClientMessage("HB2: HB2AntiRoll HB2Torque4WD toggles (manual testing only)");
	ClientMessage("HB2: WASD drive (W/S gas, A/D front steer in p2_tires), Space/Duck brake, F3 HUD");
}

// P2.6b A/B test without recompilation: physical StaticMesh contacts from
// front-of-wheel probe rays. Visual wheel positions are unchanged.
exec function HB2AntiRoll()
{
    if (!NeedBody()) return;
    Body.bAntiRollEnabled = !Body.bAntiRollEnabled;
    ClientMessage("HB2 anti-roll="$Body.bAntiRollEnabled);
    Log("HB2_ANTIROLL_TOGGLE t="$Level.TimeSeconds$" enabled="$Body.bAntiRollEnabled);
}

exec function HB2Torque4WD()
{
    if (!NeedBody()) return;
    Body.bTorque4WDEnabled = !Body.bTorque4WDEnabled;
    ClientMessage("HB2 torque 4WD="$Body.bTorque4WDEnabled);
    Log("HB2_TORQUE4WD_TOGGLE t="$Level.TimeSeconds$" enabled="$Body.bTorque4WDEnabled);
}

exec function HB2Obstacles()
{
	if (!NeedBody()) return;
	Body.bWheelObstacleContactsEnabled = !Body.bWheelObstacleContactsEnabled;
	ClientMessage("HB2 wheel obstacle collisions="$Body.bWheelObstacleContactsEnabled
		$" contacts="$Body.WheelObstacleContactCount
		$" total="$Body.WheelObstacleContactTotal);
	Log("HB2_P26B TOGGLE enabled="$Body.bWheelObstacleContactsEnabled
		$" t="$Level.TimeSeconds);
}

exec function HB2Wheels()
{
	if (!NeedBody()) return;
	if (Body.bVisualWheelsEnabled)
	{
		Body.bVisualWheelsEnabled = False;
		Body.DestroyVisualWheels();
		ClientMessage("HB2 visual wheels OFF");
	}
	else
	{
		Body.bVisualWheelsEnabled = True;
		Body.SpawnVisualWheels();
		ClientMessage("HB2 visual wheels ON");
	}
	Log("HB2_VIS_WHEELS enabled="$Body.bVisualWheelsEnabled);
}

exec function HB2Dump()
{
	if (!NeedBody()) return;
	ClientMessage("HB2 loc="$Body.Location$" vel="$Body.Velocity$" contacts="$Body.ContactCount$" hit="$Body.LastHitKind$" pen="$Body.LastMaxPenUU$" gas="$Body.LastGas$" str="$Body.LastSteer);
	Log("HB2_DUMP loc="$Body.Location$" vel="$Body.Velocity$" contacts="$Body.ContactCount$" hit="$Body.LastHitKind$" mode="$Body.SteerMode);
}

exec function HB2Reset()
{
	if (!NeedBody()) return;
	if (Body.RecoverUpright())
	{
		ResetBodyCamera("HB2Reset");
		ClientMessage("HB2 reset upright yaw="$Body.Core.OutYaw_rad
			$" pitch="$Body.Core.OutPitch_rad$" roll="$Body.Core.OutRoll_rad);
	}
	else
	{
		ClientMessage("HB2 reset FAILED "$Body.LastRecoverReason, 'Event');
		Warn("HB2_RESET player-facing fail reason="$Body.LastRecoverReason);
	}
}

exec function HB2Physics()
{
	if (!NeedBody()) return;
	ClientMessage("HB2 mass="$Body.MassKg$" profile="$Body.ChassisProfile$" half="$Body.ChassisHalfUU$" rest="$Body.Restitution$" fric="$Body.Friction$" core="$Body.Core.bReady);
	if (Body.Vis != None)
		ClientMessage("HB2 vis mesh="$Body.Vis.MeshName$" size="$Body.Vis.MeshLocalSize$" scale="$Body.Vis.DrawScale$" pivot="$Body.Vis.PrePivot);
}

exec function HB2Collision()
{
	if (!NeedBody()) return;
	ClientMessage("HB2 hit="$Body.LastHitKind$" actor="$Body.LastHitActor$" penUU="$Body.LastMaxPenUU$" contacts="$Body.ContactCount);
}

exec function HB2Impulse(float Vx, float Vy, float Vz)
{
	local vector Imp;
	if (!NeedBody()) return;
	Imp.X = Vx; Imp.Y = Vy; Imp.Z = Vz;
	Body.ImpulseUU(Imp);
	ClientMessage("HB2 impulse "$Vx$","$Vy$","$Vz);
}

exec function HB2SteerMode(optional int Mode)
{
	if (!NeedBody()) return;
	if (Mode == 0)
		Body.SteerMode = "yaw";
	else if (Mode == 1)
		Body.SteerMode = "strafe_diag";
	else if (Body.SteerMode == "yaw")
		Body.SteerMode = "strafe_diag";
	else
		Body.SteerMode = "yaw";
	ClientMessage("HB2 SteerMode="$Body.SteerMode$" (0=yaw steer, 1=P0 strafe diag)");
	Log("HB2_STEERMODE "$Body.SteerMode);
}

exec function HB2Test()
{
	ClientMessage("HB2 auto: Launch-HB227VehicleV2-P0.cmd  manual: Launch-HB227VehicleV2-Manual.cmd");
}

event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
	if (Body == None || !bEntered)
	{
		Super.PlayerCalcView(ViewActor, CameraLocation, CameraRotation);
		return;
	}
	// Authoritative camera path. HB2Input does not participate in CalcView.
	ViewActor = Body;
	CalcBodyCamera(CameraLocation, CameraRotation);
	ViewRotation = CameraRotation;
}

event Destroyed()
{
	if (Body != None && Body.CrushDriver == Self)
		Body.SetCrushDriver(None);
	Super.Destroyed();
}

defaultproperties
{
	bInvertThrottleAxis=False
	bInvertSteerAxis=False
	CameraDistanceUU=280.0
	CameraHeightUU=80.0
	CameraTargetHeightUU=60.0
	CameraYawFollowRate=3.5
	CameraMaxYawRateUU=14000.0
	CameraTargetFollowRate=10.0
	CameraCollisionReleaseRate=3.0
	CameraCollisionPaddingUU=12.0
	CameraCollisionHoldSeconds=0.15
	CameraMinArmUU=45.0
	CameraTeleportDistanceUU=600.0
}
