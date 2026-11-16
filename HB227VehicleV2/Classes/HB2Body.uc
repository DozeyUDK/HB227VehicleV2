//=============================================================================
// HB2Body Ă˘â‚¬â€ť P0 native-solver test body. PHYS_None, no PhysX.
// Patterns from Raycast backup: visual mesh follower, floor Trace, chase cam later.
//=============================================================================
class HB2Body expands Actor;

var HBVehicleBridge3D Core;
var HB2Vis Vis;
var HB2Vis VisNose;
var HB2Vis VisTail;
var HB2Vis VisWheels[4];
var() bool bVisualWheelsEnabled;
var float WheelSpinRad[4];
// P2.7 independently integrated four wheel angular speeds (rad/s).
var float WheelOmegaRadps[4];
var float WheelDriveTorqueNm[4];
var int ForwardGear;
var float EngineRPM, LastDriveMaxWheelSlipMps;
var int DriveDirection;
var int LastEngagedDirection;
var float GearShiftCooldownSec;
var float LastAntiRollFrontN, LastAntiRollRearN;
var int AntiRollImpulseFailureCount;
var string LastRecoverReason;
var float LastRecoverYawRad;
var bool bLastRecoverOK;
var() float MassKg;
var() float HalfExtentUU;      // longest half-extent (legacy isotropic traces)
var() vector ChassisHalfUU;    // true OBB half-size X/Y/Z in UU
var() string ChassisProfile;   // "legacy_cube" or "p15_vehicle"
var() float FaceNeighborSepUU; // P1.3c second-corner promotion, world UU
var() bool bDrawChassisDebug;
var() float Restitution;
var() float Friction;
var() bool bDiagnosticLog;
var() float DiagnosticInterval;

var float AccumDt;
var float FixedDt;
var int MaxSubsteps;
var float NextLogTime;
var bool bReady;
var vector LastSafeLoc;
var int ContactCount;
var float LastMaxPenUU;
var Actor LastHitActor;
var string LastHitKind; // BSP / StaticMesh / Actor / None
var int TotalStepCount;
var int StepFailureCount;
var int ActorSyncFailureCount;
var int NonFiniteStateCount;
var int ReliablePointContactCount;
var int ReliableSweepPointCount;
var int FallbackPointContactCount;
var int DuplicateContactCount;
var bool bLastStepOK;
var bool bLastActorSyncOK;
var bool bLoggedLineSemantics;
var bool bLoggedExtentSemantics;
var vector LastContactPointUU;
var vector LastSweepCenterUU;
var float LastSweepPointOffsetUU;
var string LastReliableSweepHitKind;

// These mirror the fixed Core3D configuration set during initialization and
// keep world-query prediction identical to the native semi-implicit step.
var vector CoreGravityMps2;
var float CoreLinearDamping;

// P1: four independent massless suspension support points. Geometry remains
// in Unreal units here and is converted exactly once at the native boundary.
var() bool bSuspensionEnabled;
var() vector SuspensionAttachmentUU[4];
var() vector SuspensionAxisBody[4];
var() float SuspensionRestUU[4];
var() float SuspensionMinUU[4];
var() float SuspensionMaxUU[4];
var() float WheelRadiusUU[4];
var() float SuspensionSpringNpm[4];
var() float SuspensionDamperCompressionNspm[4];
var() float SuspensionDamperReboundNspm[4];
var() float SuspensionBumpStopNpm[4];
var() float SuspensionMinNormalAlignment[4];
var int WheelContactCount;
var int SuspensionHitFailureCount;
var int SuspensionThreeContactStepCount;
var int SuspensionContactLossStepCount;
// Bounded transition telemetry: exact step when real ground support vanishes.
var int WheelContactTransitionLogCount;
var float NextWheelContactTransitionLogTime[4];
var vector LastWheelHitUU[4];
var vector LastWheelNormal[4];
var float LastWheelLengthUU[4];
var Actor LastWheelHitActor[4];
var float PrevWheelLengthUU[4];
var vector PrevWheelNormal[4];
var byte PrevWheelHadContact[4];
var float LastWheelLengthDeltaUU[4];
var float LastWheelCompressRateMps[4];
var float LastWheelSpringN[4];
var float LastWheelDamperN[4];
var string LastWheelContactSource[4];
var int WheelGeomGlitchCount;
var int WheelRealImpactCount;
var float MaxWheelLengthJumpUU;
var bool bLogWheelContact;
var int LastWheelProbePick[4];
var int LastWheelProbeCount[4];
var float LastWheelProbeMinL[4];
var float LastWheelProbeMaxL[4];
var float LastWheelBumpN[4];
var float LastWheelDlRateMps[4];
var bool bLogRide;
var bool bLogLandingTrace;
var bool bRefineWheelSupport;
var bool bProjectWheelTangent;
var bool bVerifyMeshFootprints;
var bool bResampleChassisSweep;
var bool bSampleMeshBelly;
var bool bMeshBellySkidFriction;
var bool bConfirmDeepWheelHits;
var string LastRideTag;
var float LastVertAccelMps2;
var float LastRollAccelRadps2;
var float LastChassisJnN;
var float LastKeJ;
var string LastRideCause;
var float MaxVertAccelMps2;
var float MaxRollAccelRadps2;
var int MaxVertAccelStep;
var int MaxRollAccelStep;
var string MaxVertAccelCause;
var string MaxRollAccelCause;
var int MaxVertAccelWheel;
var int MaxRollAccelWheel;
var int LastChassisSkipCount;

// P2.6b: one finite wheel-obstacle contact per wheel, separate from chassis
// contacts. Current implementation tests static meshes only; not a sphere sweep.
var() bool bWheelObstacleContactsEnabled;
var int WheelObstacleContactCount;
var int WheelObstacleContactTotal;
var int WheelObstacleProbeHitTotal;
var float NextWheelObstacleEventLogTime;
var float WheelObstacleLastPenUU;
var int WheelObstacleLastWheel;
var vector WheelObstacleLastNormal;
var vector WheelObstacleLastPointUU;
var Actor WheelObstacleLastActor;
var int ChassisAABBRejectCount;
var int ChassisFootprintRejectCount;
var int ChassisBellyPreservedCount;

// External test impulse (UU/s) applied once then cleared.
var vector PendingImpulseUU;

// Manual drive (not P0 auto).
var float LastGas, LastSteer, LastBrake;
var bool bDriverActive;
var() string SteerMode; // "yaw" (default) or "strafe_diag" (P0 lateral impulse)
var() float DriverMaxYawRateRadps;
var() float DriverYawRiseRateRadps2;
var() float DriverYawNeutralRateRadps2;
var() float DriverYawReverseRateRadps2;
var() float DriverMaxControlDt;
var float LastYawTargetRadps;
var float LastYawCorrectionRadps;
var float LastYawControlDt;
var float NextYawControlLogTime;

// P1.4 coast / resistance. Applied in the fixed physics step via
// NativeApplyImpulseAtPoint. Engine brake is a prototype load term, not a
// drivetrain. Wheel-dependent terms require a current suspension hit.
var() bool bCoastResistanceEnabled;
var() float RollingResistanceCoeff;
var() float AeroDragNsp2;
var() float EngineBrakeLoadCoeff;
var() float SpaceBrakeLoadCoeff;
var() float CoastSpeedDeadzoneMps;
var() float DriverAccelMps2;
// Manual Bulldog profile: high low-speed tractive demand, falling to zero
// near road speed. This is a wheel-force demand curve, not an RPM gearbox.
var() bool bDieselDriveCurve;
var() bool bLevelRestHoldEnabled;
var() float DieselLaunchAccelMps2;
var() float DieselMaxSpeedMps;
// Manual/Spire 4WD with wheel rotational inertia, gearbox and redline.
var() bool bTorque4WDEnabled;
var() float EnginePeakTorqueNm, EngineIdleRPM, EngineRedlineRPM;
var() float FinalDriveRatio, GearRatio1, GearRatio2, GearRatio3, GearRatio4, ReverseGearRatio;
var() float TransmissionEfficiency, WheelInertiaKgM2;
var() float MaxRoadSpeedMps;
var int LastEngineSoundPitch;
var() float WheelSlipStiffnessNspm, WheelBearingDampingNms, WheelBrakeTorqueNm;
// ScriptedPawn contacts feed Core3D and share their hit with crush damage.
// Keep pawns out of world and suspension Trace masks.
var() bool bPawnCrushEnabled;
var() float CrushEnterMps;
var() float CrushRefMps;
var() float CrushDamageAtRef;
var() float CrushDamageMaxMult;
var() float CrushCooldownSec;
var() float CrushSearchPaddingUU;
var HB2Driver CrushDriver;
var ScriptedPawn PawnContact;
var vector PawnContactNormal, PawnContactCenterUU, PawnContactPointUU;
var float PawnContactTime, PawnContactDepthUU, PawnContactClosingMps;
var Actor CrushCooldownPawn[8];
var float CrushCooldownUntil[8];
var float NextCrushLogTime;
var float LastCrushDamage;
var float LastCrushClosingMps;
// Pairwise anti-roll couples through the Core3D impulse API.
var() bool bAntiRollEnabled;
var() float FrontAntiRollNpm, RearAntiRollNpm;
var() float AntiRollDampingNs, AntiRollMaxForceN;
// Peak longitudinal demand at rest. Heavy off-road taper: DesiredDriveAccel
// falls toward DriverAccelMinFrac*peak by DriverAccelFadeSpeedMps. Does not
// raise TireMu or change suspension springs.
var() float DriverAccelFadeSpeedMps;
var() float DriverAccelMinFrac;
var float LastDesiredDriveAccelMps2;
var string LastCoastMode;
var float LastLoadSumN;
var float LastRollImpulseNs;
var float LastEngineImpulseNs;
var float LastBrakeImpulseNs;
var float LastAeroImpulseNs;
var float LastThrottleImpulseNs;
var float LastTangentSpeedMps;
var int LastCoastGroundWheels;

// P2.0 tire MVP. "p1_direct" keeps COM gas + yaw couple. "p2_tires" uses
// four contact-point forces and no yaw regulator. No Pacejka, gearbox or
// wheel spin. Core3D is unchanged; impulses go through NativeApplyImpulseAtPoint.
var() string ControlProfile;
var() float TireMu;
var() float MaxSteerRad;
var() float TireLateralSlipCoeff;
var() float MaxCorneringAccelMps2, HighSpeedCorneringAccelMps2;
var() float TireContactRiseTime;
var float TireContactBlend[4];
var float LastTireN[4];
var float LastTireVLong[4];
var float LastTireVLat[4];
var float LastTireSlipAngleRad[4];
var float LastTireFx[4];
var float LastTireFy[4];
var float LastTireCapN[4];
var float LastTireMuUtil[4];
var string LastTireSource[4];
var int LastTireActiveCount;
var int LastTireImpulseFail;
var float LastTireMaxMuUtil;
var float NextTireLogTime;
var float LastEffectiveSteerRad;
var bool bMeasureTireYaw;
var float LastFrontTireYawNm, LastRearTireYawNm;
var float LastBodyLateralSpeedMps;
var float LastRollRateRadps;
var float LastYawRateRadps;
var float PrevTireForceMagN[4];
var float MaxTireForceDeltaN[4];
var byte PrevTireForceActive[4];
var float MaxTireRecontactForceN[4];

// P1.3 chassis-contact telemetry. Estimates J from measured ĂŽâ€ťv; with
// suspension enabled that ĂŽâ€ťv also includes spring/damper forces.
var vector LastSurfacePointUU;
var vector LastApplyPointUU;
var vector LastContactNormal;
var vector LastContactRUU;
var float LastRxNLenUU;
var string LastChassisContactMode;
var vector P13OmegaPre, P13OmegaPost, P13VelPreM, P13VelPostM;
var int P13ContactLogCount;
var float NextP13LogTime;
var bool bP13HSLatch;
var float P13HSLatchedOmega;
var float P13HSLatchedUnique;
var float LastSweepHitTime;
var vector LastToiUU;
var vector LastProposedUU;
var string LastCornerSepProposed;
var string LastCornerSepToi;
var int LastManifoldAdded;
var int LastFeatureBase;
var int P13CLogCount;
var int LastSimSubIndex;
var float LastStepDt;
var string P13CTag;

function ApplyWheelSet(
	vector FL, vector FR, vector RL, vector RR,
	float RestUU, float MinUU, float MaxUU, float RadiusUU,
	float SpringNpm, float DampC, float DampR, float BumpNpm)
{
	local int i;
	SuspensionAttachmentUU[0] = FL;
	SuspensionAttachmentUU[1] = FR;
	SuspensionAttachmentUU[2] = RL;
	SuspensionAttachmentUU[3] = RR;
	for (i = 0; i < 4; ++i)
	{
		SuspensionAxisBody[i] = vect(0,0,-1);
		SuspensionRestUU[i] = RestUU;
		SuspensionMinUU[i] = MinUU;
		SuspensionMaxUU[i] = MaxUU;
		WheelRadiusUU[i] = RadiusUU;
		SuspensionSpringNpm[i] = SpringNpm;
		SuspensionDamperCompressionNspm[i] = DampC;
		SuspensionDamperReboundNspm[i] = DampR;
		SuspensionBumpStopNpm[i] = BumpNpm;
		SuspensionMinNormalAlignment[i] = 0.200;
	}
}

function ApplyLegacyCubeProfile()
{
	local vector FL, FR, RL, RR;
	ChassisProfile = "legacy_cube";
	MassKg = 200;
	ChassisHalfUU.X = 24.0;
	ChassisHalfUU.Y = 24.0;
	ChassisHalfUU.Z = 24.0;
	HalfExtentUU = 24;
	FaceNeighborSepUU = 24;
	AeroDragNsp2 = 0.300;
	FL.X = 28.875; FL.Y = -19.950; FL.Z = -10.500;
	FR.X = 28.875; FR.Y = 19.950; FR.Z = -10.500;
	RL.X = -28.875; RL.Y = -19.950; RL.Z = -10.500;
	RR.X = -28.875; RR.Y = 19.950; RR.Z = -10.500;
	ApplyWheelSet(FL, FR, RL, RR,
		28.875, 7.875, 36.750, 11.550,
		3000.000, 700.000, 900.000, 30000.000);
	SetCollisionSize(24, 24);
}

function ApplyP15VehicleProfile()
{
	local vector FL, FR, RL, RR;
	ChassisProfile = "p15_vehicle";
	MassKg = 2000;
	ChassisHalfUU.X = 118.0;
	ChassisHalfUU.Y = 52.5;
	ChassisHalfUU.Z = 31.5;
	HalfExtentUU = 118;
	FaceNeighborSepUU = 24;
	AeroDragNsp2 = 0.850;
	// Original Bulldog WheelOffset scaled by the same uniform factor as the
	// 236 UU body mesh.  Z is the spring attachment; at static Leq it puts
	// the axle at -41.562 UU, matching the source wheel arch.
	FL.X = 59.168; FL.Y = -56.442; FL.Z = -14.045;
	FR.X = 59.168; FR.Y = 56.442; FR.Z = -14.045;
	RL.X = -71.514; RL.Y = -56.442; RL.Z = -14.045;
	RR.X = -71.514; RR.Y = 56.442; RR.Z = -14.045;
	ApplyWheelSet(FL, FR, RL, RR,
		36.100, 15.100, 46.100, 32.839,
		30000.000, 7000.000, 9000.000, 300000.000);
	SetCollisionSize(118, 31.5);
}

function ApplyChassisProfileFromGame()
{
	local HB2TestGame G;
	G = HB2TestGame(Level.Game);
	if (G != None && (G.bP2 || G.bP21 || G.bP22 || G.bP23 || G.bP24 || G.bP25a))
	{
		ApplyP15VehicleProfile();
		ControlProfile = "p2_tires";
		return;
	}
	if (G != None && !G.bP15 && (G.bP0 || G.bP1))
	{
		ApplyLegacyCubeProfile();
		ControlProfile = "p1_direct";
		return;
	}
	ApplyP15VehicleProfile();
	if (G != None && (G.bP0 || G.bP1))
		ControlProfile = "p1_direct";
	else
		ControlProfile = "p2_tires";
}

function vector ChassisAABBProxyUU()
{
	local vector X, Y, Z, E;
	if (ChassisProfile == "legacy_cube")
	{
		E.X = ChassisHalfUU.X;
		E.Y = ChassisHalfUU.Y;
		E.Z = ChassisHalfUU.Z;
		return E;
	}
	GetAxes(Rotation, X, Y, Z);
	E.X = Abs(X.X) * ChassisHalfUU.X + Abs(Y.X) * ChassisHalfUU.Y + Abs(Z.X) * ChassisHalfUU.Z;
	E.Y = Abs(X.Y) * ChassisHalfUU.X + Abs(Y.Y) * ChassisHalfUU.Y + Abs(Z.Y) * ChassisHalfUU.Z;
	E.Z = Abs(X.Z) * ChassisHalfUU.X + Abs(Y.Z) * ChassisHalfUU.Y + Abs(Z.Z) * ChassisHalfUU.Z;
	return E;
}

function float BoxInertiaKgM2(int Axis)
{
	local float Hx, Hy, Hz;
	Hx = class'HB2WorldQuery'.static.UUToM(ChassisHalfUU.X);
	Hy = class'HB2WorldQuery'.static.UUToM(ChassisHalfUU.Y);
	Hz = class'HB2WorldQuery'.static.UUToM(ChassisHalfUU.Z);
	if (Axis == 0)
		return MassKg * (Hy * Hy + Hz * Hz) / 3.0;
	if (Axis == 1)
		return MassKg * (Hx * Hx + Hz * Hz) / 3.0;
	return MassKg * (Hx * Hx + Hy * Hy) / 3.0;
}

function float GroundClearanceUU()
{
	return ChassisSpawnHeightUU() - ChassisHalfUU.Z;
}

function float ChassisSpawnHeightUU()
{
	local float Leq;
	Leq = SuspensionRestUU[0]
		- class'HB2WorldQuery'.static.MToUU(
			MassKg * 9.81 / (4.0 * SuspensionSpringNpm[0]));
	return -SuspensionAttachmentUU[0].Z + Leq + WheelRadiusUU[0];
}

function LogVisVersusPhysics()
{
	local vector PhysSize, VisSize, Over;
	if (Vis == None || !Vis.bMeshMeasured)
		return;
	PhysSize.X = 2.0 * ChassisHalfUU.X;
	PhysSize.Y = 2.0 * ChassisHalfUU.Y;
	PhysSize.Z = 2.0 * ChassisHalfUU.Z;
	VisSize = Vis.MeshLocalSize;
	Over = (VisSize - PhysSize) * 0.5;
	Log("HB2_P15_BOUNDS physOBB="$PhysSize$" visAABB="$VisSize
		$" overhangHalfUU="$Over$" mesh="$Vis.MeshName
		$" drawScale="$Vis.DrawScale$" prePivot="$Vis.PrePivot
		$" note=visual_overhang_is_not_chassis_penetration");
}

function color DebugColor(byte R, byte G, byte B)
{
	local color C;
	C.R = R; C.G = G; C.B = B;
	return C;
}

function DrawDebugEdge(Canvas C, vector A, vector B, color Col)
{
	if (C != None)
		C.Draw3DLine(Col, A, B);
}

function DrawChassisDebug(Canvas C)
{
	local vector X, Y, Z, P0, P1, P2, P3, P4, P5, P6, P7;
	local vector Attach, Hit, Axis;
	local color ColOBB, ColVis, ColSus, ColHit, ColContact;
	local int i;
	local float Hx, Hy, Hz;

	if (C == None)
		return;
	GetAxes(Rotation, X, Y, Z);
	Hx = ChassisHalfUU.X; Hy = ChassisHalfUU.Y; Hz = ChassisHalfUU.Z;
	P0 = Location + X*Hx + Y*Hy + Z*Hz;
	P1 = Location + X*Hx + Y*Hy - Z*Hz;
	P2 = Location + X*Hx - Y*Hy + Z*Hz;
	P3 = Location + X*Hx - Y*Hy - Z*Hz;
	P4 = Location - X*Hx + Y*Hy + Z*Hz;
	P5 = Location - X*Hx + Y*Hy - Z*Hz;
	P6 = Location - X*Hx - Y*Hy + Z*Hz;
	P7 = Location - X*Hx - Y*Hy - Z*Hz;
	ColOBB = DebugColor(0, 220, 255);
	DrawDebugEdge(C, P0, P1, ColOBB);
	DrawDebugEdge(C, P1, P3, ColOBB);
	DrawDebugEdge(C, P3, P2, ColOBB);
	DrawDebugEdge(C, P2, P0, ColOBB);
	DrawDebugEdge(C, P4, P5, ColOBB);
	DrawDebugEdge(C, P5, P7, ColOBB);
	DrawDebugEdge(C, P7, P6, ColOBB);
	DrawDebugEdge(C, P6, P4, ColOBB);
	DrawDebugEdge(C, P0, P4, ColOBB);
	DrawDebugEdge(C, P1, P5, ColOBB);
	DrawDebugEdge(C, P2, P6, ColOBB);
	DrawDebugEdge(C, P3, P7, ColOBB);
	DrawDebugEdge(C, Location, Location + X * (Hx + 28), DebugColor(255, 80, 80));
	DrawDebugEdge(C, Location, Location - X * (Hx + 18), DebugColor(80, 80, 255));

	if (Vis != None && Vis.bMeshMeasured)
	{
		Hx = 0.5 * Vis.MeshLocalSize.X;
		Hy = 0.5 * Vis.MeshLocalSize.Y;
		Hz = 0.5 * Vis.MeshLocalSize.Z;
		P0 = Location + X*Hx + Y*Hy + Z*Hz;
		P1 = Location + X*Hx + Y*Hy - Z*Hz;
		P2 = Location + X*Hx - Y*Hy + Z*Hz;
		P3 = Location + X*Hx - Y*Hy - Z*Hz;
		P4 = Location - X*Hx + Y*Hy + Z*Hz;
		P5 = Location - X*Hx + Y*Hy - Z*Hz;
		P6 = Location - X*Hx - Y*Hy + Z*Hz;
		P7 = Location - X*Hx - Y*Hy - Z*Hz;
		ColVis = DebugColor(255, 160, 0);
		DrawDebugEdge(C, P0, P1, ColVis);
		DrawDebugEdge(C, P1, P3, ColVis);
		DrawDebugEdge(C, P3, P2, ColVis);
		DrawDebugEdge(C, P2, P0, ColVis);
		DrawDebugEdge(C, P4, P5, ColVis);
		DrawDebugEdge(C, P5, P7, ColVis);
		DrawDebugEdge(C, P7, P6, ColVis);
		DrawDebugEdge(C, P6, P4, ColVis);
		DrawDebugEdge(C, P0, P4, ColVis);
		DrawDebugEdge(C, P1, P5, ColVis);
		DrawDebugEdge(C, P2, P6, ColVis);
		DrawDebugEdge(C, P3, P7, ColVis);
	}

	ColSus = DebugColor(80, 255, 80);
	ColHit = DebugColor(255, 255, 0);
	for (i = 0; i < 4; ++i)
	{
		Attach = Location
			+ X * SuspensionAttachmentUU[i].X
			+ Y * SuspensionAttachmentUU[i].Y
			+ Z * SuspensionAttachmentUU[i].Z;
		Axis = X * SuspensionAxisBody[i].X
			+ Y * SuspensionAxisBody[i].Y
			+ Z * SuspensionAxisBody[i].Z;
		DrawDebugEdge(C, Attach, Attach + Axis * SuspensionMaxUU[i], ColSus);
		if (PrevWheelHadContact[i] == 1 && VSize(LastWheelHitUU[i]) > 1)
		{
			Hit = LastWheelHitUU[i];
			DrawDebugEdge(C, Attach, Hit, ColHit);
		}
	}

	if (ContactCount > 0 && VSize(LastApplyPointUU) > 1)
	{
		ColContact = DebugColor(255, 40, 40);
		DrawDebugEdge(C, LastApplyPointUU, LastApplyPointUU + LastContactNormal * 28, ColContact);
		DrawDebugEdge(C, Location, LastApplyPointUU, ColContact);
	}
}

function float WheelLengthUUAt(int i)
{
	if (LastWheelLengthUU[i] > 0.5)
		return LastWheelLengthUU[i];
	return SuspensionRestUU[i];
}

function ResolveVisualWheelsEnabled()
{
	local HB2TestGame G;
	G = HB2TestGame(Level.Game);
	bVisualWheelsEnabled = True;
	if (Level.NetMode == NM_DedicatedServer)
		bVisualWheelsEnabled = False;
	if (ChassisProfile != "p15_vehicle")
		bVisualWheelsEnabled = False;
	if (G != None)
	{
		if (G.bP0 || G.bP1 || G.bP2 || G.bP21 || G.bP22 || G.bP23)
			bVisualWheelsEnabled = False;
		if (G.bNoWheels)
			bVisualWheelsEnabled = False;
		if (G.bForceWheels && ChassisProfile == "p15_vehicle"
			&& Level.NetMode != NM_DedicatedServer)
			bVisualWheelsEnabled = True;
	}
}

function DestroyVisualWheels()
{
	local int i;
	for (i = 0; i < 4; ++i)
	{
		if (VisWheels[i] != None)
		{
			VisWheels[i].Destroy();
			VisWheels[i] = None;
		}
		WheelSpinRad[i] = 0;
	}
}

function SpawnVisualWheels()
{
	local int i;
	local bool bRight;

	DestroyVisualWheels();
	if (!bVisualWheelsEnabled || ChassisProfile != "p15_vehicle")
		return;
	for (i = 0; i < 4; ++i)
	{
		bRight = (i == 1 || i == 3);
		VisWheels[i] = Spawn(class'HB2Vis',,, Location, Rotation);
		if (VisWheels[i] == None)
		{
			Warn("HB2: visual wheel spawn failed i="$i);
			continue;
		}
		if (!VisWheels[i].ApplyWheelVisual(bRight, WheelRadiusUU[i]))
		{
			Warn("HB2: Bulldog wheel mesh missing i="$i$" right="$bRight);
			VisWheels[i].Destroy();
			VisWheels[i] = None;
			continue;
		}
	}
	Log("HB2_VIS_WHEELS spawned body="$Vis.MeshName
		$" bodyHasSeparateWheels=True using=HB227BulldogWheel/WheelR"
		$" scale0="$VisWheels[0].DrawScale$" physRadius="$WheelRadiusUU[0]
		$" note=body_mesh_is_chassis_only_no_double_wheels");
	UpdateVisualWheels();
}

function bool ModernVehicleProfileActive()
{
    local HB2TestGame G;
    G = HB2TestGame(Level.Game);
    return ChassisProfile == "p15_vehicle"
        && ControlProfile == "p2_tires"
        && (G == None || !(G.bP0 || G.bP1 || G.bP2 || G.bP21
            || G.bP22 || G.bP23 || G.bP24 || G.bP25a || G.bP26a));
}

function bool ModernTorqueDriveActive()
{
    return bTorque4WDEnabled && ModernVehicleProfileActive();
}

function float CurrentTransmissionRatio()
{
    if (LastGas < -0.05)
        return ReverseGearRatio;
    if (ForwardGear <= 1)
        return GearRatio1;
    if (ForwardGear == 2)
        return GearRatio2;
    if (ForwardGear == 3)
        return GearRatio3;
    return GearRatio4;
}

function float DieselTorqueAtRPM(float RPM)
{
    // Nm: idle torque, broad diesel plateau, soft fade and RPM limiter.
    if (RPM >= EngineRedlineRPM)
        return 0;
    if (RPM < 1200.0)
        return EnginePeakTorqueNm * 0.72;
    if (RPM < 2300.0)
        return EnginePeakTorqueNm * (0.72 + 0.28 * (RPM - 1200.0) / 1100.0);
    if (RPM < 2850.0)
        return EnginePeakTorqueNm * (1.0 - 0.20 * (RPM - 2300.0) / 550.0);
    return EnginePeakTorqueNm * 0.80 * FClamp(
        (EngineRedlineRPM - RPM) / FMax(1.0, EngineRedlineRPM - 2850.0), 0.0, 1.0);
}

function UpdateEngineAudio()
{
    local int PitchNow;
    if (!ModernVehicleProfileActive())
        return;
    // Engine1 ambient loop: 64 idle, 82 near governed redline. The
    // current gearbox ratio controls EngineRPM so upshifts lower pitch.
    PitchNow = int(FClamp(64.0 + 18.0 * (EngineRPM - EngineIdleRPM)
        / FMax(1.0, EngineRedlineRPM - EngineIdleRPM), 64.0, 82.0));
    if (PitchNow != LastEngineSoundPitch)
    {
        SoundPitch = PitchNow;
        LastEngineSoundPitch = PitchNow;
    }
}

function UpdateTorque4WD(float DT)
{
    local int i, RequestedDirection;
    local float MeanOmega, Ratio, Demand, TotalTorqueNm, ShaftRPM;
    local float V, DragNm, BrakeNm, StepDelta, ForwardSpeed;
    local float TargetRPM, Response, MaxDrivenOmega, Inertia;
    local vector Vel, Fwd, Right, Up;

    if (DT <= 0 || !ModernTorqueDriveActive())
        return;
    if (ForwardGear < 1 || ForwardGear > 4)
        ForwardGear = 1;

    // Distinguish true neutral from the forward and reverse transmissions.
    // Never infer engine RPM from the absolute speed of free-spinning tyres:
    // that previously produced RPM=4594 at zero gas and near-zero road speed.
    RequestedDirection = 0;
    if (LastGas > 0.05)
        RequestedDirection = 1;
    else if (LastGas < -0.05)
        RequestedDirection = -1;

    if (GearShiftCooldownSec > 0)
        GearShiftCooldownSec = FMax(0.0, GearShiftCooldownSec - DT);
    if (RequestedDirection != 0 && LastEngagedDirection != RequestedDirection)
    {
        // Switching F<->R always starts in first or reverse, never 4th.
        ForwardGear = 1;
        GearShiftCooldownSec = 0.40;
    }
    DriveDirection = RequestedDirection;
    if (RequestedDirection != 0)
        LastEngagedDirection = RequestedDirection;

    Demand = FClamp(Abs(LastGas), 0.0, 1.0);
    // Shift thresholds follow the actual road speed, not an unloaded
    // wheel's overspeed (which previously jumped straight to 4th at 3km/h).
    ForwardSpeed = 0;
    if (Core != None)
    {
        GetAxes(Rotation, Fwd, Right, Up);
        Vel.X = Core.OutVelX_mps;
        Vel.Y = Core.OutVelY_mps;
        Vel.Z = Core.OutVelZ_mps;
        ForwardSpeed = Vel Dot Fwd;
    }
    Ratio = CurrentTransmissionRatio();
    MeanOmega = 0;
    if (RequestedDirection != 0)
    {
        for (i = 0; i < 4; ++i)
            MeanOmega += FMax(0.0, WheelOmegaRadps[i] * RequestedDirection) * 0.25;
    }
    ShaftRPM = MeanOmega * 9.5492966 * Ratio * FinalDriveRatio;

    // Only forward gears shift. Reverse is a dedicated fixed ratio;
    // shifting is inhibited during the direction-change clutch interval.
    if (RequestedDirection == 1 && GearShiftCooldownSec <= 0.0)
    {
        if ((ForwardGear == 1 && ForwardSpeed > 5.3)
            || (ForwardGear == 2 && ForwardSpeed > 7.9)
            || (ForwardGear == 3 && ForwardSpeed > 10.4))
        {
            ForwardGear++;
            GearShiftCooldownSec = 0.45;
        }
        else if ((ForwardGear == 4 && ForwardSpeed < 8.9)
            || (ForwardGear == 3 && ForwardSpeed < 6.4)
            || (ForwardGear == 2 && ForwardSpeed < 3.8))
        {
            ForwardGear--;
            GearShiftCooldownSec = 0.45;
        }
        Ratio = CurrentTransmissionRatio();
        ShaftRPM = MeanOmega * 9.5492966 * Ratio * FinalDriveRatio;
    }

    // Neutral disengages the engine from the wheel shaft. Under power,
    // a slipping clutch allows launch RPM before the vehicle starts moving.
    TargetRPM = EngineIdleRPM;
    if (RequestedDirection != 0)
        TargetRPM = FMax(EngineIdleRPM + 1250.0 * Demand,
            FMin(EngineRedlineRPM, ShaftRPM));
    TargetRPM = FClamp(TargetRPM, EngineIdleRPM, EngineRedlineRPM);
    Response = FClamp(DT * 3.5, 0.0, 1.0);
    EngineRPM += (TargetRPM - EngineRPM) * Response;
    EngineRPM = FClamp(EngineRPM, EngineIdleRPM, EngineRedlineRPM);

    if (RequestedDirection == 1 && Core != None)
        Demand *= FClamp((MaxRoadSpeedMps - ForwardSpeed) / 0.75, 0.0, 1.0);

    // No throttle means precisely zero delivered axle torque. Free-spinning
    // wheels can still decelerate through bearings or through real contact.
    TotalTorqueNm = 0;
    if (RequestedDirection != 0)
        TotalTorqueNm = DieselTorqueAtRPM(EngineRPM) * Ratio
            * FinalDriveRatio * TransmissionEfficiency * Demand
            * RequestedDirection;

    // Stop adding engine torque to unloaded tyres at shaft redline.
    // Contact and braking can still change their speed independently.
    Inertia = FMax(1.0, WheelInertiaKgM2);
    MaxDrivenOmega = EngineRedlineRPM / FMax(0.01, 9.5492966 * Ratio * FinalDriveRatio);
    for (i = 0; i < 4; ++i)
    {
        WheelDriveTorqueNm[i] = TotalTorqueNm * 0.25;
        if (RequestedDirection != 0 && !WheelTireActive(i))
            WheelDriveTorqueNm[i] = RequestedDirection * FMin(Abs(WheelDriveTorqueNm[i]),
                FMax(0.0, MaxDrivenOmega - WheelOmegaRadps[i] * RequestedDirection)
                * Inertia / DT);
        WheelOmegaRadps[i] += WheelDriveTorqueNm[i] * DT / Inertia;
        V = WheelOmegaRadps[i];
        DragNm = FMin(Abs(V) * WheelBearingDampingNms,
            Abs(V) * WheelInertiaKgM2 / DT);
        BrakeNm = FMin(LastBrake * WheelBrakeTorqueNm,
            FMax(0.0, Abs(V) * WheelInertiaKgM2 / DT - DragNm));
        StepDelta = (DragNm + BrakeNm) * DT / FMax(1.0, WheelInertiaKgM2);
        if (V > 0.0)
            WheelOmegaRadps[i] = FMax(0.0, V - StepDelta);
        else if (V < 0.0)
            WheelOmegaRadps[i] = FMin(0.0, V + StepDelta);
    }
}

function ApplyAntiRollBar(int L, int R, float StiffNpm, float DT)
{
    local vector Fwd, Right, Up, LeftP, RightP, J, W;
    local float DiffM, RollRate, FBar;
    if (Core == None || DT <= 0 || StiffNpm <= 0)
        return;
    if (PrevWheelHadContact[L] != 1 || PrevWheelHadContact[R] != 1)
        return;
    // Wheel attachment-to-ground lengths (not visual mesh contact).
    DiffM = class'HB2WorldQuery'.static.UUToM(
        LastWheelLengthUU[R] - LastWheelLengthUU[L]);
    GetAxes(Rotation, Fwd, Right, Up);
    W.X = Core.OutAngX_radps;
    W.Y = Core.OutAngY_radps;
    W.Z = Core.OutAngZ_radps;
    RollRate = W Dot Fwd;
    FBar = FClamp(StiffNpm * DiffM + AntiRollDampingNs * RollRate,
        -AntiRollMaxForceN, AntiRollMaxForceN);
    if (Abs(FBar) < 0.05)
        return;
    LeftP = Location + Fwd * SuspensionAttachmentUU[L].X
        + Right * SuspensionAttachmentUU[L].Y
        + Up * SuspensionAttachmentUU[L].Z;
    RightP = Location + Fwd * SuspensionAttachmentUU[R].X
        + Right * SuspensionAttachmentUU[R].Y
        + Up * SuspensionAttachmentUU[R].Z;
    J = Up * (FBar * DT);
    if (!Core.NativeApplyImpulseAtPoint(J.X, J.Y, J.Z,
        class'HB2WorldQuery'.static.UUToM(LeftP.X),
        class'HB2WorldQuery'.static.UUToM(LeftP.Y),
        class'HB2WorldQuery'.static.UUToM(LeftP.Z)))
        AntiRollImpulseFailureCount++;
    if (!Core.NativeApplyImpulseAtPoint(-J.X, -J.Y, -J.Z,
        class'HB2WorldQuery'.static.UUToM(RightP.X),
        class'HB2WorldQuery'.static.UUToM(RightP.Y),
        class'HB2WorldQuery'.static.UUToM(RightP.Z)))
        AntiRollImpulseFailureCount++;
    if (L == 0)
        LastAntiRollFrontN = FBar;
    else
        LastAntiRollRearN = FBar;
}

function ApplyAntiRollBars(float DT)
{
    LastAntiRollFrontN = 0;
    LastAntiRollRearN = 0;
    if (!bAntiRollEnabled || !ModernVehicleProfileActive())
        return;
    ApplyAntiRollBar(0, 1, FrontAntiRollNpm, DT);
    ApplyAntiRollBar(2, 3, RearAntiRollNpm, DT);
}

function AdvanceWheelSpin(float DT)
{
	local int i;
	local vector Fwd, Right, Up, Attach, Axis, Center, PointM, V, LongDir;
	local float RadiusM, SteerRad, VLong;
	if (DT <= 0 || Core == None)
		return;
	GetAxes(Rotation, Fwd, Right, Up);
	for (i = 0; i < 4; ++i)
	{
		RadiusM = class'HB2WorldQuery'.static.UUToM(WheelRadiusUU[i]);
		if (RadiusM < 0.001)
			continue;
		Attach = Location
			+ Fwd * SuspensionAttachmentUU[i].X
			+ Right * SuspensionAttachmentUU[i].Y
			+ Up * SuspensionAttachmentUU[i].Z;
		Axis = Fwd * SuspensionAxisBody[i].X
			+ Right * SuspensionAxisBody[i].Y
			+ Up * SuspensionAxisBody[i].Z;
		Center = Attach + Axis * WheelLengthUUAt(i);
		PointM = class'HB2WorldQuery'.static.UUToMVec(Center);
		V = PointVelocityMps(PointM);
		SteerRad = 0;
		if (i == 0 || i == 1)
			SteerRad = EffectiveSteerRad();
		LongDir = SteerLongDir(Fwd, Up, SteerRad);
		if (VSize(LongDir) < 0.05)
			LongDir = Fwd;
		VLong = V Dot LongDir;
		if (ModernTorqueDriveActive())
			WheelSpinRad[i] += WheelOmegaRadps[i] * DT;
		else
			WheelSpinRad[i] += VLong / RadiusM * DT;
		while (WheelSpinRad[i] > 6.283185)
			WheelSpinRad[i] = WheelSpinRad[i] - 6.283185;
		while (WheelSpinRad[i] < -6.283185)
			WheelSpinRad[i] = WheelSpinRad[i] + 6.283185;
	}
}

function rotator WheelWorldRot(int i, vector Fwd, vector Right, vector Up)
{
	local float SteerRad, C, S, Cs, Ss;
	local vector LongDir, Axle, MeshX, MeshY, MeshZ;

	// Kingpin = body Up so steer/roll stay correct after chassis Pitch/Roll.
	// HB227BulldogWheel/WheelR: disc in XZ, axle = local Y (AABB 42Ä‚â€”26Ä‚â€”42).
	// Positive spin = forward roll: front of the tyre moves down (around +Y).
	// Physical attachments are not moved to fit the mesh.
	SteerRad = 0;
	if (i == 0 || i == 1)
		SteerRad = EffectiveSteerRad();
	Cs = Cos(SteerRad);
	Ss = Sin(SteerRad);
	LongDir = Fwd * Cs + Right * Ss;
	Axle = Right * Cs - Fwd * Ss;
	C = Cos(WheelSpinRad[i]);
	S = Sin(WheelSpinRad[i]);
	MeshX = LongDir * C - Up * S;
	MeshY = Axle;
	if (VSize(MeshX) < 0.05 || VSize(MeshY) < 0.05)
		return Rotation;
	MeshX = Normal(MeshX);
	MeshY = Normal(MeshY);
	MeshZ = MeshX Cross MeshY;
	if (VSize(MeshZ) < 0.05)
		return Rotation;
	MeshZ = Normal(MeshZ);
	MeshY = Normal(MeshZ Cross MeshX);
	return OrthoRotation(MeshX, MeshY, MeshZ);
}

function UpdateVisualWheels()
{
	local int i;
	local vector Fwd, Right, Up, Attach, Axis, Center;

	if (!bVisualWheelsEnabled)
		return;
	GetAxes(Rotation, Fwd, Right, Up);
	for (i = 0; i < 4; ++i)
	{
		if (VisWheels[i] == None)
			continue;
		Attach = Location
			+ Fwd * SuspensionAttachmentUU[i].X
			+ Right * SuspensionAttachmentUU[i].Y
			+ Up * SuspensionAttachmentUU[i].Z;
		Axis = Fwd * SuspensionAxisBody[i].X
			+ Right * SuspensionAxisBody[i].Y
			+ Up * SuspensionAxisBody[i].Z;
		Center = Attach + Axis * WheelLengthUUAt(i);
		VisWheels[i].SetLocation(Center);
		VisWheels[i].SetRotation(WheelWorldRot(i, Fwd, Right, Up));
		VisWheels[i].DrawScale3D.X = 1;
		VisWheels[i].DrawScale3D.Y = 1;
		VisWheels[i].DrawScale3D.Z = 1;
	}
}

function UpdateChassisVisuals()
{
	local vector Fwd, Right, Up;
	GetAxes(Rotation, Fwd, Right, Up);
	if (Vis != None)
	{
		Vis.SetLocation(Location);
		Vis.SetRotation(Rotation);
	}
	if (VisNose != None)
	{
		VisNose.SetLocation(Location + Fwd * (ChassisHalfUU.X + 10) + Up * ChassisHalfUU.Z);
		VisNose.SetRotation(Rotation);
	}
	if (VisTail != None)
	{
		VisTail.SetLocation(Location - Fwd * (ChassisHalfUU.X + 10) + Up * ChassisHalfUU.Z);
		VisTail.SetRotation(Rotation);
	}
	UpdateVisualWheels();
}

simulated function PostBeginPlay()
{
	local float Hx, Hy, Hz;
	Super.PostBeginPlay();

	SetPhysics(PHYS_None);
	SetCollision(False, False, False);
	bCollideWorld = False;
	bBlockZeroExtentTraces = True;
	bBlockNonZeroExtentTraces = True;

	FixedDt = 1.0 / 60.0;
	MaxSubsteps = 8;
	AccumDt = 0;

	ApplyChassisProfileFromGame();
	EngineRPM = EngineIdleRPM;
	LastEngineSoundPitch = 64;
	SoundPitch = 64;
	if (ModernVehicleProfileActive())
		AmbientSound = Sound(DynamicLoadObject("ArmadilloSFX.Engine1", class'Sound', True));
	else
		AmbientSound = None;
	Log("HB2_AUDIO_INIT sound="$AmbientSound
		$" pitch="$SoundPitch$" idleRPM="$EngineIdleRPM
		$" maxRPM="$EngineRedlineRPM$" speedGovernorKmh="
		$MaxRoadSpeedMps * 3.6);

	Core = Spawn(class'HBVehicleBridge3D', Self);
	if (Core == None)
	{
		Warn("HB2 FAIL: HBVehicleBridge3D spawn failed");
		return;
	}
	Hx = class'HB2WorldQuery'.static.UUToM(ChassisHalfUU.X);
	Hy = class'HB2WorldQuery'.static.UUToM(ChassisHalfUU.Y);
	Hz = class'HB2WorldQuery'.static.UUToM(ChassisHalfUU.Z);
	if (!Core.NativeInit(MassKg, Hx, Hy, Hz))
	{
		Warn("HB2 FAIL: NativeInit failed");
		return;
	}
	// Gravity in SI; Unreal Z-up. Mirror the fixed native values so the
	// world-query prediction follows the same semi-implicit step.
	CoreGravityMps2 = vect(0,0,-9.81);
	CoreLinearDamping = 0.02;
	Core.NativeSetGravity(CoreGravityMps2.X, CoreGravityMps2.Y, CoreGravityMps2.Z);
	if (HB2TestGame(Level.Game) != None && HB2TestGame(Level.Game).bP0
		&& !HB2TestGame(Level.Game).bP1)
		bSuspensionEnabled = False;
	if (bSuspensionEnabled && !ConfigureSuspension())
	{
		Warn("HB2 FAIL: suspension configuration rejected");
		return;
	}
	if (!PushActorToCore(vect(0,0,0)))
	{
		Warn("HB2 FAIL: initial NativeSetRigidState rejected");
		return;
	}
	bReady = True;
	bLastStepOK = True;
	bLastActorSyncOK = True;
	LastSafeLoc = Location;
	NextLogTime = Level.TimeSeconds + 0.25;

	if (Level.NetMode != NM_DedicatedServer)
	{
		Vis = Spawn(class'HB2Vis',,, Location, Rotation);
		if (Vis != None)
			Vis.ApplyChassisVisual(ChassisHalfUU, ChassisProfile);
		VisNose = Spawn(class'HB2Vis',,, Location, Rotation);
		if (VisNose != None)
			VisNose.ApplyMarker(True);
		VisTail = Spawn(class'HB2Vis',,, Location, Rotation);
		if (VisTail != None)
			VisTail.ApplyMarker(False);
		ResolveVisualWheelsEnabled();
		if (bVisualWheelsEnabled)
			SpawnVisualWheels();
		UpdateChassisVisuals();
		Log("HB2: Vis="$Vis$" nose="$VisNose$" tail="$VisTail
			$" visualWheels="$bVisualWheelsEnabled);
		LogVisVersusPhysics();
	}
	Log("HB2_API ready version="$Core.OutAPIVersion$" profile="$ChassisProfile
		$" control="$ControlProfile$" mass="$MassKg$" halfUU="$ChassisHalfUU$" halfScalar="$HalfExtentUU
		$" Ikgm2="$BoxInertiaKgM2(0)$","$BoxInertiaKgM2(1)$","$BoxInertiaKgM2(2)
		$" clearanceUU="$GroundClearanceUU()$" spawnHeightUU="$ChassisSpawnHeightUU()
		$" tireMu="$TireMu$" maxSteerRad="$MaxSteerRad
		$" loc="$Location$" PHYS_None Core3D_authoritative noPhysX_calls suspension="$bSuspensionEnabled);
}

function bool ConfigureSuspension()
{
	local int i;
	local vector A;
	for (i = 0; i < 4; ++i)
	{
		A = class'HB2WorldQuery'.static.UUToMVec(SuspensionAttachmentUU[i]);
		if (!Core.NativeConfigureSuspensionPoint(i,
			A.X, A.Y, A.Z,
			SuspensionAxisBody[i].X, SuspensionAxisBody[i].Y,
			SuspensionAxisBody[i].Z,
			class'HB2WorldQuery'.static.UUToM(SuspensionRestUU[i]),
			class'HB2WorldQuery'.static.UUToM(SuspensionMinUU[i]),
			class'HB2WorldQuery'.static.UUToM(SuspensionMaxUU[i]),
			SuspensionSpringNpm[i], SuspensionDamperCompressionNspm[i],
			SuspensionDamperReboundNspm[i], SuspensionBumpStopNpm[i],
			SuspensionMinNormalAlignment[i]))
			return False;
	}
	Log("HB2_P1 suspension configured four independent points");
	return True;
}

function BuildCoreQuatFromActorRotation(
	rotator ActorRot,
	out float Qw, out float Qx, out float Qy, out float Qz)
{
	local float Yaw, Pitch, Roll;
	local float CY, SY, CP, SP, CR, SR;
	Yaw = ActorRot.Yaw * (2.0 * 3.14159265 / 65536.0);
	// Unreal Pitch/Roll signs are opposite the solver's right-handed axes.
	Pitch = -ActorRot.Pitch * (2.0 * 3.14159265 / 65536.0);
	Roll = -ActorRot.Roll * (2.0 * 3.14159265 / 65536.0);
	CY = Cos(Yaw * 0.5); SY = Sin(Yaw * 0.5);
	CP = Cos(Pitch * 0.5); SP = Sin(Pitch * 0.5);
	CR = Cos(Roll * 0.5); SR = Sin(Roll * 0.5);
	Qw = CR*CP*CY + SR*SP*SY;
	Qx = SR*CP*CY - CR*SP*SY;
	Qy = CR*SP*CY + SR*CP*SY;
	Qz = CR*CP*SY - SR*SP*CY;
}

function bool PushActorToCore(vector VelUU)
{
	local vector Pm, Vm;
	local float Qw, Qx, Qy, Qz;
	Pm = class'HB2WorldQuery'.static.UUToMVec(Location);
	Vm = class'HB2WorldQuery'.static.UUToMVec(VelUU);
	BuildCoreQuatFromActorRotation(Rotation, Qw, Qx, Qy, Qz);
	return Core != None && Core.bReady && Core.NativeSetRigidState(
		Pm.X, Pm.Y, Pm.Z, Vm.X, Vm.Y, Vm.Z,
		Qw, Qx, Qy, Qz, 0, 0, 0);
}

function bool PullCoreToActor()
{
	local vector P, V;
	local rotator R;
	P.X = Core.OutPosX_m; P.Y = Core.OutPosY_m; P.Z = Core.OutPosZ_m;
	V.X = Core.OutVelX_mps; V.Y = Core.OutVelY_mps; V.Z = Core.OutVelZ_mps;
	P = class'HB2WorldQuery'.static.MToUUVec(P);
	V = class'HB2WorldQuery'.static.MToUUVec(V);
	R.Yaw = int(Core.OutYaw_rad * 10430.3783505); // rad Ă˘â€ â€™ UU rotator (~65536/2pi)
	R.Pitch = int(-Core.OutPitch_rad * 10430.3783505);
	R.Roll = int(-Core.OutRoll_rad * 10430.3783505);
	if (!SetLocation(P, R))
	{
		ActorSyncFailureCount++;
		bLastActorSyncOK = False;
		Warn("HB2_SYNC FAIL count="$ActorSyncFailureCount$" target="$P$" rot="$R);
		return False;
	}
	Velocity = V; // telemetry only; PHYS_None
	bLastActorSyncOK = True;
	UpdateChassisVisuals();
	return True;
}

function SetCrushDriver(HB2Driver D)
{
	CrushDriver = D;
	if (D != None)
		Instigator = D;
	else
		Instigator = None;
}

function Pawn CrushInstigator()
{
	if (CrushDriver != None)
		return CrushDriver;
	return Instigator;
}

function bool CrushCooldownActive(Actor Victim)
{
	local int i;
	if (Victim == None)
		return False;
	for (i = 0; i < 8; ++i)
	{
		if (CrushCooldownPawn[i] == Victim && Level.TimeSeconds < CrushCooldownUntil[i])
			return True;
	}
	return False;
}

function ArmCrushCooldown(Actor Victim)
{
	local int i, Free;
	if (Victim == None)
		return;
	Free = -1;
	for (i = 0; i < 8; ++i)
	{
		if (CrushCooldownPawn[i] == Victim)
		{
			CrushCooldownUntil[i] = Level.TimeSeconds + CrushCooldownSec;
			return;
		}
		if (Free < 0 && (CrushCooldownPawn[i] == None
			|| Level.TimeSeconds >= CrushCooldownUntil[i]))
			Free = i;
	}
	if (Free < 0)
		Free = 0;
	CrushCooldownPawn[Free] = Victim;
	CrushCooldownUntil[Free] = Level.TimeSeconds + CrushCooldownSec;
}

// Distance from a pawn's XY center to the yaw-oriented chassis rectangle.
function float PawnPlanarGapSq(vector Offset)
{
	local float X, Y;
	X = FMax(0.0, Abs(Offset.X) - ChassisHalfUU.X);
	Y = FMax(0.0, Abs(Offset.Y) - ChassisHalfUU.Y);
	return X*X + Y*Y;
}

// Sweep a yaw-oriented rectangle against the pawn cylinder, with vertical
// bounds from the full rotated chassis. Return the first contact in the step.
function bool SweepPawnCylinder(vector StartUU, vector DeltaUU, Pawn P,
	out float Time, out vector NormalUU, out float DepthUU)
{
	local vector S, D, AtHit, Nearest, Bounds;
	local rotator YawOnly;
	local float Lo, Hi, A, B, Z, R2, Middle, First, Last;
	local int i;

	Bounds = ChassisAABBProxyUU();
	YawOnly.Yaw = Rotation.Yaw;
	S = (StartUU - P.Location) << YawOnly;
	D = DeltaUU << YawOnly;
	Z = Bounds.Z + P.CollisionHeight;
	Lo = 0.0;
	Hi = 1.0;
	if (Abs(D.Z) < 0.0001)
	{
		if (Abs(S.Z) >= Z)
			return False;
	}
	else
	{
		A = (-Z - S.Z) / D.Z;
		B = (Z - S.Z) / D.Z;
		Lo = FMax(Lo, FMin(A, B));
		Hi = FMin(Hi, FMax(A, B));
		if (Lo > Hi)
			return False;
	}

	// Reject cheap axis bounds before searching the rounded corners.
	if (FMin(S.X, S.X + D.X) > ChassisHalfUU.X + P.CollisionRadius
		|| FMax(S.X, S.X + D.X) < -ChassisHalfUU.X - P.CollisionRadius
		|| FMin(S.Y, S.Y + D.Y) > ChassisHalfUU.Y + P.CollisionRadius
		|| FMax(S.Y, S.Y + D.Y) < -ChassisHalfUU.Y - P.CollisionRadius)
		return False;
	R2 = P.CollisionRadius * P.CollisionRadius;
	Time = Lo;
	if (PawnPlanarGapSq(S + D * Lo) > R2)
	{
		// Distance squared along the segment is convex. Find its minimum
		// inside the vertical interval, then bisect the entry side.
		First = Lo;
		Last = Hi;
		for (i = 0; i < 14; ++i)
		{
			A = (2.0 * First + Last) / 3.0;
			B = (First + 2.0 * Last) / 3.0;
			if (PawnPlanarGapSq(S + D * A) <= PawnPlanarGapSq(S + D * B))
				Last = B;
			else
				First = A;
		}
		Hi = FClamp((First + Last) * 0.5, Lo, Hi);
		if (PawnPlanarGapSq(S + D * Hi) > R2)
			return False;
		for (i = 0; i < 12; ++i)
		{
			Middle = (Lo + Hi) * 0.5;
			if (PawnPlanarGapSq(S + D * Middle) > R2)
				Lo = Middle;
			else
				Hi = Middle;
		}
		Time = Hi;
	}

	AtHit = S + D * Time;
	Nearest.X = AtHit.X - FClamp(AtHit.X, -ChassisHalfUU.X, ChassisHalfUU.X);
	Nearest.Y = AtHit.Y - FClamp(AtHit.Y, -ChassisHalfUU.Y, ChassisHalfUU.Y);
	DepthUU = 0.0;
	if (Abs(Abs(AtHit.Z) - Z) < 0.05 && Abs(D.Z) > 0.0001
		&& Abs(S.Z) >= Z)
	{
		NormalUU = vect(0,0,1);
		if (AtHit.Z < 0)
			NormalUU = -NormalUU;
	}
	else if (VSize(Nearest) > 0.001)
	{
		NormalUU = Normal(Nearest) >> YawOnly;
		if (Time <= 0.0001)
			DepthUU = FMax(0.0, P.CollisionRadius - VSize(Nearest));
	}
	else
	{
		A = ChassisHalfUU.X - Abs(AtHit.X);
		B = ChassisHalfUU.Y - Abs(AtHit.Y);
		if (A < B)
		{
			Nearest = vect(1,0,0);
			if (AtHit.X < 0)
				Nearest = -Nearest;
		}
		else
		{
			Nearest = vect(0,1,0);
			if (AtHit.Y < 0)
				Nearest = -Nearest;
		}
		NormalUU = Nearest >> YawOnly;
		DepthUU = P.CollisionRadius + FMin(A, B);
	}
	return True;
}

function bool CanCollideWithPawn(ScriptedPawn SP)
{
	return SP != None && !SP.bDeleteMe && SP.Health > 0 && SP.bCollideActors
		&& !SP.bIsPlayer && !SP.IsA('PlayerPawn') && !SP.IsA('HB2Driver')
		&& SP != CrushDriver;
}

function GatherPawnContact(vector StartUU, vector PredVelM)
{
	local ScriptedPawn SP;
	local vector DeltaUU, Center, N, Point, RayEnd, HitLoc, HitNorm, Bounds;
	local float RadiusUU, T, DepthUU, SupportUU, ClosingMps;

	PawnContact = None;
	PawnContactTime = 2.0;
	if (!bPawnCrushEnabled || !ModernVehicleProfileActive())
		return;

	DeltaUU = class'HB2WorldQuery'.static.MToUUVec(PredVelM * FixedDt);
	Bounds = ChassisAABBProxyUU();
	Center = StartUU + DeltaUU * 0.5;
	// RadiusActors tests actor origins, so use PawnList and size-aware
	// bounds to handle large creatures as well as small ones.
	foreach AllActors(class'ScriptedPawn', SP)
	{
		if (!CanCollideWithPawn(SP))
			continue;
		RadiusUU = VSize(Bounds) + VSize(DeltaUU) * 0.5
			+ FMax(SP.CollisionHeight, SP.CollisionRadius) + CrushSearchPaddingUU;
		if (VSize(SP.Location - Center) > RadiusUU
			|| !SweepPawnCylinder(StartUU, DeltaUU, SP, T, N, DepthUU)
			|| T >= PawnContactTime)
			continue;
		ClosingMps = -((PredVelM - ContactSurfaceVelocityMps(SP)) Dot N);
		if (DepthUU <= 0.01 && ClosingMps <= 0.0 && (DeltaUU Dot N) >= 0.0)
			continue;

		Point = StartUU + DeltaUU * T;
		SupportUU = class'HB2WorldQuery'.static.OBBSupportRadius(ChassisHalfUU, Rotation, N);
		RayEnd = Point - N * FMax(0.0, SupportUU - FMin(DepthUU, SupportUU));
		if (Trace(HitLoc, HitNorm, RayEnd, Point, True, vect(0,0,0), True, 0,
			class'HB2WorldQuery'.static.VehicleTraceFlags(True)) != None)
			continue;
		PawnContact = SP;
		PawnContactTime = T;
		PawnContactNormal = N;
		PawnContactClosingMps = FMax(0.0, ClosingMps);
		PawnContactDepthUU = DepthUU;
		PawnContactCenterUU = Point;
		PawnContactPointUU = RayEnd;
	}

	if (PawnContact != None && ContactCount < 16)
		AddPointContact(PawnContactPointUU, PawnContactNormal,
			FMin(PawnContactDepthUU, 6.0), 0.0, PawnContact, 1201);
}

// Core3D integrates position before solving contacts. Keep its resolved
// tangent velocity and rotation, and remove residual travel through the pawn.
function bool ConstrainPawnContact()
{
	local vector P, V, N;
	local float IntoUU, IntoMps;
	if (PawnContact == None)
		return True;
	N = PawnContactNormal;
	P.X = Core.OutPosX_m;
	P.Y = Core.OutPosY_m;
	P.Z = Core.OutPosZ_m;
	P = class'HB2WorldQuery'.static.MToUUVec(P);
	IntoUU = -((P - PawnContactCenterUU) Dot N);
	V.X = Core.OutVelX_mps;
	V.Y = Core.OutVelY_mps;
	V.Z = Core.OutVelZ_mps;
	IntoMps = -((V - ContactSurfaceVelocityMps(PawnContact)) Dot N);
	if (IntoUU <= 0.0 && IntoMps <= 0.0 && PawnContactDepthUU <= 0.01)
		return True;
	P += N * (FMax(0.0, IntoUU + FMin(PawnContactDepthUU, 6.0)));
	P = class'HB2WorldQuery'.static.UUToMVec(P);
	V += N * FMax(0.0, IntoMps);
	return Core.NativeSetRigidState(P.X, P.Y, P.Z, V.X, V.Y, V.Z,
		Core.OutQuatW, Core.OutQuatX, Core.OutQuatY, Core.OutQuatZ,
		Core.OutAngX_radps, Core.OutAngY_radps, Core.OutAngZ_radps);
}

function ApplyPawnCrush()
{
	local ScriptedPawn SP;
	local float ClosingMps, Span, DamageF;
	local int DamageI;
	local Pawn Killer;
	local bool bAlreadyInContact;

	SP = PawnContact;
	if (Role != ROLE_Authority || !CanCollideWithPawn(SP))
		return;
	bAlreadyInContact = CrushCooldownActive(SP);
	ArmCrushCooldown(SP);
	ClosingMps = PawnContactClosingMps;
	Killer = CrushInstigator();
	if (!bAlreadyInContact && ClosingMps >= CrushEnterMps)
	{
		Span = FMax(0.05, CrushRefMps - CrushEnterMps);
		DamageF = CrushDamageAtRef * (ClosingMps - CrushEnterMps) / Span;
		DamageI = int(FClamp(DamageF, 0.0, CrushDamageAtRef * CrushDamageMaxMult) + 0.5);
		if (DamageI > 0)
		{
			SP.TakeDamage(DamageI, Killer, PawnContactPointUU,
				-PawnContactNormal * (MassKg * ClosingMps * 0.35), 'Crushed');
			LastCrushDamage = DamageI;
			LastCrushClosingMps = ClosingMps;
		}
	}
	if (!bAlreadyInContact && Level.TimeSeconds >= NextCrushLogTime)
	{
		NextCrushLogTime = Level.TimeSeconds + 0.20;
		Log("HB2_CRUSH pawn="$SP.Class$" closingMps="$ClosingMps
			$" dmg="$DamageI$" healthLeft="$SP.Health
			$" speedAfterMps="$Core.OutSpeed_mps$" normal="$PawnContactNormal
			$" toi="$PawnContactTime$" instigator="$Killer);
	}
}

function string ClassifyHit(Actor Hit)
{
	if (Hit == None)
		return "None";
	if (Hit == Level)
		return "BSP";
	if (Hit.IsA('StaticMeshActor') || Hit.bIsStaticMesh)
		return "StaticMesh";
	if (Hit.IsA('Mover'))
		return "Mover";
	if (Hit.IsA('HB2CollideMesh'))
		return "CollideMesh";
	if (Hit.Mesh != None && Hit.bCollideActors)
		return "ActorMesh";
	return "Actor";
}

function bool IsFiniteValue(float F)
{
	return F == F && Abs(F) < 1.0e30;
}

function bool IsCoreStateFinite()
{
	local float QNormSq;
	if (Core == None)
		return False;
	QNormSq = Core.OutQuatW*Core.OutQuatW + Core.OutQuatX*Core.OutQuatX
		+ Core.OutQuatY*Core.OutQuatY + Core.OutQuatZ*Core.OutQuatZ;
	return IsFiniteValue(Core.OutPosX_m) && IsFiniteValue(Core.OutPosY_m)
		&& IsFiniteValue(Core.OutPosZ_m) && IsFiniteValue(Core.OutVelX_mps)
		&& IsFiniteValue(Core.OutVelY_mps) && IsFiniteValue(Core.OutVelZ_mps)
		&& IsFiniteValue(Core.OutAngX_radps) && IsFiniteValue(Core.OutAngY_radps)
		&& IsFiniteValue(Core.OutAngZ_radps) && IsFiniteValue(QNormSq)
		&& QNormSq > 0.98 && QNormSq < 1.02;
}

function int ContactFeatureId(Actor Hit, bool bGround)
{
	local int Kind;
	if (Hit == Level) Kind = 1;
	else if (Hit != None && (Hit.IsA('StaticMeshActor') || Hit.bIsStaticMesh)) Kind = 2;
	else if (Hit != None && Hit.IsA('Mover')) Kind = 3;
	else Kind = 4;
	// UE227 Trace does not expose a BSP node/triangle feature identifier to
	// script. Query slot + kind + corner index (x10) identifies face-manifold
	// points so Core3D will not merge them.
	if (bGround)
		return 100 + Kind;
	return 200 + Kind;
}

function vector ContactSurfaceVelocityMps(Actor Hit)
{
	if (Hit == None || Hit == Level)
		return vect(0,0,0);
	return class'HB2WorldQuery'.static.UUToMVec(Hit.Velocity);
}

function AddPointContact(
	vector PointUU,
	vector HitNorm,
	float PenUU,
	float ContactRestitution,
	Actor Hit,
	int FeatureId,
	optional float FrictionScale)
{
	local vector PointM, SurfaceVelM;
	if (FrictionScale<=0.0) FrictionScale=1.0;
	PointM = class'HB2WorldQuery'.static.UUToMVec(PointUU);
	SurfaceVelM = ContactSurfaceVelocityMps(Hit);
	Core.NativeAddContactAtPoint(
		PointM.X, PointM.Y, PointM.Z,
		HitNorm.X, HitNorm.Y, HitNorm.Z,
		class'HB2WorldQuery'.static.UUToM(PenUU),
		ContactRestitution, Friction * FrictionScale,
		SurfaceVelM.X, SurfaceVelM.Y, SurfaceVelM.Z,
		FeatureId);
	ContactCount++;
	LastContactPointUU = PointUU;
	LastApplyPointUU = PointUU;
	LastContactNormal = HitNorm;
	LastHitActor = Hit;
	LastHitKind = ClassifyHit(Hit);
	if (PenUU > LastMaxPenUU)
		LastMaxPenUU = PenUU;
}

// 1-4 contacts on a verified world plane. Corners in front of the plane are
// skipped so a vertex/edge stays a vertex/edge. Distinct feature IDs keep
// Core3D from merging them into one impulse.
function int AddVerifiedPlaneContacts(
	vector ProposedUU,
	vector SurfaceUU,
	vector HitNorm,
	float ContactRestitution,
	Actor Hit,
	bool bGround)
{
	local vector Extent, C0, C1, C2, C3, Corner, Apply, LocalSurface;
	local float PenUU, Sep, MaxRxN, BestSep, SecondSep;
	local int i, Added, BaseId, BestI, SecondI;

	HitNorm = Normal(HitNorm);
	Extent = ChassisHalfUU;
	class'HB2WorldQuery'.static.OBBFaceCorners(
		ProposedUU, Extent, Rotation, HitNorm, C0, C1, C2, C3);
	BaseId = ContactFeatureId(Hit, bGround);
	Added = 0;
	MaxRxN = 0;
	BestSep = 100000;
	SecondSep = 100000;
	BestI = -1;
	SecondI = -1;
	LastSurfacePointUU = SurfaceUU;
	LastContactNormal = HitNorm;
	for (i = 0; i < 4; ++i)
	{
		if (i == 0) Corner = C0;
		else if (i == 1) Corner = C1;
		else if (i == 2) Corner = C2;
		else Corner = C3;
		Sep = (Corner - SurfaceUU) Dot HitNorm;
		if (Sep < BestSep)
		{
			SecondSep = BestSep;
			SecondI = BestI;
			BestSep = Sep;
			BestI = i;
		}
		else if (Sep < SecondSep)
		{
			SecondSep = Sep;
			SecondI = i;
		}
		if (Sep > 12.0 || (bSuspensionEnabled && Sep > 0.5))
			continue;
		PenUU = FMax(0.0, -Sep);
		Apply = class'HB2WorldQuery'.static.ProjectOnPlane(Corner, SurfaceUU, HitNorm);
		if (bSuspensionEnabled
			&& !class'HB2WorldQuery'.static.VerifyBSPContactFootprint(
				Self, Hit, Apply, SurfaceUU, HitNorm, bVerifyMeshFootprints))
		{
			ChassisFootprintRejectCount++;
			continue;
		}
		MaxRxN = FMax(MaxRxN, VSize((Apply - ProposedUU) Cross HitNorm));
		AddPointContact(Apply, HitNorm, PenUU, ContactRestitution, Hit, BaseId + i * 10);
		if (Added == 0)
		{
			LastApplyPointUU = Apply;
			LastContactRUU = Apply - ProposedUU;
		}
		Added++;
	}
	// Swept AABB can report one vertex while the neighboring face-edge
	// corner is still on the same plane (Sep just outside 12 UU). Promote
	// that second corner so first contact is an edge, not a false vertex.
	if (Added == 1 && SecondI >= 0 && SecondSep <= FaceNeighborSepUU
		&& (!bSuspensionEnabled || SecondSep <= 0.5))
	{
		if (SecondI == 0) Corner = C0;
		else if (SecondI == 1) Corner = C1;
		else if (SecondI == 2) Corner = C2;
		else Corner = C3;
		PenUU = FMax(0.0, -SecondSep);
		Apply = class'HB2WorldQuery'.static.ProjectOnPlane(Corner, SurfaceUU, HitNorm);
		if (!bSuspensionEnabled
			|| class'HB2WorldQuery'.static.VerifyBSPContactFootprint(
				Self, Hit, Apply, SurfaceUU, HitNorm, bVerifyMeshFootprints))
		{
			MaxRxN = FMax(MaxRxN, VSize((Apply - ProposedUU) Cross HitNorm));
			AddPointContact(Apply, HitNorm, PenUU, ContactRestitution, Hit, BaseId + SecondI * 10);
			Added++;
		}
		else
			ChassisFootprintRejectCount++;
	}
	if (Added == 0)
	{
		if (bSuspensionEnabled)
		{
			// A narrow BSP patch may intersect the face without touching
			// corners. Use the real hit only if the OBB contains that point.
			LocalSurface = (SurfaceUU - ProposedUU) << Rotation;
			if (Abs(LocalSurface.X) > ChassisHalfUU.X + 1.0
				|| Abs(LocalSurface.Y) > ChassisHalfUU.Y + 1.0
				|| Abs(LocalSurface.Z) > ChassisHalfUU.Z + 1.0
				|| !class'HB2WorldQuery'.static.VerifyBSPContactFootprint(
					Self, Hit, SurfaceUU, SurfaceUU, HitNorm, bVerifyMeshFootprints))
			{
				ChassisFootprintRejectCount++;
				return 0;
			}
			Apply = SurfaceUU;
		}
		else
			Apply = class'HB2WorldQuery'.static.ProjectOnPlane(ProposedUU, SurfaceUU, HitNorm);
		PenUU = FMax(0.0, class'HB2WorldQuery'.static.OBBSupportRadius(Extent, Rotation, HitNorm)
			- ((ProposedUU - SurfaceUU) Dot HitNorm));
		LastContactRUU = Apply - ProposedUU;
		LastRxNLenUU = VSize(LastContactRUU Cross HitNorm);
		LastChassisContactMode = "plane_com";
		LastManifoldAdded = 1;
		LastFeatureBase = BaseId;
		AddPointContact(Apply, HitNorm, PenUU, ContactRestitution, Hit, BaseId);
		return 1;
	}
	LastRxNLenUU = MaxRxN;
	LastChassisContactMode = "face_"$Added;
	LastManifoldAdded = Added;
	LastFeatureBase = BaseId;
	return Added;
}

function string CornerSepList(vector CenterUU, vector SurfaceUU, vector HitNorm)
{
	local vector Extent, C0, C1, C2, C3, Corner;
	local int i;
	local string S;
	HitNorm = Normal(HitNorm);
	Extent = ChassisHalfUU;
	class'HB2WorldQuery'.static.OBBFaceCorners(
		CenterUU, Extent, Rotation, HitNorm, C0, C1, C2, C3);
	S = "";
	for (i = 0; i < 4; ++i)
	{
		if (i == 0) Corner = C0;
		else if (i == 1) Corner = C1;
		else if (i == 2) Corner = C2;
		else Corner = C3;
		if (i > 0)
			S = S$",";
		S = S$((Corner - SurfaceUU) Dot HitNorm);
	}
	return S;
}

function float WheelSpringNAt(int i)
{
	if (i == 0) return Core.OutWheel0Spring_N;
	if (i == 1) return Core.OutWheel1Spring_N;
	if (i == 2) return Core.OutWheel2Spring_N;
	return Core.OutWheel3Spring_N;
}

function float WheelDamperNAt(int i)
{
	if (i == 0) return Core.OutWheel0Damper_N;
	if (i == 1) return Core.OutWheel1Damper_N;
	if (i == 2) return Core.OutWheel2Damper_N;
	return Core.OutWheel3Damper_N;
}

function bool AcceptWheelProbe(
	int i, vector AttachUU, vector AxisDown, vector HitLoc, vector HitNorm,
	float RadiusUU, out float LengthUU, out float LatUU)
{
	local vector N, Center, OnAxis;
	local float Align;

	LengthUU = 0;
	LatUU = 0;
	if (VSize(HitNorm) < 0.5)
		return False;
	N = Normal(HitNorm);
	Align = N Dot (AxisDown * -1.0);
	if (Align < SuspensionMinNormalAlignment[i])
		return False;
	Center = HitLoc + N * RadiusUU;
	LengthUU = (Center - AttachUU) Dot AxisDown;
	OnAxis = AttachUU + AxisDown * LengthUU;
	LatUU = VSize(Center - OnAxis);
	if (LatUU > RadiusUU * 0.70)
		return False;
	if (LengthUU < -2.0 || LengthUU > SuspensionMaxUU[i] + 0.5)
		return False;
	if (LengthUU < 0)
		LengthUU = 0;
	return True;
}

// Disc probes, not a sphere sweep. 227k Extent Trace is AABB. One contact
// is chosen: prefer the longer cluster when probes straddle a BSP edge;
// if compression exceeds |v_attachĂ‚Â·D|Ă‚Â·dt+10 UU and the previous plane is
// gone, that substep is an honest miss (no sticky contact, no bump slam).
function RefineWheelSupport(
	int I, vector AttachUU, vector AxisDown, float RadiusUU, Actor SurfaceActor,
	out vector SurfaceP, out vector SurfaceN, out float LengthUU)
{
	local float Align, TangentLength, Dist;
	local vector ActualPoint, ActualNormal, Tangent;
	local Actor ActualActor;

	Align = -(AxisDown Dot SurfaceN);
	if (Align < 0.35)
		return;
	TangentLength = (((AttachUU - SurfaceP) Dot SurfaceN) - RadiusUU) / Align;
	if (TangentLength < 0.0 || TangentLength > SuspensionMaxUU[I])
		return;
	if (Abs(TangentLength - LengthUU) < 0.05
		|| Abs(TangentLength - LengthUU) > RadiusUU * 0.30)
		return;
	Tangent = AttachUU + AxisDown*TangentLength - SurfaceN*RadiusUU;
	if (VSize(Tangent-SurfaceP) > RadiusUU * 0.70)
		return;
	// An offset ray may see a neighbouring face. Accept the tangent plane
	// only if the actual tangent point is on the same surface.
	if (!class'HB2WorldQuery'.static.GroundQuery(Self,
		Tangent+SurfaceN*4.0,-SurfaceN,8.0,True,ActualPoint,ActualNormal,Dist,ActualActor))
		return;
	if (ActualActor!=SurfaceActor || (Normal(ActualNormal) Dot SurfaceN)<0.995
		|| VSize(ActualPoint-Tangent)>0.25)
		return;
	SurfaceP = ActualPoint;
	LengthUU = TangentLength;
}


function bool ConfirmDeepWheelHit(int I, vector Attach, vector Down, float Radius,
	Actor ExpectedHit, out vector P, out vector N, out float Length)
{
	local float Align, ExactLength, Dist;
	local vector T, H, HN;
	local Actor Hit;
	if(!bConfirmDeepWheelHits || Length >= 1.0)
		return True;
	Align=-(Down Dot N);
	if(Align<0.35) return False;
	ExactLength=(((Attach-P) Dot N)-Radius)/Align;
	if(ExactLength < -2.0 || ExactLength>SuspensionMaxUU[I]) return False;
	T=Attach+Down*ExactLength-N*Radius;
	if(!class'HB2WorldQuery'.static.GroundQuery(Self,T+N*4.0,-N,8.0,True,H,HN,Dist,Hit))
		return False;
	if(Hit!=ExpectedHit || (Normal(HN) Dot N)<0.995 || VSize(H-T)>0.35)
		return False;
	P=H;
	Length=FMax(0.0,ExactLength);
	return True;
}


function bool QueryWheelContact(int i, vector BodyCenterUU)
{
	local vector AttachUU, AxisDown, Fwd, Right, Up, LongDir, Axle, Offset;
	local vector AttachVelMps, GroundMove;
	local vector HitLoc, HitNorm, BestP, BestN, Ext;
	local vector CandP[12], CandN[12];
	local float CandL[12], CandLat[12];
	local Actor CandHit[12];
	local Actor Hit, BestHit;
	local float RadiusUU, RayLengthUU, LengthUU, LatUU, HitDistUU;
	local float MinL, MaxL, BestL, BestLat, SteerRad, Cs, Ss;
	local float PhysDeltaUU, NearMin;
	local int p, NCand, CountNearMin, CountNearMax, Pick, FeatureId;
	local int CandProbe[12];
	local vector PointM, SurfaceVelM, SurfaceP, SurfaceN;
	local float CenterToSurf, HitTime;
	local string Src;
	local bool bHit;

	GetAxes(Rotation, Fwd, Right, Up);
	AttachUU = BodyCenterUU + (SuspensionAttachmentUU[i] >> Rotation);
	AxisDown = Normal(SuspensionAxisBody[i] >> Rotation);
	RadiusUU = WheelRadiusUU[i];
	RayLengthUU = SuspensionMaxUU[i] + RadiusUU + 8.0;
	SteerRad = 0;
	// Wheel ground probes must use the same effective steering angle as tyre
	// forces and visual wheel geometry. Raw steering diverges at speed.
	if (i == 0 || i == 1)
		SteerRad = EffectiveSteerRad();
	Cs = Cos(SteerRad);
	Ss = Sin(SteerRad);
	LongDir = Fwd * Cs + Right * Ss;
	Axle = Right * Cs - Fwd * Ss;
	// Extra footprint samples in the wheel attachment motion direction.
	// Every accepted hit still requires a valid BSP/mesh Trace and normal.
	AttachVelMps = PointVelocityMps(
		class'HB2WorldQuery'.static.UUToMVec(AttachUU));
	GroundMove = AttachVelMps - Up * (AttachVelMps Dot Up);
	if (VSize(GroundMove) > 0.50)
		GroundMove = Normal(GroundMove);
	else
		GroundMove = vect(0,0,0);
	NCand = 0;

	for (p = 0; p < 13; ++p)
	{
		if (p == 9 && (!bRefineWheelSupport || NCand > 0))
			break;
		if (p >= 7 && p < 9 && VSize(GroundMove) < 0.5)
			continue;
		if (p == 0)
			Offset = vect(0,0,0);
		else if (p == 1)
			Offset = LongDir * (RadiusUU * 0.55);
		else if (p == 2)
			Offset = LongDir * (RadiusUU * -0.55);
		else if (p == 3)
			Offset = Axle * (RadiusUU * 0.30);
		else if (p == 4)
			Offset = Axle * (RadiusUU * -0.30);
		else if (p == 5)
			Offset = LongDir * (RadiusUU * 0.65);
		else if (p == 6)
			Offset = LongDir * (RadiusUU * -0.65);
		else if (p == 7)
			Offset = GroundMove * (RadiusUU * 0.55);
		else if (p == 8)
			Offset = GroundMove * (RadiusUU * -0.55);
		else if (p == 9)
			Offset = (LongDir * 0.44 + Axle * 0.31) * RadiusUU;
		else if (p == 10)
			Offset = (LongDir * 0.44 - Axle * 0.31) * RadiusUU;
		else if (p == 11)
			Offset = (-LongDir * 0.44 + Axle * 0.31) * RadiusUU;
		else
			Offset = (-LongDir * 0.44 - Axle * 0.31) * RadiusUU;
		bHit = class'HB2WorldQuery'.static.GroundQuery(
			Self, AttachUU + Offset, AxisDown, RayLengthUU, True,
			HitLoc, HitNorm, HitDistUU, Hit);
		if (!bHit)
			continue;
		if (!AcceptWheelProbe(i, AttachUU, AxisDown, HitLoc, HitNorm,
			RadiusUU, LengthUU, LatUU))
			continue;
		if (!ConfirmDeepWheelHit(i,AttachUU,AxisDown,RadiusUU,Hit,HitLoc,HitNorm,LengthUU))
			continue;
		if (NCand >= 12)
			break;
		CandL[NCand] = LengthUU;
		CandLat[NCand] = LatUU;
		CandP[NCand] = HitLoc;
		CandN[NCand] = Normal(HitNorm);
		CandHit[NCand] = Hit;
		CandProbe[NCand] = p;
		NCand++;
	}

	Src = "none";
	Pick = -1;
	MinL = 0;
	MaxL = 0;
	if (NCand > 0)
	{
		MinL = CandL[0];
		MaxL = CandL[0];
		for (p = 1; p < NCand; ++p)
		{
			if (CandL[p] < MinL)
				MinL = CandL[p];
			if (CandL[p] > MaxL)
				MaxL = CandL[p];
		}
	}
	if (NCand > 0 && PrevWheelHadContact[i] == 1)
	{
		PhysDeltaUU = Abs(LastWheelCompressRateMps[i])
			* class'HB2WorldQuery'.static.MToUU(FixedDt) + 10.0;
		NearMin = 100000;
		for (p = 0; p < NCand; ++p)
		{
			if (Abs(CandL[p] - PrevWheelLengthUU[i]) <= PhysDeltaUU
				&& (CandN[p] Dot PrevWheelNormal[i]) > 0.50)
			{
				if (Abs(CandL[p] - PrevWheelLengthUU[i]) < NearMin)
				{
					NearMin = Abs(CandL[p] - PrevWheelLengthUU[i]);
					Pick = p;
					BestL = CandL[p];
					Src = "hold";
				}
			}
		}
	}
	if (Pick < 0 && NCand > 0)
	{
		MinL = CandL[0];
		MaxL = CandL[0];
		for (p = 1; p < NCand; ++p)
		{
			if (CandL[p] < MinL)
				MinL = CandL[p];
			if (CandL[p] > MaxL)
				MaxL = CandL[p];
		}
		CountNearMin = 0;
		CountNearMax = 0;
		for (p = 0; p < NCand; ++p)
		{
			if (CandL[p] <= MinL + 8.0)
				CountNearMin++;
			if (CandL[p] >= MaxL - 8.0)
				CountNearMax++;
		}
		if ((MaxL - MinL) > 12.0 && CountNearMax > CountNearMin)
		{
			Src = "geom_reject";
			WheelGeomGlitchCount++;
			BestL = 100000;
			for (p = 0; p < NCand; ++p)
			{
				if (CandL[p] < MaxL - 8.0)
					continue;
				if (CandL[p] < BestL)
				{
					BestL = CandL[p];
					Pick = p;
				}
			}
		}
		else
		{
			Src = "disc";
			BestL = 100000;
			for (p = 0; p < NCand; ++p)
			{
				if (CandLat[p] > RadiusUU * 0.45)
					continue;
				if (CandL[p] < BestL)
				{
					BestL = CandL[p];
					Pick = p;
				}
			}
			if (Pick < 0)
			{
				BestL = MinL;
				for (p = 0; p < NCand; ++p)
					if (CandL[p] <= MinL + 0.05)
						Pick = p;
			}
		}
	}

	if (Pick < 0)
	{
		Ext.X = 6; Ext.Y = 6; Ext.Z = 6;
		bHit = class'HB2WorldQuery'.static.SweepExtent(
			Self, AttachUU, AttachUU + AxisDown * RayLengthUU, Ext, True,
			HitLoc, HitNorm, HitTime, Hit);
		if (bHit && class'HB2WorldQuery'.static.ResolveSweepSurfacePoint(
			Self, Hit, HitLoc, HitNorm, Ext, True,
			SurfaceP, SurfaceN, CenterToSurf))
		{
			if (AcceptWheelProbe(i, AttachUU, AxisDown, SurfaceP, SurfaceN,
				RadiusUU, LengthUU, LatUU)
				&& ConfirmDeepWheelHit(i,AttachUU,AxisDown,RadiusUU,Hit,SurfaceP,SurfaceN,LengthUU))
			{
				Src = "seam_aabb";
				BestL = LengthUU;
				BestLat = LatUU;
				BestP = SurfaceP;
				BestN = Normal(SurfaceN);
				BestHit = Hit;
				Pick = 100;
			}
		}
	}

	if (Pick >= 0 && Pick < 12)
	{
		BestL = CandL[Pick];
		BestLat = CandLat[Pick];
		BestP = CandP[Pick];
		BestN = CandN[Pick];
		BestHit = CandHit[Pick];
	}

	if (Pick >= 0 && bProjectWheelTangent)
		RefineWheelSupport(i,AttachUU,AxisDown,RadiusUU,BestHit,BestP,BestN,BestL);
	if (Pick >= 0 && PrevWheelHadContact[i] == 1)
	{
		PhysDeltaUU = Abs(LastWheelCompressRateMps[i])
			* class'HB2WorldQuery'.static.MToUU(FixedDt) + 10.0;
		if (PrevWheelLengthUU[i] - BestL > PhysDeltaUU)
		{
			NearMin = 100000;
			CountNearMin = -1;
			for (p = 0; p < NCand; ++p)
			{
				if (Abs(CandL[p] - PrevWheelLengthUU[i]) < PhysDeltaUU
					&& (CandN[p] Dot PrevWheelNormal[i]) > 0.50)
				{
					if (Abs(CandL[p] - PrevWheelLengthUU[i]) < NearMin)
					{
						NearMin = Abs(CandL[p] - PrevWheelLengthUU[i]);
						CountNearMin = p;
					}
				}
			}
			if (CountNearMin >= 0)
			{
				Pick = CountNearMin;
				BestL = CandL[Pick];
				BestLat = CandLat[Pick];
				BestP = CandP[Pick];
				BestN = CandN[Pick];
				BestHit = CandHit[Pick];
				Src = "geom_reject";
				WheelGeomGlitchCount++;
			}
			else
			{
				Pick = -1;
				Src = "geom_reject";
				WheelGeomGlitchCount++;
			}
		}
		else if (PrevWheelLengthUU[i] - BestL > 6.0)
			WheelRealImpactCount++;
	}

	LastWheelProbeCount[i] = NCand;
	LastWheelProbeMinL[i] = 0;
	LastWheelProbeMaxL[i] = 0;
	if (NCand > 0)
	{
		LastWheelProbeMinL[i] = MinL;
		LastWheelProbeMaxL[i] = MaxL;
	}
	LastWheelProbePick[i] = -1;
	if (Pick == 100)
		LastWheelProbePick[i] = 99;
	else if (Pick >= 0 && Pick < 12)
		LastWheelProbePick[i] = CandProbe[Pick];

	LastWheelLengthDeltaUU[i] = 0;
	LastWheelDlRateMps[i] = 0;
	LastWheelContactSource[i] = Src;
	if (Pick >= 0)
	{
		if (PrevWheelHadContact[i] == 1)
		{
			LastWheelLengthDeltaUU[i] = BestL - PrevWheelLengthUU[i];
			if (FixedDt > 0.0001)
				LastWheelDlRateMps[i] = -class'HB2WorldQuery'.static.UUToM(
					LastWheelLengthDeltaUU[i]) / FixedDt;
		}
		if (Abs(LastWheelLengthDeltaUU[i]) > Abs(MaxWheelLengthJumpUU))
			MaxWheelLengthJumpUU = LastWheelLengthDeltaUU[i];
		LastWheelHitUU[i] = BestP;
		LastWheelNormal[i] = BestN;
		LastWheelHitActor[i] = BestHit;
		LastWheelLengthUU[i] = BestL;
		PrevWheelLengthUU[i] = BestL;
		PrevWheelNormal[i] = BestN;
		PrevWheelHadContact[i] = 1;
		PointM = class'HB2WorldQuery'.static.UUToMVec(BestP);
		SurfaceVelM = ContactSurfaceVelocityMps(BestHit);
		LastWheelCompressRateMps[i] =
			(PointVelocityMps(class'HB2WorldQuery'.static.UUToMVec(AttachUU))
			- SurfaceVelM) Dot AxisDown;
		FeatureId = 1000 + i * 100 + ContactFeatureId(BestHit, True);
		if (!Core.NativeSetSuspensionHit(i, 1,
			class'HB2WorldQuery'.static.UUToM(BestL),
			PointM.X, PointM.Y, PointM.Z,
			BestN.X, BestN.Y, BestN.Z,
			SurfaceVelM.X, SurfaceVelM.Y, SurfaceVelM.Z,
			FeatureId))
		{
			SuspensionHitFailureCount++;
			return False;
		}
		return True;
	}

	// A lost hit must not keep its old world-space contact position:
	// debug suspension rays otherwise span entire valleys after rollover.
	LastWheelHitUU[i] = vect(0,0,0);
	LastWheelHitActor[i] = None;
	LastWheelLengthUU[i] = SuspensionMaxUU[i];
	LastWheelNormal[i] = vect(0,0,0);
	LastWheelCompressRateMps[i] = 0;
	PrevWheelHadContact[i] = 0;
	if (!Core.NativeSetSuspensionHit(i, 0,
		class'HB2WorldQuery'.static.UUToM(SuspensionMaxUU[i]),
		0, 0, 0, 0, 0, 0, 0, 0, 0, 1000 + i * 100))
		SuspensionHitFailureCount++;
	return False;
}

function GatherSuspensionHits(vector BodyCenterUU)
{
	local int i;
	local bool bWasSupported, bIsSupported;
	local vector PreviousHit;
	local float PreviousLengthUU, SpeedMps;
	local string Transition;

	Core.NativeClearSuspensionHits();
	WheelContactCount = 0;
	for (i = 0; i < 4; ++i)
	{
		bWasSupported = PrevWheelHadContact[i] == 1;
		PreviousHit = LastWheelHitUU[i];
		PreviousLengthUU = LastWheelLengthUU[i];
		bIsSupported = QueryWheelContact(i, BodyCenterUU);
		if (bIsSupported)
			WheelContactCount++;
		if (bWasSupported != bIsSupported && bDiagnosticLog
			&& WheelContactTransitionLogCount < 400
			&& Level.TimeSeconds >= NextWheelContactTransitionLogTime[i])
		{
			WheelContactTransitionLogCount++;
			NextWheelContactTransitionLogTime[i] = Level.TimeSeconds + 0.20;
			if (bIsSupported)
				Transition = "regain";
			else
				Transition = "lost";
			SpeedMps = Sqrt(Core.OutVelX_mps * Core.OutVelX_mps
				+ Core.OutVelY_mps * Core.OutVelY_mps
				+ Core.OutVelZ_mps * Core.OutVelZ_mps);
			Log("HB2_WHEEL_TRANSITION kind="$Transition
				$" t="$Level.TimeSeconds$" step="$TotalStepCount
				$" i="$i$" speedMps="$SpeedMps
				$" gas="$LastGas$" steer="$LastSteer
				$" yaw="$Core.OutYaw_rad
				$" pitch="$Core.OutPitch_rad$" roll="$Core.OutRoll_rad
				$" wx="$Core.OutAngX_radps$" wy="$Core.OutAngY_radps
				$" wz="$Core.OutAngZ_radps
				$" com="$BodyCenterUU$" previousHit="$PreviousHit
				$" prevLengthUU="$PreviousLengthUU
				$" nowSource="$LastWheelContactSource[i]
				$" newHit="$LastWheelHitUU[i]
				$" prevChassisN="$ContactCount
				$" prevPenUU="$LastMaxPenUU);
		}
	}
	if (WheelContactCount == 3)
		SuspensionThreeContactStepCount++;
	if (WheelContactCount < 4)
		SuspensionContactLossStepCount++;
}

function CaptureWheelForceTelemetry()
{
	local int i;
	local float BelowMinM;
	for (i = 0; i < 4; ++i)
	{
		LastWheelSpringN[i] = WheelSpringNAt(i);
		LastWheelDamperN[i] = WheelDamperNAt(i);
		LastWheelBumpN[i] = 0;
		if (PrevWheelHadContact[i] == 1 && LastWheelLengthUU[i] < SuspensionMinUU[i])
		{
			BelowMinM = class'HB2WorldQuery'.static.UUToM(
				SuspensionMinUU[i] - LastWheelLengthUU[i]);
			LastWheelBumpN[i] = SuspensionBumpStopNpm[i] * BelowMinM;
		}
	}
}

function ResetRideMetrics()
{
	MaxVertAccelMps2 = 0;
	MaxRollAccelRadps2 = 0;
	MaxVertAccelStep = 0;
	MaxRollAccelStep = 0;
	MaxVertAccelCause = "none";
	MaxRollAccelCause = "none";
	MaxVertAccelWheel = -1;
	MaxRollAccelWheel = -1;
	LastRideCause = "none";
	LastVertAccelMps2 = 0;
	LastRollAccelRadps2 = 0;
	LastChassisJnN = 0;
}

function string ClassifyRideCause()
{
	local int i, Worst;
	local float Spread, AbsDL, MaxBump, MaxAbsDamp, MaxAbsDL, MaxSpread;
	local float MaxAbsSpring, DlRateGap;

	MaxBump = 0;
	MaxAbsDamp = 0;
	MaxAbsDL = 0;
	MaxSpread = 0;
	MaxAbsSpring = 0;
	DlRateGap = 0;
	Worst = 0;
	for (i = 0; i < 4; ++i)
	{
		AbsDL = Abs(LastWheelLengthDeltaUU[i]);
		Spread = LastWheelProbeMaxL[i] - LastWheelProbeMinL[i];
		if (LastWheelBumpN[i] > MaxBump)
		{
			MaxBump = LastWheelBumpN[i];
			Worst = i;
		}
		if (Abs(LastWheelDamperN[i]) > MaxAbsDamp)
			MaxAbsDamp = Abs(LastWheelDamperN[i]);
		if (Abs(LastWheelSpringN[i]) > MaxAbsSpring)
			MaxAbsSpring = Abs(LastWheelSpringN[i]);
		if (AbsDL > MaxAbsDL)
		{
			MaxAbsDL = AbsDL;
			Worst = i;
		}
		if (Spread > MaxSpread)
			MaxSpread = Spread;
		if (Abs(LastWheelDlRateMps[i] - LastWheelCompressRateMps[i]) > DlRateGap)
			DlRateGap = Abs(LastWheelDlRateMps[i] - LastWheelCompressRateMps[i]);
	}
	MaxVertAccelWheel = Worst;
	if (ContactCount > 0 && Abs(LastChassisJnN) > 800 && LastMaxPenUU > 0.40)
		return "chassis";
	if (MaxAbsDL > 6.0 && MaxSpread > 12.0)
		return "geom";
	if (MaxAbsDL > 8.0 && DlRateGap > 2.0)
		return "geom";
	if (MaxBump > 2500.0)
		return "bump";
	if (MaxAbsDamp > MaxAbsSpring * 1.40 && MaxAbsDamp > 6000.0 && MaxAbsDL < 4.0)
		return "damper";
	if (MaxAbsDL > 4.0)
		return "impact";
	return "none";
}

function LogRideIfNeeded()
{
	local int i;
	local HB2TestGame G;
	local vector ComUU, J;
	local float KeLin, KeAng, Ixx, Iyy, Izz;

	G = HB2TestGame(Level.Game);
	if (!bLogRide && (G == None || !G.bP24))
		return;
	if (!bLogRide)
		return;

	P13VelPostM.X = Core.OutVelX_mps;
	P13VelPostM.Y = Core.OutVelY_mps;
	P13VelPostM.Z = Core.OutVelZ_mps;
	P13OmegaPost.X = Core.OutAngX_radps;
	P13OmegaPost.Y = Core.OutAngY_radps;
	P13OmegaPost.Z = Core.OutAngZ_radps;
	LastVertAccelMps2 = (P13VelPostM.Z - P13VelPreM.Z) / FixedDt;
	LastRollAccelRadps2 = (P13OmegaPost.X - P13OmegaPre.X) / FixedDt;
	J = (P13VelPostM - P13VelPreM) * MassKg;
	LastChassisJnN = 0;
	if (ContactCount > 0 && VSize(LastContactNormal) > 0.5)
		LastChassisJnN = J Dot LastContactNormal;
	KeLin = 0.5 * MassKg * (P13VelPostM Dot P13VelPostM);
	Ixx = BoxInertiaKgM2(0);
	Iyy = BoxInertiaKgM2(1);
	Izz = BoxInertiaKgM2(2);
	KeAng = 0.5 * (Ixx * P13OmegaPost.X * P13OmegaPost.X
		+ Iyy * P13OmegaPost.Y * P13OmegaPost.Y
		+ Izz * P13OmegaPost.Z * P13OmegaPost.Z);
	LastKeJ = KeLin + KeAng;
	LastRideCause = ClassifyRideCause();
	if (Abs(LastVertAccelMps2) >= Abs(MaxVertAccelMps2))
	{
		MaxVertAccelMps2 = LastVertAccelMps2;
		MaxVertAccelStep = TotalStepCount;
		MaxVertAccelCause = LastRideCause;
		MaxVertAccelWheel = MaxVertAccelWheel;
	}
	if (Abs(LastRollAccelRadps2) >= Abs(MaxRollAccelRadps2))
	{
		MaxRollAccelRadps2 = LastRollAccelRadps2;
		MaxRollAccelStep = TotalStepCount;
		MaxRollAccelCause = LastRideCause;
		MaxRollAccelWheel = MaxVertAccelWheel;
	}

	ComUU.X = class'HB2WorldQuery'.static.MToUU(Core.OutPosX_m);
	ComUU.Y = class'HB2WorldQuery'.static.MToUU(Core.OutPosY_m);
	ComUU.Z = class'HB2WorldQuery'.static.MToUU(Core.OutPosZ_m);
	Log("HB2_P24 SUB tag="$LastRideTag$" step="$TotalStepCount
		$" az="$LastVertAccelMps2$" rollAcc="$LastRollAccelRadps2
		$" ke="$LastKeJ$" com="$ComUU
		$" ypr="$Core.OutYaw_rad$","$Core.OutPitch_rad$","$Core.OutRoll_rad
		$" w="$P13OmegaPost
		$" v="$P13VelPostM
		$" wheels="$WheelContactCount$" chassisN="$ContactCount
		$" chassisSkip="$LastChassisSkipCount
		$" penUU="$LastMaxPenUU$" Jn="$LastChassisJnN
		$" cause="$LastRideCause);
	for (i = 0; i < 4; ++i)
	{
		Log("HB2_P24 W tag="$LastRideTag$" step="$TotalStepCount$" i="$i
			$" probe="$LastWheelProbePick[i]$" nCand="$LastWheelProbeCount[i]
			$" Lmin="$LastWheelProbeMinL[i]$" Lmax="$LastWheelProbeMaxL[i]
			$" L="$LastWheelLengthUU[i]$" dL="$LastWheelLengthDeltaUU[i]
			$" rate="$LastWheelCompressRateMps[i]$" dLrate="$LastWheelDlRateMps[i]
			$" spr="$LastWheelSpringN[i]$" damp="$LastWheelDamperN[i]
			$" bump="$LastWheelBumpN[i]$" N="$WheelLoadAt(i)
			$" src="$LastWheelContactSource[i]
			$" n="$LastWheelNormal[i]$" hit="$LastWheelHitUU[i]
			$" st="$WheelStatusAt(i));
	}
}

function LogWheelContactIfNeeded()
{
	local int i;
	local HB2TestGame G;
	G = HB2TestGame(Level.Game);
	if (!bLogWheelContact && (G == None || !G.bP23))
		return;
	for (i = 0; i < 4; ++i)
	{
		if (!bLogWheelContact && Abs(LastWheelLengthDeltaUU[i]) < 6.0)
			continue;
		Log("HB2_P23 WHEEL i="$i
			$" L="$LastWheelLengthUU[i]$" dL="$LastWheelLengthDeltaUU[i]
			$" rate="$LastWheelCompressRateMps[i]
			$" n="$LastWheelNormal[i]
			$" springN="$LastWheelSpringN[i]$" damperN="$LastWheelDamperN[i]
			$" N="$WheelLoadAt(i)$" src="$LastWheelContactSource[i]
			$" hitUU="$LastWheelHitUU[i]$" status="$WheelStatusAt(i));
	}
}

// Wheels own supported ground. A high-n.z chassis hit while two or more
// suspension points are active is a belly scrape, not a wall. Walls (n.z
// below 0.50) still enter the manifold. This does not change wheel probes
// or spring/damper coefficients.
// P2.6a: only a matching wheel support plane may own a non-penetrating
// ground contact. Never suppress genuine chassis penetration into obstacles.
function bool ChassisGroundOwnedByWheels(
	Actor Hit, vector SurfaceUU, vector HitNorm, float SeparationUU)
{
	local int i, Matches;
	local vector N;
	if (!bSuspensionEnabled || WheelContactCount < 2 || Hit == None
		|| VSize(HitNorm) < 0.5 || HitNorm.Z < 0.50)
		return False;
	N = Normal(HitNorm);
	Matches = 0;
	for (i = 0; i < 4; ++i)
	{
		if (PrevWheelHadContact[i] != 1 || LastWheelHitActor[i] != Hit
			|| VSize(LastWheelNormal[i]) < 0.5)
			continue;
		if ((Normal(LastWheelNormal[i]) Dot N) < 0.98)
			continue;
		if (Abs((LastWheelHitUU[i] - SurfaceUU) Dot N) > 2.0)
			continue;
		Matches++;
	}
	// The wheel suspension already owns this coplanar floor, even during
	// a brief OBB overlap near a ramp seam. Check ownership before depth.
	if (Matches >= 2)
		return True;
	// Preserve actual chassis impacts only against unmatched planes.
	if (SeparationUU < -0.25)
		ChassisBellyPreservedCount++;
	return False;
}

// Surface point is unverified: use only actor/normal, never claim coplanarity.
function bool ChassisFallbackNormalOwnedByWheels(Actor Hit, vector HitNorm)
{
	local int i, Matches;
	local vector N;
	if (!bSuspensionEnabled || WheelContactCount < 2 || Hit == None
		|| VSize(HitNorm) < 0.5 || HitNorm.Z < 0.50)
		return False;
	N = Normal(HitNorm);
	Matches = 0;
	for (i = 0; i < 4; ++i)
		if (PrevWheelHadContact[i] == 1 && LastWheelHitActor[i] == Hit
			&& VSize(LastWheelNormal[i]) > 0.5
			&& (Normal(LastWheelNormal[i]) Dot N) >= 0.98)
			Matches++;
	return (Matches >= 2);
}

// P0.6 contact path. Zero-extent HitLocation is a world surface point. A
// swept-Extent HitLocation is treated only as the proxy centre at impact and
// receives a second, zero-extent verification before it may create a lever arm.
function bool ResampleChassisSweep(
	Actor ExpectedHit, vector AtImpact, vector N,
	out vector Surface, out vector SurfaceNormal)
{
	local vector A, B, C, D, P, H, HN;
	local float Dist, Best;
	local int I;
	local Actor Hit;
	if(ExpectedHit==None)
		return False;
	class'HB2WorldQuery'.static.OBBFaceCorners(AtImpact,ChassisHalfUU,Rotation,N,A,B,C,D);
	Best=100000;
	for(I=0;I<5;I++)
	{
		if(I==0) P=A;
		else if(I==1) P=B;
		else if(I==2) P=C;
		else if(I==3) P=D;
		else P=(A+B+C+D)*0.25;
		if(!class'HB2WorldQuery'.static.GroundQuery(Self,P+N*10.0,-N,22.0,True,H,HN,Dist,Hit))
			continue;
		if(Hit!=ExpectedHit || (Normal(HN) Dot N)<0.88 || Abs(Dist-10.0)>=Best)
			continue;
		Best=Abs(Dist-10.0);
		Surface=H;
		SurfaceNormal=Normal(HN);
	}
	return Best<100000;
}

// Depth is measured along the sampled surface normal against the actual OBB
// slice. The furthest corner of an infinite support plane is not used here.
function float MeshPointDepthUU(vector Center, vector Point, vector N)
{
	local vector P, D, H;
	local float Along, HalfSize, Origin, Lo, Hi, NearT, FarT, Swap;
	local int Axis;
	P=(Point-Center) << Rotation;
	D=N << Rotation;
	H=ChassisHalfUU;
	NearT=-100000.0;
	FarT=100000.0;
	for(Axis=0;Axis<3;Axis++)
	{
		if(Axis==0){Origin=P.X; Along=D.X; HalfSize=H.X;}
		else if(Axis==1){Origin=P.Y; Along=D.Y; HalfSize=H.Y;}
		else {Origin=P.Z; Along=D.Z; HalfSize=H.Z;}
		if(Abs(Along)<0.0001)
		{
			if(Abs(Origin)>HalfSize) return 0.0;
			continue;
		}
		Lo=(-HalfSize-Origin)/Along;
		Hi=(HalfSize-Origin)/Along;
		if(Lo>Hi){Swap=Lo; Lo=Hi; Hi=Swap;}
		NearT=FMax(NearT,Lo);
		FarT=FMin(FarT,Hi);
		if(NearT>FarT) return 0.0;
	}
	// A small allowance handles a point just through the top of the OBB
	// after a fast drop. Distant terrain above the body is not support.
	if(FarT < -6.0) return 0.0;
	return FMax(0.0,-NearT);
}

function int AddMeshBellyContacts(vector Center, vector CentralPoint,
	vector CentralNormal, Actor ExpectedHit)
{
	local vector A,B,C,D,Mid,Sample,P,N,Down,Proxy;
	local vector Points[9], Normals[9];
	local float Depths[9], Dist, Depth, Best, SupportLoad, SkidScale;
	local int I,J,Pick,Added,BaseId;
	local Actor Hit;

	Down=vect(0,0,-1);
	Proxy=ChassisAABBProxyUU();
	class'HB2WorldQuery'.static.OBBFaceCorners(Center,ChassisHalfUU,Rotation,
		CentralNormal,A,B,C,D);
	Mid=(A+B+C+D)*0.25;
	for(I=0;I<9;I++)
	{
		if(I==0){P=CentralPoint; N=CentralNormal;}
		else
		{
			if(I==1) Sample=A;
			else if(I==2) Sample=B;
			else if(I==3) Sample=C;
			else if(I==4) Sample=D;
			else if(I==5) Sample=(A+B)*0.5;
			else if(I==6) Sample=(B+D)*0.5;
			else if(I==7) Sample=(D+C)*0.5;
			else Sample=(C+A)*0.5;
			Sample=Mid+(Sample-Mid)*0.88;
			Sample.Z=Center.Z+Proxy.Z+8.0;
			if(!class'HB2WorldQuery'.static.GroundQuery(Self,Sample,Down,
				2.0*Proxy.Z+16.0,True,P,N,Dist,Hit))
				continue;
			if(Hit!=ExpectedHit || VSize(N)<0.5)
				continue;
			N=Normal(N);
		}
		if(N.Z<0.50) continue;
		Depth=MeshPointDepthUU(Center,P,N);
		if(Depth<0.10) continue;
		if(ChassisGroundOwnedByWheels(ExpectedHit,P,N,-Depth)) continue;
		Points[I]=P;
		Normals[I]=N;
		Depths[I]=Depth;
	}
	SkidScale=1;
	if(bMeshBellySkidFriction)
	{
		for(I=0;I<4;I++) SupportLoad+=WheelLoadAt(I);
		// When the wheels carry weight, the belly rubs like a skid plate.
		// Normal impulses still prevent penetration and landings stay solid.
		SkidScale=1.0-0.82*FClamp(SupportLoad/FMax(1.0,MassKg*9.81),0.0,1.0);
	}
	BaseId=6000+ContactFeatureId(ExpectedHit,True);
	for(J=0;J<3 && ContactCount<16;J++)
	{
		Pick=-1; Best=0;
		for(I=0;I<9;I++)
			if(Depths[I]>Best){Pick=I; Best=Depths[I];}
		if(Pick<0) break;
		P=Points[Pick];
		N=Normals[Pick];
		for(I=0;I<9;I++)
			if(VSize(Points[I]-P)<16.0) Depths[I]=0;
		AddPointContact(P,N,Best,0.0,ExpectedHit,BaseId+Pick*10,SkidScale);
		LastSurfacePointUU=P;
		LastContactRUU=P-Center;
		LastRxNLenUU=VSize(LastContactRUU Cross N);
		Added++;
	}
	if(Added>0)
	{
		LastChassisContactMode="mesh_belly";
		LastManifoldAdded=Added;
		LastFeatureBase=BaseId;
	}
	return Added;
}


function GatherContactsV2(vector PrevUU, vector ProposedUU)
{
	local vector HitLoc, HitNorm, Extent, Start, End, Down;
	local vector ContactPoint, SurfaceNorm;
	local vector GroundPoint, GroundNorm;
	local Actor Hit, GroundHit;
	local float PenUU, HitTime, SupportUU, SeparationUU, OffsetUU, ContactRestitution;
	local bool bHit, bGroundAdded, bReliablePoint, bDuplicate;
	local int Added;
	local vector ProxyAABB;

	Core.NativeClearContacts();
	ContactCount = 0;
	LastChassisSkipCount = 0;
	LastMaxPenUU = 0;
	LastHitActor = None;
	LastHitKind = "None";
	LastSweepHitTime = 1.0;
	LastManifoldAdded = 0;
	LastCornerSepProposed = "";
	LastCornerSepToi = "";
	LastProposedUU = ProposedUU;
	LastToiUU = ProposedUU;
	ProxyAABB = ChassisAABBProxyUU();
	Extent = ProxyAABB;

	// Sweep first. A vertical probe at the *end* of a 1/60 step can steal the
	// wall manifold after the AABB TOI and sample corners in a tunneled pose
	// (P1.3c: 2000 UU/s face_1, |ÄŽâ€°| 0Ă˘â€ â€™13.53, fid=101). Contacts belong at TOI.
	bHit = class'HB2WorldQuery'.static.SweepExtent(
		Self, PrevUU, ProposedUU, Extent, True,
		HitLoc, HitNorm, HitTime, Hit);
	if (bHit && HitTime < 0.999 && VSize(HitNorm) > 0.5)
	{
		HitNorm = Normal(HitNorm);
		LastSweepCenterUU = HitLoc;
		LastSweepHitTime = HitTime;
		LastToiUU = PrevUU + (ProposedUU - PrevUU) * HitTime;
		bReliablePoint = class'HB2WorldQuery'.static.ResolveSweepSurfacePoint(
			Self, Hit, HitLoc, HitNorm, Extent, True,
			ContactPoint, SurfaceNorm, OffsetUU);
		if (!bReliablePoint && bResampleChassisSweep)
		{
			bReliablePoint=ResampleChassisSweep(Hit,LastToiUU,HitNorm,ContactPoint,SurfaceNorm);
			if(bReliablePoint)
				OffsetUU=Abs((HitLoc-ContactPoint) Dot HitNorm);
		}
		if (bReliablePoint)
		{
			HitNorm = Normal(SurfaceNorm);
			LastSurfacePointUU = ContactPoint;
			SupportUU = class'HB2WorldQuery'.static.OBBSupportRadius(ChassisHalfUU, Rotation, HitNorm);
			SeparationUU = ((ProposedUU - LastSurfacePointUU) Dot HitNorm) - SupportUU;
			if (bSuspensionEnabled && SeparationUU > 0.5)
			{
				ChassisAABBRejectCount++;
			}
			else if (ChassisGroundOwnedByWheels(
				Hit, LastSurfacePointUU, HitNorm, SeparationUU))
			{
				LastChassisSkipCount++;
			}
			else
			{
			if (Abs(HitNorm.Z) < 0.55)
				ContactRestitution = 0.0;
			else
				ContactRestitution = Restitution;
			Added = AddVerifiedPlaneContacts(
				ProposedUU, LastSurfacePointUU, HitNorm, ContactRestitution, Hit, False);
			if (Added == 0)
				ChassisFootprintRejectCount++;
			else
			{
			LastCornerSepProposed = CornerSepList(ProposedUU, LastSurfacePointUU, HitNorm);
			LastCornerSepToi = CornerSepList(LastToiUU, LastSurfacePointUU, HitNorm);
			ReliablePointContactCount += Added;
			ReliableSweepPointCount++;
			LastReliableSweepHitKind = ClassifyHit(Hit);
			LastSweepPointOffsetUU = OffsetUU;
			GroundHit = Hit;
			GroundPoint = LastApplyPointUU;
			GroundNorm = HitNorm;
			bGroundAdded = True;
			if (!bLoggedExtentSemantics)
			{
				bLoggedExtentSemantics = True;
				Log("HB2_TRACE EXTENT_CENTER_VERIFIED center="$HitLoc$" surface="$LastSurfacePointUU$" apply="$LastApplyPointUU$" normal="$HitNorm$" centerToSurfaceUU="$OffsetUU$" obbSupportUU="$SupportUU$" rXnUU="$LastRxNLenUU$" mode="$LastChassisContactMode$" added="$Added);
			}
			}
			}
		}
		else
		{
			// Diagnostic fallback: normal impulse at COM, zero penetration and no
			// invented moment arm. This geometry path remains NOT_IMPLEMENTED.
			if (ChassisFallbackNormalOwnedByWheels(Hit, HitNorm))
				LastChassisSkipCount++;
			else
			{
			FallbackPointContactCount++;
			LastSurfacePointUU = HitLoc;
			LastContactRUU = vect(0,0,0);
			LastRxNLenUU = 0;
			LastChassisContactMode = "com_fallback";
			AddPointContact(ProposedUU, HitNorm, 0.0, 0.0, Hit,
				900 + ContactFeatureId(Hit, False));
			GroundHit = Hit;
			GroundNorm = HitNorm;
			bGroundAdded = True;
			if (FallbackPointContactCount <= 4)
				Log("HB2_TRACE NOT_IMPLEMENTED sweep contact point fallback=COM hit="$Hit$" kind="$ClassifyHit(Hit)$" center="$HitLoc$" normal="$HitNorm);
			}
		}
	}

	// Vertical support probe. Skip if the sweep already owns this surface.
	Start = ProposedUU + vect(0,0,1) * (ProxyAABB.Z + 8);
	End = ProposedUU - vect(0,0,1) * (ProxyAABB.Z + 400);
	Down = vect(0,0,-1);
	bHit = class'HB2WorldQuery'.static.GroundQuery(
		Self, Start, Down, VSize(End - Start), True,
		HitLoc, HitNorm, OffsetUU, Hit);
	if (bHit && VSize(HitNorm) > 0.5 && HitNorm.Z >= 0.34)
	{
		HitNorm = Normal(HitNorm);
		bDuplicate = bGroundAdded && Hit == GroundHit
			&& (HitNorm Dot GroundNorm) > 0.98;
		if (bDuplicate)
		{
			DuplicateContactCount++;
		}
		else
		{
			SupportUU = class'HB2WorldQuery'.static.OBBSupportRadius(ChassisHalfUU, Rotation, HitNorm);
			SeparationUU = ((ProposedUU - HitLoc) Dot HitNorm) - SupportUU;
			if ((!bSuspensionEnabled && SeparationUU <= 4.0)
				|| (bSuspensionEnabled && SeparationUU < 0.0))
			{
				if (ChassisGroundOwnedByWheels(Hit, HitLoc, HitNorm, SeparationUU))
					LastChassisSkipCount++;
				else if (bSampleMeshBelly && (Hit.IsA('StaticMeshActor') || Hit.bIsStaticMesh))
					Added=AddMeshBellyContacts(ProposedUU,HitLoc,HitNorm,Hit);
				else if (HitNorm.Z >= 0.90
					&& !(bVerifyMeshFootprints && (Hit.IsA('StaticMeshActor') || Hit.bIsStaticMesh)))
				{
					PenUU = FMax(0.0, -SeparationUU);
					ContactPoint = class'HB2WorldQuery'.static.ProjectOnPlane(ProposedUU, HitLoc, HitNorm);
					LastSurfacePointUU = HitLoc;
					LastContactRUU = ContactPoint - ProposedUU;
					LastRxNLenUU = VSize(LastContactRUU Cross HitNorm);
					LastChassisContactMode = "plane_com";
					AddPointContact(ContactPoint, HitNorm, PenUU, 0.0, Hit,
						ContactFeatureId(Hit, True));
					Added = 1;
					LastManifoldAdded = 1;
					LastFeatureBase = ContactFeatureId(Hit, True);
				}
				else
					Added = AddVerifiedPlaneContacts(ProposedUU, HitLoc, HitNorm, 0.0, Hit, True);
				ReliablePointContactCount += Added;
				if (!bLoggedLineSemantics)
				{
					bLoggedLineSemantics = True;
					Log("HB2_TRACE LINE_SURFACE verified mode="$LastChassisContactMode$" apply="$LastApplyPointUU$" normal="$HitNorm$" separationUU="$SeparationUU$" obbSupportUU="$SupportUU$" rXnUU="$LastRxNLenUU$" added="$Added);
				}
			}
		}
	}
	// Native Core3D consumes obstacle contacts in the same fixed substep
	// as the suspension and chassis, without changing the tyre force model.
	GatherWheelObstacleContacts(ProposedUU);
}


// P2.6b: conservative front-of-tire obstacle feelers.
// UE227 does not expose a swept wheel sphere. Seven finite radial rays sample
// the front hemisphere of the tyre; eligible StaticMesh hits yield one physical
// chassis impulse contact at the wheel surface, separate from tyre traction.
// This is *not* a replacement for a native sphere/convex wheel narrowphase.
function GatherWheelObstacleContacts(vector ProposedUU)
{
	local vector Fwd, Right, Up, Travel, Axle, Down, AttachUU, WheelCenter, WheelVelM, PlanarWheelVel;
	local vector Dir, HitLoc, HitNorm, BestPoint, BestNorm, ContactM, SurfaceVelM;
	local vector FaceProbe, FacePoint, FaceNormal;
	local Actor FaceActor;
	local float FaceDistance;
	local float RadiusUU, LengthUU, DistUU, PenUU, BestPenUU;
	local float SteerRad, Cs, Ss;
	local Actor Hit, BestHit;
	local int i, p, BestProbe;

	WheelObstacleContactCount = 0;
	WheelObstacleLastWheel = -1;
	WheelObstacleLastPenUU = 0;
	WheelObstacleLastActor = None;
	WheelObstacleLastNormal = vect(0,0,0);
	WheelObstacleLastPointUU = vect(0,0,0);
	if (!bWheelObstacleContactsEnabled || !bSuspensionEnabled
		|| ChassisProfile != "p15_vehicle" || Core == None)
		return;
	GetAxes(Rotation, Fwd, Right, Up);
	for (i = 0; i < 4; ++i)
	{
		SteerRad = 0;
		if (i < 2)
			SteerRad = EffectiveSteerRad();
		Cs = Cos(SteerRad);
		Ss = Sin(SteerRad);
		Travel = Fwd * Cs + Right * Ss;
		Axle = Right * Cs - Fwd * Ss;
		Down = Normal(SuspensionAxisBody[i] >> Rotation);
		AttachUU = ProposedUU + (SuspensionAttachmentUU[i] >> Rotation);
		LengthUU = LastWheelLengthUU[i];
		if (LengthUU < 0.5 && PrevWheelHadContact[i] == 0)
			LengthUU = SuspensionRestUU[i];
		WheelCenter = AttachUU + Down * LengthUU;
		// When moving, probe the tyre's actual direction of travel, not
		// the throttle command. Covers rollback and sideways sliding.
		// At very low speed retain the steered/commanded front hemisphere.
		WheelVelM = PointVelocityMps(
			class'HB2WorldQuery'.static.UUToMVec(WheelCenter));
		PlanarWheelVel = WheelVelM - Up * (WheelVelM Dot Up);
		if (VSize(PlanarWheelVel) >= 0.50)
		{
			Travel = Normal(PlanarWheelVel);
			Axle = Normal(Up Cross Travel);
		}
		else if (LastGas < -0.05)
			Travel = -Travel;
		RadiusUU = WheelRadiusUU[i];
		BestPenUU = 0.0;
		BestHit = None;
		BestProbe = -1;
		for (p = 0; p < 7; ++p)
		{
			if (p == 0)
				Dir = Travel;
			else if (p == 1)
				Dir = Normal(Travel + Down * 0.45);
			else if (p == 2)
				Dir = Normal(Travel + Down * 0.75);
			else if (p == 3)
				Dir = Normal(Travel - Down * 0.35);
			else if (p == 4)
				Dir = Normal(Travel - Down * 0.65);
			else if (p == 5)
				Dir = Normal(Travel + Axle * 0.40);
			else
				Dir = Normal(Travel - Axle * 0.40);
			if (!class'HB2WorldQuery'.static.GroundQuery(
				Self, WheelCenter, Dir, RadiusUU, True,
				HitLoc, HitNorm, DistUU, Hit))
				continue;
			if (Hit == None || !(Hit.IsA('StaticMeshActor') || Hit.bIsStaticMesh))
				continue;
			if (VSize(HitNorm) < 0.5 || DistUU < 0.1)
				continue;
			HitNorm = Normal(HitNorm);
			// Upward-facing ground is handled by suspension tyre rays.
			// Obstacle surfaces must genuinely oppose wheel travel.
			if ((HitNorm Dot Travel) > -0.15 || HitNorm.Z > 0.90)
				continue;
			if ((HitNorm Dot Normal(WheelCenter - HitLoc)) < 0.40)
				continue;
			// Verify the face above the sample so a short mesh seam or
			// bevel cannot repeatedly contribute an obstacle impulse.
			FaceProbe = HitLoc + vect(0,0,1) * (RadiusUU * 0.45);
			if (!class'HB2WorldQuery'.static.GroundQuery(Self, FaceProbe + HitNorm * 3.0,
				-HitNorm, 6.0, True, FacePoint, FaceNormal, FaceDistance, FaceActor)
				|| FaceActor != Hit || (Normal(FaceNormal) Dot HitNorm) < 0.92)
				continue;
			// Prevent a second solver contact on the same supported plane.
			if (LastWheelHitActor[i] == Hit
				&& VSize(LastWheelNormal[i]) > 0.5
				&& (HitNorm Dot Normal(LastWheelNormal[i])) > 0.98
				&& Abs((LastWheelHitUU[i] - HitLoc) Dot HitNorm) <= 2.0)
				continue;
			PenUU = RadiusUU - DistUU;
			if (PenUU <= 0.10)
				continue;
			WheelObstacleProbeHitTotal++;
			if (PenUU > BestPenUU)
			{
				BestPenUU = PenUU;
				BestPoint = HitLoc;
				BestNorm = HitNorm;
				BestHit = Hit;
				BestProbe = p;
			}
		}
		if (BestProbe < 0)
			continue;
		// The native solver currently accepts up to 16 world contacts.
		// Avoid exceeding it when chassis has a multi-point manifold.
		if (ContactCount + WheelObstacleContactCount >= 16)
			break;
		ContactM = class'HB2WorldQuery'.static.UUToMVec(BestPoint);
		SurfaceVelM = ContactSurfaceVelocityMps(BestHit);
		Core.NativeAddContactAtPoint(
			ContactM.X, ContactM.Y, ContactM.Z,
			BestNorm.X, BestNorm.Y, BestNorm.Z,
			class'HB2WorldQuery'.static.UUToM(BestPenUU),
			0.0, FClamp(TireMu, 0.0, 1.0),
			SurfaceVelM.X, SurfaceVelM.Y, SurfaceVelM.Z,
			4000 + i * 100 + ContactFeatureId(BestHit, False));
		WheelObstacleContactCount++;
		WheelObstacleContactTotal++;
		if (bDiagnosticLog && Level.TimeSeconds >= NextWheelObstacleEventLogTime)
		{
			NextWheelObstacleEventLogTime = Level.TimeSeconds + 0.25;
			Log("HB2_P26B HIT t="$Level.TimeSeconds
				$" wheel="$i$" probe="$BestProbe$" actor="$BestHit
				$" loc="$BestPoint$" n="$BestNorm
				$" penUU="$BestPenUU$" chassisN="$ContactCount
				$" chassisPoint="$LastContactPointUU$" gas="$LastGas
				$" chassisHalf="$ChassisHalfUU);
		}
		if (BestPenUU > WheelObstacleLastPenUU)
		{
			WheelObstacleLastPenUU = BestPenUU;
			WheelObstacleLastWheel = i;
			WheelObstacleLastActor = BestHit;
			WheelObstacleLastPointUU = BestPoint;
			WheelObstacleLastNormal = BestNorm;
		}
	}
}

function float WheelStatusAt(int i)
{
	if (i == 0) return Core.OutWheel0Status;
	if (i == 1) return Core.OutWheel1Status;
	if (i == 2) return Core.OutWheel2Status;
	return Core.OutWheel3Status;
}

function float WheelLoadAt(int i)
{
	if (i == 0) return Core.OutWheel0NormalLoad_N;
	if (i == 1) return Core.OutWheel1NormalLoad_N;
	if (i == 2) return Core.OutWheel2NormalLoad_N;
	return Core.OutWheel3NormalLoad_N;
}

function bool WheelTireActive(int i)
{
	if (!bSuspensionEnabled)
		return False;
	if (i < 0 || i > 3)
		return False;
	if (VSize(LastWheelNormal[i]) < 0.5)
		return False;
	if (WheelStatusAt(i) < 2.5)
		return False;
	if (WheelLoadAt(i) <= 0)
		return False;
	return True;
}

function vector PointVelocityMps(vector PointM)
{
	local vector Com, R, Omega, Vel;
	Com.X = Core.OutPosX_m;
	Com.Y = Core.OutPosY_m;
	Com.Z = Core.OutPosZ_m;
	Omega.X = Core.OutAngX_radps;
	Omega.Y = Core.OutAngY_radps;
	Omega.Z = Core.OutAngZ_radps;
	Vel.X = Core.OutVelX_mps;
	Vel.Y = Core.OutVelY_mps;
	Vel.Z = Core.OutVelZ_mps;
	R = PointM - Com;
	return Vel + (Omega Cross R);
}

function vector SteerLongDir(vector Fwd, vector Nrm, float SteerRad)
{
	local vector LongDir, Lat;
	LongDir = Fwd - Nrm * (Fwd Dot Nrm);
	if (VSize(LongDir) < 0.05)
		return vect(0,0,0);
	LongDir = Normal(LongDir);
	if (Abs(SteerRad) < 0.001)
		return LongDir;
	Lat = Nrm Cross LongDir;
	if (VSize(Lat) < 0.05)
		return LongDir;
	Lat = Normal(Lat);
	return Normal(LongDir * Cos(SteerRad) + Lat * Sin(SteerRad));
}

function float ModernSteerLimitRad(float Speed)
{
	local float WheelbaseM, CornerAccel, TanMax, AccelRatio;
	if (MaxCorneringAccelMps2 <= 0.0)
		return MaxSteerRad;
	WheelbaseM = class'HB2WorldQuery'.static.UUToM(
		Abs(SuspensionAttachmentUU[0].X - SuspensionAttachmentUU[2].X));
	if (WheelbaseM <= 0.01)
		return MaxSteerRad;
	CornerAccel = MaxCorneringAccelMps2;
	if (HighSpeedCorneringAccelMps2 > CornerAccel)
		CornerAccel += (HighSpeedCorneringAccelMps2 - CornerAccel)
			* FClamp((Speed * 3.6 - 25.0) / 19.0, 0.0, 1.0);
	TanMax = Sin(MaxSteerRad) / Cos(MaxSteerRad);
	AccelRatio = Speed*Speed * TanMax / (CornerAccel * WheelbaseM);
	return Atan(TanMax / Sqrt(1.0 + AccelRatio*AccelRatio));
}

function float EffectiveSteerRad()
{
	local vector Vel, Fwd, Right, Up;
	local float Demand, Want, Speed, WheelbaseM, Limit;
	Demand = FClamp(LastSteer, -1.0, 1.0);
	Want = Demand * MaxSteerRad;
	if (Core == None || Abs(Want) < 0.001 || MaxCorneringAccelMps2 <= 0)
		return Want;
	Vel.X = Core.OutVelX_mps;
	Vel.Y = Core.OutVelY_mps;
	Vel.Z = Core.OutVelZ_mps;
	if (ModernVehicleProfileActive())
	{
		// Scale steering input after limiting the full-lock angle. Partial
		// input must retain its range as the speed envelope narrows.
		Speed = Sqrt(Vel.X*Vel.X + Vel.Y*Vel.Y);
		return Demand * ModernSteerLimitRad(Speed);
	}
	GetAxes(Rotation, Fwd, Right, Up);
	Speed = Abs(Vel Dot Fwd);
	if (Speed < 0.50)
		return Want;
	WheelbaseM = class'HB2WorldQuery'.static.UUToM(
		Abs(SuspensionAttachmentUU[0].X - SuspensionAttachmentUU[2].X));
	Limit = Atan(MaxCorneringAccelMps2 * WheelbaseM / (Speed * Speed));
	return FClamp(Want, -Limit, Limit);
}

function float TireSlipAngleRad(float VLong, float VLat)
{
	if (Abs(VLong) < 0.05 && Abs(VLat) < 0.0001)
		return 0;
	return Atan(VLat / FMax(Abs(VLong), 0.05));
}

function vector InverseInertiaWorldMul(vector V)
{
	local vector X, Y, Z, R;
	local float Ixx, Iyy, Izz;
	GetAxes(Rotation, X, Y, Z);
	Ixx = BoxInertiaKgM2(0);
	Iyy = BoxInertiaKgM2(1);
	Izz = BoxInertiaKgM2(2);
	if (Ixx <= 0 || Iyy <= 0 || Izz <= 0)
		return vect(0,0,0);
	R = X * ((V Dot X) / Ixx);
	R += Y * ((V Dot Y) / Iyy);
	R += Z * ((V Dot Z) / Izz);
	return R;
}

function float EffectiveMassAtPoint(vector PointM, vector Dir)
{
	local vector Com, R, RxD, Angular;
	local float K;
	if (MassKg <= 0 || Core == None || VSize(Dir) < 0.5)
		return 0;
	Dir = Normal(Dir);
	Com.X = Core.OutPosX_m;
	Com.Y = Core.OutPosY_m;
	Com.Z = Core.OutPosZ_m;
	R = PointM - Com;
	RxD = R Cross Dir;
	Angular = InverseInertiaWorldMul(RxD);
	K = 1.0 / MassKg + ((Angular Cross R) Dot Dir);
	if (K <= 0.0000001)
		return 0;
	return 1.0 / K;
}

function TrackTireForceChange(int i, float ForceMagN)
{
	local float DeltaN;
	if (i < 0 || i > 3)
		return;
	DeltaN = Abs(ForceMagN - PrevTireForceMagN[i]);
	if (DeltaN > MaxTireForceDeltaN[i])
		MaxTireForceDeltaN[i] = DeltaN;
	PrevTireForceMagN[i] = ForceMagN;
}

function TrackTireRecontact(int i, float ForceMagN)
{
	if (i < 0 || i > 3)
		return;
	if (PrevTireForceActive[i] == 0 && ForceMagN > MaxTireRecontactForceN[i])
		MaxTireRecontactForceN[i] = ForceMagN;
	PrevTireForceActive[i] = 1;
}

function ResetTireForceChangeTelemetry()
{
	local int i;
	for (i = 0; i < 4; ++i)
	{
		PrevTireForceMagN[i] = Sqrt(LastTireFx[i] * LastTireFx[i]
			+ LastTireFy[i] * LastTireFy[i]);
		MaxTireForceDeltaN[i] = 0;
		MaxTireRecontactForceN[i] = 0;
		if (WheelTireActive(i))
			PrevTireForceActive[i] = 1;
		else
			PrevTireForceActive[i] = 0;
	}
}

function ClearTireTelemetry()
{
	local int i;
	LastTireActiveCount = 0;
	LastTireMaxMuUtil = 0;
	LastFrontTireYawNm = 0;
	LastRearTireYawNm = 0;
	for (i = 0; i < 4; ++i)
	{
		LastTireN[i] = 0;
		LastTireVLong[i] = 0;
		LastTireVLat[i] = 0;
		LastTireSlipAngleRad[i] = 0;
		LastTireFx[i] = 0;
		LastTireFy[i] = 0;
		LastTireCapN[i] = 0;
		LastTireMuUtil[i] = 0;
		LastTireSource[i] = "none";
	}
}

function RefreshBodyMotionTelemetry()
{
	local vector Vel, Fwd, Right, Up;
	if (Core == None)
		return;
	Vel.X = Core.OutVelX_mps;
	Vel.Y = Core.OutVelY_mps;
	Vel.Z = Core.OutVelZ_mps;
	GetAxes(Rotation, Fwd, Right, Up);
	LastBodyLateralSpeedMps = Vel Dot Right;
	LastRollRateRadps = Core.OutAngX_radps;
	LastYawRateRadps = Core.OutAngZ_radps;
}

function float DesiredDriveAccelMps2()
{
	local vector Vel, Fwd, Right, Up;
	local float Spd, Taper, Frac;
	local HB2TestGame G;
	if (Core == None)
		return DriverAccelMps2;
	Vel.X = Core.OutVelX_mps;
	Vel.Y = Core.OutVelY_mps;
	Vel.Z = Core.OutVelZ_mps;
	Spd = VSize(Vel);
	// Keep the published P2.3/P2.4/P2.5a regression vehicle parameters
	// stable; apply the heavy-diesel demand curve only to manual driving
	// and the separate SpireVillage road test.
	G = HB2TestGame(Level.Game);
	if (bDieselDriveCurve && ChassisProfile == "p15_vehicle"
		&& ControlProfile == "p2_tires"
		&& (G == None || !(G.bP0 || G.bP1 || G.bP2 || G.bP21
			|| G.bP22 || G.bP23 || G.bP24 || G.bP25a || G.bP26a)))
	{
		GetAxes(Rotation, Fwd, Right, Up);
		Spd = Abs(Vel Dot Fwd);
		if (Spd <= 5.0)
			Taper = 1.0;
		else if (Spd < 12.0)
			Taper = 1.0 - 0.25 * (Spd - 5.0) / 7.0;
		else
			Taper = 0.75 * FClamp((DieselMaxSpeedMps - Spd)
				/ FMax(1.0, DieselMaxSpeedMps - 12.0), 0.0, 1.0);
		LastDesiredDriveAccelMps2 = DieselLaunchAccelMps2 * Taper;
		return LastDesiredDriveAccelMps2;
	}
	Frac = DriverAccelMinFrac;
	if (Frac < 0.05)
		Frac = 0.05;
	if (Frac > 1.0)
		Frac = 1.0;
	if (DriverAccelFadeSpeedMps <= 0.05)
		Taper = 1.0;
	else
	{
		Taper = 1.0 - (1.0 - Frac) * FClamp(Spd / DriverAccelFadeSpeedMps, 0.0, 1.0);
	}
	LastDesiredDriveAccelMps2 = DriverAccelMps2 * Taper;
	return LastDesiredDriveAccelMps2;
}

function LogTireTelemetry()
{
	local int i;
	RefreshBodyMotionTelemetry();
	for (i = 0; i < 4; ++i)
		Log("HB2_TIRE t="$Level.TimeSeconds$" i="$i
			$" contact="$WheelTireActive(i)$" status="$WheelStatusAt(i)
			$" N="$LastTireN[i]$" vLong="$LastTireVLong[i]$" vLat="$LastTireVLat[i]
			$" slipRad="$LastTireSlipAngleRad[i]$" capN="$LastTireCapN[i]
			$" Fx="$LastTireFx[i]$" Fy="$LastTireFy[i]
			$" muUtil="$LastTireMuUtil[i]$" src="$LastTireSource[i]
			$" hitUU="$LastWheelHitUU[i]$" n="$LastWheelNormal[i]);
	Log("HB2_TIRE_SUM t="$Level.TimeSeconds$" control="$ControlProfile
		$" active="$LastTireActiveCount$" loadN="$LastLoadSumN
		$" wheels="$LastCoastGroundWheels$" maxMu="$LastTireMaxMuUtil
		$" Jgas="$LastThrottleImpulseNs$" Jbrake="$LastBrakeImpulseNs
		$" Jroll="$LastRollImpulseNs$" Jeng="$LastEngineImpulseNs
		$" Jaero="$LastAeroImpulseNs$" mode="$LastCoastMode
		$" gas="$LastGas$" steer="$LastSteer$" brake="$LastBrake
		$" yawCorr="$LastYawCorrectionRadps$" steerEffRad="$LastEffectiveSteerRad
		$" bodyLatMps="$LastBodyLateralSpeedMps$" rollRate="$LastRollRateRadps
		$" yawRate="$LastYawRateRadps$" omegaZ="$Core.OutAngZ_radps
		$" driveA="$LastDesiredDriveAccelMps2
		$" chassisPenUU="$LastMaxPenUU$" chassisMode="$LastChassisContactMode
		$" impulseFail="$LastTireImpulseFail);
}

function ApplyOneWheelTire(int i, float DT, float LoadSum, bool bUseTireSnapshot,
	vector TireComM, vector TireVelMps, vector TireOmega, float SnapshotSteer)
{
	local vector Nrm, Fwd, Right, Up, LongDir, LatDir, PointM, Vrel, J, ComM, YawTorque;
	local float N, SteerRad, VLong, VLat, Fx, Fy, Cap, Mag, Scale, Sgn, MaxF, EffMass, LongCap;
	local string Src;
	local bool bLevelRestHold;

	LastTireSource[i] = "none";
	if (!WheelTireActive(i) || DT <= 0 || LoadSum <= 0)
		return;
	if (TireContactRiseTime > 0)
		TireContactBlend[i] = FClamp(TireContactBlend[i] + DT / TireContactRiseTime, 0.0, 1.0);
	else
		TireContactBlend[i] = 1.0;
	N = WheelLoadAt(i) * TireContactBlend[i];
	LastTireN[i] = N;
	Nrm = Normal(LastWheelNormal[i]);
	GetAxes(Rotation, Fwd, Right, Up);
	SteerRad = 0;
	if (i == 0 || i == 1)
	{
		if (bUseTireSnapshot)
			SteerRad = SnapshotSteer;
		else
			SteerRad = EffectiveSteerRad();
		LastEffectiveSteerRad = SteerRad;
	}
	LongDir = SteerLongDir(Fwd, Nrm, SteerRad);
	if (VSize(LongDir) < 0.05)
		return;
	LatDir = Nrm Cross LongDir;
	if (VSize(LatDir) < 0.05)
		return;
	LatDir = Normal(LatDir);
	PointM = class'HB2WorldQuery'.static.UUToMVec(LastWheelHitUU[i]);
	if (bUseTireSnapshot)
		Vrel = TireVelMps + (TireOmega Cross (PointM - TireComM));
	else
		Vrel = PointVelocityMps(PointM);
	Vrel -= ContactSurfaceVelocityMps(LastWheelHitActor[i]);
	Vrel = Vrel - Nrm * (Vrel Dot Nrm);
	VLong = Vrel Dot LongDir;
	VLat = Vrel Dot LatDir;
	LastTireVLong[i] = VLong;
	LastTireVLat[i] = VLat;
	LastTireSlipAngleRad[i] = TireSlipAngleRad(VLong, VLat);
	Fx = 0;
	if (Abs(LastGas) > 0.05)
		Fx = LastGas * DesiredDriveAccelMps2() * MassKg * (N / LoadSum);
	Sgn = 0;
	if (Abs(LastGas) <= 0.05)
	{
		// Neutral rolling resistance must keep acting below the display/rest
		// deadzone.  The effective-mass cap below prevents velocity reversal.
		if (VLong > 0.0001)
			Sgn = 1;
		else if (VLong < -0.0001)
			Sgn = -1;
	}
	else if (VLong > CoastSpeedDeadzoneMps)
		Sgn = 1;
	else if (VLong < -CoastSpeedDeadzoneMps)
		Sgn = -1;
	if (Sgn != 0)
	{
		Fx = Fx - RollingResistanceCoeff * N * Sgn;
		if (Abs(LastGas) <= 0.05)
			Fx = Fx - EngineBrakeLoadCoeff * N * Sgn;
		if (LastBrake > 0.1)
			Fx = Fx - SpaceBrakeLoadCoeff * N * LastBrake * Sgn;
	}
	if (ModernTorqueDriveActive())
	{
		if (Abs(LastGas) > 0.05)
		{
			// Powered longitudinal force comes from actual wheel-to-ground
			// speed difference. Airborne wheels have no ground hit/force.
			Fx = FClamp((WheelOmegaRadps[i]
				* class'HB2WorldQuery'.static.UUToM(WheelRadiusUU[i]) - VLong)
				* WheelSlipStiffnessNspm, -TireMu * N, TireMu * N);
			LastDriveMaxWheelSlipMps = FMax(LastDriveMaxWheelSlipMps,
				Abs(WheelOmegaRadps[i]
				* class'HB2WorldQuery'.static.UUToM(WheelRadiusUU[i]) - VLong));
		}
		else
		{
			// Disengaged clutch: bleed *residual wheel slip* against ground
			// speed without pushing the chassis forward. Preserve the
			// independent rolling/braking Fx computed above (always opposing
			// motion). Uncontacted airborne wheels still spin down through
			// bearing drag in UpdateTorque4WD.
			WheelOmegaRadps[i] += FClamp(DT * 12.0, 0.0, 1.0)
				* (VLong / FMax(0.01,
				class'HB2WorldQuery'.static.UUToM(WheelRadiusUU[i]))
				- WheelOmegaRadps[i]);
		}
	}
	Fy = -TireLateralSlipCoeff * N * LastTireSlipAngleRad[i];
	// At zero driver demand, a fully supported near-level vehicle may
	// settle into static tyre friction instead of slowly integrating tiny
	// per-substep contact jitter for hours. This applies contact impulses
	// through Core3D, never snaps position, velocity or wheel locations.
	// Do not engage on slopes, partial support, or deliberate movement.
	bLevelRestHold = bLevelRestHoldEnabled && LastCoastGroundWheels == 4
		&& Abs(LastGas) < 0.05 && Abs(LastSteer) < 0.05
		&& LastBrake < 0.05 && Nrm.Z > 0.990
		&& Abs(VLong) < 0.15 && Abs(VLat) < 0.15
		&& Abs(Core.OutAngZ_radps) < 0.04;
	if (bLevelRestHold)
	{
		Fx = -EffectiveMassAtPoint(PointM, LongDir) * VLong * 0.95 / DT;
		Fy = -EffectiveMassAtPoint(PointM, LatDir) * VLat * 0.95 / DT;
	}
	Cap = TireMu * N;
	if (Cap < 0)
		Cap = 0;
	LastTireCapN[i] = Cap;
	if (Sgn != 0 && Fx * VLong < 0 && Abs(VLong) > 0)
	{
		EffMass = EffectiveMassAtPoint(PointM, LongDir);
		MaxF = 0.99 * EffMass * Abs(VLong) / DT;
		if (Abs(Fx) > MaxF)
			Fx = -Sgn * MaxF;
	}
	if (Fy * VLat < 0 && Abs(VLat) > 0)
	{
		EffMass = EffectiveMassAtPoint(PointM, LatDir);
		MaxF = 0.99 * EffMass * Abs(VLat) / DT;
		if (Abs(Fy) > MaxF)
		{
			if (VLat > 0)
				Fy = -MaxF;
			else
				Fy = MaxF;
		}
	}
	if (i >= 2 && ModernTorqueDriveActive() && Fx * VLong > 0.0 && Cap > 0.0)
	{
		// Rear drive yields to lateral grip under power. Preserve the full
		// friction circle and let the model's braking path handle braking.
		Fy = FClamp(Fy, -Cap, Cap);
		LongCap = Sqrt(FMax(0.0, Cap*Cap - Fy*Fy));
		Fx = FClamp(Fx, -LongCap, LongCap);
	}
	Mag = Sqrt(Fx * Fx + Fy * Fy);
	Src = "coast";
	if (Abs(LastGas) > 0.05)
		Src = "drive";
	else if (LastBrake > 0.1)
		Src = "brake";
	if (bLevelRestHold)
		Src = "level_rest_hold";
	if (Cap > 0 && Mag > Cap)
	{
		Scale = Cap / Mag;
		Fx = Fx * Scale;
		Fy = Fy * Scale;
		Mag = Cap;
		Src = "friction_circle";
	}
	if (ModernTorqueDriveActive() && Abs(LastGas) > 0.05)
	{
		// Reaction torque is only needed for a powered/engaged wheel.
		// Neutral uses passive rolling speed and cannot self-propel.
		WheelOmegaRadps[i] -= Fx
			* class'HB2WorldQuery'.static.UUToM(WheelRadiusUU[i])
			* DT / FMax(1.0, WheelInertiaKgM2);
	}
	LastTireFx[i] = Fx;
	LastTireFy[i] = Fy;
	if (Cap > 0)
		LastTireMuUtil[i] = Mag / Cap;
	else
		LastTireMuUtil[i] = 0;
	LastTireSource[i] = Src;
	TrackTireForceChange(i, Mag);
	TrackTireRecontact(i, Mag);
	LastTireActiveCount++;
	if (LastTireMuUtil[i] > LastTireMaxMuUtil)
		LastTireMaxMuUtil = LastTireMuUtil[i];
	J = LongDir * (Fx * DT) + LatDir * (Fy * DT);
	if (VSize(J) < 0.000001)
		return;
	if (!Core.NativeApplyImpulseAtPoint(J.X, J.Y, J.Z, PointM.X, PointM.Y, PointM.Z))
	{
		LastTireImpulseFail++;
		return;
	}
	if (bMeasureTireYaw)
	{
		ComM = class'HB2WorldQuery'.static.UUToMVec(Location);
		YawTorque = (PointM - ComM) Cross (J / DT);
		if (i < 2)
			LastFrontTireYawNm += YawTorque.Z;
		else
			LastRearTireYawNm += YawTorque.Z;
	}
	if (Abs(LastGas) > 0.05)
		LastThrottleImpulseNs = LastThrottleImpulseNs + Abs(Fx) * DT;
	if (LastBrake > 0.1 && Sgn != 0)
		LastBrakeImpulseNs = LastBrakeImpulseNs + Abs(SpaceBrakeLoadCoeff * N * LastBrake * Sgn) * DT;
	if (Sgn != 0)
	{
		LastRollImpulseNs = LastRollImpulseNs + RollingResistanceCoeff * N * DT;
		if (Abs(LastGas) <= 0.05)
			LastEngineImpulseNs = LastEngineImpulseNs + EngineBrakeLoadCoeff * N * DT;
	}
}

function ApplyTireForces(float DT)
{
	local int i, GroundN;
	local float LoadSum, VtMag, SnapshotSteer;
	local vector Vel, Nrm, Vt, TireComM, TireVelMps, TireOmega;
	local bool bUseTireSnapshot;

	ClearTireTelemetry();
	LastDriveMaxWheelSlipMps = 0;
	UpdateTorque4WD(DT);
	LastRollImpulseNs = 0;
	LastEngineImpulseNs = 0;
	LastBrakeImpulseNs = 0;
	LastThrottleImpulseNs = 0;
	LastLoadSumN = 0;
	LastTangentSpeedMps = 0;
	LastCoastGroundWheels = 0;
	LastCoastMode = "air";
	GroundN = 0;
	LoadSum = 0;
	Nrm = vect(0,0,0);
	for (i = 0; i < 4; ++i)
	{
		if (!WheelTireActive(i))
		{
			TireContactBlend[i] = 0;
			TrackTireForceChange(i, 0);
			PrevTireForceActive[i] = 0;
			continue;
		}
		GroundN++;
		LoadSum = LoadSum + WheelLoadAt(i);
		Nrm = Nrm + LastWheelNormal[i];
	}
	LastLoadSumN = LoadSum;
	LastCoastGroundWheels = GroundN;
	// Always refresh body motion from Core3D, including airborne frames where
	// no tire forces run Ă˘â‚¬â€ť otherwise HB2_TIRE_SUM keeps stale bodyLat/yawRate.
	RefreshBodyMotionTelemetry();
	if (GroundN <= 0 || LoadSum <= 0)
	{
		LastCoastMode = "air";
		LastDesiredDriveAccelMps2 = DesiredDriveAccelMps2();
		return;
	}
	// All four tyres act over the same substep. Sample the same chassis
	// motion before applying any tyre impulse so index order cannot bias slip.
	bUseTireSnapshot = ModernVehicleProfileActive();
	if (bUseTireSnapshot)
	{
		TireComM = class'HB2WorldQuery'.static.UUToMVec(Location);
		TireVelMps.X = Core.OutVelX_mps;
		TireVelMps.Y = Core.OutVelY_mps;
		TireVelMps.Z = Core.OutVelZ_mps;
		TireOmega.X = Core.OutAngX_radps;
		TireOmega.Y = Core.OutAngY_radps;
		TireOmega.Z = Core.OutAngZ_radps;
		SnapshotSteer = EffectiveSteerRad();
	}
	for (i = 0; i < 4; ++i)
		ApplyOneWheelTire(i, DT, LoadSum, bUseTireSnapshot,
			TireComM, TireVelMps, TireOmega, SnapshotSteer);
	Vel.X = Core.OutVelX_mps;
	Vel.Y = Core.OutVelY_mps;
	Vel.Z = Core.OutVelZ_mps;
	if (VSize(Nrm) < 0.2)
		Nrm = vect(0,0,1);
	else
		Nrm = Normal(Nrm);
	Vt = Vel - Nrm * (Vel Dot Nrm);
	VtMag = VSize(Vt);
	LastTangentSpeedMps = VtMag;
	if (Abs(LastGas) > 0.05)
		LastCoastMode = "drive";
	else if (LastBrake > 0.1)
		LastCoastMode = "brake";
	else if (VtMag < CoastSpeedDeadzoneMps)
		LastCoastMode = "rest";
	else
		LastCoastMode = "coast";
}

function bool ApplyCoreImpulseNs(vector Jns)
{
	local vector PointM;
	if (Core == None || VSize(Jns) < 0.000001)
		return True;
	PointM.X = Core.OutPosX_m;
	PointM.Y = Core.OutPosY_m;
	PointM.Z = Core.OutPosZ_m;
	return Core.NativeApplyImpulseAtPoint(
		Jns.X, Jns.Y, Jns.Z, PointM.X, PointM.Y, PointM.Z);
}

// P1.4: throttle, rolling, prototype engine-brake, Space brake and aero.
// Wheel terms use current suspension hits; aero also runs in the air.
function ApplyLongitudinalForces(float DT)
{
	local vector Vel, N, Vt, J, Fwd, Right;
	local float LoadSum, Load, VtMag, VMag, FRoll, FEng, FBrake, FWant, JMag;
	local float Scale, GasAbs;
	local int i, GroundN;

	LastRollImpulseNs = 0;
	LastEngineImpulseNs = 0;
	LastBrakeImpulseNs = 0;
	LastAeroImpulseNs = 0;
	LastThrottleImpulseNs = 0;
	LastLoadSumN = 0;
	LastTangentSpeedMps = 0;
	LastCoastGroundWheels = 0;
	LastCoastMode = "none";
	if (!bCoastResistanceEnabled || Core == None || DT <= 0)
		return;

	Vel.X = Core.OutVelX_mps;
	Vel.Y = Core.OutVelY_mps;
	Vel.Z = Core.OutVelZ_mps;
	VMag = VSize(Vel);

	if (AeroDragNsp2 > 0 && VMag > CoastSpeedDeadzoneMps)
	{
		JMag = AeroDragNsp2 * VMag * VMag * DT;
		if (JMag > MassKg * VMag * 0.99)
			JMag = MassKg * VMag * 0.99;
		J = (Vel * (-1.0 / VMag)) * JMag;
		if (ApplyCoreImpulseNs(J))
			LastAeroImpulseNs = JMag;
		Vel.X = Core.OutVelX_mps;
		Vel.Y = Core.OutVelY_mps;
		Vel.Z = Core.OutVelZ_mps;
		VMag = VSize(Vel);
	}

	if (ControlProfile == "p2_tires")
	{
		ApplyTireForces(DT);
		return;
	}

	GroundN = 0;
	LoadSum = 0;
	N = vect(0,0,0);
	if (bSuspensionEnabled)
	{
		for (i = 0; i < 4; ++i)
		{
			if (VSize(LastWheelNormal[i]) < 0.5)
				continue;
			if (WheelStatusAt(i) < 2.5)
				continue;
			Load = WheelLoadAt(i);
			if (Load <= 0)
				continue;
			GroundN++;
			LoadSum += Load;
			N = N + LastWheelNormal[i];
		}
	}
	LastLoadSumN = LoadSum;
	LastCoastGroundWheels = GroundN;

	GasAbs = LastGas;
	if (Abs(GasAbs) > 0.05)
	{
		Fwd.X = Cos(Core.OutYaw_rad);
		Fwd.Y = Sin(Core.OutYaw_rad);
		Fwd.Z = 0;
		if (VSize(Fwd) < 0.01)
			Fwd = vect(1,0,0);
		else
			Fwd = Normal(Fwd);
		J = Fwd * (GasAbs * DesiredDriveAccelMps2() * MassKg * DT);
		if (SteerMode == "strafe_diag")
		{
			Right.X = -Fwd.Y;
			Right.Y = Fwd.X;
			Right.Z = 0;
			J = J + Right * (LastSteer * DesiredDriveAccelMps2() * MassKg * DT);
		}
		if (ApplyCoreImpulseNs(J))
			LastThrottleImpulseNs = VSize(J);
		LastCoastMode = "drive";
		Vel.X = Core.OutVelX_mps;
		Vel.Y = Core.OutVelY_mps;
		Vel.Z = Core.OutVelZ_mps;
	}

	if (GroundN <= 0 || LoadSum <= 0)
	{
		if (LastCoastMode == "none")
			LastCoastMode = "air";
		return;
	}

	if (VSize(N) < 0.2)
		N = vect(0,0,1);
	else
		N = Normal(N);
	Vt = Vel - N * (Vel Dot N);
	VtMag = VSize(Vt);
	LastTangentSpeedMps = VtMag;
	if (VtMag < CoastSpeedDeadzoneMps)
	{
		if (LastCoastMode == "none")
			LastCoastMode = "rest";
		return;
	}

	FRoll = RollingResistanceCoeff * LoadSum;
	FEng = 0;
	if (Abs(GasAbs) <= 0.05)
		FEng = EngineBrakeLoadCoeff * LoadSum;
	FBrake = 0;
	if (LastBrake > 0.1)
		FBrake = SpaceBrakeLoadCoeff * LoadSum * LastBrake;
	FWant = FRoll + FEng + FBrake;
	if (FWant <= 0)
		return;
	JMag = FWant * DT;
	if (JMag > MassKg * VtMag * 0.99)
		JMag = MassKg * VtMag * 0.99;
	Scale = JMag / (FWant * DT);
	J = (Vt * (-1.0 / VtMag)) * JMag;
	if (!ApplyCoreImpulseNs(J))
		return;
	LastRollImpulseNs = FRoll * DT * Scale;
	LastEngineImpulseNs = FEng * DT * Scale;
	LastBrakeImpulseNs = FBrake * DT * Scale;
	if (LastBrake > 0.1)
		LastCoastMode = "brake";
	else if (LastCoastMode == "none" || LastCoastMode == "drive")
	{
		if (Abs(GasAbs) <= 0.05)
			LastCoastMode = "coast";
	}
}

function ApplyPendingImpulse()
{
	local vector DeltaVM, ImpulseNs, PointM;
	if (VSize(PendingImpulseUU) < 0.1)
		return;
	DeltaVM = class'HB2WorldQuery'.static.UUToMVec(PendingImpulseUU);
	ImpulseNs = DeltaVM * MassKg;
	PointM.X = Core.OutPosX_m;
	PointM.Y = Core.OutPosY_m;
	PointM.Z = Core.OutPosZ_m;
	if (!Core.NativeApplyImpulseAtPoint(
		ImpulseNs.X, ImpulseNs.Y, ImpulseNs.Z,
		PointM.X, PointM.Y, PointM.Z))
		Warn("HB2_IMPULSE FAIL COM impulseNs="$ImpulseNs$" pointM="$PointM);
	PendingImpulseUU = vect(0,0,0);
}

function bool ImpulseAtOffsetUU(vector DeltaVelUU, vector OffsetUU)
{
	local vector DeltaVM, ImpulseNs, PointM;
	DeltaVM = class'HB2WorldQuery'.static.UUToMVec(DeltaVelUU);
	ImpulseNs = DeltaVM * MassKg;
	PointM.X = Core.OutPosX_m;
	PointM.Y = Core.OutPosY_m;
	PointM.Z = Core.OutPosZ_m;
	PointM += class'HB2WorldQuery'.static.UUToMVec(OffsetUU);
	return Core.NativeApplyImpulseAtPoint(
		ImpulseNs.X, ImpulseNs.Y, ImpulseNs.Z,
		PointM.X, PointM.Y, PointM.Z);
}

// Equal and opposite impulses at the lower left/right sides. Translation
// cancels; the requested yaw delta is carried by angular momentum in Core3D.
function bool ApplyYawImpulseCouple(float DeltaOmegaZ)
{
	local vector Fwd, Right, ComM, LeftPointM, RightPointM;
	local vector LeftImpulse, RightImpulse;
	local float HalfYM, HalfZM, Izz, J;
	if (Core == None || !Core.bReady || Abs(DeltaOmegaZ) < 0.0001)
		return False;
	HalfYM = class'HB2WorldQuery'.static.UUToM(ChassisHalfUU.Y);
	HalfZM = class'HB2WorldQuery'.static.UUToM(ChassisHalfUU.Z);
	Izz = BoxInertiaKgM2(2);
	J = Izz * DeltaOmegaZ / (2.0 * HalfYM);
	Fwd.X = Cos(Core.OutYaw_rad); Fwd.Y = Sin(Core.OutYaw_rad); Fwd.Z = 0;
	Right.X = -Fwd.Y; Right.Y = Fwd.X; Right.Z = 0;
	ComM.X = Core.OutPosX_m; ComM.Y = Core.OutPosY_m; ComM.Z = Core.OutPosZ_m;
	LeftPointM = ComM + Right * HalfYM + vect(0,0,-1) * HalfZM;
	RightPointM = ComM - Right * HalfYM + vect(0,0,-1) * HalfZM;
	LeftImpulse = -Fwd * J;
	RightImpulse = Fwd * J;
	if (!Core.NativeApplyImpulseAtPoint(
		LeftImpulse.X, LeftImpulse.Y, LeftImpulse.Z,
		LeftPointM.X, LeftPointM.Y, LeftPointM.Z))
		return False;
	return Core.NativeApplyImpulseAtPoint(
		RightImpulse.X, RightImpulse.Y, RightImpulse.Z,
		RightPointM.X, RightPointM.Y, RightPointM.Z);
}

function SnapshotP13Pre()
{
	P13OmegaPre.X = Core.OutAngX_radps;
	P13OmegaPre.Y = Core.OutAngY_radps;
	P13OmegaPre.Z = Core.OutAngZ_radps;
	P13VelPreM.X = Core.OutVelX_mps;
	P13VelPreM.Y = Core.OutVelY_mps;
	P13VelPreM.Z = Core.OutVelZ_mps;
}

function LogP13ContactAfterStep()
{
	local vector J, RM;
	local float Omega0, Omega1, Inertia, Jn;
	if (!bDiagnosticLog || Core == None || ContactCount <= 0)
		return;
	P13OmegaPost.X = Core.OutAngX_radps;
	P13OmegaPost.Y = Core.OutAngY_radps;
	P13OmegaPost.Z = Core.OutAngZ_radps;
	P13VelPostM.X = Core.OutVelX_mps;
	P13VelPostM.Y = Core.OutVelY_mps;
	P13VelPostM.Z = Core.OutVelZ_mps;
	Omega0 = VSize(P13OmegaPre);
	Omega1 = VSize(P13OmegaPost);
	if (P13ContactLogCount >= 96)
		return;
	if (Core.OutUniqueContacts < 2.0 && Abs(LastContactNormal.Z) > 0.92
		&& Omega0 < 2.0 && Omega1 < 2.0 && Abs(Omega1 - Omega0) < 0.75
		&& LastMaxPenUU < 2.0 && Level.TimeSeconds < NextP13LogTime)
		return;
	NextP13LogTime = Level.TimeSeconds + 0.15;
	P13ContactLogCount++;
	J = (P13VelPostM - P13VelPreM) * MassKg;
	Jn = J Dot LastContactNormal;
	RM = class'HB2WorldQuery'.static.UUToMVec(LastApplyPointUU);
	RM.X = RM.X - Core.OutPosX_m;
	RM.Y = RM.Y - Core.OutPosY_m;
	RM.Z = RM.Z - Core.OutPosZ_m;
	Inertia = 0.5 * (BoxInertiaKgM2(0) * P13OmegaPre.X * P13OmegaPre.X
		+ BoxInertiaKgM2(1) * P13OmegaPre.Y * P13OmegaPre.Y
		+ BoxInertiaKgM2(2) * P13OmegaPre.Z * P13OmegaPre.Z);
	Log("HB2_P13 t="$Level.TimeSeconds$" step="$TotalStepCount
		$" kind="$LastHitKind$" mode="$LastChassisContactMode
		$" n="$LastContactNormal$" surface="$LastSurfacePointUU$" apply="$LastApplyPointUU
		$" rUU="$LastContactRUU$" rXnUU="$LastRxNLenUU
		$" penUU="$LastMaxPenUU$" unique="$Core.OutUniqueContacts
		$" omega0="$P13OmegaPre$" omega1="$P13OmegaPost
		$" vel0="$P13VelPreM$" vel1="$P13VelPostM
		$" Jn="$Jn$" Jt="$VSize(J - LastContactNormal * Jn)$" rXJ="$VSize(RM Cross J)
		$" keLin0="$(0.5 * MassKg * (P13VelPreM Dot P13VelPreM))
		$" keLin1="$(0.5 * MassKg * (P13VelPostM Dot P13VelPostM))
		$" Ikgm2="$BoxInertiaKgM2(0)$","$BoxInertiaKgM2(1)$","$BoxInertiaKgM2(2)
		$" keAng0="$Inertia
		$" keAng1="$(0.5 * (BoxInertiaKgM2(0) * P13OmegaPost.X * P13OmegaPost.X
			+ BoxInertiaKgM2(1) * P13OmegaPost.Y * P13OmegaPost.Y
			+ BoxInertiaKgM2(2) * P13OmegaPost.Z * P13OmegaPost.Z)));
}

function LogP13CAfterStep()
{
	local vector J;
	local float Omega0, Omega1, Jn;
	if (!bDiagnosticLog || Core == None)
		return;
	if (P13CLogCount >= 24)
		return;
	if (!bP13HSLatch && LastSweepHitTime >= 0.999)
		return;
	P13OmegaPost.X = Core.OutAngX_radps;
	P13OmegaPost.Y = Core.OutAngY_radps;
	P13OmegaPost.Z = Core.OutAngZ_radps;
	P13VelPostM.X = Core.OutVelX_mps;
	P13VelPostM.Y = Core.OutVelY_mps;
	P13VelPostM.Z = Core.OutVelZ_mps;
	Omega0 = VSize(P13OmegaPre);
	Omega1 = VSize(P13OmegaPost);
	if (ContactCount <= 0 && Abs(Omega1 - Omega0) < 0.25 && LastSweepHitTime >= 0.999)
		return;
	if (LastSweepHitTime >= 0.999 && LastChassisContactMode == "plane_com"
		&& Abs(Omega1 - Omega0) < 0.50)
		return;
	P13CLogCount++;
	J = (P13VelPostM - P13VelPreM) * MassKg;
	Jn = J Dot LastContactNormal;
	Log("HB2_P13C tag="$P13CTag$" t="$Level.TimeSeconds$" step="$TotalStepCount$" sub="$LastSimSubIndex
		$" dt="$LastStepDt$" hitTime="$LastSweepHitTime
		$" com="$LastProposedUU$" toi="$LastToiUU
		$" q="$Core.OutQuatW$","$Core.OutQuatX$","$Core.OutQuatY$","$Core.OutQuatZ
		$" vel0="$P13VelPreM$" omega0="$P13OmegaPre
		$" n="$LastContactNormal$" penUU="$LastMaxPenUU
		$" added="$LastManifoldAdded$" mode="$LastChassisContactMode
		$" sepsP="$LastCornerSepProposed$" sepsT="$LastCornerSepToi
		$" fid="$LastFeatureBase$" unique="$Core.OutUniqueContacts
		$" omega1="$P13OmegaPost$" vel1="$P13VelPostM
		$" Jn="$Jn$" Jt="$VSize(J - LastContactNormal * Jn)
		$" rXnUU="$LastRxNLenUU$" accum="$AccumDt$" maxSub="$MaxSubsteps);
}

function float LandingRollRate(vector Fwd)
{
	return Core.OutAngX_radps*Fwd.X + Core.OutAngY_radps*Fwd.Y
		+ Core.OutAngZ_radps*Fwd.Z;
}

function LogLandingTrace(float TireD, float AntiRollD)
{
	local vector Fwd, Right, Up, R, AxisUp, J;
	local float Align, SuspensionD, TotalD, Load, Torque, Ixx;
	local int i;
	GetAxes(Rotation, Fwd, Right, Up);
	Ixx=FMax(1.0,BoxInertiaKgM2(0));
	for(i=0;i<4;i++)
	{
		AxisUp=Normal(-(SuspensionAxisBody[i] >> Rotation));
		Align=AxisUp Dot Normal(LastWheelNormal[i]);
		Load=WheelLoadAt(i);
		Torque=0;
		if(Load>0 && Align>0.001)
		{
			R=class'HB2WorldQuery'.static.UUToMVec(SuspensionAttachmentUU[i] >> Rotation);
			J=AxisUp * (Load / Align);
			Torque=(R Cross J) Dot Fwd;
		}
		SuspensionD+=Torque*FixedDt/Ixx;
		Log("HB2_LAND_W t="$Level.TimeSeconds$" step="$TotalStepCount$" i="$i$" N="$Load
			$" spring="$LastWheelSpringN[i]$" damper="$LastWheelDamperN[i]$" bump="$LastWheelBumpN[i]
			$" L="$LastWheelLengthUU[i]$" normal="$LastWheelNormal[i]$" src="$LastWheelContactSource[i]
			$" Fx="$LastTireFx[i]$" Fy="$LastTireFy[i]$" suspTorque="$Torque);
	}
	TotalD=LandingRollRate(Fwd)-(P13OmegaPre Dot Fwd);
	Log("HB2_LAND t="$Level.TimeSeconds$" step="$TotalStepCount$" wheels="$WheelContactCount
		$" chassis="$ContactCount$" mode="$LastChassisContactMode$" roll="$Core.OutRoll_rad
		$" before="$(P13OmegaPre Dot Fwd)$" rollRate="$LandingRollRate(Fwd)$" total="$TotalD
		$" tireAero="$TireD$" antiRoll="$AntiRollD$" susp="$SuspensionD
		$" residual="$(TotalD-TireD-AntiRollD-SuspensionD)$" velZ="$Core.OutVelZ_mps);
}

function SimStep(float DT)
{
	local vector PrevUU, ProposedUU, PredVelM, TraceForward;
	local float TraceTireD, TraceBarD;
	local int Steps;

	if (!bReady || Core == None || !Core.bReady)
		return;

	ApplyPendingImpulse();
	AccumDt += DT;
	if (AccumDt > FixedDt * MaxSubsteps)
	{
		Log("HB2 WARN: sim overload drop accum="$AccumDt);
		AccumDt = FixedDt * MaxSubsteps;
	}
	Steps = 0;
	while (AccumDt >= FixedDt && Steps < MaxSubsteps)
	{
		PrevUU.X = class'HB2WorldQuery'.static.MToUU(Core.OutPosX_m);
		PrevUU.Y = class'HB2WorldQuery'.static.MToUU(Core.OutPosY_m);
		PrevUU.Z = class'HB2WorldQuery'.static.MToUU(Core.OutPosZ_m);

		PredVelM.X = Core.OutVelX_mps;
		PredVelM.Y = Core.OutVelY_mps;
		PredVelM.Z = Core.OutVelZ_mps;
		PredVelM = PredVelM * Exp(-CoreLinearDamping * FixedDt);
		PredVelM = PredVelM + CoreGravityMps2 * FixedDt;
		ProposedUU = PrevUU + class'HB2WorldQuery'.static.MToUUVec(PredVelM * FixedDt);

		LastSimSubIndex = Steps;
		LastStepDt = FixedDt;
		SnapshotP13Pre();
		if (bSuspensionEnabled)
		{
			GatherSuspensionHits(PrevUU);
			if (!Core.NativePrepareSuspension())
			{
				StepFailureCount++;
				bLastStepOK = False;
				Warn("HB2_STEP FAIL suspension_prepare count="$StepFailureCount);
				AccumDt -= FixedDt;
				Steps++;
				continue;
			}
		}
		GatherContactsV2(PrevUU, ProposedUU);
		ApplyLongitudinalForces(FixedDt);
		if(bLogLandingTrace)
		{
			TraceForward=vector(Rotation);
			TraceTireD=LandingRollRate(TraceForward)-(P13OmegaPre Dot TraceForward);
		}
		UpdateEngineAudio();
		ApplyAntiRollBars(FixedDt);
		if(bLogLandingTrace)
			TraceBarD=LandingRollRate(TraceForward)-(P13OmegaPre Dot TraceForward)-TraceTireD;
		if (bPawnCrushEnabled && ModernVehicleProfileActive())
		{
			PredVelM.X = Core.OutVelX_mps;
			PredVelM.Y = Core.OutVelY_mps;
			PredVelM.Z = Core.OutVelZ_mps;
			PredVelM = PredVelM * Exp(-CoreLinearDamping * FixedDt)
				+ CoreGravityMps2 * FixedDt;
			GatherPawnContact(PrevUU, PredVelM);
		}
		else
			PawnContact = None;
		if ((bSuspensionEnabled && !Core.NativeStepSuspended(FixedDt))
			|| (!bSuspensionEnabled && !Core.NativeStep(FixedDt)))
		{
			StepFailureCount++;
			bLastStepOK = False;
			Warn("HB2_STEP FAIL atomic_reject count="$StepFailureCount$" dt="$FixedDt$" contacts="$ContactCount);
			AccumDt -= FixedDt;
			Steps++;
			continue;
		}
		bLastStepOK = True;
		TotalStepCount++;
		if (bSuspensionEnabled)
		{
			CaptureWheelForceTelemetry();
			if(bLogLandingTrace)
				LogLandingTrace(TraceTireD,TraceBarD);
			LogWheelContactIfNeeded();
			LogRideIfNeeded();
		}
		if (!IsCoreStateFinite())
		{
			NonFiniteStateCount++;
			Warn("HB2_STATE FAIL nonfinite count="$NonFiniteStateCount$" q="$Core.OutQuatW$","$Core.OutQuatX$","$Core.OutQuatY$","$Core.OutQuatZ$" omega="$Core.OutAngX_radps$","$Core.OutAngY_radps$","$Core.OutAngZ_radps);
			AccumDt -= FixedDt;
			Steps++;
			continue;
		}
		if (!ConstrainPawnContact())
		{
			ActorSyncFailureCount++;
			Warn("HB2_SYNC FAIL pawn contact state rejected");
		}
		else if (PullCoreToActor())
			ApplyPawnCrush();
		AdvanceWheelSpin(FixedDt);
		UpdateVisualWheels();
		LogP13ContactAfterStep();
		LogP13CAfterStep();
		if (bP13HSLatch)
		{
			if (Core.OutAngularSpeed_radps > P13HSLatchedOmega)
				P13HSLatchedOmega = Core.OutAngularSpeed_radps;
			if (Core.OutUniqueContacts > P13HSLatchedUnique)
				P13HSLatchedUnique = Core.OutUniqueContacts;
		}

		if (LastMaxPenUU < 2.0 && Core.OutAngularSpeed_radps < 3.0
			&& Abs(Core.OutPitch_rad) < 0.40 && Abs(Core.OutRoll_rad) < 0.40
			&& WheelContactCount >= 4)
			LastSafeLoc = Location;
		AccumDt -= FixedDt;
		Steps++;
	}
}

simulated event Tick(float DT)
{
	Super.Tick(DT);
	if (!bReady)
		return;
	SimStep(DT);
	if (bDiagnosticLog && Level.TimeSeconds >= NextLogTime)
	{
		NextLogTime = Level.TimeSeconds + DiagnosticInterval;
		Log("HB2_P14 t="$Level.TimeSeconds$" mode="$LastCoastMode
			$" loadN="$LastLoadSumN$" wheels="$LastCoastGroundWheels
			$" vt="$LastTangentSpeedMps
			$" Jroll="$LastRollImpulseNs$" Jeng="$LastEngineImpulseNs
			$" Jbrake="$LastBrakeImpulseNs$" Jaero="$LastAeroImpulseNs
			$" Jgas="$LastThrottleImpulseNs$" gas="$LastGas$" brake="$LastBrake);
		Log("HB2_STATE t="$Level.TimeSeconds$" step="$TotalStepCount$" loc="$Location$" vel="$Velocity
			$" q="$Core.OutQuatW$","$Core.OutQuatX$","$Core.OutQuatY$","$Core.OutQuatZ
			$" omega="$Core.OutAngX_radps$","$Core.OutAngY_radps$","$Core.OutAngZ_radps
			$" euler="$Core.OutYaw_rad$","$Core.OutPitch_rad$","$Core.OutRoll_rad
			$" actorRot="$Rotation$" contacts="$Core.OutContacts$" unique="$Core.OutUniqueContacts
			$" iterations="$Core.OutSolverIterations$" pen_m="$Core.OutMaxPen_m
			$" hit="$LastHitKind$" stepOK="$bLastStepOK$" syncOK="$bLastActorSyncOK
			$" failures="$StepFailureCount$","$ActorSyncFailureCount$","$NonFiniteStateCount);
		if (bSuspensionEnabled && ChassisProfile == "p15_vehicle")
			Log("HB2_P26A t="$Level.TimeSeconds
				$" aabbReject="$ChassisAABBRejectCount
				$" footprintReject="$ChassisFootprintRejectCount
				$" bellyPreserved="$ChassisBellyPreservedCount
				$" supportSkip="$LastChassisSkipCount$" chassisN="$ContactCount);
		if (bSuspensionEnabled && ChassisProfile == "p15_vehicle")
			Log("HB2_P26B t="$Level.TimeSeconds
				$" wheelObstacleN="$WheelObstacleContactCount
				$" wheelObstacleTotal="$WheelObstacleContactTotal
				$" obstacleProbeHitTotal="$WheelObstacleProbeHitTotal
				$" wheel="$WheelObstacleLastWheel
				$" actor="$WheelObstacleLastActor
				$" penUU="$WheelObstacleLastPenUU
				$" n="$WheelObstacleLastNormal
				$" point="$WheelObstacleLastPointUU
				$" gas="$LastGas
				$" driveA="$LastDesiredDriveAccelMps2
				$" tireMuMax="$LastTireMaxMuUtil
				$" Jdrive="$LastThrottleImpulseNs);
		if (bSuspensionEnabled)
			Log("HB2_SUSP t="$Level.TimeSeconds$" hits="$WheelContactCount$" hitFail="$SuspensionHitFailureCount
				$" w0="$Core.OutWheel0Status$","$Core.OutWheel0Length_m$","$Core.OutWheel0Compression_m$","$Core.OutWheel0Spring_N$","$Core.OutWheel0Damper_N$","$Core.OutWheel0NormalLoad_N
				$" w1="$Core.OutWheel1Status$","$Core.OutWheel1Length_m$","$Core.OutWheel1Compression_m$","$Core.OutWheel1Spring_N$","$Core.OutWheel1Damper_N$","$Core.OutWheel1NormalLoad_N
				$" w2="$Core.OutWheel2Status$","$Core.OutWheel2Length_m$","$Core.OutWheel2Compression_m$","$Core.OutWheel2Spring_N$","$Core.OutWheel2Damper_N$","$Core.OutWheel2NormalLoad_N
				$" w3="$Core.OutWheel3Status$","$Core.OutWheel3Length_m$","$Core.OutWheel3Compression_m$","$Core.OutWheel3Spring_N$","$Core.OutWheel3Damper_N$","$Core.OutWheel3NormalLoad_N);
		if (ControlProfile == "p2_tires")
		{
			LogTireTelemetry();
			if (ModernTorqueDriveActive())
				Log("HB2_DRIVETRAIN t="$Level.TimeSeconds
					$" gear="$ForwardGear$" dir="$DriveDirection$" rpm="$EngineRPM
					$" gas="$LastGas$" omega0="$WheelOmegaRadps[0]
					$" omega1="$WheelOmegaRadps[1]
					$" omega2="$WheelOmegaRadps[2]
					$" omega3="$WheelOmegaRadps[3]
					$" driveNm0="$WheelDriveTorqueNm[0]
					$" wheelSlip="$LastDriveMaxWheelSlipMps
					$" antiFrontN="$LastAntiRollFrontN
					$" antiRearN="$LastAntiRollRearN
					$" antiFail="$AntiRollImpulseFailureCount
					$" engineSound="$AmbientSound$" soundPitch="$SoundPitch
					$" speedKmh="$(VSize(Velocity) / 52.5 * 3.6));
		}
	}
}

function ClearSimControlState()
{
	local int i;
	WheelObstacleContactCount = 0;
	WheelContactTransitionLogCount = 0;
	WheelObstacleContactTotal = 0;
	WheelObstacleProbeHitTotal = 0;
	NextWheelObstacleEventLogTime = 0;
	WheelObstacleLastPenUU = 0;
	WheelObstacleLastWheel = -1;
	WheelObstacleLastActor = None;
	WheelObstacleLastNormal = vect(0,0,0);
	WheelObstacleLastPointUU = vect(0,0,0);
	ChassisAABBRejectCount = 0;
	ChassisFootprintRejectCount = 0;
	ChassisBellyPreservedCount = 0;
	AccumDt = 0;
	PendingImpulseUU = vect(0,0,0);
	LastGas = 0;
	LastSteer = 0;
	LastBrake = 0;
	bDriverActive = False;
	ForwardGear = 1;
	DriveDirection = 0;
	LastEngagedDirection = 0;
	GearShiftCooldownSec = 0;
	EngineRPM = EngineIdleRPM;
	LastEngineSoundPitch = 64;
	SoundPitch = 64;
	LastAntiRollFrontN = 0;
	LastAntiRollRearN = 0;
	LastDriveMaxWheelSlipMps = 0;
	LastYawTargetRadps = 0;
	LastYawCorrectionRadps = 0;
	LastYawControlDt = 0;
	LastCoastMode = "none";
	LastThrottleImpulseNs = 0;
	LastBrakeImpulseNs = 0;
	LastRollImpulseNs = 0;
	LastEngineImpulseNs = 0;
	LastAeroImpulseNs = 0;
	for (i = 0; i < 4; ++i)
	{
		WheelSpinRad[i] = 0;
		WheelOmegaRadps[i] = 0;
		WheelDriveTorqueNm[i] = 0;
		TireContactBlend[i] = 0;
		LastWheelHitActor[i] = None;
	}
	ClearWheelContactHistory();
	for (i = 0; i < 4; ++i)
	{
		PrevTireForceMagN[i] = 0;
		MaxTireForceDeltaN[i] = 0;
		MaxTireRecontactForceN[i] = 0;
		PrevTireForceActive[i] = 0;
	}
	ClearTireTelemetry();
}

function vector UprightAABBExtent(rotator R)
{
	local vector X, Y, Z, E;
	GetAxes(R, X, Y, Z);
	E.X = Abs(X.X) * ChassisHalfUU.X + Abs(Y.X) * ChassisHalfUU.Y + Abs(Z.X) * ChassisHalfUU.Z;
	E.Y = Abs(X.Y) * ChassisHalfUU.X + Abs(Y.Y) * ChassisHalfUU.Y + Abs(Z.Y) * ChassisHalfUU.Z;
	E.Z = Abs(X.Z) * ChassisHalfUU.X + Abs(Y.Z) * ChassisHalfUU.Y + Abs(Z.Z) * ChassisHalfUU.Z;
	return E;
}

function bool UprightOBBBlocked(vector ComUU, rotator R)
{
	local vector Extent, HitLoc, HitNorm, Start, End, X, Y, Z, Corner;
	local float HitTime;
	local Actor Hit;
	local int sx, sy, sz;

	Extent = UprightAABBExtent(R);
	Start = ComUU;
	Start.Z = ComUU.Z + Extent.Z + 72.0;
	End = ComUU;
	if (class'HB2WorldQuery'.static.SweepExtent(
		Self, Start, End, Extent, True, HitLoc, HitNorm, HitTime, Hit))
	{
		if (VSize(HitLoc - ComUU) > 6.0)
			return True;
	}
	GetAxes(R, X, Y, Z);
	for (sx = -1; sx <= 1; sx += 2)
	{
		for (sy = -1; sy <= 1; sy += 2)
		{
			for (sz = -1; sz <= 1; sz += 2)
			{
				Corner = ComUU + X * (sx * ChassisHalfUU.X)
					+ Y * (sy * ChassisHalfUU.Y)
					+ Z * (sz * ChassisHalfUU.Z);
				if (class'HB2WorldQuery'.static.GroundQuery(
					Self, ComUU, Normal(Corner - ComUU),
					VSize(Corner - ComUU) * 0.96, True,
					HitLoc, HitNorm, HitTime, Hit))
					return True;
			}
		}
	}
	return False;
}

function bool ProbeUprightFloor(vector ProbeXY, out vector FloorUU, out vector FloorN)
{
	local vector Start, End, HitLoc, HitNorm, Delta;
	local float HitDist;
	local Actor Hit;

	Start = ProbeXY;
	Start.Z = ProbeXY.Z + 360;
	End = ProbeXY;
	End.Z = ProbeXY.Z - 700;
	if (!class'HB2WorldQuery'.static.GroundQuery(
		Self, Start, vect(0,0,-1), VSize(End - Start), False,
		HitLoc, HitNorm, HitDist, Hit))
		return False;
	if (VSize(HitNorm) < 0.5 || HitNorm.Z < 0.85)
		return False;
	Delta = HitLoc - ProbeXY;
	Delta.Z = 0;
	if (VSize(Delta) > 280)
		return False;
	FloorUU = HitLoc;
	FloorN = Normal(HitNorm);
	return True;
}

function bool UprightFourWheelsOk(vector ComUU, rotator R)
{
	local int i, Hits;
	local vector AttachmentUU, AxisDown, HitLoc, HitNorm;
	local float HitDistUU, LengthUU, RayLengthUU;
	local Actor Hit;

	Hits = 0;
	for (i = 0; i < 4; ++i)
	{
		AttachmentUU = ComUU + (SuspensionAttachmentUU[i] >> R);
		AxisDown = Normal(SuspensionAxisBody[i] >> R);
		RayLengthUU = SuspensionMaxUU[i] + WheelRadiusUU[i] + 8.0;
		if (!class'HB2WorldQuery'.static.GroundQuery(
			Self, AttachmentUU, AxisDown, RayLengthUU, True,
			HitLoc, HitNorm, HitDistUU, Hit))
			continue;
		if (VSize(HitNorm) < 0.5 || HitNorm.Z < 0.80)
			continue;
		LengthUU = HitDistUU - WheelRadiusUU[i];
		if (LengthUU < SuspensionMinUU[i] - 4.0)
			continue;
		if (LengthUU > SuspensionMaxUU[i] + 12.0)
			continue;
		Hits++;
	}
	return (Hits == 4);
}

function bool TryUprightCandidate(vector ProbeXY, rotator UprightRot, out vector ComUU, out vector FloorUU)
{
	local vector FloorN, Candidate;
	local int Lift;
	local float Height;

	if (!ProbeUprightFloor(ProbeXY, FloorUU, FloorN))
		return False;
	Height = ChassisSpawnHeightUU();
	for (Lift = 0; Lift < 3; ++Lift)
	{
		Candidate = FloorUU;
		Candidate.Z = FloorUU.Z + Height + Lift * 24.0;
		if (UprightOBBBlocked(Candidate, UprightRot))
			continue;
		if (!UprightFourWheelsOk(Candidate, UprightRot))
			continue;
		ComUU = Candidate;
		return True;
	}
	return False;
}

function bool FindSafeUprightLoc(rotator UprightRot, out vector ComUU, out vector FloorUU)
{
	local vector Probe, Origin, Hub;
	local int Pass, Step, Dir;
	local float Rad, Ang;

	Origin = Location;
	if (VSize(LastSafeLoc) > 1.0 && TryUprightCandidate(LastSafeLoc, UprightRot, ComUU, FloorUU))
		return True;
	if (TryUprightCandidate(Origin, UprightRot, ComUU, FloorUU))
		return True;

	for (Pass = 0; Pass < 2; ++Pass)
	{
		if (Pass == 0)
			Hub = Origin;
		else
			Hub = LastSafeLoc;
		if (Pass == 1 && VSize(Hub - Origin) < 8.0)
			continue;
		for (Step = 0; Step < 24; ++Step)
		{
			Rad = 120.0 * (1 + (Step / 8));
			Dir = Step % 8;
			Ang = Dir * 0.785398;
			Probe = Hub;
			Probe.X = Hub.X + Rad * Cos(Ang);
			Probe.Y = Hub.Y + Rad * Sin(Ang);
			if (TryUprightCandidate(Probe, UprightRot, ComUU, FloorUU))
				return True;
		}
	}
	return False;
}

function bool RecoverUpright()
{
	local rotator UprightRot, SavedRot;
	local vector ComUU, FloorUU, Vel, Omega;
	local float KeepYaw, YawErr;

	bLastRecoverOK = False;
	LastRecoverReason = "not_attempted";
	if (!bReady || Core == None || !Core.bReady)
	{
		LastRecoverReason = "core_not_ready";
		Warn("HB2_RESET FAIL reason="$LastRecoverReason);
		return False;
	}

	KeepYaw = Core.OutYaw_rad;
	LastRecoverYawRad = KeepYaw;
	UprightRot.Yaw = int(KeepYaw * 10430.3783505);
	UprightRot.Pitch = 0;
	UprightRot.Roll = 0;

	if (!FindSafeUprightLoc(UprightRot, ComUU, FloorUU))
	{
		LastRecoverReason = "no_safe_obb_location";
		Warn("HB2_RESET FAIL reason="$LastRecoverReason$" from="$Location
			$" yaw="$KeepYaw$" half="$ChassisHalfUU);
		return False;
	}

	ClearSimControlState();
	SavedRot = Rotation;
	Velocity = vect(0,0,0);
	if (!SetLocation(ComUU, UprightRot))
	{
		SetRotation(SavedRot);
		LastRecoverReason = "setlocation_rejected";
		ActorSyncFailureCount++;
		Warn("HB2_RESET FAIL reason="$LastRecoverReason$" target="$ComUU);
		return False;
	}
	Velocity = vect(0,0,0);
	if (!PushActorToCore(vect(0,0,0)))
	{
		LastRecoverReason = "nativesetrigidstate_rejected";
		StepFailureCount++;
		Warn("HB2_RESET FAIL reason="$LastRecoverReason$" target="$ComUU$" rot="$UprightRot);
		return False;
	}

	Vel.X = Core.OutVelX_mps; Vel.Y = Core.OutVelY_mps; Vel.Z = Core.OutVelZ_mps;
	Omega.X = Core.OutAngX_radps; Omega.Y = Core.OutAngY_radps; Omega.Z = Core.OutAngZ_radps;
	YawErr = Core.OutYaw_rad - KeepYaw;
	while (YawErr > 3.141593)
		YawErr = YawErr - 6.283185;
	while (YawErr < -3.141593)
		YawErr = YawErr + 6.283185;
	if (Abs(Core.OutPitch_rad) > 0.03 || Abs(Core.OutRoll_rad) > 0.03
		|| Abs(YawErr) > 0.12 || VSize(Vel) > 0.05 || VSize(Omega) > 0.05)
	{
		LastRecoverReason = "core_quat_not_upright";
		Warn("HB2_RESET FAIL reason="$LastRecoverReason
			$" euler="$Core.OutYaw_rad$","$Core.OutPitch_rad$","$Core.OutRoll_rad
			$" keepYaw="$KeepYaw$" vel="$Vel$" omega="$Omega
			$" q="$Core.OutQuatW$","$Core.OutQuatX$","$Core.OutQuatY$","$Core.OutQuatZ);
		return False;
	}

	LastSafeLoc = ComUU;
	if (bSuspensionEnabled)
		GatherSuspensionHits(ComUU);
	if (!PullCoreToActor())
	{
		LastRecoverReason = "pull_sync_rejected";
		Warn("HB2_RESET FAIL reason="$LastRecoverReason$" target="$ComUU);
		return False;
	}
	bLastRecoverOK = True;
	LastRecoverReason = "ok";
	Log("HB2_RESET OK loc="$ComUU$" floor="$FloorUU
		$" yaw="$Core.OutYaw_rad$" pitch="$Core.OutPitch_rad$" roll="$Core.OutRoll_rad
		$" q="$Core.OutQuatW$","$Core.OutQuatX$","$Core.OutQuatY$","$Core.OutQuatZ
		$" vel="$Vel$" omega="$Omega$" wheels="$WheelContactCount
		$" actorRot="$Rotation);
	return True;
}

function ResetTo(vector Loc, vector VelUU)
{
	if (!SetLocation(Loc))
	{
		ActorSyncFailureCount++;
		Warn("HB2_RESET FAIL SetLocation target="$Loc);
		return;
	}
	LastSafeLoc = Loc;
	AccumDt = 0;
	ClearWheelContactHistory();
	if (!PushActorToCore(VelUU))
	{
		StepFailureCount++;
		Warn("HB2_RESET FAIL NativeSetRigidState loc="$Loc$" vel="$VelUU);
		return;
	}
	PendingImpulseUU = vect(0,0,0);
	UpdateChassisVisuals();
	Log("HB2: reset loc="$Loc$" vel="$VelUU);
}

function ClearWheelContactHistory()
{
	local int i;
	for (i = 0; i < 4; ++i)
	{
		PrevWheelHadContact[i] = 0;
		PrevWheelLengthUU[i] = 0;
		PrevWheelNormal[i] = vect(0,0,0);
		LastWheelHitUU[i] = vect(0,0,0);
		LastWheelHitActor[i] = None;
		LastWheelLengthDeltaUU[i] = 0;
		LastWheelCompressRateMps[i] = 0;
		LastWheelContactSource[i] = "none";
	}
}

event Destroyed()
{
	local int i;
	CrushDriver = None;
	Instigator = None;
	DestroyVisualWheels();
	if (Vis != None) Vis.Destroy();
	if (VisNose != None) VisNose.Destroy();
	if (VisTail != None) VisTail.Destroy();
	Vis = None;
	VisNose = None;
	VisTail = None;
	for (i = 0; i < 4; ++i)
		VisWheels[i] = None;
	Super.Destroyed();
}

function PumpPhysics(float OuterDt, float Duration)
{
	local int n, i;
	if (OuterDt <= 0 || Duration <= 0)
		return;
	n = int(Duration / OuterDt + 0.5);
	if (n < 1)
		n = 1;
	for (i = 0; i < n; ++i)
		SimStep(OuterDt);
}

function ImpulseUU(vector DeltaVelUU)
{
	PendingImpulseUU = PendingImpulseUU + DeltaVelUU;
	Log("HB2_IMPULSE pending="$PendingImpulseUU$" (delta="$DeltaVelUU$")");
}

// Manual drive: W/S forward accel, A/D yaw rate (default) or strafe_diag (P0 probe).
function ApplyDriverInput(float Gas, float Steer, float Brake, float DT)
{
	local float TargetOmegaZ, DeltaOmegaZ;
	local float ControlDT, ControlRate, MaxDeltaOmega;
	local bool bNeutralSteer;

	if (!bReady || Core == None || DT <= 0)
		return;
	// Automated gates must not inherit live keyboard state. Manual
	// suspension driving remains available when neither gate option is set.
	if (HB2TestGame(Level.Game) != None
		&& (HB2TestGame(Level.Game).bP0
			|| HB2TestGame(Level.Game).bP1
			|| HB2TestGame(Level.Game).bP2
			|| HB2TestGame(Level.Game).bP21
			|| HB2TestGame(Level.Game).bP22
			|| HB2TestGame(Level.Game).bP23
			|| HB2TestGame(Level.Game).bP24
			|| HB2TestGame(Level.Game).bP25a
			|| HB2TestGame(Level.Game).bPSpire))
		return;

	LastGas = Gas;
	LastSteer = Steer;
	LastBrake = Brake;
	bDriverActive = (Abs(Gas) > 0.05 || Abs(Steer) > 0.05 || Brake > 0.05);

	if (ControlProfile == "p2_tires")
	{
		LastYawTargetRadps = 0;
		LastYawCorrectionRadps = 0;
		LastYawControlDt = 0;
		return;
	}

	if (SteerMode == "yaw" || SteerMode == "")
	{
		// This temporary pre-tire controller requests angular momentum only via
		// the existing equal/opposite impulse couple. It never writes Core state.
		// Neutral steering is an explicit zero-yaw-rate target, so releasing A/D
		// removes residual spin instead of leaving it to weak global damping.
		ControlDT = FClamp(DT, 0.0, DriverMaxControlDt);
		bNeutralSteer = Abs(Steer) <= 0.05;
		if (bNeutralSteer)
			TargetOmegaZ = 0.0;
		else
			TargetOmegaZ = FClamp(Steer, -1.0, 1.0) * DriverMaxYawRateRadps;

		if (bNeutralSteer)
			ControlRate = DriverYawNeutralRateRadps2;
		else if (Core.OutAngZ_radps * TargetOmegaZ < -0.001)
			ControlRate = DriverYawReverseRateRadps2;
		else if (Abs(TargetOmegaZ) + 0.001 < Abs(Core.OutAngZ_radps))
			ControlRate = DriverYawNeutralRateRadps2;
		else
			ControlRate = DriverYawRiseRateRadps2;

		DeltaOmegaZ = TargetOmegaZ - Core.OutAngZ_radps;
		MaxDeltaOmega = ControlRate * ControlDT;
		DeltaOmegaZ = FClamp(DeltaOmegaZ, -MaxDeltaOmega, MaxDeltaOmega);
		LastYawTargetRadps = TargetOmegaZ;
		LastYawCorrectionRadps = DeltaOmegaZ;
		LastYawControlDt = ControlDT;
		if (Abs(DeltaOmegaZ) > 0.001 && !ApplyYawImpulseCouple(DeltaOmegaZ))
			Warn("HB2_STEER FAIL yaw couple deltaOmega="$DeltaOmegaZ);

		if (bDiagnosticLog && Level.TimeSeconds >= NextYawControlLogTime
			&& (!bNeutralSteer || Abs(Core.OutAngZ_radps) > 0.02))
		{
			NextYawControlLogTime = Level.TimeSeconds + 0.25;
			Log("HB2_YAW t="$Level.TimeSeconds$" steer="$Steer
				$" target="$TargetOmegaZ$" omegaZ="$Core.OutAngZ_radps
				$" correction="$DeltaOmegaZ$" rate="$ControlRate
				$" controlDt="$ControlDT$" neutral="$bNeutralSteer);
		}
	}

	// Gas, Space, rolling and aero run in SimStep at FixedDt.
}

defaultproperties
{
	DrawType=DT_Sprite
	Texture=Texture'Engine.S_Actor'
	bHidden=False
	bStatic=False
	bMovable=True
	bNoDelete=False
	Physics=PHYS_None
	bCollideWorld=False
	bCollideActors=False
	bBlockActors=False
	bBlockPlayers=False
	CollisionRadius=24
	CollisionHeight=24
	MassKg=200
	HalfExtentUU=24
	ChassisHalfUU=(X=24.000,Y=24.000,Z=24.000)
	ChassisProfile="legacy_cube"
	FaceNeighborSepUU=24
	bDrawChassisDebug=True
	Restitution=0.0
	Friction=0.55
	SteerMode="yaw"
	bVisualWheelsEnabled=True
	ControlProfile="p1_direct"
	TireMu=1.150
	SoundPitch=64
	SoundVolume=150
	SoundRadius=96
	bTorque4WDEnabled=True
	EnginePeakTorqueNm=490.0
	EngineIdleRPM=850.0
	EngineRedlineRPM=3300.0
	FinalDriveRatio=5.200
	GearRatio1=7.100
	GearRatio2=5.000
	GearRatio3=3.800
	GearRatio4=3.000
	ReverseGearRatio=5.400
	MaxRoadSpeedMps=13.8889
	TransmissionEfficiency=0.840
	WheelInertiaKgM2=14.000
	WheelSlipStiffnessNspm=1400.0
	WheelBearingDampingNms=1.250
	WheelBrakeTorqueNm=2100.0
	bPawnCrushEnabled=True
	CrushEnterMps=1.100
	CrushRefMps=5.000
	CrushDamageAtRef=300.0
	CrushDamageMaxMult=2.000
	CrushCooldownSec=0.350
	CrushSearchPaddingUU=12.0
	bAntiRollEnabled=True
	FrontAntiRollNpm=9500.0
	RearAntiRollNpm=7500.0
	AntiRollDampingNs=1500.0
	AntiRollMaxForceN=3500.0
	bWheelObstacleContactsEnabled=True
	bSampleMeshBelly=True
	bMeshBellySkidFriction=True
	MaxSteerRad=0.480
	TireLateralSlipCoeff=6.000
	MaxCorneringAccelMps2=4.500
	HighSpeedCorneringAccelMps2=6.400
	TireContactRiseTime=0.080
	DriverMaxYawRateRadps=1.600
	DriverYawRiseRateRadps2=2.800
	DriverYawNeutralRateRadps2=4.500
	DriverYawReverseRateRadps2=5.500
	DriverMaxControlDt=0.050
	bSuspensionEnabled=True
	SuspensionAttachmentUU(0)=(X=28.875,Y=-19.950,Z=-10.500)
	SuspensionAttachmentUU(1)=(X=28.875,Y=19.950,Z=-10.500)
	SuspensionAttachmentUU(2)=(X=-28.875,Y=-19.950,Z=-10.500)
	SuspensionAttachmentUU(3)=(X=-28.875,Y=19.950,Z=-10.500)
	SuspensionAxisBody(0)=(Z=-1.000)
	SuspensionAxisBody(1)=(Z=-1.000)
	SuspensionAxisBody(2)=(Z=-1.000)
	SuspensionAxisBody(3)=(Z=-1.000)
	SuspensionRestUU(0)=28.875
	SuspensionRestUU(1)=28.875
	SuspensionRestUU(2)=28.875
	SuspensionRestUU(3)=28.875
	SuspensionMinUU(0)=7.875
	SuspensionMinUU(1)=7.875
	SuspensionMinUU(2)=7.875
	SuspensionMinUU(3)=7.875
	SuspensionMaxUU(0)=36.750
	SuspensionMaxUU(1)=36.750
	SuspensionMaxUU(2)=36.750
	SuspensionMaxUU(3)=36.750
	WheelRadiusUU(0)=11.550
	WheelRadiusUU(1)=11.550
	WheelRadiusUU(2)=11.550
	WheelRadiusUU(3)=11.550
	SuspensionSpringNpm(0)=3000.000
	SuspensionSpringNpm(1)=3000.000
	SuspensionSpringNpm(2)=3000.000
	SuspensionSpringNpm(3)=3000.000
	SuspensionDamperCompressionNspm(0)=700.000
	SuspensionDamperCompressionNspm(1)=700.000
	SuspensionDamperCompressionNspm(2)=700.000
	SuspensionDamperCompressionNspm(3)=700.000
	SuspensionDamperReboundNspm(0)=900.000
	SuspensionDamperReboundNspm(1)=900.000
	SuspensionDamperReboundNspm(2)=900.000
	SuspensionDamperReboundNspm(3)=900.000
	SuspensionBumpStopNpm(0)=30000.000
	SuspensionBumpStopNpm(1)=30000.000
	SuspensionBumpStopNpm(2)=30000.000
	SuspensionBumpStopNpm(3)=30000.000
	SuspensionMinNormalAlignment(0)=0.200
	SuspensionMinNormalAlignment(1)=0.200
	SuspensionMinNormalAlignment(2)=0.200
	SuspensionMinNormalAlignment(3)=0.200
	bCoastResistanceEnabled=True
	RollingResistanceCoeff=0.055
	AeroDragNsp2=0.300
	EngineBrakeLoadCoeff=0.040
	SpaceBrakeLoadCoeff=0.450
	CoastSpeedDeadzoneMps=0.080
	DriverAccelMps2=4.500
	bDieselDriveCurve=True
	bLevelRestHoldEnabled=True
	DieselLaunchAccelMps2=6.000
	DieselMaxSpeedMps=25.000
	DriverAccelFadeSpeedMps=18.000
	DriverAccelMinFrac=0.350
	bDiagnosticLog=True
	DiagnosticInterval=0.5
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
}
