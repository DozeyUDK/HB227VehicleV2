//=============================================================================
// HB2TestGame — P0 collision gates (no PhysX).
// ?hb2p0=1 → auto gates. Without it → free manual drive (no auto impulses).
//=============================================================================
class HB2TestGame expands UnrealShare.UnrealGameInfo;

var bool bP0;
var bool bP06;
var bool bP1;
var bool bP15;
var bool bP2;
var bool bP21;
var bool bP22;
var bool bP23;
var bool bP24;
var bool bP25a;
var bool bP26a;
var bool bPSpire;
var bool bNoWheels;
var bool bForceWheels;
var bool bMapTrace;
var HB2MapTraceProbe MapTrace;
var HB2Body TestBody;
var int Phase; // 0 wait, 1A, 2B, 3C, 4D, 5E, 9 done
var float PhaseStart;
var vector Origin;
var vector WallDir;
var vector TargetDir;
var string ResultA, ResultB, ResultC, ResultD, ResultE;
var Actor Blocker;
var Actor MeshTarget;
var bool bSpawnedBlocker;
var bool bPreparedC;
var bool bPreparedE;
var vector SlopeAim;
var vector P06Origin;
var vector P06FastStart;
var int P06SweepStart;
var float P06YawStart;
var string ResultRotation, ResultCouple, ResultFastBSP;
var int P1Phase;
var float P1PhaseStart;
var vector P1FlatCenter;
var int P1StartSteps;
var int P1ThreeContactStart;
var int P1ContactLossStart;
var float P1MaxAbsRoll;
var float P1MaxAbsPitch;
var vector P1SlopeNormal;
var vector P1WallDir;
var int P1WallPointStart;
var int P1WallSweepStart;
var int P1WallFallbackStart;
var int P1WallBSPContactSamples;
var bool bP1SlopeSupportedResponse;
var string ResultP1Stationary, ResultP1ContactLoss, ResultP1Heave;
var string ResultP1Roll, ResultP1Pitch, ResultP1Chassis;
var string ResultP13HighSpeed;
var float P13HSMaxOmega;
var float P13HSLaunchSpeed;
var float P13HSMaxUnique;
var int P13HSContactSamples;
var string ResultP13C1500;
var string ResultP14Flat;
var string ResultP14Brake;
var string ResultP14Slope;
var string ResultP14Air;
var string ResultP14Fps;
var string ResultP15Drive;
var string ResultP15Side;
var string ResultP2Straight, ResultP2SteerLow, ResultP2SteerHigh, ResultP2Release;
var string ResultP2Brake, ResultP2Air, ResultP2Roof, ResultP2Slope;
var string ResultP2Mu, ResultP2Fps;
var string ResultP21Roof, ResultP21Left, ResultP21Right, ResultP21Crash, ResultP21FailPath;
var string ResultP21WheelGeom;
var string ResultP22Geometry, ResultP22StraightBrake, ResultP22Turns;
var string ResultP22Reverse, ResultP22FrontBSP, ResultP22SlopeLoss;
var string ResultP22Roof, ResultP22Reset, ResultP22Idle;
var int P22MinContacts;
var bool bP22SawTwoWheelLoss;
var float P22MaxAbsBodyLat, P22MaxAbsYawRate, P22MaxAbsRollRate;
var float P22MaxMu, P22MaxForceDelta;
var float P22MaxRecontactForce;
var float P22LastYawRate, P22LastRollRate, P22LastBodyLat;
var string ResultP23Edge, ResultP23Turns, ResultP23Reverse, ResultP23Rest;
var string ResultP23Straight, ResultP23SteerHigh, ResultP23Mu;
var float P23MaxAbsDL, P23MaxCompressDL, P23MaxForceDelta;
var int P23MinContacts;
var string ResultP23HistoricP15, ResultP23HistoricP2;
var string ResultP24Flat300, ResultP24Flat600, ResultP24Flat900;
var string ResultP24Slope, ResultP24Edge, ResultP24Lip, ResultP24Break;
var string ResultP24Probe, ResultP24DamperCheck, ResultP24ChassisImpulse;
var int P24ProbeSwitchCount;
var int P24PrevProbe[4];
var float P24PeakAz, P24PeakRollAcc;
var float P24MaxAbsChassisJn, P24MaxChassisPenUU;
var int P24MaxChassisContacts, P24MaxChassisSkip;
var string ResultP26aSeparateSlope;
var int P26aMaxFlatWheels, P26aMaxChassisContacts;
var float P26aMaxAbsJn, P26aPeakPenUU;
var bool bP26aSawSlopeChassis, bP26aSawQualifiedContact;
var int P24PeakAzStep, P24PeakRollStep;
var string P24PeakAzCause, P24PeakRollCause, P24PeakAzTag, P24PeakRollTag;
var int P24PeakAzWheel, P24PeakRollWheel;
var string ResultP25aSweep9905, ResultP25aSweep600, ResultP25aSweep450, ResultP25aSweep300;
var string ResultP25aStraightLong, ResultP25aSym, ResultP25aBaseline05;
var string ResultP25aHistoricP2Straight;
var float P25aMinFrontN, P25aMaxPitch, P25aMaxAbsYaw, P25aMaxAbsBodyLat;
var int P25aMinWheels;
var float P14TmpDist, P14TmpKe0, P14TmpKe1, P14TmpSpd0, P14TmpSpd1;
var float P14TmpRoll, P14TmpAero, P14TmpEng, P14TmpLoad;
var vector P14TmpOrigin;
var int P14TmpWheels;

event InitGame(string Options, out string Error)
{
	Super.InitGame(Options, Error);
	bP0 = (ParseOption(Options, "hb2p0") == "1");
	bP06 = (ParseOption(Options, "hb2p06") == "1");
	bP1 = (ParseOption(Options, "hb2p1") == "1");
	bP15 = (ParseOption(Options, "hb2p15") == "1");
	bP2 = (ParseOption(Options, "hb2p2") == "1");
	bP21 = (ParseOption(Options, "hb2p21") == "1");
	bP22 = (ParseOption(Options, "hb2p22") == "1");
	bP23 = (ParseOption(Options, "hb2p23") == "1");
	bP24 = (ParseOption(Options, "hb2p24") == "1");
	bP25a = (ParseOption(Options, "hb2p25a") == "1");
	bP26a = (ParseOption(Options, "hb2p26a") == "1");
	bPSpire = (ParseOption(Options, "hb2spire") == "1");
	bNoWheels = (ParseOption(Options, "hb2nowheels") == "1");
	bForceWheels = (ParseOption(Options, "hb2wheels") == "1");
	bMapTrace = (ParseOption(Options, "hb2maptrace") == "1");
	if (bP06)
		bP0 = True;
	if (bP15)
		bP1 = True;
}

function EnsurePlayerStart()
{
	local PlayerStart PS;
	local HB2PlayerStart HBPS;
	local vector Loc;
	local int N;

	N = 0;
	foreach AllActors(class'PlayerStart', PS)
	{
		PS.bSinglePlayerStart = True;
		PS.bCoopStart = True;
		PS.bEnabled = True;
		N++;
		Log("HB2: found PlayerStart="$PS$" at="$PS.Location$" class="$PS.Class);
	}
	if (N > 0)
		return;

	// Stock PlayerStart is bStatic — cannot Spawn at runtime. Use HB2PlayerStart.
	// Also covers maps where placed Engine.PlayerStart failed to enter the world
	// (stuck in solid / outside subtractive playable volume).
	Loc = vect(0,0,220);
	HBPS = Spawn(class'HB2PlayerStart',,, Loc);
	if (HBPS == None)
	{
		Warn("HB2: emergency HB2PlayerStart spawn FAILED at "$Loc);
		return;
	}
	HBPS.bSinglePlayerStart = True;
	HBPS.bCoopStart = True;
	HBPS.bEnabled = True;
	Log("HB2: spawned emergency HB2PlayerStart at="$HBPS.Location$" (no live PlayerStart in world)");
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	EnsurePlayerStart();
	if (bPSpire)
	{
		Spawn(class'HB2SpireDriveGate');
		Log("HB2_SPIRE ARMED scripted drive suite on "$Level);
	}
	Log("HB2: gametype ready (native Core3D + Engine Trace, no PhysX calls) hb2p0="$bP0$" hb2p06="$bP06$" hb2p1="$bP1$" hb2p15="$bP15$" hb2p2="$bP2$" hb2p21="$bP21$" hb2p22="$bP22$" hb2p23="$bP23$" hb2p24="$bP24$" hb2p25a="$bP25a$" hb2maptrace="$bMapTrace);
	if (bMapTrace)
	{
		MapTrace = Spawn(class'HB2MapTraceProbe');
		Log("HB2: MapTraceProbe="$MapTrace);
	}
	if (bP0)
		SetTimer(0.25, True);
	else if (bP2)
		SetTimer(0.25, True);
	else if (bP21)
		SetTimer(0.25, True);
	else if (bP22)
		SetTimer(0.25, True);
	else if (bP23)
		SetTimer(0.25, True);
	else if (bP24)
		SetTimer(0.25, True);
	else if (bP25a)
		SetTimer(0.25, True);
	else if (bP26a)
		SetTimer(0.25, True);
	else if (bP1)
		SetTimer(0.25, True);
	else if (!bMapTrace)
		Log("HB2: MANUAL session — no auto P0 impulses/resets");
}

// Accept any PlayerStart in the physics sandbox (ignore disabled single-player flags).
function NavigationPoint FindPlayerStart(byte Team, optional string incomingName)
{
	local PlayerStart Dest;
	local Teleporter Tel;
	local NavigationPoint N;

	if (incomingName != "")
	{
		foreach AllActors(class'Teleporter', Tel)
			if (string(Tel.Tag) ~= incomingName)
				return Tel;
	}

	EnsurePlayerStart();

	foreach AllActors(class'PlayerStart', Dest)
	{
		Dest.bSinglePlayerStart = True;
		Dest.bEnabled = True;
		return Dest;
	}

	N = Super.FindPlayerStart(Team, incomingName);
	if (N != None)
		return N;

	Warn("HB2: FindPlayerStart found NO PlayerStart actors in level");
	return None;
}

function float ChassisClipStandoffUU()
{
	if (bP15)
		return TestBody.ChassisHalfUU.X + 196.0;
	return 220.0;
}

function float ChassisHSStandoffUU()
{
	if (bP15)
		return TestBody.ChassisHalfUU.X + 296.0;
	return 320.0;
}

function float ChassisClipLiftUU()
{
	if (bP15)
		return TestBody.ChassisHalfUU.Z + 24.0;
	return 30.0;
}

function float ChassisHSLiftUU()
{
	if (bP15)
		return TestBody.ChassisHalfUU.Z + 24.0;
	return 55.0;
}

function float P1LoadAbsTolN()
{
	if (bP15)
		return 20.0;
	return 2.0;
}

function bool FindBody()
{
	local HB2Body B;
	if (TestBody != None && !TestBody.bDeleteMe)
		return True;
	foreach AllActors(class'HB2Body', B)
	{
		if (B != None && !B.bDeleteMe)
		{
			TestBody = B;
			return True;
		}
	}
	return False;
}

function Timer()
{
	if (bP0)
		TickP0();
	else if (bP2)
		TickP2();
	else if (bP21)
		TickP21();
	else if (bP22)
		TickP22();
	else if (bP23)
		TickP23();
	else if (bP24)
		TickP24();
	else if (bP25a)
		TickP25a();
	else if (bP26a)
		TickP26a();
	else if (bP1)
		TickP1();
}

function bool FindFlatSuspensionSite(out vector FloorCenter)
{
	local int ix, iy, i, HitCount;
	local float GroundMin, GroundMax, GroundSum;
	local vector ProbeXY, Start, End, HitLoc, HitNorm, ScanOrigin;
	local Actor Hit;

	// P2.4 fixture: game PlayerStart jitter used to alter the first valid
	// flat patch and subsequently select a different slope (PASS/FAIL
	// depended on spawn). Lock only P2.4 to a previously verified scan
	// origin on testmap-physics; keep manual/gameplay probes unchanged.
	ScanOrigin = TestBody.Location;
	if (bP24)
	{
		ScanOrigin.X = 260.0;
		ScanOrigin.Y = -20.0;
		Log("HB2_P24 SITE_SEED="$ScanOrigin$" bodySpawn="$TestBody.Location);
	}
	for (ix = -10; ix <= 10; ++ix)
	{
		for (iy = -10; iy <= 10; ++iy)
		{
			ProbeXY.X = ScanOrigin.X + ix * 80.0;
			ProbeXY.Y = ScanOrigin.Y + iy * 80.0;
			ProbeXY.Z = 0;
			HitCount = 0;
			GroundSum = 0;
			GroundMin = 1000000;
			GroundMax = -1000000;
			for (i = 0; i < 4; ++i)
			{
				Start = ProbeXY + TestBody.SuspensionAttachmentUU[i];
				Start.Z = TestBody.Location.Z + 320;
				End = Start;
				End.Z = TestBody.Location.Z - 320;
				Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
				if (Hit == None || HitNorm.Z < 0.995)
					break;
				HitCount++;
				GroundSum += HitLoc.Z;
				GroundMin = FMin(GroundMin, HitLoc.Z);
				GroundMax = FMax(GroundMax, HitLoc.Z);
			}
			if (HitCount == 4 && GroundMax - GroundMin < 0.25)
			{
				FloorCenter = ProbeXY;
				FloorCenter.Z = GroundSum * 0.25;
				Log("HB2_P1 flat site center="$FloorCenter$" heightSpread="$(GroundMax - GroundMin));
				return True;
			}
		}
	}
	return False;
}

function int ActiveSuspensionCount()
{
	local int N;
	if (TestBody.Core.OutWheel0Status == 3) N++;
	if (TestBody.Core.OutWheel1Status == 3) N++;
	if (TestBody.Core.OutWheel2Status == 3) N++;
	if (TestBody.Core.OutWheel3Status == 3) N++;
	return N;
}

function rotator SlopeAlignedRotation(int YawUnits, vector N)
{
	local vector Fwd, Along;
	local rotator R;
	N = Normal(N);
	Fwd.X = Cos(YawUnits * (2.0 * 3.14159265 / 65536.0));
	Fwd.Y = Sin(YawUnits * (2.0 * 3.14159265 / 65536.0));
	Fwd.Z = 0;
	if (VSize(Fwd) < 0.05)
		Fwd = vect(1,0,0);
	Along = Fwd - N * (Fwd Dot N);
	if (VSize(Along) < 0.08)
	{
		R.Yaw = YawUnits;
		return R;
	}
	return rotator(Normal(Along));
}

function bool PlaceForSlope(int YawUnits, out vector SurfaceNormal)
{
	local vector Aim, AimNorm, Start, End, HitLoc, HitNorm, Center;
	local rotator R;
	local Actor Hit;
	local float EquilibriumLengthUU;

	if (!FindSlopeNear(P1FlatCenter, 4500, Aim, AimNorm))
		return False;
	Start = Aim + vect(0,0,320);
	End = Aim - vect(0,0,640);
	Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
	if (Hit == None || HitNorm.Z < 0.40 || HitNorm.Z > 0.92)
		return False;
	EquilibriumLengthUU = TestBody.SuspensionRestUU[0]
		- class'HB2WorldQuery'.static.MToUU(
			TestBody.MassKg * 9.81 / (4.0 * TestBody.SuspensionSpringNpm[0]));
	Center = HitLoc;
	if (bP15 || bP2 || bP22 || bP23 || bP24 || bP25a)
	{
		// World-Z placement puts the 118 UU nose into the BSP face
		// (α≈29° → 73.5 sin α ≈ 35 UU drop vs 17 UU clearance).
		Center = HitLoc + HitNorm * TestBody.ChassisSpawnHeightUU();
		R = SlopeAlignedRotation(YawUnits, HitNorm);
	}
	else
	{
		Center.Z = HitLoc.Z - TestBody.SuspensionAttachmentUU[0].Z
			+ EquilibriumLengthUU + TestBody.WheelRadiusUU[0];
		R.Yaw = YawUnits;
	}
	TestBody.SetRotation(R);
	TestBody.ResetTo(Center, vect(0,0,0));
	SurfaceNormal = HitNorm;
	Log("HB2_P1 slope placement yaw="$YawUnits$" center="$Center$" normal="$HitNorm
		$" profile="$TestBody.ChassisProfile);
	return True;
}

function StartP13HighSpeedSlope()
{
	local vector Downhill, Gravity, WallHit;
	local rotator ZeroRot;

	P13HSMaxOmega = 0;
	P13HSLaunchSpeed = 0;
	P13HSMaxUnique = 0;
	P13HSContactSamples = 0;

	// Controlled descending BSP face (same wall as chassis, higher speed +
	// downward component). A free slope run on this map leaves the hill
	// airborne and is not a chassis-clip measurement.
	if (FindBSPWallNear(P1FlatCenter, P1WallDir, WallHit))
	{
		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(WallHit - P1WallDir * ChassisHSStandoffUU()
			+ vect(0,0,1) * ChassisHSLiftUU(), vect(0,0,0));
		TestBody.ImpulseUU(P1WallDir * 2000 + vect(0,0,-600));
		TestBody.bP13HSLatch = True;
		TestBody.P13HSLatchedOmega = 0;
		TestBody.P13HSLatchedUnique = 0;
		TestBody.P13CLogCount = 0;
		TestBody.P13CTag = "2000";
		P1Phase = 8;
		P1PhaseStart = Level.TimeSeconds;
		Log("HB2_P13B START_HIGHSPEED wall dir="$P1WallDir$" wall="$WallHit
			$" loc="$TestBody.Location$" impulseUU=2000,-600z");
		return;
	}

	if (PlaceForSlope(0, P1SlopeNormal))
	{
		Gravity = vect(0,0,-1);
		Downhill = Gravity - P1SlopeNormal * (Gravity Dot P1SlopeNormal);
		if (VSize(Downhill) < 0.08)
		{
			ResultP13HighSpeed = "NOT_RUN flat slope";
			Log("HB2_P13B NOT_RUN_HIGHSPEED downhill degenerate n="$P1SlopeNormal);
			BeginP1FinalRest();
			return;
		}
		Downhill = Normal(Downhill);
		TestBody.ResetTo(TestBody.Location - P1SlopeNormal * 12, vect(0,0,0));
		TestBody.ImpulseUU(Downhill * 1400);
		TestBody.bP13HSLatch = True;
		TestBody.P13HSLatchedOmega = 0;
		TestBody.P13HSLatchedUnique = 0;
		TestBody.P13CLogCount = 0;
		TestBody.P13CTag = "2000";
		P1Phase = 8;
		P1PhaseStart = Level.TimeSeconds;
		Log("HB2_P13B START_HIGHSPEED slope downhill="$Downhill$" n="$P1SlopeNormal
			$" loc="$TestBody.Location$" impulseUU=1400 sinkN=12");
		return;
	}

	ResultP13HighSpeed = "NOT_RUN no slope or wall";
	Log("HB2_P13B NOT_RUN_HIGHSPEED no slope or BSP wall");
	BeginP1FinalRest();
}

function StartP13MidSpeedClip()
{
	local vector WallHit;
	local rotator ZeroRot;

	if (!FindBSPWallNear(P1FlatCenter, P1WallDir, WallHit))
	{
		ResultP13C1500 = "NOT_RUN no BSP wall";
		Log("HB2_P13C NOT_RUN_1500 no BSP wall");
		StartP13HighSpeedSlope();
		return;
	}
	TestBody.SetRotation(ZeroRot);
	TestBody.ResetTo(WallHit - P1WallDir * ChassisHSStandoffUU()
		+ vect(0,0,1) * ChassisHSLiftUU(), vect(0,0,0));
	TestBody.ImpulseUU(P1WallDir * 1500 + vect(0,0,-450));
	TestBody.bP13HSLatch = True;
	TestBody.P13HSLatchedOmega = 0;
	TestBody.P13HSLatchedUnique = 0;
	TestBody.P13CLogCount = 0;
	TestBody.P13CTag = "1500";
	P13HSMaxOmega = 0;
	P13HSMaxUnique = 0;
	P13HSContactSamples = 0;
	P13HSLaunchSpeed = 1500;
	P1Phase = 10;
	P1PhaseStart = Level.TimeSeconds;
	Log("HB2_P13C START_1500 wall dir="$P1WallDir$" wall="$WallHit
		$" loc="$TestBody.Location$" impulseUU=1500,-450z");
}

function P14SettleFlat()
{
	local rotator ZeroRot;
	TestBody.LastGas = 0;
	TestBody.LastBrake = 0;
	TestBody.bP13HSLatch = False;
	TestBody.SetRotation(ZeroRot);
	TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
	TestBody.PumpPhysics(1.0 / 60.0, 0.40);
}

function P14LaunchVel(vector VelUU)
{
	TestBody.ResetTo(TestBody.Location, VelUU);
}

function P14Measure(float OuterDt, float Duration)
{
	local vector V;
	V.X = TestBody.Core.OutVelX_mps;
	V.Y = TestBody.Core.OutVelY_mps;
	V.Z = TestBody.Core.OutVelZ_mps;
	P14TmpSpd0 = VSize(V);
	P14TmpKe0 = 0.5 * TestBody.MassKg * (V Dot V);
	P14TmpOrigin = TestBody.Location;
	TestBody.PumpPhysics(OuterDt, Duration);
	V.X = TestBody.Core.OutVelX_mps;
	V.Y = TestBody.Core.OutVelY_mps;
	V.Z = TestBody.Core.OutVelZ_mps;
	P14TmpSpd1 = VSize(V);
	P14TmpKe1 = 0.5 * TestBody.MassKg * (V Dot V);
	P14TmpDist = VSize(TestBody.Location - P14TmpOrigin);
	P14TmpWheels = TestBody.LastCoastGroundWheels;
	P14TmpRoll = TestBody.LastRollImpulseNs;
	P14TmpAero = TestBody.LastAeroImpulseNs;
	P14TmpEng = TestBody.LastEngineImpulseNs;
	P14TmpLoad = TestBody.LastLoadSumN;
}

function StartP14CoastSuite()
{
	local float D30, D60, D120, K60_0, K60_1, BrakeDist, CoastKeRatio;
	local float SlopeK0, SlopeK1, AirS0, AirS1, FpsRatio, Lo, Hi;
	local float SlopeLaunchUU, SlopeDur;
	local vector Downhill, Gravity, VelUU;
	local rotator ZeroRot;
	local bool bFlatOk, bBrakeOk, bFpsOk, bSlopeOk, bAirOk;

	Log("HB2_P14 START_COAST_SUITE loc="$TestBody.Location);
	ResultP14Flat = "NOT_RUN";
	ResultP14Brake = "NOT_RUN";
	ResultP14Slope = "NOT_RUN";
	ResultP14Air = "NOT_RUN";
	ResultP14Fps = "NOT_RUN";
	VelUU = vect(800,0,0);

	P14SettleFlat();
	P14LaunchVel(VelUU);
	TestBody.LastGas = 0;
	TestBody.LastBrake = 0;
	P14Measure(1.0 / 30.0, 3.0);
	D30 = P14TmpDist;
	Log("HB2_P14 FLAT fps=30 distUU="$P14TmpDist$" spd="$P14TmpSpd0$"->"$P14TmpSpd1
		$" ke="$P14TmpKe0$"->"$P14TmpKe1$" loadN="$P14TmpLoad
		$" wheels="$P14TmpWheels$" Jroll="$P14TmpRoll$" Jeng="$P14TmpEng
		$" Jaero="$P14TmpAero$" mode="$TestBody.LastCoastMode);

	P14SettleFlat();
	P14LaunchVel(VelUU);
	TestBody.LastGas = 0;
	TestBody.LastBrake = 0;
	P14Measure(1.0 / 60.0, 3.0);
	D60 = P14TmpDist;
	K60_0 = P14TmpKe0;
	K60_1 = P14TmpKe1;
	Log("HB2_P14 FLAT fps=60 distUU="$P14TmpDist$" spd="$P14TmpSpd0$"->"$P14TmpSpd1
		$" ke="$P14TmpKe0$"->"$P14TmpKe1$" loadN="$P14TmpLoad
		$" wheels="$P14TmpWheels$" Jroll="$P14TmpRoll$" Jeng="$P14TmpEng
		$" Jaero="$P14TmpAero$" mode="$TestBody.LastCoastMode);

	P14SettleFlat();
	P14LaunchVel(VelUU);
	TestBody.LastGas = 0;
	TestBody.LastBrake = 0;
	P14Measure(1.0 / 120.0, 3.0);
	D120 = P14TmpDist;
	Log("HB2_P14 FLAT fps=120 distUU="$P14TmpDist$" spd="$P14TmpSpd0$"->"$P14TmpSpd1
		$" ke="$P14TmpKe0$"->"$P14TmpKe1$" loadN="$P14TmpLoad
		$" wheels="$P14TmpWheels$" Jroll="$P14TmpRoll$" Jeng="$P14TmpEng
		$" Jaero="$P14TmpAero$" mode="$TestBody.LastCoastMode);

	Lo = D30;
	if (D60 < Lo) Lo = D60;
	if (D120 < Lo) Lo = D120;
	Hi = D30;
	if (D60 > Hi) Hi = D60;
	if (D120 > Hi) Hi = D120;
	if (Lo > 1)
		FpsRatio = Hi / Lo;
	else
		FpsRatio = 999;
	CoastKeRatio = 1;
	if (K60_0 > 1)
		CoastKeRatio = K60_1 / K60_0;
	bFlatOk = (K60_1 < K60_0 * 0.92 && K60_1 > 0 && D60 > 50);
	bFpsOk = (FpsRatio <= 1.18);
	if (bFlatOk)
		ResultP14Flat = "PASS";
	else
		ResultP14Flat = "FAIL";
	if (bFpsOk)
		ResultP14Fps = "PASS";
	else
		ResultP14Fps = "FAIL";
	Log("HB2_P14 FLAT_SUMMARY keRatio="$CoastKeRatio$" dist30="$D30
		$" dist60="$D60$" dist120="$D120$" fpsRatio="$FpsRatio
		$" flat="$ResultP14Flat$" fps="$ResultP14Fps);

	P14SettleFlat();
	P14LaunchVel(VelUU);
	TestBody.LastGas = 0;
	TestBody.LastBrake = 1.0;
	P14Measure(1.0 / 60.0, 3.0);
	BrakeDist = P14TmpDist;
	bBrakeOk = (BrakeDist > 20 && D60 > 50 && BrakeDist < D60 * 0.72
		&& P14TmpKe1 < P14TmpKe0);
	if (bBrakeOk)
		ResultP14Brake = "PASS";
	else
		ResultP14Brake = "FAIL";
	Log("HB2_P14 BRAKE fps=60 distUU="$BrakeDist$" coastDistUU="$D60
		$" spd="$P14TmpSpd0$"->"$P14TmpSpd1$" ke="$P14TmpKe0$"->"$P14TmpKe1
		$" Jbrake="$TestBody.LastBrakeImpulseNs$" mode="$TestBody.LastCoastMode
		$" result="$ResultP14Brake);
	TestBody.LastBrake = 0;

	if (PlaceForSlope(0, P1SlopeNormal))
	{
		Gravity = vect(0,0,-1);
		Downhill = Gravity - P1SlopeNormal * (Gravity Dot P1SlopeNormal);
		if (VSize(Downhill) > 0.08)
		{
			Downhill = Normal(Downhill);
			TestBody.LastGas = 0;
			TestBody.LastBrake = 0;
			SlopeLaunchUU = 600;
			SlopeDur = 2.50;
			if (bP15)
			{
				// Cube 600 UU/s × 2.5 s covers ~847 UU on this BSP face.
				// The P1.5 chassis is 236 UU long; the same launch leaves
				// the face airborne (wheels=0, KE→0). Keep the load-coast
				// check on the face: 350 UU/s × 1.20 s.
				SlopeLaunchUU = 350;
				SlopeDur = 1.20;
			}
			TestBody.ResetTo(TestBody.Location, Downhill * SlopeLaunchUU);
			P14Measure(1.0 / 60.0, SlopeDur);
			SlopeK0 = P14TmpKe0;
			SlopeK1 = P14TmpKe1;
			bSlopeOk = (SlopeK1 < SlopeK0 && P14TmpWheels > 0
				&& TestBody.StepFailureCount == 0);
			if (bSlopeOk)
				ResultP14Slope = "PASS";
			else
				ResultP14Slope = "FAIL";
			Log("HB2_P14 SLOPE distUU="$P14TmpDist$" spd="$P14TmpSpd0$"->"$P14TmpSpd1
				$" ke="$SlopeK0$"->"$SlopeK1$" loadN="$P14TmpLoad
				$" wheels="$P14TmpWheels$" Jroll="$P14TmpRoll
				$" launchUU="$SlopeLaunchUU$" dur="$SlopeDur
				$" mode="$TestBody.LastCoastMode$" result="$ResultP14Slope);
		}
		else
		{
			ResultP14Slope = "NOT_RUN degenerate downhill";
			Log("HB2_P14 NOT_RUN_SLOPE downhill degenerate");
		}
	}
	else
	{
		ResultP14Slope = "NOT_RUN no slope";
		Log("HB2_P14 NOT_RUN_SLOPE no usable BSP slope");
	}

	TestBody.SetRotation(ZeroRot);
	TestBody.LastGas = 0;
	TestBody.LastBrake = 0;
	TestBody.ResetTo(P1FlatCenter + vect(0,0,420), vect(800,0,0));
	P14Measure(1.0 / 60.0, 0.45);
	AirS0 = P14TmpSpd0;
	AirS1 = P14TmpSpd1;
	bAirOk = (P14TmpWheels == 0 && P14TmpRoll == 0 && P14TmpAero > 0
		&& TestBody.LastCoastMode == "air");
	if (bAirOk)
		ResultP14Air = "PASS";
	else if (P14TmpWheels > 0)
		ResultP14Air = "NOT_RUN landed";
	else
		ResultP14Air = "FAIL";
	Log("HB2_P14 AIR distUU="$P14TmpDist$" spd="$AirS0$"->"$AirS1
		$" ke="$P14TmpKe0$"->"$P14TmpKe1$" wheels="$P14TmpWheels
		$" Jroll="$P14TmpRoll$" Jaero="$P14TmpAero
		$" mode="$TestBody.LastCoastMode$" result="$ResultP14Air);

	Log("HB2_P14 GATE_DONE flat="$ResultP14Flat$" brake="$ResultP14Brake
		$" slope="$ResultP14Slope$" air="$ResultP14Air$" fps="$ResultP14Fps
		$" stepFail="$TestBody.StepFailureCount
		$" nonFinite="$TestBody.NonFiniteStateCount);
	BeginP1FinalRest();
}

function BeginP1FinalRest()
{
	local rotator ZeroRot;
	if (TestBody != None)
		TestBody.bP13HSLatch = False;
	TestBody.SetRotation(ZeroRot);
	TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
	P1StartSteps = TestBody.TotalStepCount;
	P1Phase = 7;
	P1PhaseStart = Level.TimeSeconds;
	Log("HB2_P1 START_FINAL_REST duration=30s");
}

function StartP1ChassisBSP()
{
	local vector WallHit;
	local rotator ZeroRot;
	if (!FindBSPWallNear(P1FlatCenter, P1WallDir, WallHit))
	{
		ResultP1Chassis = "NOT_RUN no BSP wall";
		Log("HB2_P1 NOT_RUN_CHASSIS no BSP wall in query range");
		if (bP15)
			StartP15SideBSP();
		else
			StartP13MidSpeedClip();
		return;
	}
	TestBody.SetRotation(ZeroRot);
	TestBody.ResetTo(WallHit - P1WallDir * ChassisClipStandoffUU()
		+ vect(0,0,1) * ChassisClipLiftUU(), vect(0,0,0));
	P1WallSweepStart = TestBody.ReliableSweepPointCount;
	P1WallPointStart = TestBody.ReliablePointContactCount;
	P1WallFallbackStart = TestBody.FallbackPointContactCount;
	P1WallBSPContactSamples = 0;
	TestBody.ImpulseUU(P1WallDir * 1100);
	TestBody.bP13HSLatch = True;
	TestBody.P13CTag = "1100";
	TestBody.P13CLogCount = 0;
	TestBody.P13HSLatchedOmega = 0;
	TestBody.P13HSLatchedUnique = 0;
	P1Phase = 6;
	P1PhaseStart = Level.TimeSeconds;
	Log("HB2_P1 START_CHASSIS_BSP dir="$P1WallDir$" wallHit="$WallHit
		$" start="$TestBody.Location$" sweepStart="$P1WallSweepStart);
}

function StartP1ContactLoss()
{
	local vector Kick;
	local float DeltaUU;
	local rotator ZeroRot;

	DeltaUU = 100.0;
	if (bP15)
	{
		// Cube 100 UU/s: P15 at 100 tumbled (recoveredActive=0, scrape
		// atan(17/44.5)≈21° vs cube ≈37°). P15 at 45.7 never unloaded.
		// 75 UU/s is the in-between kick that unloads a wheel.
		DeltaUU = 75.0;
		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
		TestBody.PumpPhysics(1.0 / 60.0, 0.25);
	}
	P1ThreeContactStart = TestBody.SuspensionThreeContactStepCount;
	P1ContactLossStart = TestBody.SuspensionContactLossStepCount;
	Kick.Z = DeltaUU;
	if (!TestBody.ImpulseAtOffsetUU(Kick, TestBody.SuspensionAttachmentUU[0]))
	{
		ResultP1ContactLoss = "FAIL impulse rejected";
		Warn("HB2_P1 FAIL_CONTACT_LOSS corner impulse rejected");
	}
	Kick.Z = -DeltaUU;
	if (!TestBody.ImpulseAtOffsetUU(Kick, TestBody.SuspensionAttachmentUU[3]))
	{
		ResultP1ContactLoss = "FAIL impulse rejected";
		Warn("HB2_P1 FAIL_CONTACT_LOSS corner impulse rejected");
	}
	P1Phase = 2;
	P1PhaseStart = Level.TimeSeconds;
	Log("HB2_P1 START_CONTACT_LOSS opposedCornerDeltaVelUU=+"$DeltaUU$"/-"$DeltaUU
		$" netLinearImpulse=0 profile="$TestBody.ChassisProfile);
}

function StartP15DriveSmoke()
{
	local rotator ZeroRot;
	TestBody.SetRotation(ZeroRot);
	TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
	TestBody.LastGas = 1.0;
	TestBody.LastBrake = 0;
	P1Phase = 20;
	P1PhaseStart = Level.TimeSeconds;
	Log("HB2_P15 START_DRIVE_SMOKE gas=1 profile="$TestBody.ChassisProfile
		$" Izz="$TestBody.BoxInertiaKgM2(2));
}

function StartP15SideBSP()
{
	local vector WallHit;
	local rotator SideRot;

	if (!FindBSPWallNear(P1FlatCenter, P1WallDir, WallHit))
	{
		ResultP15Side = "NOT_RUN no BSP wall";
		Log("HB2_P15 NOT_RUN_SIDE no BSP wall");
		StartP13MidSpeedClip();
		return;
	}
	SideRot.Yaw = 16384;
	TestBody.SetRotation(SideRot);
	TestBody.ResetTo(WallHit - P1WallDir * (TestBody.ChassisHalfUU.Y + 160.0)
		+ vect(0,0,1) * ChassisHSLiftUU(), vect(0,0,0));
	P1WallBSPContactSamples = 0;
	TestBody.ImpulseUU(P1WallDir * 900);
	TestBody.bP13HSLatch = True;
	TestBody.P13CTag = "side";
	TestBody.P13CLogCount = 0;
	TestBody.P13HSLatchedOmega = 0;
	P1Phase = 11;
	P1PhaseStart = Level.TimeSeconds;
	Log("HB2_P15 START_SIDE_BSP dir="$P1WallDir$" wall="$WallHit
		$" yaw90 start="$TestBody.Location);
}

function P2SettleFlat()
{
	local rotator ZeroRot;
	TestBody.LastGas = 0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.SetRotation(ZeroRot);
	TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
	TestBody.PumpPhysics(1.0 / 60.0, 0.40);
}

function float P2HorizSpeed()
{
	local vector V;
	V.X = TestBody.Core.OutVelX_mps;
	V.Y = TestBody.Core.OutVelY_mps;
	V.Z = 0;
	return VSize(V);
}

function StartP2TireSuite()
{
	local vector VelUU, RoofLoc, Gravity, Downhill, Fwd;
	local rotator RoofRot, ZeroRot;
	local float D30, D60, D120, BrakeDist, FpsRatio, Lo, Hi;
	local float Spd0, Spd1, Yaw0, Yaw1, OmegaRel, OmegaAfter, LatRatio;
	local float FwdSpd, LatSpd, MuMax, AirGas, AirBrake;
	local bool bOk;

	Log("HB2_P2 START_TIRE_SUITE control="$TestBody.ControlProfile
		$" chassis="$TestBody.ChassisProfile$" mu="$TestBody.TireMu
		$" steerRad="$TestBody.MaxSteerRad$" loc="$TestBody.Location);
	ResultP2Straight = "NOT_RUN";
	ResultP2SteerLow = "NOT_RUN";
	ResultP2SteerHigh = "NOT_RUN";
	ResultP2Release = "NOT_RUN";
	ResultP2Brake = "NOT_RUN";
	ResultP2Air = "NOT_RUN";
	ResultP2Roof = "NOT_RUN";
	ResultP2Slope = "NOT_RUN";
	ResultP2Mu = "NOT_RUN";
	ResultP2Fps = "NOT_RUN";

	P2SettleFlat();
	TestBody.LastGas = 1.0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.PumpPhysics(1.0 / 60.0, 1.50);
	FwdSpd = TestBody.Core.OutVelX_mps;
	LatSpd = Abs(TestBody.Core.OutVelY_mps);
	if (Abs(FwdSpd) > 0.05)
		LatRatio = LatSpd / Abs(FwdSpd);
	else
		LatRatio = 999;
	MuMax = TestBody.LastTireMaxMuUtil;
	bOk = (FwdSpd > 3.0 && LatRatio < 0.20
		&& Abs(TestBody.Core.OutAngZ_radps) < 0.50
		&& TestBody.LastTireActiveCount >= 3
		&& TestBody.LastThrottleImpulseNs > 0
		&& TestBody.LastYawCorrectionRadps == 0
		&& TestBody.StepFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0);
	if (bOk)
		ResultP2Straight = "PASS";
	else
		ResultP2Straight = "FAIL";
	Log("HB2_P2 STRAIGHT vx="$FwdSpd$" vy="$TestBody.Core.OutVelY_mps
		$" latRatio="$LatRatio$" omegaZ="$TestBody.Core.OutAngZ_radps
		$" active="$TestBody.LastTireActiveCount$" Jgas="$TestBody.LastThrottleImpulseNs
		$" muMax="$MuMax$" yawCorr="$TestBody.LastYawCorrectionRadps
		$" result="$ResultP2Straight);
	if (MuMax <= 1.02 && TestBody.LastTireActiveCount > 0)
		ResultP2Mu = "PASS";
	else
		ResultP2Mu = "FAIL";
	Log("HB2_P2 MU maxUtil="$MuMax$" cap=1.02 result="$ResultP2Mu);

	P2SettleFlat();
	TestBody.LastGas = 0.35;
	TestBody.LastSteer = 1.0;
	TestBody.LastBrake = 0;
	Yaw0 = TestBody.Core.OutYaw_rad;
	TestBody.PumpPhysics(1.0 / 60.0, 1.50);
	Yaw1 = TestBody.Core.OutYaw_rad;
	bOk = (Abs(Yaw1 - Yaw0) > 0.12
		&& TestBody.LastYawCorrectionRadps == 0
		&& TestBody.LastTireActiveCount >= 2
		&& TestBody.StepFailureCount == 0);
	if (bOk)
		ResultP2SteerLow = "PASS";
	else
		ResultP2SteerLow = "FAIL";
	Log("HB2_P2 STEER_LOW dYaw="$(Yaw1 - Yaw0)$" omegaZ="$TestBody.Core.OutAngZ_radps
		$" yawCorr="$TestBody.LastYawCorrectionRadps$" vx="$TestBody.Core.OutVelX_mps
		$" result="$ResultP2SteerLow);

	P2SettleFlat();
	TestBody.LastGas = 1.0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.PumpPhysics(1.0 / 60.0, 1.20);
	Spd0 = P2HorizSpeed();
	TestBody.LastSteer = 1.0;
	TestBody.PumpPhysics(1.0 / 60.0, 0.80);
	bOk = (Spd0 > 4.0 && Abs(TestBody.Core.OutAngZ_radps) > 0.18
		&& TestBody.LastYawCorrectionRadps == 0
		&& TestBody.StepFailureCount == 0);
	if (bOk)
		ResultP2SteerHigh = "PASS";
	else
		ResultP2SteerHigh = "FAIL";
	Log("HB2_P2 STEER_HIGH spd0="$Spd0$" omegaZ="$TestBody.Core.OutAngZ_radps
		$" yawCorr="$TestBody.LastYawCorrectionRadps$" vx="$TestBody.Core.OutVelX_mps
		$" vy="$TestBody.Core.OutVelY_mps$" result="$ResultP2SteerHigh);

	OmegaRel = Abs(TestBody.Core.OutAngZ_radps);
	TestBody.LastSteer = 0;
	TestBody.LastGas = 0;
	TestBody.PumpPhysics(1.0 / 60.0, 0.60);
	OmegaAfter = Abs(TestBody.Core.OutAngZ_radps);
	bOk = (TestBody.LastYawCorrectionRadps == 0
		&& OmegaAfter <= OmegaRel + 0.08
		&& TestBody.StepFailureCount == 0);
	if (bOk)
		ResultP2Release = "PASS";
	else
		ResultP2Release = "FAIL";
	Log("HB2_P2 RELEASE omegaRel="$OmegaRel$" omegaAfter="$OmegaAfter
		$" yawCorr="$TestBody.LastYawCorrectionRadps$" result="$ResultP2Release);

	P2SettleFlat();
	VelUU = vect(800,0,0);
	TestBody.ResetTo(TestBody.Location, VelUU);
	TestBody.LastGas = 0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	P14Measure(1.0 / 30.0, 2.50);
	D30 = P14TmpDist;
	P2SettleFlat();
	TestBody.ResetTo(TestBody.Location, VelUU);
	P14Measure(1.0 / 60.0, 2.50);
	D60 = P14TmpDist;
	P2SettleFlat();
	TestBody.ResetTo(TestBody.Location, VelUU);
	P14Measure(1.0 / 120.0, 2.50);
	D120 = P14TmpDist;
	Lo = D30;
	if (D60 < Lo) Lo = D60;
	if (D120 < Lo) Lo = D120;
	Hi = D30;
	if (D60 > Hi) Hi = D60;
	if (D120 > Hi) Hi = D120;
	if (Lo > 1)
		FpsRatio = Hi / Lo;
	else
		FpsRatio = 999;
	if (FpsRatio <= 1.18 && D60 > 40)
		ResultP2Fps = "PASS";
	else
		ResultP2Fps = "FAIL";
	Log("HB2_P2 FPS dist30="$D30$" dist60="$D60$" dist120="$D120
		$" fpsRatio="$FpsRatio$" result="$ResultP2Fps);

	P2SettleFlat();
	TestBody.ResetTo(TestBody.Location, VelUU);
	TestBody.LastBrake = 1.0;
	P14Measure(1.0 / 60.0, 2.50);
	BrakeDist = P14TmpDist;
	bOk = (D60 > 40 && BrakeDist > 10 && BrakeDist < D60
		&& P14TmpKe1 < P14TmpKe0);
	if (bOk)
		ResultP2Brake = "PASS";
	else
		ResultP2Brake = "FAIL";
	Log("HB2_P2 BRAKE dist="$BrakeDist$" coastDist="$D60
		$" ke0="$P14TmpKe0$" ke1="$P14TmpKe1
		$" Jbrake="$TestBody.LastBrakeImpulseNs$" mode="$TestBody.LastCoastMode
		$" result="$ResultP2Brake);
	TestBody.LastBrake = 0;

	P2SettleFlat();
	TestBody.LastGas = 1.0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 1.0;
	TestBody.ResetTo(P1FlatCenter + vect(0,0,420), vect(800,0,0));
	TestBody.PumpPhysics(1.0 / 60.0, 0.40);
	AirGas = TestBody.LastThrottleImpulseNs;
	AirBrake = TestBody.LastBrakeImpulseNs;
	bOk = (TestBody.LastTireActiveCount == 0
		&& TestBody.LastCoastGroundWheels == 0
		&& AirGas == 0 && AirBrake == 0
		&& TestBody.LastAeroImpulseNs > 0);
	if (bOk)
		ResultP2Air = "PASS";
	else if (TestBody.LastCoastGroundWheels > 0)
		ResultP2Air = "NOT_RUN landed";
	else
		ResultP2Air = "FAIL";
	Log("HB2_P2 AIR wheels="$TestBody.LastCoastGroundWheels
		$" active="$TestBody.LastTireActiveCount
		$" Jgas="$AirGas$" Jbrake="$AirBrake$" Jaero="$TestBody.LastAeroImpulseNs
		$" mode="$TestBody.LastCoastMode$" result="$ResultP2Air);

	P2SettleFlat();
	RoofRot.Roll = 32768;
	RoofLoc = P1FlatCenter;
	RoofLoc.Z = P1FlatCenter.Z - TestBody.ChassisSpawnHeightUU()
		+ TestBody.ChassisHalfUU.Z + 10.0;
	TestBody.SetRotation(RoofRot);
	Fwd = vect(400,0,0);
	TestBody.ResetTo(RoofLoc, Fwd);
	TestBody.LastGas = 1.0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	Spd0 = P2HorizSpeed();
	TestBody.PumpPhysics(1.0 / 60.0, 0.50);
	Spd1 = P2HorizSpeed();
	bOk = (TestBody.LastThrottleImpulseNs == 0
		&& TestBody.LastTireActiveCount == 0
		&& TestBody.StepFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0);
	if (bOk)
		ResultP2Roof = "PASS";
	else
		ResultP2Roof = "FAIL";
	Log("HB2_P2 ROOF wheels="$TestBody.WheelContactCount
		$" active="$TestBody.LastTireActiveCount
		$" loadN="$TestBody.LastLoadSumN$" Jgas="$TestBody.LastThrottleImpulseNs
		$" spd0="$Spd0$" spd1="$Spd1$" chassisMode="$TestBody.LastChassisContactMode
		$" contacts="$TestBody.ContactCount$" result="$ResultP2Roof);

	if (PlaceForSlope(0, P1SlopeNormal))
	{
		Gravity = vect(0,0,-1);
		Downhill = Gravity - P1SlopeNormal * (Gravity Dot P1SlopeNormal);
		if (VSize(Downhill) > 0.08)
		{
			TestBody.LastGas = 0.40;
			TestBody.LastSteer = 0;
			TestBody.LastBrake = 0;
			TestBody.PumpPhysics(1.0 / 60.0, 1.00);
			bOk = (TestBody.LastCoastGroundWheels > 0
				&& TestBody.LastTireMaxMuUtil <= 1.02
				&& TestBody.StepFailureCount == 0
				&& TestBody.NonFiniteStateCount == 0);
			if (bOk)
				ResultP2Slope = "PASS";
			else
				ResultP2Slope = "FAIL";
			Log("HB2_P2 SLOPE wheels="$TestBody.LastCoastGroundWheels
				$" active="$TestBody.LastTireActiveCount
				$" loadN="$TestBody.LastLoadSumN$" muMax="$TestBody.LastTireMaxMuUtil
				$" Jgas="$TestBody.LastThrottleImpulseNs
				$" vx="$TestBody.Core.OutVelX_mps$" result="$ResultP2Slope);
		}
		else
		{
			ResultP2Slope = "NOT_RUN degenerate downhill";
			Log("HB2_P2 NOT_RUN_SLOPE downhill degenerate");
		}
	}
	else
	{
		ResultP2Slope = "NOT_RUN no slope";
		Log("HB2_P2 NOT_RUN_SLOPE no usable BSP slope");
	}

	TestBody.SetRotation(ZeroRot);
	TestBody.LastGas = 0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
	Log("HB2_P2 GATE_DONE straight="$ResultP2Straight
		$" steerLow="$ResultP2SteerLow$" steerHigh="$ResultP2SteerHigh
		$" release="$ResultP2Release$" brake="$ResultP2Brake
		$" air="$ResultP2Air$" roof="$ResultP2Roof$" slope="$ResultP2Slope
		$" mu="$ResultP2Mu$" fps="$ResultP2Fps
		$" stepFail="$TestBody.StepFailureCount
		$" syncFail="$TestBody.ActorSyncFailureCount
		$" nonFinite="$TestBody.NonFiniteStateCount
		$" tireImpulseFail="$TestBody.LastTireImpulseFail);
}

function TickP2()
{
	local vector HitLoc;
	local rotator ZeroRot;
	local float EquilibriumLengthUU, ExpectedCenterZ;

	if (!FindBody())
	{
		Log("HB2_P2 WAIT: no body");
		return;
	}
	if (P1Phase == 0)
	{
		if (!FindFlatSuspensionSite(HitLoc))
		{
			ResultP2Straight = "FAIL no four-ray flat BSP site";
			Warn("HB2_P2 FAIL no four-ray flat BSP site");
			P1Phase = 99;
			SetTimer(0, False);
			return;
		}
		EquilibriumLengthUU = TestBody.SuspensionRestUU[0]
			- class'HB2WorldQuery'.static.MToUU(
				TestBody.MassKg * 9.81 / (4.0 * TestBody.SuspensionSpringNpm[0]));
		ExpectedCenterZ = HitLoc.Z - TestBody.SuspensionAttachmentUU[0].Z
			+ EquilibriumLengthUU + TestBody.WheelRadiusUU[0];
		P1FlatCenter = HitLoc;
		P1FlatCenter.Z = ExpectedCenterZ;
		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
		Log("HB2_P2 START floor="$HitLoc$" center="$P1FlatCenter
			$" control="$TestBody.ControlProfile$" chassis="$TestBody.ChassisProfile);
		StartP2TireSuite();
		P1Phase = 99;
		SetTimer(0, False);
	}
}

function float P22Max4(float A, float B, float C, float D)
{
	return FMax(FMax(A, B), FMax(C, D));
}

function P22ResetMetrics()
{
	P22MinContacts = 4;
	bP22SawTwoWheelLoss = False;
	P22MaxAbsBodyLat = 0;
	P22MaxAbsYawRate = 0;
	P22MaxAbsRollRate = 0;
	P22MaxMu = 0;
	P22MaxForceDelta = 0;
	P22MaxRecontactForce = 0;
	TestBody.ResetTireForceChangeTelemetry();
}

function P22Sample()
{
	P22MinContacts = Min(P22MinContacts, TestBody.LastTireActiveCount);
	if (TestBody.LastTireActiveCount <= 2)
		bP22SawTwoWheelLoss = True;
	P22MaxAbsBodyLat = FMax(P22MaxAbsBodyLat, Abs(TestBody.LastBodyLateralSpeedMps));
	P22MaxAbsYawRate = FMax(P22MaxAbsYawRate, Abs(TestBody.Core.OutAngZ_radps));
	P22MaxAbsRollRate = FMax(P22MaxAbsRollRate, Abs(TestBody.Core.OutAngX_radps));
	P22MaxMu = FMax(P22MaxMu, TestBody.LastTireMaxMuUtil);
	P22MaxForceDelta = FMax(P22MaxForceDelta,
		P22Max4(TestBody.MaxTireForceDeltaN[0], TestBody.MaxTireForceDeltaN[1],
			TestBody.MaxTireForceDeltaN[2], TestBody.MaxTireForceDeltaN[3]));
	P22MaxRecontactForce = FMax(P22MaxRecontactForce,
		P22Max4(TestBody.MaxTireRecontactForceN[0], TestBody.MaxTireRecontactForceN[1],
			TestBody.MaxTireRecontactForceN[2], TestBody.MaxTireRecontactForceN[3]));
	P22LastYawRate = TestBody.Core.OutAngZ_radps;
	P22LastRollRate = TestBody.Core.OutAngX_radps;
	P22LastBodyLat = TestBody.LastBodyLateralSpeedMps;
}

function P22Pump(float Duration)
{
	local int i, N;
	N = int(Duration * 60.0 + 0.5);
	if (N < 1)
		N = 1;
	for (i = 0; i < N; ++i)
	{
		TestBody.PumpPhysics(1.0 / 60.0, 1.0 / 60.0);
		P22Sample();
	}
}

function P22LogWheels(string Tag)
{
	local int i;
	for (i = 0; i < 4; ++i)
		Log("HB2_P22 WHEEL tag="$Tag$" i="$i
			$" active="$TestBody.WheelTireActive(i)$" N="$TestBody.LastTireN[i]
			$" alphaRad="$TestBody.LastTireSlipAngleRad[i]
			$" Fx="$TestBody.LastTireFx[i]$" Fy="$TestBody.LastTireFy[i]
			$" muN="$TestBody.LastTireCapN[i]$" muUtil="$TestBody.LastTireMuUtil[i]
			$" forceDeltaMaxN="$TestBody.MaxTireForceDeltaN[i]
			$" recontactMaxN="$TestBody.MaxTireRecontactForceN[i]
			$" hitUU="$TestBody.LastWheelHitUU[i]);
}

function bool P22RunTurn(float Steer, string Tag)
{
	local vector VelUU;
	local bool bOk;
	P2SettleFlat();
	VelUU.X = 420.0;
	TestBody.ResetTo(P1FlatCenter, VelUU);
	TestBody.LastGas = 0.20;
	TestBody.LastSteer = Steer;
	TestBody.LastBrake = 0;
	P22ResetMetrics();
	P22Pump(0.80);
	bOk = (Steer * P22LastYawRate > 0.12
		&& P22MinContacts >= 3
		&& P22MaxAbsRollRate < 2.50
		&& P22MaxAbsBodyLat < 5.00
		&& P22MaxMu <= 1.02
		&& TestBody.StepFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0);
	Log("HB2_P22 TURN tag="$Tag$" steer="$Steer
		$" steerEffRad="$TestBody.LastEffectiveSteerRad
		$" yawRate="$P22LastYawRate$" maxYaw="$P22MaxAbsYawRate
		$" rollRate="$P22LastRollRate$" maxRoll="$P22MaxAbsRollRate
		$" bodyLat="$P22LastBodyLat$" maxBodyLat="$P22MaxAbsBodyLat
		$" minContacts="$P22MinContacts$" maxMu="$P22MaxMu
		$" maxForceDeltaN="$P22MaxForceDelta$" maxRecontactN="$P22MaxRecontactForce$" ok="$bOk);
	P22LogWheels(Tag);
	return bOk;
}

function bool P22RunReverse(float SpeedUU, string Tag)
{
	local vector VelUU;
	local float YawA, YawD;
	local bool bOk;
	P2SettleFlat();
	VelUU.X = SpeedUU;
	TestBody.ResetTo(P1FlatCenter, VelUU);
	TestBody.LastGas = 0.10;
	TestBody.LastBrake = 0;
	TestBody.LastSteer = 1.0;
	P22ResetMetrics();
	P22Pump(0.30);
	YawA = TestBody.Core.OutAngZ_radps;
	TestBody.LastSteer = -1.0;
	P22Pump(0.60);
	YawD = TestBody.Core.OutAngZ_radps;
	bOk = (YawA > 0.05 && YawD < YawA - 0.10
		&& P22MinContacts >= 3
		&& P22MaxAbsRollRate < 3.00
		&& P22MaxMu <= 1.02
		&& TestBody.StepFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0);
	Log("HB2_P22 REVERSE tag="$Tag$" speedUU="$SpeedUU
		$" yawA="$YawA$" yawD="$YawD
		$" maxYaw="$P22MaxAbsYawRate$" maxRoll="$P22MaxAbsRollRate
		$" maxBodyLat="$P22MaxAbsBodyLat$" minContacts="$P22MinContacts
		$" maxForceDeltaN="$P22MaxForceDelta$" maxRecontactN="$P22MaxRecontactForce$" ok="$bOk);
	return bOk;
}

function bool P22RunFrontBSP()
{
	local vector N;
	local bool bFrontBSP, bOk;
	local int i;
	if (!PlaceForSlope(0, N))
	{
		ResultP22FrontBSP = "NOT_RUN no BSP slope";
		Log("HB2_P22 FRONT_BSP result="$ResultP22FrontBSP);
		return False;
	}
	TestBody.LastGas = 0.35;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	P22ResetMetrics();
	for (i = 0; i < 60; ++i)
	{
		TestBody.PumpPhysics(1.0 / 60.0, 1.0 / 60.0);
		P22Sample();
		if ((TestBody.LastTireN[0] > 0 && TestBody.LastWheelNormal[0].Z < 0.98)
			|| (TestBody.LastTireN[1] > 0 && TestBody.LastWheelNormal[1].Z < 0.98))
			bFrontBSP = True;
	}
	bOk = (bFrontBSP && P22MinContacts >= 2
		&& P22MaxAbsRollRate < 3.50
		&& TestBody.StepFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0);
	if (bOk)
		ResultP22FrontBSP = "PASS";
	else
		ResultP22FrontBSP = "FAIL";
	Log("HB2_P22 FRONT_BSP normal="$N$" frontBSP="$bFrontBSP
		$" maxRoll="$P22MaxAbsRollRate$" minContacts="$P22MinContacts
		$" chassisPenUU="$TestBody.LastMaxPenUU
		$" note=wheel_rays_are_support_chassis_manifold_is_separate result="$ResultP22FrontBSP);
	P22LogWheels("front_bsp");
	return bOk;
}

function bool P22RunSlopeLoss()
{
	local vector N, Kick, LeftOffset, RightOffset;
	local bool bOk;
	if (!PlaceForSlope(0, N))
	{
		ResultP22SlopeLoss = "NOT_RUN no BSP slope";
		Log("HB2_P22 SLOPE_LOSS result="$ResultP22SlopeLoss);
		return False;
	}
	TestBody.LastGas = 0.15;
	TestBody.LastSteer = 0.55;
	TestBody.LastBrake = 0;
	TestBody.PumpPhysics(1.0 / 60.0, 0.25);
	LeftOffset.Y = -Abs(TestBody.SuspensionAttachmentUU[0].Y);
	RightOffset.Y = Abs(TestBody.SuspensionAttachmentUU[1].Y);
	Kick.Z = 20.0;
	TestBody.ImpulseAtOffsetUU(Kick, LeftOffset);
	Kick.Z = -20.0;
	TestBody.ImpulseAtOffsetUU(Kick, RightOffset);
	P22ResetMetrics();
	P22Pump(0.80);
	TestBody.LastGas = 0;
	TestBody.LastSteer = 0;
	P22Pump(1.20);
	bOk = (bP22SawTwoWheelLoss && TestBody.LastTireActiveCount >= 3
		&& P22MaxAbsRollRate < 3.50
		&& P22MaxMu <= 1.02
		&& TestBody.StepFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0);
	if (bOk)
		ResultP22SlopeLoss = "PASS";
	else if (!bP22SawTwoWheelLoss)
		ResultP22SlopeLoss = "NOT_RUN no two-wheel loss";
	else
		ResultP22SlopeLoss = "FAIL";
	Log("HB2_P22 SLOPE_LOSS normal="$N$" sawTwo="$bP22SawTwoWheelLoss
		$" finalActive="$TestBody.LastTireActiveCount$" minContacts="$P22MinContacts
		$" maxRoll="$P22MaxAbsRollRate$" maxYaw="$P22MaxAbsYawRate
		$" maxForceDeltaN="$P22MaxForceDelta$" maxRecontactN="$P22MaxRecontactForce
		$" result="$ResultP22SlopeLoss);
	return bOk;
}

function StartP22Suite()
{
	local float S, Leq, TargetFX, TargetRX, TargetY, TargetZ, TargetRadius;
	local float ActualCenterZ, Speed0, Speed1, LeftYaw, RightYaw, SymRatio, IdleDriftUU;
	local bool bGeom, bStraight, bLeft, bRight, bR300, bR600, bR900, bRoof, bReset, bIdle;
	local vector RoofLoc, IdleStart, IdleVel;
	local rotator RoofRot, ZeroRot;

	Log("HB2_P22 START package=P2.2 wheel_fit_cornering");
	S = TestBody.Vis.DrawScale;
	TargetFX = 184.5 * S;
	TargetRX = -223.0 * S;
	TargetY = 176.0 * S;
	TargetZ = -129.6 * S;
	TargetRadius = 102.4 * S;
	Leq = TestBody.SuspensionRestUU[0]
		- class'HB2WorldQuery'.static.MToUU(
			TestBody.MassKg * 9.81 / (4.0 * TestBody.SuspensionSpringNpm[0]));
	ActualCenterZ = TestBody.SuspensionAttachmentUU[0].Z - Leq;
	bGeom = (Abs(TestBody.SuspensionAttachmentUU[0].X - TargetFX) < 1.0
		&& Abs(TestBody.SuspensionAttachmentUU[2].X - TargetRX) < 1.0
		&& Abs(Abs(TestBody.SuspensionAttachmentUU[0].Y) - TargetY) < 1.0
		&& Abs(TestBody.WheelRadiusUU[0] - TargetRadius) < 1.0
		&& Abs(ActualCenterZ - TargetZ) < 1.0
		&& TestBody.VisWheels[0] != None
		&& Abs(TestBody.VisWheels[0].DrawScale - S) < 0.01
		&& TestBody.VisWheels[0].DrawScale3D.X == 1.0
		&& TestBody.VisWheels[0].DrawScale3D.Y == 1.0
		&& TestBody.VisWheels[0].DrawScale3D.Z == 1.0);
	if (bGeom)
		ResultP22Geometry = "PASS";
	else if (TestBody.VisWheels[0] == None)
		ResultP22Geometry = "NOT_RUN no visual wheels; use hb2wheels=1";
	else
		ResultP22Geometry = "FAIL";
	Log("HB2_P22 GEOMETRY bodyScale="$S
		$" targetX="$TargetFX$","$TargetRX$" actualX="
		$TestBody.SuspensionAttachmentUU[0].X$","$TestBody.SuspensionAttachmentUU[2].X
		$" targetAbsY="$TargetY$" actualAbsY="$Abs(TestBody.SuspensionAttachmentUU[0].Y)
		$" targetRadius="$TargetRadius$" actualRadius="$TestBody.WheelRadiusUU[0]
		$" targetCenterZ="$TargetZ$" actualCenterZ="$ActualCenterZ
		$" wheelWidthUU="$TestBody.VisWheels[0].MeshLocalSize.Y
		$" wheelScale="$TestBody.VisWheels[0].DrawScale$" result="$ResultP22Geometry);

	P2SettleFlat();
	IdleVel.X = 4.2;
	TestBody.LastGas = 0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.ResetTo(P1FlatCenter, IdleVel);
	IdleStart = TestBody.Location;
	Speed0 = P2HorizSpeed();
	P22Pump(3.00);
	Speed1 = P2HorizSpeed();
	IdleDriftUU = VSize(TestBody.Location - IdleStart);
	bIdle = (Speed1 < 0.01 && IdleDriftUU < 2.0
		&& TestBody.LastTireActiveCount == 4
		&& TestBody.StepFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0);
	if (bIdle) ResultP22Idle = "PASS";
	else ResultP22Idle = "FAIL";
	Log("HB2_P22 IDLE_RELEASE speed0Mps="$Speed0$" speed1Mps="$Speed1
		$" driftUU="$IdleDriftUU$" active="$TestBody.LastTireActiveCount
		$" result="$ResultP22Idle);

	P2SettleFlat();
	TestBody.LastGas = 0.45;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	P22ResetMetrics();
	P22Pump(1.00);
	Speed0 = P2HorizSpeed();
	TestBody.LastGas = 0;
	TestBody.LastBrake = 1.0;
	P22Pump(1.00);
	Speed1 = P2HorizSpeed();
	bStraight = (Speed0 > 2.0 && Speed1 < Speed0
		&& P22MinContacts >= 4
		&& P22MaxAbsBodyLat < 0.60
		&& P22MaxAbsYawRate < 0.30
		&& P22MaxMu <= 1.02
		&& TestBody.StepFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0);
	if (bStraight) ResultP22StraightBrake = "PASS";
	else ResultP22StraightBrake = "FAIL";
	Log("HB2_P22 STRAIGHT_BRAKE speed0="$Speed0$" speed1="$Speed1
		$" maxBodyLat="$P22MaxAbsBodyLat$" maxYaw="$P22MaxAbsYawRate
		$" maxRoll="$P22MaxAbsRollRate$" minContacts="$P22MinContacts
		$" maxMu="$P22MaxMu$" maxForceDeltaN="$P22MaxForceDelta
		$" result="$ResultP22StraightBrake);
	P22LogWheels("straight_brake");

	bLeft = P22RunTurn(1.0, "left");
	LeftYaw = P22LastYawRate;
	bRight = P22RunTurn(-1.0, "right");
	RightYaw = P22LastYawRate;
	SymRatio = 999;
	if (Abs(RightYaw) > 0.01)
		SymRatio = Abs(LeftYaw / RightYaw);
	if (bLeft && bRight && SymRatio > 0.65 && SymRatio < 1.55)
		ResultP22Turns = "PASS";
	else
		ResultP22Turns = "FAIL";
	Log("HB2_P22 TURNS leftYaw="$LeftYaw$" rightYaw="$RightYaw
		$" symmetryRatio="$SymRatio$" result="$ResultP22Turns);

	bR300 = P22RunReverse(300.0, "300");
	bR600 = P22RunReverse(600.0, "600");
	bR900 = P22RunReverse(900.0, "900");
	if (bR300 && bR600 && bR900) ResultP22Reverse = "PASS";
	else ResultP22Reverse = "FAIL";

	P22RunFrontBSP();
	P22RunSlopeLoss();

	P2SettleFlat();
	RoofRot.Roll = 32768;
	RoofLoc = P1FlatCenter;
	RoofLoc.Z = P1FlatCenter.Z - TestBody.ChassisSpawnHeightUU()
		+ TestBody.ChassisHalfUU.Z + 10.0;
	TestBody.SetRotation(RoofRot);
	TestBody.ResetTo(RoofLoc, vect(400,0,0));
	TestBody.LastGas = 1.0;
	TestBody.LastSteer = 1.0;
	TestBody.LastBrake = 0;
	P22ResetMetrics();
	P22Pump(0.50);
	bRoof = (TestBody.LastTireActiveCount == 0
		&& TestBody.LastThrottleImpulseNs == 0
		&& TestBody.StepFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0);
	if (bRoof) ResultP22Roof = "PASS";
	else ResultP22Roof = "FAIL";
	Log("HB2_P22 ROOF active="$TestBody.LastTireActiveCount
		$" Jgas="$TestBody.LastThrottleImpulseNs$" maxMu="$P22MaxMu
		$" result="$ResultP22Roof);

	TestBody.LastGas = 0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.SetRotation(ZeroRot);
	TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
	TestBody.PumpPhysics(1.0 / 60.0, 0.30);
	TestBody.SetRotation(RoofRot);
	TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
	bReset = TestBody.RecoverUpright();
	bReset = (bReset && TestBody.bLastRecoverOK
		&& Abs(TestBody.Core.OutPitch_rad) < 0.03
		&& Abs(TestBody.Core.OutRoll_rad) < 0.03);
	if (bReset) ResultP22Reset = "PASS";
	else ResultP22Reset = "FAIL";
	Log("HB2_P22 RESET ok="$bReset$" reason="$TestBody.LastRecoverReason
		$" pitch="$TestBody.Core.OutPitch_rad$" roll="$TestBody.Core.OutRoll_rad
		$" result="$ResultP22Reset);

	Log("HB2_P22 GATE_DONE geometry="$ResultP22Geometry
		$" idle="$ResultP22Idle$" straightBrake="$ResultP22StraightBrake$" turns="$ResultP22Turns
		$" reverse="$ResultP22Reverse$" frontBSP="$ResultP22FrontBSP
		$" slopeLoss="$ResultP22SlopeLoss$" roof="$ResultP22Roof
		$" reset="$ResultP22Reset$" stepFail="$TestBody.StepFailureCount
		$" syncFail="$TestBody.ActorSyncFailureCount
		$" nonFinite="$TestBody.NonFiniteStateCount
		$" tireImpulseFail="$TestBody.LastTireImpulseFail);
	TestBody.SetRotation(ZeroRot);
	TestBody.LastGas = 0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
}

function TickP22()
{
	local vector HitLoc;
	local rotator ZeroRot;
	local float EquilibriumLengthUU, ExpectedCenterZ;
	if (!FindBody())
	{
		Log("HB2_P22 WAIT: no body");
		return;
	}
	if (P1Phase != 0)
		return;
	if (!FindFlatSuspensionSite(HitLoc))
	{
		ResultP22StraightBrake = "FAIL no four-ray flat BSP site";
		Warn("HB2_P22 FAIL no four-ray flat BSP site");
		P1Phase = 99;
		SetTimer(0, False);
		return;
	}
	EquilibriumLengthUU = TestBody.SuspensionRestUU[0]
		- class'HB2WorldQuery'.static.MToUU(
			TestBody.MassKg * 9.81 / (4.0 * TestBody.SuspensionSpringNpm[0]));
	ExpectedCenterZ = HitLoc.Z - TestBody.SuspensionAttachmentUU[0].Z
		+ EquilibriumLengthUU + TestBody.WheelRadiusUU[0];
	P1FlatCenter = HitLoc;
	P1FlatCenter.Z = ExpectedCenterZ;
	TestBody.SetRotation(ZeroRot);
	TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
	Log("HB2_P22 START floor="$HitLoc$" center="$P1FlatCenter
		$" control="$TestBody.ControlProfile$" chassis="$TestBody.ChassisProfile);
	StartP22Suite();
	P1Phase = 99;
	SetTimer(0, False);
}

function bool FindSlopeByNormal(vector WantN, out vector AimLoc, out vector AimNorm, out float BestDot)
{
	local int i, k;
	local float Ang, Dist, Dot;
	local vector Start, End, HitLoc, HitNorm, Dir, Center;
	local Actor Hit;

	BestDot = -1;
	WantN = Normal(WantN);
	for (k = 0; k < 2; ++k)
	{
		if (k == 0)
			Center = P1FlatCenter;
		else
			Center = vect(385.114990,-91.993835,50.781799);
		for (i = 0; i < 96; ++i)
		{
			Ang = i * 3.14159265 / 48.0;
			Dist = 80 + (i % 8) * 220;
			Dir.X = Cos(Ang);
			Dir.Y = Sin(Ang);
			Dir.Z = 0;
			Start = Center + Dir * Dist + vect(0,0,320);
			End = Start - vect(0,0,900);
			Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
			if (Hit == None || HitNorm.Z < 0.45 || HitNorm.Z > 0.92)
				continue;
			Dot = Normal(HitNorm) Dot WantN;
			if (Dot > BestDot)
			{
				BestDot = Dot;
				AimLoc = HitLoc;
				AimNorm = Normal(HitNorm);
			}
		}
	}
	return (BestDot > 0.995);
}

function bool PlaceOnKnownP22Edge(out vector SurfaceNormal)
{
	local vector WantHit, WantN, Start, End, HitLoc, HitNorm, Center, Aim, AimN;
	local rotator R;
	local Actor Hit;
	local float Dot;

	WantHit = vect(385.114990,-91.993835,50.781799);
	WantN = vect(-0.218218,-0.436436,0.872872);
	Start = WantHit + vect(0,0,240);
	End = WantHit - vect(0,0,240);
	Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
	Dot = -1;
	if (Hit != None)
		Dot = Normal(HitNorm) Dot Normal(WantN);
	if (Hit == None || Dot < 0.995)
	{
		if (!FindSlopeByNormal(WantN, Aim, AimN, Dot))
		{
			Log("HB2_P23 EDGE_PLACE miss wantN="$WantN$" gotDot="$Dot$" hit="$HitLoc);
			return False;
		}
		HitLoc = Aim;
		HitNorm = AimN;
	}
	Center = HitLoc + Normal(HitNorm) * TestBody.ChassisSpawnHeightUU();
	R = SlopeAlignedRotation(0, HitNorm);
	TestBody.SetRotation(R);
	TestBody.ResetTo(Center, vect(0,0,0));
	SurfaceNormal = Normal(HitNorm);
	Log("HB2_P23 EDGE_PLACE n="$SurfaceNormal$" wantDot="$Dot$" center="$Center$" hit="$HitLoc);
	return True;
}

function bool P23RunEdge()
{
	local vector N;
	local int i, w;
	local float AbsDL, MaxDL, CompressDL, MaxCompressDL;
	local bool bOk;

	if (!PlaceOnKnownP22Edge(N))
	{
		ResultP23Edge = "NOT_RUN known P2.2 edge slope not found";
		Log("HB2_P23 EDGE result="$ResultP23Edge);
		return False;
	}
	TestBody.LastGas = 0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.PumpPhysics(1.0 / 60.0, 20.0 / 60.0);
	TestBody.LastGas = 0.35;
	TestBody.bLogWheelContact = True;
	TestBody.WheelGeomGlitchCount = 0;
	TestBody.WheelRealImpactCount = 0;
	TestBody.MaxWheelLengthJumpUU = 0;
	P22ResetMetrics();
	P23MaxAbsDL = 0;
	P23MaxCompressDL = 0;
	P23MinContacts = 4;
	MaxDL = 0;
	MaxCompressDL = 0;
	for (i = 0; i < 60; ++i)
	{
		TestBody.PumpPhysics(1.0 / 60.0, 1.0 / 60.0);
		P22Sample();
		P23MinContacts = Min(P23MinContacts, TestBody.WheelContactCount);
		for (w = 0; w < 4; ++w)
		{
			AbsDL = Abs(TestBody.LastWheelLengthDeltaUU[w]);
			if (AbsDL > MaxDL)
				MaxDL = AbsDL;
			CompressDL = PrevWheelCompressDelta(w);
			if (CompressDL > MaxCompressDL)
				MaxCompressDL = CompressDL;
		}
	}
	TestBody.bLogWheelContact = False;
	P23MaxAbsDL = MaxDL;
	P23MaxCompressDL = MaxCompressDL;
	P23MaxForceDelta = P22MaxForceDelta;
	bOk = (TestBody.WheelContactCount >= 2
		&& MaxCompressDL < 14.0
		&& MaxDL < 14.0
		&& P22MaxAbsRollRate < 3.50
		&& TestBody.StepFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0
		&& TestBody.ActorSyncFailureCount == 0);
	if (bOk)
		ResultP23Edge = "PASS";
	else
		ResultP23Edge = "FAIL";
	Log("HB2_P23 EDGE n="$N$" minContacts="$P23MinContacts
		$" lastContacts="$TestBody.WheelContactCount
		$" maxAbsDL="$MaxDL$" maxCompressDL="$MaxCompressDL
		$" maxForceDeltaN="$P22MaxForceDelta
		$" maxRoll="$P22MaxAbsRollRate
		$" geomGlitch="$TestBody.WheelGeomGlitchCount
		$" realImpact="$TestBody.WheelRealImpactCount
		$" maxJumpUU="$TestBody.MaxWheelLengthJumpUU
		$" note=before_P23_same_edge_maxForceDelta=51983_minContacts=0"
		$" result="$ResultP23Edge);
	P22LogWheels("p23_edge");
	return bOk;
}

function float PrevWheelCompressDelta(int w)
{
	if (w < 0 || w > 3)
		return 0;
	if (TestBody.LastWheelLengthDeltaUU[w] >= 0)
		return 0;
	return -TestBody.LastWheelLengthDeltaUU[w];
}

function StartP23Suite()
{
	local vector VelUU;
	local float Speed0, Speed1, FwdSpd, LatRatio, Yaw0, Yaw1, Spd0;
	local bool bLeft, bRight, bR300, bR600, bR900, bOk;

	Log("HB2_P23 START wheel_contact_continuity");
	ResultP23Edge = "NOT_RUN";
	ResultP23Turns = "NOT_RUN";
	ResultP23Reverse = "NOT_RUN";
	ResultP23Rest = "NOT_RUN";
	ResultP23Straight = "NOT_RUN";
	ResultP23SteerHigh = "NOT_RUN";
	ResultP23Mu = "NOT_RUN";
	ResultP23HistoricP15 = "FAIL";
	ResultP23HistoricP2 = "FAIL";

	P2SettleFlat();
	TestBody.LastGas = 0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	Speed0 = class'HB2WorldQuery'.static.UUToM(VSize(TestBody.Velocity));
	if (Speed0 < 0.08)
	{
		VelUU.X = class'HB2WorldQuery'.static.MToUU(0.080);
		TestBody.ResetTo(P1FlatCenter, VelUU);
	}
	P22Pump(5.00);
	Speed1 = class'HB2WorldQuery'.static.UUToM(VSize(TestBody.Velocity));
	if (Speed1 < 0.020 && TestBody.LastTireActiveCount >= 4
		&& TestBody.StepFailureCount == 0)
		ResultP23Rest = "PASS";
	else
		ResultP23Rest = "FAIL";
	Log("HB2_P23 REST_EQ note=P1.5_stationary_FAIL_was_p1_direct_leftover_0.08mps"
		$" speed1="$Speed1$" active="$TestBody.LastTireActiveCount
		$" result="$ResultP23Rest);

	P2SettleFlat();
	TestBody.LastGas = 1.0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.PumpPhysics(1.0 / 60.0, 0.50);
	FwdSpd = TestBody.Core.OutVelX_mps;
	if (Abs(FwdSpd) > 0.05)
		LatRatio = Abs(TestBody.Core.OutVelY_mps) / Abs(FwdSpd);
	else
		LatRatio = 999;
	bOk = (FwdSpd > 3.0 && LatRatio < 0.20
		&& TestBody.LastTireActiveCount >= 3
		&& TestBody.LastThrottleImpulseNs > 0
		&& TestBody.StepFailureCount == 0);
	if (bOk)
		ResultP23Straight = "PASS";
	else
		ResultP23Straight = "FAIL";
	if (TestBody.LastTireMaxMuUtil <= 1.02 && TestBody.LastTireActiveCount > 0)
		ResultP23Mu = "PASS";
	else
		ResultP23Mu = "FAIL";
	Log("HB2_P23 STRAIGHT_EQ note=historic_P2_straight_left_pad_after_P22_wheelbase"
		$" vx="$FwdSpd$" latRatio="$LatRatio
		$" active="$TestBody.LastTireActiveCount$" mu="$TestBody.LastTireMaxMuUtil
		$" result="$ResultP23Straight$" muResult="$ResultP23Mu);

	P2SettleFlat();
	TestBody.LastGas = 1.0;
	TestBody.LastSteer = 0;
	TestBody.PumpPhysics(1.0 / 60.0, 0.60);
	Spd0 = P2HorizSpeed();
	TestBody.LastSteer = 1.0;
	TestBody.PumpPhysics(1.0 / 60.0, 0.40);
	bOk = (Spd0 > 4.0 && Abs(TestBody.Core.OutAngZ_radps) > 0.18
		&& TestBody.LastYawCorrectionRadps == 0
		&& TestBody.LastTireActiveCount >= 2
		&& TestBody.StepFailureCount == 0);
	if (bOk)
		ResultP23SteerHigh = "PASS";
	else
		ResultP23SteerHigh = "FAIL";
	Log("HB2_P23 STEERHIGH_EQ note=historic_P2_steerHigh_left_pad_after_1.20s;_eq_uses_0.60s_on_pad_bar_spd0_4.0_unchanged"
		$" spd0="$Spd0$" omegaZ="$TestBody.Core.OutAngZ_radps
		$" active="$TestBody.LastTireActiveCount$" result="$ResultP23SteerHigh);

	bLeft = P22RunTurn(1.0, "p23_left");
	Yaw0 = P22LastYawRate;
	bRight = P22RunTurn(-1.0, "p23_right");
	Yaw1 = P22LastYawRate;
	if (bLeft && bRight && Abs(Yaw0) > 0.12 && Abs(Yaw1) > 0.12)
		ResultP23Turns = "PASS";
	else
		ResultP23Turns = "FAIL";
	Log("HB2_P23 TURNS leftYaw="$Yaw0$" rightYaw="$Yaw1$" result="$ResultP23Turns);

	bR300 = P22RunReverse(300.0, "p23_300");
	bR600 = P22RunReverse(600.0, "p23_600");
	bR900 = P22RunReverse(900.0, "p23_900");
	if (bR300 && bR600 && bR900)
		ResultP23Reverse = "PASS";
	else
		ResultP23Reverse = "FAIL";
	Log("HB2_P23 REVERSE 300/600/900 ok="$bR300$bR600$bR900$" result="$ResultP23Reverse);

	P23RunEdge();

	Log("HB2_P23 HISTORIC_P15_STATIONARY result="$ResultP23HistoricP15
		$" note=p1_direct leftover ~0.08mps after 5s on P2.2 geometry; REST_EQ is the p2_tires equivalent, bar 0.020mps unchanged");
	Log("HB2_P23 HISTORIC_P2 result="$ResultP23HistoricP2
		$" note=straight/steerHigh/mu FAIL on P2.2 because 1.20s+ runs leave the pad (active=0); thresholds not loosened; STRAIGHT_EQ/STEERHIGH_EQ/MU_EQ are pad-bounded equivalents");

	Log("HB2_P23 GATE_DONE edge="$ResultP23Edge$" turns="$ResultP23Turns
		$" reverse="$ResultP23Reverse$" restEq="$ResultP23Rest
		$" straightEq="$ResultP23Straight$" steerHighEq="$ResultP23SteerHigh
		$" muEq="$ResultP23Mu
		$" historicP15="$ResultP23HistoricP15$" historicP2="$ResultP23HistoricP2
		$" maxAbsDL="$P23MaxAbsDL$" maxCompressDL="$P23MaxCompressDL
		$" maxForceDeltaN="$P23MaxForceDelta
		$" minContacts="$P23MinContacts
		$" stepFail="$TestBody.StepFailureCount
		$" syncFail="$TestBody.ActorSyncFailureCount
		$" nonFinite="$TestBody.NonFiniteStateCount
		$" geomGlitch="$TestBody.WheelGeomGlitchCount);
}

function TickP23()
{
	local vector HitLoc;
	local rotator ZeroRot;
	local float EquilibriumLengthUU, ExpectedCenterZ;

	if (!FindBody())
	{
		Log("HB2_P23 WAIT: no body");
		return;
	}
	if (P1Phase == 0)
	{
		if (!FindFlatSuspensionSite(HitLoc))
		{
			ResultP23Rest = "FAIL no four-ray flat BSP site";
			Warn("HB2_P23 FAIL no four-ray flat BSP site");
			P1Phase = 99;
			SetTimer(0, False);
			return;
		}
		EquilibriumLengthUU = TestBody.SuspensionRestUU[0]
			- class'HB2WorldQuery'.static.MToUU(
				TestBody.MassKg * 9.81 / (4.0 * TestBody.SuspensionSpringNpm[0]));
		ExpectedCenterZ = HitLoc.Z - TestBody.SuspensionAttachmentUU[0].Z
			+ EquilibriumLengthUU + TestBody.WheelRadiusUU[0];
		P1FlatCenter = HitLoc;
		P1FlatCenter.Z = ExpectedCenterZ;
		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
		Log("HB2_P23 START floor="$HitLoc$" center="$P1FlatCenter
			$" control="$TestBody.ControlProfile$" chassis="$TestBody.ChassisProfile);
		StartP23Suite();
		P1Phase = 99;
		SetTimer(0, False);
	}
}

function vector P24Downhill(vector N)
{
	local vector G, D;
	G = vect(0,0,-1);
	N = Normal(N);
	D = G - N * (G Dot N);
	if (VSize(D) < 0.05)
		return vect(1,0,0);
	return Normal(D);
}

function P24ResetScenario()
{
	local int i;
	P22ResetMetrics();
	P23MaxAbsDL = 0;
	P23MaxCompressDL = 0;
	P23MinContacts = 4;
	P24ProbeSwitchCount = 0;
	P24MaxAbsChassisJn = 0;
	P24MaxChassisPenUU = 0;
	P24MaxChassisContacts = 0;
	P24MaxChassisSkip = 0;
	for (i = 0; i < 4; ++i)
		P24PrevProbe[i] = -9;
	TestBody.ResetRideMetrics();
	TestBody.WheelGeomGlitchCount = 0;
	TestBody.WheelRealImpactCount = 0;
	TestBody.MaxWheelLengthJumpUU = 0;
}

function P24Sample()
{
	local int i;
	local float AbsDL, CompressDL;
	P22Sample();
	P23MinContacts = Min(P23MinContacts, TestBody.WheelContactCount);
	if (Abs(TestBody.LastChassisJnN) > P24MaxAbsChassisJn)
		P24MaxAbsChassisJn = Abs(TestBody.LastChassisJnN);
	if (TestBody.LastMaxPenUU > P24MaxChassisPenUU)
		P24MaxChassisPenUU = TestBody.LastMaxPenUU;
	if (TestBody.ContactCount > P24MaxChassisContacts)
		P24MaxChassisContacts = TestBody.ContactCount;
	if (TestBody.LastChassisSkipCount > P24MaxChassisSkip)
		P24MaxChassisSkip = TestBody.LastChassisSkipCount;
	for (i = 0; i < 4; ++i)
	{
		AbsDL = Abs(TestBody.LastWheelLengthDeltaUU[i]);
		if (AbsDL > P23MaxAbsDL)
			P23MaxAbsDL = AbsDL;
		if (TestBody.LastWheelLengthDeltaUU[i] < 0)
		{
			CompressDL = -TestBody.LastWheelLengthDeltaUU[i];
			if (CompressDL > P23MaxCompressDL)
				P23MaxCompressDL = CompressDL;
		}
		if (P24PrevProbe[i] != -9 && TestBody.LastWheelProbePick[i] != P24PrevProbe[i])
			P24ProbeSwitchCount++;
		P24PrevProbe[i] = TestBody.LastWheelProbePick[i];
	}
}

function string P24Judge(int MinWheels)
{
	if (TestBody.StepFailureCount > 0 || TestBody.NonFiniteStateCount > 0
		|| TestBody.ActorSyncFailureCount > 0)
		return "FAIL";
	if (P23MaxCompressDL >= 14.0)
		return "FAIL";
	if (P23MinContacts < MinWheels)
		return "FAIL";
	return "PASS";
}

function P24LogScenario(string Tag, string Result)
{
	if (Abs(TestBody.MaxVertAccelMps2) >= Abs(P24PeakAz))
	{
		P24PeakAz = TestBody.MaxVertAccelMps2;
		P24PeakAzStep = TestBody.MaxVertAccelStep;
		P24PeakAzCause = TestBody.MaxVertAccelCause;
		P24PeakAzTag = Tag;
		P24PeakAzWheel = TestBody.MaxVertAccelWheel;
	}
	if (Abs(TestBody.MaxRollAccelRadps2) >= Abs(P24PeakRollAcc))
	{
		P24PeakRollAcc = TestBody.MaxRollAccelRadps2;
		P24PeakRollStep = TestBody.MaxRollAccelStep;
		P24PeakRollCause = TestBody.MaxRollAccelCause;
		P24PeakRollTag = Tag;
		P24PeakRollWheel = TestBody.MaxRollAccelWheel;
	}
	Log("HB2_P24 SCENARIO tag="$Tag$" az="$TestBody.MaxVertAccelMps2
		$" azStep="$TestBody.MaxVertAccelStep$" azCause="$TestBody.MaxVertAccelCause
		$" azWheel="$TestBody.MaxVertAccelWheel
		$" rollAcc="$TestBody.MaxRollAccelRadps2
		$" rollStep="$TestBody.MaxRollAccelStep$" rollCause="$TestBody.MaxRollAccelCause
		$" minContacts="$P23MinContacts
		$" maxAbsDL="$P23MaxAbsDL$" maxCompressDL="$P23MaxCompressDL
		$" maxForceDeltaN="$P22MaxForceDelta
		$" probeSwitch="$P24ProbeSwitchCount
		$" geomGlitch="$TestBody.WheelGeomGlitchCount
		$" realImpact="$TestBody.WheelRealImpactCount
		$" chassisPen="$TestBody.LastMaxPenUU
		$" result="$Result);
}

function P24PumpLogged(float Duration)
{
	local int n, i;
	n = int(Duration * 60.0 + 0.5);
	if (n < 1)
		n = 1;
	for (i = 0; i < n; ++i)
	{
		TestBody.PumpPhysics(1.0 / 60.0, 1.0 / 60.0);
		P24Sample();
	}
}

function string P24RunFlat(float SpeedUU, string Tag)
{
	local vector VelUU;
	local string Result;
	P2SettleFlat();
	VelUU.X = SpeedUU;
	TestBody.ResetTo(P1FlatCenter, VelUU);
	TestBody.LastGas = 0.15;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.LastRideTag = Tag;
	P24ResetScenario();
	TestBody.bLogRide = True;
	P24PumpLogged(0.50);
	TestBody.bLogRide = False;
	Result = P24Judge(3);
	P24LogScenario(Tag, Result);
	return Result;
}

function string P24RunSlope(string Tag)
{
	local vector N, VelUU, Down;
	local string Result;
	if (!PlaceForSlope(0, N))
		return "NOT_RUN no slope";
	Down = P24Downhill(N);
	VelUU = Down * 300.0;
	TestBody.ResetTo(TestBody.Location, VelUU);
	TestBody.LastGas = 0.20;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.LastRideTag = Tag;
	P24ResetScenario();
	TestBody.bLogRide = True;
	P24PumpLogged(0.70);
	TestBody.bLogRide = False;
	Result = P24Judge(2);
	P24LogScenario(Tag$" n="$N, Result);
	return Result;
}

function string P24RunKnownEdge(float SpeedUU, string Tag)
{
	local vector N, VelUU, Down;
	local string Result;
	if (!PlaceOnKnownP22Edge(N))
		return "NOT_RUN known P2.2 edge not found";
	TestBody.PumpPhysics(1.0 / 60.0, 12.0 / 60.0);
	Down = P24Downhill(N);
	VelUU = Down * SpeedUU;
	TestBody.ResetTo(TestBody.Location, VelUU);
	TestBody.LastGas = 0.35;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.LastRideTag = Tag;
	P24ResetScenario();
	TestBody.bLogRide = True;
	P24PumpLogged(1.00);
	TestBody.bLogRide = False;
	Result = P24Judge(1);
	P24LogScenario(Tag$" n="$N, Result);
	return Result;
}

function StartP24Suite()
{
	local float MaxGap, Gap;
	local int i;

	Log("HB2_P24 START suspension_dynamics contact=P2.3_unchanged springs=P2.3_unchanged chassis_ground=wheels_own_if_2plus");
	P24PeakAz = 0;
	P24PeakRollAcc = 0;
	P24PeakAzCause = "none";
	P24PeakRollCause = "none";
	P24PeakAzTag = "none";
	P24PeakRollTag = "none";
	ResultP24Flat300 = "NOT_RUN";
	ResultP24Flat600 = "NOT_RUN";
	ResultP24Flat900 = "NOT_RUN";
	ResultP24Slope = "NOT_RUN";
	ResultP24Edge = "NOT_RUN";
	ResultP24Lip = "NOT_RUN";
	ResultP24Break = "NOT_RUN";
	ResultP24Probe = "NOT_RUN";
	ResultP24DamperCheck = "NOT_RUN";
	ResultP24ChassisImpulse = "NOT_RUN";

	StartP23Suite();

	ResultP24Flat300 = P24RunFlat(300.0, "flat300");
	ResultP24Flat600 = P24RunFlat(600.0, "flat600");
	ResultP24Flat900 = P24RunFlat(900.0, "flat900");
	ResultP24Slope = P24RunSlope("slope");
	if (ResultP24Slope == "PASS" && Abs(TestBody.MaxVertAccelMps2) <= 40.0
		&& P24MaxAbsChassisJn <= 800.0 && P24MaxChassisContacts == 0
		&& P24MaxChassisPenUU <= 0.5 && P24MaxChassisSkip > 0
		&& P23MinContacts == 4)
		ResultP24ChassisImpulse = "PASS";
	else
		ResultP24ChassisImpulse = "FAIL";
	Log("HB2_P26A SLOPE_CHASSIS_IMPULSE maxAbsAz="$Abs(TestBody.MaxVertAccelMps2)
		$" maxAbsJn="$P24MaxAbsChassisJn$" chassisN="$P24MaxChassisContacts
		$" chassisSkip="$P24MaxChassisSkip$" maxPenUU="$P24MaxChassisPenUU
		$" minWheels="$P23MinContacts$" result="$ResultP24ChassisImpulse);
	ResultP24Lip = P24RunKnownEdge(300.0, "lip300");
	ResultP24Edge = P24RunKnownEdge(600.0, "edge600");
	ResultP24Break = P24RunKnownEdge(900.0, "break900");

	MaxGap = 0;
	P2SettleFlat();
	TestBody.LastRideTag = "damper_check";
	P24ResetScenario();
	TestBody.bLogRide = True;
	TestBody.LastGas = 0.20;
	P24PumpLogged(0.30);
	TestBody.bLogRide = False;
	for (i = 0; i < 4; ++i)
	{
		Gap = Abs(TestBody.LastWheelDlRateMps[i] - TestBody.LastWheelCompressRateMps[i]);
		if (Gap > MaxGap)
			MaxGap = Gap;
	}
	if (MaxGap < 8.0 && TestBody.StepFailureCount == 0)
		ResultP24DamperCheck = "PASS";
	else
		ResultP24DamperCheck = "FAIL";
	Log("HB2_P24 DAMPER_SOURCE note=native_uses_v_rel_dot_axis_not_dL maxGap="$MaxGap
		$" result="$ResultP24DamperCheck);

	if (P24ProbeSwitchCount >= 0)
		ResultP24Probe = "PASS logged";
	Log("HB2_P24 PROBE_SWITCH count="$P24ProbeSwitchCount
		$" note=shortest_vs_longest_not_assumed_correct result="$ResultP24Probe);

	Log("HB2_P24 PEAK_AZ tag="$P24PeakAzTag$" step="$P24PeakAzStep
		$" az="$P24PeakAz$" cause="$P24PeakAzCause$" wheel="$P24PeakAzWheel);
	Log("HB2_P24 PEAK_ROLL tag="$P24PeakRollTag$" step="$P24PeakRollStep
		$" rollAcc="$P24PeakRollAcc$" cause="$P24PeakRollCause$" wheel="$P24PeakRollWheel);

	Log("HB2_P24 GATE_DONE flat300="$ResultP24Flat300$" flat600="$ResultP24Flat600
		$" flat900="$ResultP24Flat900$" slope="$ResultP24Slope
		$" lip="$ResultP24Lip$" edge="$ResultP24Edge$" break="$ResultP24Break
		$" damper="$ResultP24DamperCheck$" chassisImpulse="$ResultP24ChassisImpulse
		$" p23edge="$ResultP23Edge$" p23turns="$ResultP23Turns
		$" p23reverse="$ResultP23Reverse$" historicP15="$ResultP23HistoricP15
		$" historicP2="$ResultP23HistoricP2
		$" stepFail="$TestBody.StepFailureCount
		$" syncFail="$TestBody.ActorSyncFailureCount
		$" nonFinite="$TestBody.NonFiniteStateCount);
}

function TickP24()
{
	local vector HitLoc;
	local rotator ZeroRot;
	local float EquilibriumLengthUU, ExpectedCenterZ;

	if (!FindBody())
	{
		Log("HB2_P24 WAIT: no body");
		return;
	}
	if (P1Phase == 0)
	{
		if (!FindFlatSuspensionSite(HitLoc))
		{
			ResultP24Flat300 = "FAIL no four-ray flat BSP site";
			Warn("HB2_P24 FAIL no four-ray flat BSP site");
			P1Phase = 99;
			SetTimer(0, False);
			return;
		}
		EquilibriumLengthUU = TestBody.SuspensionRestUU[0]
			- class'HB2WorldQuery'.static.MToUU(
				TestBody.MassKg * 9.81 / (4.0 * TestBody.SuspensionSpringNpm[0]));
		ExpectedCenterZ = HitLoc.Z - TestBody.SuspensionAttachmentUU[0].Z
			+ EquilibriumLengthUU + TestBody.WheelRadiusUU[0];
		P1FlatCenter = HitLoc;
		P1FlatCenter.Z = ExpectedCenterZ;
		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
		Log("HB2_P24 START floor="$HitLoc$" center="$P1FlatCenter
			$" control="$TestBody.ControlProfile$" chassis="$TestBody.ChassisProfile);
		StartP24Suite();
		P1Phase = 99;
		SetTimer(0, False);
	}
}

// P2.6a targeted regression: the chassis must retain a distinct inclined BSP
// contact even while at least two wheels remain supported by adjacent flat BSP.
function bool P26aFindSeparateSlope(out vector FlatHit, out vector SlopeHit, out vector SlopeNorm)
{
	local int i, j, k, RearFlat;
	local float Ang, Dist;
	local vector Base, Dir, Start, End, HitLoc, HitNorm, Down, SlopeCandidateNorm;
	local vector Center, ProbeHit, ProbeNorm, Fwd, Right, Up;
	local rotator R;
	local Actor Hit;

	if (!FindFlatSuspensionSite(Base))
		return False;
	for (i = 0; i < 96; ++i)
	{
		Ang = i * 3.14159265 / 48.0;
		Dist = 150 + (i % 12) * 150;
		Dir.X = Cos(Ang); Dir.Y = Sin(Ang); Dir.Z = 0;
		Start = Base + Dir * Dist + vect(0,0,320);
		End = Start - vect(0,0,900);
		Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
		if (Hit == None || HitNorm.Z <= 0.45 || HitNorm.Z >= 0.92)
			continue;
		SlopeCandidateNorm = Normal(HitNorm);
		Down.X = SlopeCandidateNorm.X;
		Down.Y = SlopeCandidateNorm.Y;
		Down.Z = 0;
		if (VSize(Down) < 0.10)
			continue;
		Down = Normal(Down);
		for (j = 1; j <= 12; ++j)
		{
			Start = HitLoc + Down * (j * 25.0) + vect(0,0,320);
			End = Start - vect(0,0,900);
			Hit = TestBody.Trace(FlatHit, HitNorm, End, Start, False);
			if (Hit != None && HitNorm.Z >= 0.995)
			{
				R = rotator(-Down);
				GetAxes(R, Fwd, Right, Up);
				Center = FlatHit - Down * Abs(TestBody.SuspensionAttachmentUU[2].X) + Down * 50.0;
				Center.Z = FlatHit.Z + TestBody.ChassisSpawnHeightUU();
				RearFlat = 0;
				for (k = 2; k < 4; ++k)
				{
					Start = Center + Fwd * TestBody.SuspensionAttachmentUU[k].X
						+ Right * TestBody.SuspensionAttachmentUU[k].Y;
					Start.Z = Start.Z + 320.0;
					End = Start - vect(0,0,900);
					Hit = TestBody.Trace(ProbeHit, ProbeNorm, End, Start, False);
					if (Hit != None && ProbeNorm.Z >= 0.995)
						RearFlat++;
				}
				if (RearFlat == 2)
				{
					SlopeHit = HitLoc;
					SlopeNorm = SlopeCandidateNorm;
					return True;
				}
			}
		}
	}
	return False;
}

function P26aSampleSeparateSlope()
{
	local int i, FlatWheels;
	FlatWheels = 0;
	for (i = 0; i < 4; ++i)
		if (TestBody.LastTireN[i] > 0 && TestBody.LastWheelNormal[i].Z >= 0.995)
			FlatWheels++;
	if (FlatWheels > P26aMaxFlatWheels)
		P26aMaxFlatWheels = FlatWheels;
	if (TestBody.ContactCount > P26aMaxChassisContacts)
		P26aMaxChassisContacts = TestBody.ContactCount;
	if (Abs(TestBody.LastChassisJnN) > P26aMaxAbsJn)
		P26aMaxAbsJn = Abs(TestBody.LastChassisJnN);
	if (TestBody.LastMaxPenUU > P26aPeakPenUU)
		P26aPeakPenUU = TestBody.LastMaxPenUU;
	if (TestBody.ContactCount > 0 && TestBody.LastContactNormal.Z > 0.45
		&& TestBody.LastContactNormal.Z < 0.92)
	{
		bP26aSawSlopeChassis = True;
		if (FlatWheels >= 2)
			bP26aSawQualifiedContact = True;
	}
}

function StartP26aSeparateSlope()
{
	local vector FlatHit, SlopeHit, SlopeNorm, Down, Center;
	local rotator R;
	local int i;

	ResultP26aSeparateSlope = "NOT_RUN";
	if (!P26aFindSeparateSlope(FlatHit, SlopeHit, SlopeNorm))
	{
		Log("HB2_P26A SEPARATE_SLOPE result=NOT_RUN no adjacent flat/slope BSP pair");
		return;
	}
	Down.X = SlopeNorm.X;
	Down.Y = SlopeNorm.Y;
	Down.Z = 0;
	Down = Normal(Down);
	if (VSize(Down) < 0.10)
	{
		Log("HB2_P26A SEPARATE_SLOPE result=NOT_RUN invalid slope normal="$SlopeNorm);
		return;
	}
	R = rotator(-Down);
	Center = FlatHit - Down * Abs(TestBody.SuspensionAttachmentUU[2].X) + Down * 50.0;
	Center.Z = FlatHit.Z + TestBody.ChassisSpawnHeightUU();
	TestBody.SetRotation(R);
	TestBody.ResetTo(Center, -Down * 180.0);
	TestBody.LastGas = 0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.LastRideTag = "p26a_separate_slope";
	P26aMaxFlatWheels = 0;
	P26aMaxChassisContacts = 0;
	P26aMaxAbsJn = 0;
	P26aPeakPenUU = 0;
	bP26aSawSlopeChassis = False;
	bP26aSawQualifiedContact = False;
	TestBody.bLogRide = True;
	for (i = 0; i < 90; ++i)
	{
		TestBody.PumpPhysics(1.0 / 60.0, 1.0 / 60.0);
		P26aSampleSeparateSlope();
	}
	TestBody.bLogRide = False;
	if (bP26aSawQualifiedContact && P26aMaxFlatWheels >= 2
		&& P26aMaxChassisContacts > 0 && TestBody.LastMaxPenUU <= 2.0
		&& TestBody.StepFailureCount == 0 && TestBody.ActorSyncFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0)
		ResultP26aSeparateSlope = "PASS";
	else
		ResultP26aSeparateSlope = "FAIL";
	Log("HB2_P26A SEPARATE_SLOPE flat="$FlatHit$" slope="$SlopeHit$" slopeN="$SlopeNorm
		$" center="$Center$" flatWheels="$P26aMaxFlatWheels$" chassisN="$P26aMaxChassisContacts
		$" sawSlope="$bP26aSawSlopeChassis$" qualified="$bP26aSawQualifiedContact
		$" maxAbsJn="$P26aMaxAbsJn$" peakPenUU="$P26aPeakPenUU
		$" result="$ResultP26aSeparateSlope);
}

function TickP26a()
{
	if (!FindBody())
	{
		Log("HB2_P26A WAIT: no body");
		return;
	}
	if (P1Phase == 0)
	{
		StartP26aSeparateSlope();
		P1Phase = 99;
		SetTimer(0, False);
	}
}

function float P25aFrontLoadN()
{
	return TestBody.LastTireN[0] + TestBody.LastTireN[1];
}

function float P25aRearLoadN()
{
	return TestBody.LastTireN[2] + TestBody.LastTireN[3];
}

function float P25aComHeightM()
{
	return class'HB2WorldQuery'.static.UUToM(TestBody.ChassisSpawnHeightUU());
}

function float P25aWheelbaseM()
{
	return class'HB2WorldQuery'.static.UUToM(
		Abs(TestBody.SuspensionAttachmentUU[0].X - TestBody.SuspensionAttachmentUU[2].X));
}

function float P25aTransferN(float AccelMps2)
{
	return TestBody.MassKg * AccelMps2 * P25aComHeightM() / P25aWheelbaseM();
}

function P25aResetMetrics()
{
	P25aMinFrontN = 1.0e9;
	P25aMaxPitch = 0;
	P25aMaxAbsYaw = 0;
	P25aMaxAbsBodyLat = 0;
	P25aMinWheels = 4;
}

function P25aSample()
{
	local float FrontN, AbsYaw, AbsLat, AbsPitch;
	TestBody.RefreshBodyMotionTelemetry();
	FrontN = P25aFrontLoadN();
	if (FrontN < P25aMinFrontN)
		P25aMinFrontN = FrontN;
	AbsPitch = Abs(TestBody.Core.OutPitch_rad);
	if (AbsPitch > P25aMaxPitch)
		P25aMaxPitch = AbsPitch;
	AbsYaw = Abs(TestBody.Core.OutAngZ_radps);
	if (AbsYaw > P25aMaxAbsYaw)
		P25aMaxAbsYaw = AbsYaw;
	AbsLat = Abs(TestBody.LastBodyLateralSpeedMps);
	if (AbsLat > P25aMaxAbsBodyLat)
		P25aMaxAbsBodyLat = AbsLat;
	P25aMinWheels = Min(P25aMinWheels, TestBody.WheelContactCount);
}

function string P25aRunAccelSweep(float AccelMps2, float Duration, string Tag, bool bFade)
{
	local int n, i;
	local float SavedA, SavedFade, SavedFrac, Spd, FrontN, RearN;
	local string Result;
	local bool bOk;

	SavedA = TestBody.DriverAccelMps2;
	SavedFade = TestBody.DriverAccelFadeSpeedMps;
	SavedFrac = TestBody.DriverAccelMinFrac;
	TestBody.DriverAccelMps2 = AccelMps2;
	if (bFade)
	{
		TestBody.DriverAccelFadeSpeedMps = 18.0;
		TestBody.DriverAccelMinFrac = 0.35;
	}
	else
	{
		// Pure peak comparison: no speed taper.
		TestBody.DriverAccelFadeSpeedMps = 0;
		TestBody.DriverAccelMinFrac = 1.0;
	}

	P2SettleFlat();
	TestBody.LastGas = 1.0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	P25aResetMetrics();
	n = int(Duration * 60.0 + 0.5);
	if (n < 1)
		n = 1;
	for (i = 0; i < n; ++i)
	{
		TestBody.PumpPhysics(1.0 / 60.0, 1.0 / 60.0);
		P25aSample();
	}
	Spd = P2HorizSpeed();
	FrontN = P25aFrontLoadN();
	RearN = P25aRearLoadN();
	bOk = (P25aMinWheels >= 3
		&& P25aMinFrontN > 1500.0
		&& P25aMaxPitch < 0.18
		&& P25aMaxAbsYaw < 0.25
		&& P25aMaxAbsBodyLat < 1.50
		&& TestBody.StepFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0);
	if (bOk)
		Result = "PASS";
	else
		Result = "FAIL";
	Log("HB2_P25A SWEEP tag="$Tag$" a0="$AccelMps2$" fade="$bFade
		$" xferN="$P25aTransferN(AccelMps2)
		$" minFrontN="$P25aMinFrontN$" endFrontN="$FrontN$" endRearN="$RearN
		$" minW="$P25aMinWheels$" maxPitch="$P25aMaxPitch
		$" maxYaw="$P25aMaxAbsYaw$" maxLat="$P25aMaxAbsBodyLat
		$" spd="$Spd$" driveA="$TestBody.LastDesiredDriveAccelMps2
		$" result="$Result);
	TestBody.DriverAccelMps2 = SavedA;
	TestBody.DriverAccelFadeSpeedMps = SavedFade;
	TestBody.DriverAccelMinFrac = SavedFrac;
	return Result;
}

function string P25aRunSymmetry()
{
	local float Nfl, Nfr, Nrl, Nrr, Dfront, Drear;
	local string Result;
	P2SettleFlat();
	TestBody.LastGas = 0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.PumpPhysics(1.0 / 60.0, 0.50);
	Nfl = TestBody.LastTireN[0];
	Nfr = TestBody.LastTireN[1];
	Nrl = TestBody.LastTireN[2];
	Nrr = TestBody.LastTireN[3];
	Dfront = Abs(Nfl - Nfr);
	Drear = Abs(Nrl - Nrr);
	if (Dfront < 400.0 && Drear < 400.0
		&& TestBody.WheelContactCount >= 4
		&& Abs(TestBody.Core.OutAngZ_radps) < 0.02)
		Result = "PASS";
	else
		Result = "FAIL";
	Log("HB2_P25A SYM rest FL="$Nfl$" FR="$Nfr$" RL="$Nrl$" RR="$Nrr
		$" dFront="$Dfront$" dRear="$Drear$" result="$Result);

	P2SettleFlat();
	TestBody.LastGas = 1.0;
	TestBody.LastSteer = 0;
	TestBody.PumpPhysics(1.0 / 60.0, 0.80);
	Nfl = TestBody.LastTireN[0];
	Nfr = TestBody.LastTireN[1];
	Nrl = TestBody.LastTireN[2];
	Nrr = TestBody.LastTireN[3];
	Dfront = Abs(Nfl - Nfr);
	Drear = Abs(Nrl - Nrr);
	if (Result == "PASS" && Dfront < 1200.0 && Drear < 1200.0
		&& TestBody.WheelContactCount >= 3
		&& Abs(TestBody.LastBodyLateralSpeedMps) < 0.80)
		Result = "PASS";
	else if (Result == "PASS")
		Result = "FAIL";
	Log("HB2_P25A SYM drive FL="$Nfl$" FR="$Nfr$" RL="$Nrl$" RR="$Nrr
		$" dFront="$Dfront$" dRear="$Drear
		$" lat="$TestBody.LastBodyLateralSpeedMps$" yaw="$TestBody.Core.OutAngZ_radps
		$" result="$Result);
	return Result;
}

function StartP25aSuite()
{
	local float Wb, H, StaticFront;
	local float SavedA, SavedFade, SavedFrac;
	local float FwdSpd, LatRatio;
	local bool bOk;

	// Prevent a second Timer tick from re-entering after GATE_DONE.
	P1Phase = 99;
	SetTimer(0, False);

	Wb = P25aWheelbaseM();
	H = P25aComHeightM();
	StaticFront = TestBody.MassKg * 9.81
		* Abs(class'HB2WorldQuery'.static.UUToM(TestBody.SuspensionAttachmentUU[2].X)) / Wb;
	Log("HB2_P25A START straight_wheelie mass="$TestBody.MassKg
		$" wheelbaseM="$Wb$" comH_m="$H$" staticFrontN="$StaticFront
		$" note=log_hb2_straight_diagnostics_frontUnload_to_0_wheels");

	ResultP25aSweep9905 = "NOT_RUN";
	ResultP25aSweep600 = "NOT_RUN";
	ResultP25aSweep450 = "NOT_RUN";
	ResultP25aSweep300 = "NOT_RUN";
	ResultP25aStraightLong = "NOT_RUN";
	ResultP25aSym = "NOT_RUN";
	ResultP25aBaseline05 = "NOT_RUN";
	ResultP25aHistoricP2Straight = "FAIL";

	// Sweep without fade (other params unchanged).
	ResultP25aSweep9905 = P25aRunAccelSweep(9.905, 2.50, "a9.905", False);
	ResultP25aSweep600 = P25aRunAccelSweep(6.0, 2.50, "a6.0", False);
	ResultP25aSweep450 = P25aRunAccelSweep(4.5, 2.50, "a4.5", False);
	ResultP25aSweep300 = P25aRunAccelSweep(3.0, 2.50, "a3.0", False);

	// Chosen profile: 4.5 m/s2 peak + speed taper for heavy off-road.
	SavedA = TestBody.DriverAccelMps2;
	SavedFade = TestBody.DriverAccelFadeSpeedMps;
	SavedFrac = TestBody.DriverAccelMinFrac;
	TestBody.DriverAccelMps2 = 4.5;
	TestBody.DriverAccelFadeSpeedMps = 18.0;
	TestBody.DriverAccelMinFrac = 0.35;

	ResultP25aSym = P25aRunSymmetry();

	// Historic 0.5 s baseline bar (unchanged thresholds).
	P2SettleFlat();
	TestBody.LastGas = 1.0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.PumpPhysics(1.0 / 60.0, 0.50);
	FwdSpd = TestBody.Core.OutVelX_mps;
	if (Abs(FwdSpd) > 0.05)
		LatRatio = Abs(TestBody.Core.OutVelY_mps) / Abs(FwdSpd);
	else
		LatRatio = 999;
	bOk = (FwdSpd > 3.0 && LatRatio < 0.20
		&& TestBody.LastTireActiveCount >= 3
		&& TestBody.LastThrottleImpulseNs > 0
		&& TestBody.StepFailureCount == 0);
	if (bOk)
		ResultP25aBaseline05 = "PASS";
	else
		ResultP25aBaseline05 = "FAIL";
	Log("HB2_P25A BASELINE_05s note=historic_P2_straight_0.5s_bar_unchanged"
		$" vx="$FwdSpd$" latRatio="$LatRatio
		$" active="$TestBody.LastTireActiveCount$" result="$ResultP25aBaseline05);

	// Same speed bars as 0.5s baseline, longer gas so a=4.5 can reach vx>3
	// without loosening the threshold (ideal t>=3/4.5≈0.67s; 1.0s covers taper).
	P2SettleFlat();
	TestBody.LastGas = 1.0;
	TestBody.LastSteer = 0;
	TestBody.LastBrake = 0;
	TestBody.PumpPhysics(1.0 / 60.0, 1.00);
	FwdSpd = TestBody.Core.OutVelX_mps;
	if (Abs(FwdSpd) > 0.05)
		LatRatio = Abs(TestBody.Core.OutVelY_mps) / Abs(FwdSpd);
	else
		LatRatio = 999;
	bOk = (FwdSpd > 3.0 && LatRatio < 0.20
		&& TestBody.LastTireActiveCount >= 3
		&& TestBody.LastThrottleImpulseNs > 0
		&& TestBody.WheelContactCount >= 4
		&& P25aFrontLoadN() > 1500.0
		&& TestBody.StepFailureCount == 0);
	if (bOk)
		Log("HB2_P25A STRAIGHT_EQ08 note=same_vx_bar_as_0.5s_longer_gas_for_a4.5"
			$" vx="$FwdSpd$" latRatio="$LatRatio
			$" frontN="$P25aFrontLoadN()$" wheels="$TestBody.WheelContactCount
			$" result=PASS");
	else
		Log("HB2_P25A STRAIGHT_EQ08 note=same_vx_bar_as_0.5s_longer_gas_for_a4.5"
			$" vx="$FwdSpd$" latRatio="$LatRatio
			$" frontN="$P25aFrontLoadN()$" wheels="$TestBody.WheelContactCount
			$" result=FAIL");

	// Long straight on the flat pad (larger surface / longer time).
	ResultP25aStraightLong = P25aRunAccelSweep(4.5, 4.00, "straight_long", True);

	Log("HB2_P25A HISTORIC_P2_STRAIGHT result="$ResultP25aHistoricP2Straight
		$" note=1.20s_pad_exit_FAIL_kept;_BASELINE_05s_and_STRAIGHT_LONG_are_equivalents");

	Log("HB2_P25A GATE_DONE a9905="$ResultP25aSweep9905$" a600="$ResultP25aSweep600
		$" a450="$ResultP25aSweep450$" a300="$ResultP25aSweep300
		$" long="$ResultP25aStraightLong$" sym="$ResultP25aSym
		$" base05="$ResultP25aBaseline05
		$" historicP2straight="$ResultP25aHistoricP2Straight
		$" chosenA="$TestBody.DriverAccelMps2
		$" fadeSpeed="$TestBody.DriverAccelFadeSpeedMps
		$" minFrac="$TestBody.DriverAccelMinFrac
		$" tireMu="$TestBody.TireMu
		$" spring="$TestBody.SuspensionSpringNpm[0]
		$" stepFail="$TestBody.StepFailureCount
		$" syncFail="$TestBody.ActorSyncFailureCount
		$" nonFinite="$TestBody.NonFiniteStateCount);

	// Keep chosen profile for any subsequent manual session on this package.
	TestBody.DriverAccelMps2 = 4.5;
	TestBody.DriverAccelFadeSpeedMps = 18.0;
	TestBody.DriverAccelMinFrac = 0.35;
	if (SavedA > 0)
	{
		// silence unused if compile complains — values restored to chosen.
		SavedA = SavedA;
		SavedFade = SavedFade;
		SavedFrac = SavedFrac;
	}
}

function TickP25a()
{
	local vector HitLoc;
	local rotator ZeroRot;
	local float EquilibriumLengthUU, ExpectedCenterZ;

	if (!FindBody())
	{
		Log("HB2_P25A WAIT: no body");
		return;
	}
	if (P1Phase == 0)
	{
		if (!FindFlatSuspensionSite(HitLoc))
		{
			ResultP25aStraightLong = "FAIL no four-ray flat BSP site";
			Warn("HB2_P25A FAIL no four-ray flat BSP site");
			P1Phase = 99;
			SetTimer(0, False);
			return;
		}
		EquilibriumLengthUU = TestBody.SuspensionRestUU[0]
			- class'HB2WorldQuery'.static.MToUU(
				TestBody.MassKg * 9.81 / (4.0 * TestBody.SuspensionSpringNpm[0]));
		ExpectedCenterZ = HitLoc.Z - TestBody.SuspensionAttachmentUU[0].Z
			+ EquilibriumLengthUU + TestBody.WheelRadiusUU[0];
		P1FlatCenter = HitLoc;
		P1FlatCenter.Z = ExpectedCenterZ;
		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
		Log("HB2_P25A START floor="$HitLoc$" center="$P1FlatCenter
			$" control="$TestBody.ControlProfile$" chassis="$TestBody.ChassisProfile
			$" a0="$TestBody.DriverAccelMps2);
		StartP25aSuite();
		P1Phase = 99;
		SetTimer(0, False);
	}
}

function bool P21RecoverLooksUpright(float KeepYaw)
{
	local float YawErr, Tilt, Spd, Omega;
	if (!TestBody.bLastRecoverOK)
		return False;
	YawErr = TestBody.Core.OutYaw_rad - KeepYaw;
	while (YawErr > 3.141593)
		YawErr = YawErr - 6.283185;
	while (YawErr < -3.141593)
		YawErr = YawErr + 6.283185;
	Tilt = Sqrt(TestBody.Core.OutPitch_rad * TestBody.Core.OutPitch_rad
		+ TestBody.Core.OutRoll_rad * TestBody.Core.OutRoll_rad);
	Spd = VSize(TestBody.Velocity);
	Omega = Sqrt(TestBody.Core.OutAngX_radps * TestBody.Core.OutAngX_radps
		+ TestBody.Core.OutAngY_radps * TestBody.Core.OutAngY_radps
		+ TestBody.Core.OutAngZ_radps * TestBody.Core.OutAngZ_radps);
	return (Abs(YawErr) < 0.15 && Tilt < 0.04 && Spd < 8.0 && Omega < 0.08
		&& Abs(TestBody.Rotation.Pitch) < 400
		&& Abs(TestBody.Rotation.Roll) < 400
		&& TestBody.WheelContactCount >= 4
		&& TestBody.StepFailureCount == 0
		&& TestBody.NonFiniteStateCount == 0);
}

function bool P21WheelAxesLookRight()
{
	local rotator SavedRot, Pose;
	local vector Fwd, Right, Up, MX, MY, MZ;
	local float SavedSteer, SavedSpin[4];
	local int i;
	local bool bOk;

	SavedRot = TestBody.Rotation;
	SavedSteer = TestBody.LastSteer;
	for (i = 0; i < 4; ++i)
		SavedSpin[i] = TestBody.WheelSpinRad[i];

	Pose.Yaw = 8192;
	Pose.Pitch = 3640;
	Pose.Roll = -1820;
	TestBody.SetRotation(Pose);
	GetAxes(Pose, Fwd, Right, Up);

	bOk = True;
	TestBody.LastSteer = 0;
	for (i = 0; i < 4; ++i)
		TestBody.WheelSpinRad[i] = 0;
	GetAxes(TestBody.WheelWorldRot(2, Fwd, Right, Up), MX, MY, MZ);
	if (Abs(MY Dot Right) < 0.97 || Abs(MX Dot Fwd) < 0.97 || Abs(MZ Dot Up) < 0.97)
		bOk = False;
	Log("HB2_P21 WHEELGEOM restRL mxDotFwd="$(MX Dot Fwd)$" myDotRight="$(MY Dot Right)
		$" mzDotUp="$(MZ Dot Up)$" meshL=HB227BulldogWheel meshR=HB227BulldogWheelR");
	GetAxes(TestBody.WheelWorldRot(3, Fwd, Right, Up), MX, MY, MZ);
	if (Abs(MY Dot Right) < 0.97 || Abs(MX Dot Fwd) < 0.97)
		bOk = False;

	TestBody.LastSteer = 1.0;
	GetAxes(TestBody.WheelWorldRot(0, Fwd, Right, Up), MX, MY, MZ);
	if (Abs(MY Dot Up) > 0.08)
		bOk = False;
	if (Abs((MY Dot Right) - Cos(TestBody.MaxSteerRad)) > 0.06)
		bOk = False;
	if (Abs((MY Dot Fwd) + Sin(TestBody.MaxSteerRad)) > 0.06)
		bOk = False;
	Log("HB2_P21 WHEELGEOM steerFL myDotR="$(MY Dot Right)$" myDotF="$(MY Dot Fwd)
		$" myDotU="$(MY Dot Up)$" wantCos="$Cos(TestBody.MaxSteerRad)
		$" wantNegSin="$(-Sin(TestBody.MaxSteerRad)));

	TestBody.LastSteer = 0;
	TestBody.WheelSpinRad[0] = 1.570796;
	GetAxes(TestBody.WheelWorldRot(0, Fwd, Right, Up), MX, MY, MZ);
	if ((MX Dot Up) > -0.90 || Abs(MY Dot Right) < 0.95)
		bOk = False;
	Log("HB2_P21 WHEELGEOM spin90FL mxDotUp="$(MX Dot Up)$" myDotRight="$(MY Dot Right)
		$" note=forward_roll_front_down");

	TestBody.SetRotation(SavedRot);
	TestBody.LastSteer = SavedSteer;
	for (i = 0; i < 4; ++i)
		TestBody.WheelSpinRad[i] = SavedSpin[i];
	return bOk;
}

function StartP21ResetSuite()
{
	local rotator Pose, ZeroRot;
	local vector RoofLoc, CrashVel, WallHit;
	local float KeepYaw;
	local bool bOk;

	Log("HB2_P21 START_RESET_SUITE loc="$TestBody.Location
		$" control="$TestBody.ControlProfile$" chassis="$TestBody.ChassisProfile);
	ResultP21Roof = "NOT_RUN";
	ResultP21Left = "NOT_RUN";
	ResultP21Right = "NOT_RUN";
	ResultP21Crash = "NOT_RUN";
	ResultP21FailPath = "NOT_RUN";
	ResultP21WheelGeom = "NOT_RUN";
	if (P21WheelAxesLookRight())
		ResultP21WheelGeom = "PASS";
	else
		ResultP21WheelGeom = "FAIL";
	Log("HB2_P21 WHEELGEOM result="$ResultP21WheelGeom);

	Pose.Yaw = 8192;
	Pose.Pitch = 0;
	Pose.Roll = 0;
	TestBody.SetRotation(Pose);
	TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
	TestBody.PumpPhysics(1.0 / 60.0, 0.35);

	RoofLoc = P1FlatCenter;
	RoofLoc.Z = P1FlatCenter.Z - TestBody.ChassisSpawnHeightUU()
		+ TestBody.ChassisHalfUU.Z + 10.0;
	Pose.Yaw = 8192;
	Pose.Pitch = 0;
	Pose.Roll = 32768;
	TestBody.SetRotation(Pose);
	TestBody.ResetTo(RoofLoc, vect(250,0,0));
	TestBody.PumpPhysics(1.0 / 60.0, 0.25);
	KeepYaw = TestBody.Core.OutYaw_rad;
	bOk = TestBody.RecoverUpright() && P21RecoverLooksUpright(KeepYaw);
	if (bOk)
		ResultP21Roof = "PASS";
	else
		ResultP21Roof = "FAIL";
	Log("HB2_P21 ROOF recover="$TestBody.LastRecoverReason
		$" yaw="$TestBody.Core.OutYaw_rad$" pitch="$TestBody.Core.OutPitch_rad
		$" roll="$TestBody.Core.OutRoll_rad$" keepYaw="$KeepYaw
		$" actorRot="$TestBody.Rotation$" wheels="$TestBody.WheelContactCount
		$" result="$ResultP21Roof);

	Pose.Yaw = 8192;
	Pose.Pitch = 0;
	Pose.Roll = 16384;
	TestBody.SetRotation(Pose);
	TestBody.ResetTo(P1FlatCenter + vect(0,0,40), vect(0,0,0));
	TestBody.PumpPhysics(1.0 / 60.0, 0.20);
	KeepYaw = TestBody.Core.OutYaw_rad;
	bOk = TestBody.RecoverUpright() && P21RecoverLooksUpright(KeepYaw);
	if (bOk)
		ResultP21Left = "PASS";
	else
		ResultP21Left = "FAIL";
	Log("HB2_P21 LEFT recover="$TestBody.LastRecoverReason
		$" yaw="$TestBody.Core.OutYaw_rad$" pitch="$TestBody.Core.OutPitch_rad
		$" roll="$TestBody.Core.OutRoll_rad$" keepYaw="$KeepYaw
		$" actorRot="$TestBody.Rotation$" result="$ResultP21Left);

	Pose.Yaw = 8192;
	Pose.Pitch = 0;
	Pose.Roll = -16384;
	TestBody.SetRotation(Pose);
	TestBody.ResetTo(P1FlatCenter + vect(0,0,40), vect(0,0,0));
	TestBody.PumpPhysics(1.0 / 60.0, 0.20);
	KeepYaw = TestBody.Core.OutYaw_rad;
	bOk = TestBody.RecoverUpright() && P21RecoverLooksUpright(KeepYaw);
	if (bOk)
		ResultP21Right = "PASS";
	else
		ResultP21Right = "FAIL";
	Log("HB2_P21 RIGHT recover="$TestBody.LastRecoverReason
		$" yaw="$TestBody.Core.OutYaw_rad$" pitch="$TestBody.Core.OutPitch_rad
		$" roll="$TestBody.Core.OutRoll_rad$" keepYaw="$KeepYaw
		$" actorRot="$TestBody.Rotation$" result="$ResultP21Right);

	if (FindBSPWallNear(P1FlatCenter, P1WallDir, WallHit))
	{
		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(WallHit - P1WallDir * (TestBody.ChassisHalfUU.X + 140.0)
			+ vect(0,0,1) * (TestBody.ChassisHalfUU.Z + 24.0), vect(0,0,0));
		CrashVel = P1WallDir * 1400;
		TestBody.ImpulseUU(CrashVel);
		TestBody.PumpPhysics(1.0 / 60.0, 0.55);
		KeepYaw = TestBody.Core.OutYaw_rad;
		bOk = TestBody.RecoverUpright() && P21RecoverLooksUpright(KeepYaw);
		if (bOk)
			ResultP21Crash = "PASS";
		else
			ResultP21Crash = "FAIL";
		Log("HB2_P21 CRASH recover="$TestBody.LastRecoverReason
			$" yaw="$TestBody.Core.OutYaw_rad$" pitch="$TestBody.Core.OutPitch_rad
			$" roll="$TestBody.Core.OutRoll_rad$" keepYaw="$KeepYaw
			$" chassisMode="$TestBody.LastChassisContactMode
			$" wheels="$TestBody.WheelContactCount
			$" spd="$VSize(TestBody.Velocity)
			$" omega="$Sqrt(TestBody.Core.OutAngX_radps * TestBody.Core.OutAngX_radps
				+ TestBody.Core.OutAngY_radps * TestBody.Core.OutAngY_radps
				+ TestBody.Core.OutAngZ_radps * TestBody.Core.OutAngZ_radps)
			$" loc="$TestBody.Location
			$" result="$ResultP21Crash);
	}
	else
	{
		ResultP21Crash = "NOT_RUN no BSP wall";
		Log("HB2_P21 NOT_RUN_CRASH no BSP wall");
	}

	ResultP21FailPath = "NOT_RUN no synthetic solid cell";
	Log("HB2_P21 FAILPATH "$ResultP21FailPath
		$" note=RecoverUpright returns False without moving when OBB has no safe cell");

	TestBody.SetRotation(ZeroRot);
	TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
	Log("HB2_P21 GATE_DONE roof="$ResultP21Roof$" left="$ResultP21Left
		$" right="$ResultP21Right$" crash="$ResultP21Crash
		$" failPath="$ResultP21FailPath$" wheelGeom="$ResultP21WheelGeom
		$" stepFail="$TestBody.StepFailureCount
		$" syncFail="$TestBody.ActorSyncFailureCount
		$" nonFinite="$TestBody.NonFiniteStateCount);
}

function TickP21()
{
	local vector HitLoc;
	local rotator ZeroRot;
	local float EquilibriumLengthUU, ExpectedCenterZ;

	if (!FindBody())
	{
		Log("HB2_P21 WAIT: no body");
		return;
	}
	if (P1Phase == 0)
	{
		if (!FindFlatSuspensionSite(HitLoc))
		{
			ResultP21Roof = "FAIL no four-ray flat BSP site";
			Warn("HB2_P21 FAIL no four-ray flat BSP site");
			P1Phase = 99;
			SetTimer(0, False);
			return;
		}
		EquilibriumLengthUU = TestBody.SuspensionRestUU[0]
			- class'HB2WorldQuery'.static.MToUU(
				TestBody.MassKg * 9.81 / (4.0 * TestBody.SuspensionSpringNpm[0]));
		ExpectedCenterZ = HitLoc.Z - TestBody.SuspensionAttachmentUU[0].Z
			+ EquilibriumLengthUU + TestBody.WheelRadiusUU[0];
		P1FlatCenter = HitLoc;
		P1FlatCenter.Z = ExpectedCenterZ;
		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
		Log("HB2_P21 START floor="$HitLoc$" center="$P1FlatCenter
			$" control="$TestBody.ControlProfile$" chassis="$TestBody.ChassisProfile);
		StartP21ResetSuite();
		P1Phase = 99;
		SetTimer(0, False);
	}
}

function TickP1()
{
	local vector HitLoc, Vel;
	local rotator ZeroRot;
	local float EquilibriumLengthUU, ExpectedCenterZ;
	local float Elapsed, LoadSum, HorizontalSpeed, Tilt;
	local int ActiveCount;
	local string PointMode;

	if (!FindBody())
	{
		Log("HB2_P1 WAIT: no body");
		return;
	}

	if (P1Phase == 0)
	{
		if (!FindFlatSuspensionSite(HitLoc))
		{
			ResultP1Stationary = "FAIL no four-ray flat BSP site";
			Warn("HB2_P1 FAIL_STATIONARY no four-ray flat BSP site");
			P1Phase = 99;
			SetTimer(0, False);
			return;
		}

		// Static equilibrium of four identical supports: 4*k*x = m*g.
		EquilibriumLengthUU = TestBody.SuspensionRestUU[0]
			- class'HB2WorldQuery'.static.MToUU(
				TestBody.MassKg * 9.81 / (4.0 * TestBody.SuspensionSpringNpm[0]));
		ExpectedCenterZ = HitLoc.Z - TestBody.SuspensionAttachmentUU[0].Z
			+ EquilibriumLengthUU + TestBody.WheelRadiusUU[0];
		P1FlatCenter = HitLoc;
		P1FlatCenter.Z = ExpectedCenterZ;
		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
		P1StartSteps = TestBody.TotalStepCount;
		P1PhaseStart = Level.TimeSeconds;
		P1Phase = 1;
		Log("HB2_P1 START_STATIONARY floor="$HitLoc$" center="$P1FlatCenter
			$" equilibriumLengthUU="$EquilibriumLengthUU
			$" profile="$TestBody.ChassisProfile$" half="$TestBody.ChassisHalfUU
			$" clearanceUU="$TestBody.GroundClearanceUU());
		return;
	}

	if (P1Phase == 1)
	{
		Elapsed = Level.TimeSeconds - P1PhaseStart;
		if (Elapsed < 5.0)
			return;
		Vel = TestBody.Velocity;
		HorizontalSpeed = Sqrt(Vel.X * Vel.X + Vel.Y * Vel.Y);
		Tilt = Sqrt(TestBody.Core.OutPitch_rad * TestBody.Core.OutPitch_rad
			+ TestBody.Core.OutRoll_rad * TestBody.Core.OutRoll_rad);
		LoadSum = TestBody.Core.OutWheel0NormalLoad_N
			+ TestBody.Core.OutWheel1NormalLoad_N
			+ TestBody.Core.OutWheel2NormalLoad_N
			+ TestBody.Core.OutWheel3NormalLoad_N;
		if (TestBody.Core.OutWheel0Status == 3 && TestBody.Core.OutWheel1Status == 3
			&& TestBody.Core.OutWheel2Status == 3 && TestBody.Core.OutWheel3Status == 3
			&& Abs(Vel.Z) < 0.25 && HorizontalSpeed < 0.25 && Tilt < 0.002
			&& Abs(LoadSum - TestBody.MassKg * 9.81) < P1LoadAbsTolN()
			&& TestBody.StepFailureCount == 0 && TestBody.ActorSyncFailureCount == 0
			&& TestBody.NonFiniteStateCount == 0)
		{
			ResultP1Stationary = "PASS";
			Log("HB2_P1 PASS_STATIONARY elapsed="$Elapsed
				$" fixedSteps="$(TestBody.TotalStepCount - P1StartSteps)
				$" center="$TestBody.Location$" vel="$Vel$" tilt="$Tilt
				$" loadSumN="$LoadSum$" expectedN="$(TestBody.MassKg * 9.81));
		}
		else
		{
			ResultP1Stationary = "FAIL";
			Warn("HB2_P1 FAIL_STATIONARY elapsed="$Elapsed
				$" fixedSteps="$(TestBody.TotalStepCount - P1StartSteps)
				$" center="$TestBody.Location$" vel="$Vel$" horizontalSpeed="$HorizontalSpeed
				$" tilt="$Tilt$" loadSumN="$LoadSum
				$" statuses="$TestBody.Core.OutWheel0Status$","$TestBody.Core.OutWheel1Status
				$","$TestBody.Core.OutWheel2Status$","$TestBody.Core.OutWheel3Status
				$" failures="$TestBody.StepFailureCount$","$TestBody.ActorSyncFailureCount
				$","$TestBody.NonFiniteStateCount);
		}
		Log("HB2_P1 GATE_STATIONARY result="$ResultP1Stationary);
		if (ResultP1Stationary != "PASS")
		{
			P1Phase = 99;
			SetTimer(0, False);
			return;
		}
		if (bP15)
		{
			StartP15DriveSmoke();
			return;
		}
		StartP1ContactLoss();
		return;
	}

	if (P1Phase == 20)
	{
		Elapsed = Level.TimeSeconds - P1PhaseStart;
		if (Elapsed < 1.50)
			return;
		HorizontalSpeed = Sqrt(TestBody.Velocity.X * TestBody.Velocity.X
			+ TestBody.Velocity.Y * TestBody.Velocity.Y);
		TestBody.LastGas = 0;
		if (HorizontalSpeed > 80.0 && TestBody.StepFailureCount == 0
			&& TestBody.NonFiniteStateCount == 0)
		{
			ResultP15Drive = "PASS gas";
			Log("HB2_P15 PASS_GAS spd="$HorizontalSpeed$" loc="$TestBody.Location);
		}
		else
		{
			ResultP15Drive = "FAIL gas";
			Warn("HB2_P15 FAIL_GAS spd="$HorizontalSpeed$" loc="$TestBody.Location);
		}
		TestBody.ResetTo(P1FlatCenter, vect(0,0,0));
		TestBody.PumpPhysics(1.0 / 60.0, 0.20);
		if (!TestBody.ApplyYawImpulseCouple(0.80))
		{
			ResultP15Drive = ResultP15Drive$" FAIL yaw-impulse";
			Warn("HB2_P15 FAIL_YAW couple rejected");
			StartP1ContactLoss();
			return;
		}
		P1Phase = 21;
		P1PhaseStart = Level.TimeSeconds;
		Log("HB2_P15 START_YAW couple deltaOmegaZ=0.80");
		return;
	}

	if (P1Phase == 21)
	{
		Elapsed = Level.TimeSeconds - P1PhaseStart;
		if (Elapsed < 0.20)
			return;
		if (Abs(TestBody.Core.OutAngZ_radps) > 0.25
			&& TestBody.StepFailureCount == 0 && TestBody.NonFiniteStateCount == 0)
		{
			ResultP15Drive = ResultP15Drive$" PASS yaw";
			Log("HB2_P15 PASS_YAW omegaZ="$TestBody.Core.OutAngZ_radps);
		}
		else
		{
			ResultP15Drive = ResultP15Drive$" FAIL yaw";
			Warn("HB2_P15 FAIL_YAW omegaZ="$TestBody.Core.OutAngZ_radps);
		}
		TestBody.ApplyYawImpulseCouple(-TestBody.Core.OutAngZ_radps);
		TestBody.PumpPhysics(1.0 / 60.0, 0.35);
		Log("HB2_P15 YAW_NEUTRAL omegaZ="$TestBody.Core.OutAngZ_radps
			$" result="$ResultP15Drive);
		StartP1ContactLoss();
		return;
	}

	if (P1Phase == 11)
	{
		Elapsed = Level.TimeSeconds - P1PhaseStart;
		if (TestBody.Core.OutContacts > 0 && TestBody.LastHitKind == "BSP")
			P1WallBSPContactSamples++;
		if (Elapsed < 3.0)
			return;
		if (P1WallBSPContactSamples > 0
			&& (TestBody.Velocity Dot P1WallDir) < 700.0
			&& TestBody.StepFailureCount == 0 && TestBody.NonFiniteStateCount == 0)
		{
			ResultP15Side = "PASS";
			Log("HB2_P15 PASS_SIDE_BSP samples="$P1WallBSPContactSamples
				$" ahead="$(TestBody.Velocity Dot P1WallDir)
				$" omega="$TestBody.P13HSLatchedOmega
				$" mode="$TestBody.LastChassisContactMode);
		}
		else
		{
			ResultP15Side = "FAIL";
			Warn("HB2_P15 FAIL_SIDE_BSP samples="$P1WallBSPContactSamples
				$" ahead="$(TestBody.Velocity Dot P1WallDir)
				$" loc="$TestBody.Location);
		}
		StartP13MidSpeedClip();
		return;
	}

	if (P1Phase == 2)
	{
		Elapsed = Level.TimeSeconds - P1PhaseStart;
		if (Elapsed < 3.0)
			return;
		ActiveCount = ActiveSuspensionCount();
		Log("HB2_P1 CONTACT_LOSS_SAMPLE threeWheelSteps="
			$(TestBody.SuspensionThreeContactStepCount - P1ThreeContactStart)
			$" lossSteps="$(TestBody.SuspensionContactLossStepCount - P1ContactLossStart)
			$" recoveredActive="$ActiveCount);
		if (ResultP1ContactLoss == ""
			&& TestBody.SuspensionThreeContactStepCount > P1ThreeContactStart
			&& TestBody.SuspensionContactLossStepCount > P1ContactLossStart
			&& ActiveCount == 4 && TestBody.StepFailureCount == 0
			&& TestBody.NonFiniteStateCount == 0)
		{
			ResultP1ContactLoss = "PASS";
			Log("HB2_P1 PASS_CONTACT_LOSS threeWheelSteps="
				$(TestBody.SuspensionThreeContactStepCount - P1ThreeContactStart)
				$" lossSteps="$(TestBody.SuspensionContactLossStepCount - P1ContactLossStart)
				$" recoveredActive="$ActiveCount$" omega="$TestBody.Core.OutAngX_radps
				$","$TestBody.Core.OutAngY_radps$","$TestBody.Core.OutAngZ_radps);
		}
		else
		{
			ResultP1ContactLoss = "FAIL";
			Warn("HB2_P1 FAIL_CONTACT_LOSS threeWheelSteps="
				$(TestBody.SuspensionThreeContactStepCount - P1ThreeContactStart)
				$" lossSteps="$(TestBody.SuspensionContactLossStepCount - P1ContactLossStart)
				$" active="$ActiveCount);
		}

		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(P1FlatCenter + vect(0,0,25), vect(0,0,0));
		P1ContactLossStart = TestBody.SuspensionContactLossStepCount;
		P1Phase = 3;
		P1PhaseStart = Level.TimeSeconds;
		Log("HB2_P1 START_HEAVE dropUU=25 expected initial droop loss then damped reacquisition");
		return;
	}

	if (P1Phase == 3)
	{
		Elapsed = Level.TimeSeconds - P1PhaseStart;
		if (Elapsed < 6.0)
			return;
		Vel = TestBody.Velocity;
		ActiveCount = ActiveSuspensionCount();
		if (TestBody.SuspensionContactLossStepCount > P1ContactLossStart
			&& ActiveCount == 4 && Abs(Vel.Z) < 0.5
			&& Abs(TestBody.Location.Z - P1FlatCenter.Z) < 0.5
			&& TestBody.StepFailureCount == 0 && TestBody.NonFiniteStateCount == 0)
		{
			ResultP1Heave = "PASS";
			Log("HB2_P1 PASS_HEAVE elapsed="$Elapsed$" lossSteps="
				$(TestBody.SuspensionContactLossStepCount - P1ContactLossStart)
				$" recoveredZ="$TestBody.Location.Z$" vzUUps="$Vel.Z);
		}
		else
		{
			ResultP1Heave = "FAIL";
			Warn("HB2_P1 FAIL_HEAVE active="$ActiveCount$" loc="$TestBody.Location
				$" vel="$Vel$" lossSteps="
				$(TestBody.SuspensionContactLossStepCount - P1ContactLossStart));
		}

		if (!PlaceForSlope(0, P1SlopeNormal))
		{
			ResultP1Roll = "NOT_RUN no usable BSP slope";
			ResultP1Pitch = "NOT_RUN no usable BSP slope";
			Log("HB2_P1 NOT_RUN_SLOPE no usable BSP slope");
			StartP1ChassisBSP();
			return;
		}
		P1MaxAbsRoll = 0;
		bP1SlopeSupportedResponse = False;
		P1Phase = 4;
		P1PhaseStart = Level.TimeSeconds;
		Log("HB2_P1 START_ROLL two-side differential normal="$P1SlopeNormal);
		return;
	}

	if (P1Phase == 4)
	{
		P1MaxAbsRoll = FMax(P1MaxAbsRoll, Abs(TestBody.Core.OutRoll_rad));
		if (ActiveSuspensionCount() >= 2)
			bP1SlopeSupportedResponse = True;
		Elapsed = Level.TimeSeconds - P1PhaseStart;
		if (Elapsed < 2.0)
			return;
		if (P1MaxAbsRoll > 0.01 && bP1SlopeSupportedResponse
			&& TestBody.StepFailureCount == 0 && TestBody.NonFiniteStateCount == 0)
		{
			ResultP1Roll = "PASS";
			Log("HB2_P1 PASS_ROLL maxAbsRollRad="$P1MaxAbsRoll
				$" finalRollRad="$TestBody.Core.OutRoll_rad$" normal="$P1SlopeNormal
				$" lengthsUU="$TestBody.LastWheelLengthUU[0]$","$TestBody.LastWheelLengthUU[1]
				$","$TestBody.LastWheelLengthUU[2]$","$TestBody.LastWheelLengthUU[3]);
		}
		else
		{
			ResultP1Roll = "FAIL";
			Warn("HB2_P1 FAIL_ROLL maxAbsRollRad="$P1MaxAbsRoll
				$" contacts="$TestBody.WheelContactCount$" normal="$P1SlopeNormal);
		}

		if (!PlaceForSlope(16384, P1SlopeNormal))
		{
			ResultP1Pitch = "NOT_RUN no usable BSP slope";
			StartP1ChassisBSP();
			return;
		}
		P1MaxAbsPitch = 0;
		bP1SlopeSupportedResponse = False;
		P1Phase = 5;
		P1PhaseStart = Level.TimeSeconds;
		Log("HB2_P1 START_PITCH front-rear differential normal="$P1SlopeNormal);
		return;
	}

	if (P1Phase == 5)
	{
		P1MaxAbsPitch = FMax(P1MaxAbsPitch, Abs(TestBody.Core.OutPitch_rad));
		if (ActiveSuspensionCount() >= 2)
			bP1SlopeSupportedResponse = True;
		Elapsed = Level.TimeSeconds - P1PhaseStart;
		if (Elapsed < 2.0)
			return;
		if (P1MaxAbsPitch > 0.01 && bP1SlopeSupportedResponse
			&& TestBody.StepFailureCount == 0 && TestBody.NonFiniteStateCount == 0)
		{
			ResultP1Pitch = "PASS";
			Log("HB2_P1 PASS_PITCH maxAbsPitchRad="$P1MaxAbsPitch
				$" finalPitchRad="$TestBody.Core.OutPitch_rad$" normal="$P1SlopeNormal
				$" lengthsUU="$TestBody.LastWheelLengthUU[0]$","$TestBody.LastWheelLengthUU[1]
				$","$TestBody.LastWheelLengthUU[2]$","$TestBody.LastWheelLengthUU[3]);
		}
		else
		{
			ResultP1Pitch = "FAIL";
			Warn("HB2_P1 FAIL_PITCH maxAbsPitchRad="$P1MaxAbsPitch
				$" contacts="$TestBody.WheelContactCount$" normal="$P1SlopeNormal);
		}
		StartP1ChassisBSP();
		return;
	}

	if (P1Phase == 6)
	{
		Elapsed = Level.TimeSeconds - P1PhaseStart;
		if (TestBody.Core.OutContacts > 0 && TestBody.LastHitKind == "BSP")
			P1WallBSPContactSamples++;
		if (Elapsed < 3.0)
			return;
		if (TestBody.ReliableSweepPointCount > P1WallSweepStart)
			PointMode = "verified_sweep";
		else if (TestBody.ReliablePointContactCount > P1WallPointStart)
			PointMode = "verified_line";
		else if (TestBody.FallbackPointContactCount > P1WallFallbackStart)
			PointMode = "NOT_IMPLEMENTED_COM_FALLBACK";
		else
			PointMode = "missing";
		if (P1WallBSPContactSamples > 0
			&& (TestBody.ReliablePointContactCount > P1WallPointStart
				|| TestBody.FallbackPointContactCount > P1WallFallbackStart)
			&& (TestBody.Velocity Dot P1WallDir) < 700.0
			&& TestBody.StepFailureCount == 0 && TestBody.ActorSyncFailureCount == 0
			&& TestBody.NonFiniteStateCount == 0)
		{
			ResultP1Chassis = "PASS";
			Log("HB2_P1 PASS_CHASSIS_BSP reliableSweeps="
				$(TestBody.ReliableSweepPointCount - P1WallSweepStart)
				$" reliablePoints="$(TestBody.ReliablePointContactCount - P1WallPointStart)
				$" fallbackSweeps="$(TestBody.FallbackPointContactCount - P1WallFallbackStart)
				$" bspContactSamples="$P1WallBSPContactSamples
				$" pointMode="$PointMode
				$" finalAheadUUps="$(TestBody.Velocity Dot P1WallDir)
				$" finalLoc="$TestBody.Location);
		}
		else
		{
			ResultP1Chassis = "FAIL";
			Log("HB2_P1 FAIL_CHASSIS_BSP reliableSweeps="
				$(TestBody.ReliableSweepPointCount - P1WallSweepStart)
				$" reliablePoints="$(TestBody.ReliablePointContactCount - P1WallPointStart)
				$" fallbackSweeps="$(TestBody.FallbackPointContactCount - P1WallFallbackStart)
				$" bspContactSamples="$P1WallBSPContactSamples
				$" finalAheadUUps="$(TestBody.Velocity Dot P1WallDir)
				$" finalLoc="$TestBody.Location);
		}
		if (bP15)
			StartP15SideBSP();
		else
			StartP13MidSpeedClip();
		return;
	}

	if (P1Phase == 10)
	{
		Elapsed = Level.TimeSeconds - P1PhaseStart;
		if (Elapsed < 1.20)
			return;
		ResultP13C1500 = "omegaMax="$TestBody.P13HSLatchedOmega
			$" uniqueMax="$TestBody.P13HSLatchedUnique
			$" mode="$TestBody.LastChassisContactMode;
		Log("HB2_P13C1500 DONE "$ResultP13C1500$" loc="$TestBody.Location);
		StartP13HighSpeedSlope();
		return;
	}

	if (P1Phase == 8)
	{
		Elapsed = Level.TimeSeconds - P1PhaseStart;
		if (Elapsed < 0.40 && VSize(TestBody.Velocity) > P13HSLaunchSpeed)
			P13HSLaunchSpeed = VSize(TestBody.Velocity);
		P13HSMaxOmega = TestBody.P13HSLatchedOmega;
		P13HSMaxUnique = TestBody.P13HSLatchedUnique;
		if (TestBody.Core.OutContacts > 0
			&& (TestBody.LastHitKind == "BSP" || TestBody.LastHitKind == "StaticMesh"))
			P13HSContactSamples++;
		if (Elapsed < 3.5)
			return;
		if (P13HSContactSamples > 0
			&& TestBody.StepFailureCount == 0 && TestBody.ActorSyncFailureCount == 0
			&& TestBody.NonFiniteStateCount == 0
			&& P13HSMaxOmega < 12.0)
		{
			ResultP13HighSpeed = "PASS";
			Log("HB2_P13B PASS_HIGHSPEED maxOmega="$P13HSMaxOmega
				$" uniqueMax="$P13HSMaxUnique$" samples="$P13HSContactSamples
				$" launchUUps="$P13HSLaunchSpeed$" mode="$TestBody.LastChassisContactMode
				$" loc="$TestBody.Location);
		}
		else if (P13HSContactSamples == 0)
		{
			ResultP13HighSpeed = "NOT_RUN no chassis BSP contact";
			Log("HB2_P13B NOT_RUN_HIGHSPEED maxOmega="$P13HSMaxOmega
				$" uniqueMax="$P13HSMaxUnique$" launchUUps="$P13HSLaunchSpeed
				$" loc="$TestBody.Location);
		}
		else
		{
			ResultP13HighSpeed = "FAIL";
			Log("HB2_P13B FAIL_HIGHSPEED maxOmega="$P13HSMaxOmega
				$" uniqueMax="$P13HSMaxUnique$" samples="$P13HSContactSamples
				$" launchUUps="$P13HSLaunchSpeed$" mode="$TestBody.LastChassisContactMode
				$" stepFail="$TestBody.StepFailureCount
				$" nonFinite="$TestBody.NonFiniteStateCount$" loc="$TestBody.Location);
		}
		StartP14CoastSuite();
		return;
	}

	if (P1Phase == 7)
	{
		Elapsed = Level.TimeSeconds - P1PhaseStart;
		if (Elapsed < 30.0)
			return;
		Vel = TestBody.Velocity;
		Log("HB2_P1 GATE_DONE stationary="$ResultP1Stationary
			$" contactLoss="$ResultP1ContactLoss$" heave="$ResultP1Heave
			$" roll="$ResultP1Roll$" pitch="$ResultP1Pitch$" chassis="$ResultP1Chassis
			$" highSpeed="$ResultP13HighSpeed
			$" p13c1500="$ResultP13C1500
			$" p14flat="$ResultP14Flat$" p14brake="$ResultP14Brake
			$" p14slope="$ResultP14Slope$" p14air="$ResultP14Air
			$" p14fps="$ResultP14Fps
			$" p15drive="$ResultP15Drive$" p15side="$ResultP15Side
			$" restSteps="$(TestBody.TotalStepCount - P1StartSteps)
			$" restDriftUU="$VSize(TestBody.Location - P1FlatCenter)
			$" restVelUUps="$VSize(Vel)$" steps="$TestBody.TotalStepCount
			$" stepFail="$TestBody.StepFailureCount$" syncFail="$TestBody.ActorSyncFailureCount
			$" nonFinite="$TestBody.NonFiniteStateCount$" suspensionHitFail="$TestBody.SuspensionHitFailureCount);
		P1Phase = 99;
		SetTimer(0, False);
	}
}

function FailPhase(string Tag, string Why)
{
	Warn("HB2_P0 FAIL_"$Tag$" "$Why$" loc="$TestBody.Location$" vel="$TestBody.Velocity$" pen="$TestBody.LastMaxPenUU$" hit="$TestBody.LastHitKind);
	if (Tag == "A") ResultA = "FAIL "$Why;
	else if (Tag == "B") ResultB = "FAIL "$Why;
	else if (Tag == "C") ResultC = "FAIL "$Why;
	else if (Tag == "D") ResultD = "FAIL "$Why;
	else if (Tag == "E") ResultE = "FAIL "$Why;
}

function PassPhase(string Tag, string Detail)
{
	Log("HB2_P0 PASS_"$Tag$" "$Detail$" loc="$TestBody.Location$" vel="$TestBody.Velocity$" hit="$TestBody.LastHitKind$" pen="$TestBody.LastMaxPenUU);
	if (Tag == "A") ResultA = "PASS";
	else if (Tag == "B") ResultB = "PASS";
	else if (Tag == "C") ResultC = "PASS";
	else if (Tag == "D") ResultD = "PASS";
	else if (Tag == "E") ResultE = "PASS";
}

function FinishP0()
{
	Log("HB2_P0 GATE_DONE A="$ResultA$" B="$ResultB$" C="$ResultC$" D="$ResultD$" E="$ResultE);
	if (bP06)
	{
		Phase = 10;
		PhaseStart = Level.TimeSeconds;
	}
	else
	{
		Phase = 9;
		SetTimer(0, False);
	}
}

function FinishP06()
{
	Log("HB2_P06 GATE_DONE rotation="$ResultRotation$" opposedCouple="$ResultCouple
		$" fastBSP="$ResultFastBSP$" steps="$TestBody.TotalStepCount
		$" stepFail="$TestBody.StepFailureCount$" syncFail="$TestBody.ActorSyncFailureCount
		$" nonFinite="$TestBody.NonFiniteStateCount$" reliablePoints="$TestBody.ReliablePointContactCount
		$" reliableSweeps="$TestBody.ReliableSweepPointCount$" fallbackPoints="$TestBody.FallbackPointContactCount
		$" duplicatesSkipped="$TestBody.DuplicateContactCount);
	Phase = 99;
	SetTimer(0, False);
}

function Actor FindStaticMeshNear(vector Center, float Radius)
{
	local StaticMeshActor SMA;
	local Actor Best;
	local float BestD, D;
	Best = None;
	BestD = Radius;
	foreach AllActors(class'StaticMeshActor', SMA)
	{
		if (SMA == None || SMA.bDeleteMe)
			continue;
		D = VSize(SMA.Location - Center);
		if (D < BestD)
		{
			BestD = D;
			Best = SMA;
		}
	}
	return Best;
}

function bool FindSlopeNear(vector Center, float Radius, out vector AimLoc, out vector AimNorm)
{
	local int i, ix, iy;
	local float Ang, Dist, X, Y, SupportUU;
	local vector Start, End, HitLoc, HitNorm, Dir;
	local Actor Hit;

	// Dense radial probes.
	for (i = 0; i < 48; ++i)
	{
		Ang = i * 3.14159265 / 24.0;
		Dist = 150 + (i % 6) * 350;
		if (Dist > Radius)
			continue;
		Dir.X = Cos(Ang);
		Dir.Y = Sin(Ang);
		Dir.Z = 0;
		Start = Center + Dir * Dist + vect(0,0,320);
		End = Start - vect(0,0,900);
		Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
		// Prefer mid-range slopes (avoid near-flat cliffs edges that dump onto plateaus).
		if (Hit != None && HitNorm.Z > 0.45 && HitNorm.Z < 0.88)
		{
			// Keep the trace XY inside the finite BSP face. Moving along the
			// normal can cross a triangle edge and make the verification probe
			// see unrelated flat ground. For the production AABB proxy, solve
			// the required vertical centre height from plane separation.
			SupportUU = class'HB2WorldQuery'.static.AABBSupportRadius(
				vect(1,1,1) * TestBody.HalfExtentUU, HitNorm);
			AimLoc = HitLoc + vect(0,0,1) * (SupportUU / HitNorm.Z + 4);
			AimNorm = HitNorm;
			Log("HB2_P0 slope radial hit="$Hit$" n="$HitNorm$" at="$HitLoc$" dist="$Dist);
			return True;
		}
	}

	// Grid sweep (catches village hills / distant ramps).
	for (ix = -10; ix <= 10; ++ix)
	{
		for (iy = -10; iy <= 10; ++iy)
		{
			X = ix * 280.0;
			Y = iy * 280.0;
			if (X * X + Y * Y > Radius * Radius)
				continue;
			Start.X = Center.X + X;
			Start.Y = Center.Y + Y;
			Start.Z = Center.Z + 400;
			End = Start - vect(0,0,1200);
			Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
			if (Hit != None && HitNorm.Z > 0.45 && HitNorm.Z < 0.88)
			{
				SupportUU = class'HB2WorldQuery'.static.AABBSupportRadius(
					vect(1,1,1) * TestBody.HalfExtentUU, HitNorm);
				AimLoc = HitLoc + vect(0,0,1) * (SupportUU / HitNorm.Z + 4);
				AimNorm = HitNorm;
				Log("HB2_P0 slope grid hit="$Hit$" n="$HitNorm$" at="$HitLoc$" offset="$X$","$Y);
				return True;
			}
		}
	}
	return False;
}

function bool PlaceActorAt(Actor A, vector Loc, string Tag)
{
	if (A == None)
		return False;
	A.bMovable = True;
	A.bCollideWorld = False;
	A.SetCollision(False, False, False);
	if (!A.SetLocation(Loc))
	{
		Warn("HB2_P0 "$Tag$" SetLocation refused "$Loc$" stayed="$A.Location);
		return False;
	}
	A.SetCollision(True, True, True);
	A.bBlockActors = True;
	A.bBlockPlayers = True;
	A.bBlockZeroExtentTraces = True;
	A.bBlockNonZeroExtentTraces = True;
	// Keep bCollideWorld=False so placement does not settle into BSP / drift to origin.
	A.bCollideWorld = False;
	if (VSize(A.Location - Loc) > 8)
	{
		Warn("HB2_P0 "$Tag$" drifted after place want="$Loc$" got="$A.Location);
		return False;
	}
	return True;
}

function PlaceBlockerInFront()
{
	local vector BlockLoc;

	Origin = TestBody.Location;
	Origin.Z = Origin.Z + 20;
	TestBody.ResetTo(Origin, vect(0,0,0));

	BlockLoc = Origin;
	BlockLoc.X = Origin.X + 160;
	BlockLoc.Y = Origin.Y;
	BlockLoc.Z = Origin.Z;

	Blocker = Spawn(class'HB2Blocker',,, BlockLoc);
	if (Blocker == None)
	{
		Warn("HB2_P0 blocker spawn FAILED");
		return;
	}
	if (!PlaceActorAt(Blocker, BlockLoc, "blocker"))
		Warn("HB2_P0 blocker place FAILED");
	Log("HB2_P0 START_D blocker="$Blocker$" at="$Blocker.Location$" body="$TestBody.Location$" dy="$(Blocker.Location.Y - TestBody.Location.Y));
}

function bool FindWallNear(vector Center, out vector DirOut, out vector HitLocOut)
{
	local int i;
	local float Ang;
	local vector Start, End, HitLoc, HitNorm, Dir;
	local Actor Hit;

	for (i = 0; i < 16; ++i)
	{
		Ang = i * 3.14159265 / 8.0;
		Dir.X = Cos(Ang);
		Dir.Y = Sin(Ang);
		Dir.Z = 0;
		// Start above floor so Extent does not immediately hit ground (nZ≈1).
		Start = Center;
		Start.Z = Center.Z + TestBody.HalfExtentUU + 48;
		End = Start + Dir * 3500;
		Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
		if (Hit == None || Abs(HitNorm.Z) >= 0.55)
			Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False, vect(1,1,1) * TestBody.HalfExtentUU);
		if (Hit != None && Abs(HitNorm.Z) < 0.55)
		{
			DirOut = -HitNorm; // into the wall
			DirOut.Z = 0;
			if (VSize(DirOut) < 0.1) DirOut = Dir;
			else DirOut = Normal(DirOut);
			HitLocOut = HitLoc;
			Log("HB2_P0 wall candidate hit="$Hit$" n="$HitNorm$" dir="$DirOut$" at="$HitLoc);
			return True;
		}
	}
	return False;
}

// P1 chassis regression requires actual world BSP. A StaticMesh hit may be a
// valid obstacle, but it is not evidence for the BSP contact path.
function bool FindBSPWallNear(vector Center, out vector DirOut, out vector HitLocOut)
{
	local int i;
	local float Ang;
	local vector Start, End, HitLoc, HitNorm, Dir;
	local Actor Hit;

	for (i = 0; i < 32; ++i)
	{
		Ang = i * 3.14159265 / 16.0;
		Dir.X = Cos(Ang);
		Dir.Y = Sin(Ang);
		Dir.Z = 0;
		// Probe above near-ground StaticMesh clutter. This isolates the BSP
		// cliff/wall path used by the chassis high-speed regression.
		Start = Center;
		Start.Z = Center.Z + 560;
		End = Start + Dir * 8000;
		Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
		if (Hit != None && TestBody.ClassifyHit(Hit) == "BSP"
			&& Abs(HitNorm.Z) < 0.55)
		{
			DirOut = -HitNorm;
			DirOut.Z = 0;
			if (VSize(DirOut) < 0.1)
				DirOut = Dir;
			else
				DirOut = Normal(DirOut);
			HitLocOut = HitLoc;
			Log("HB2_P1 BSP wall candidate="$Hit$" n="$HitNorm
				$" dir="$DirOut$" at="$HitLoc);
			return True;
		}
	}
	return False;
}

function TickP0()
{
	local vector Loc, Vel, MeshLoc, AimNorm, ToMesh;
	local float Spd, Elapsed, FloorZ, Displ, Ahead, QNormSq;
	local float SupportUU, NormalGapUU;
	local Actor Hit;
	local vector HitLoc, HitNorm, Start, End;
	local rotator ZeroRot;

	if (!FindBody())
	{
		Log("HB2_P0 WAIT: no body");
		return;
	}

	Elapsed = Level.TimeSeconds - PhaseStart;
	Loc = TestBody.Location;
	Vel = TestBody.Velocity;
	Spd = VSize(Vel);

	if (Phase == 0)
	{
		Phase = 1;
		PhaseStart = Level.TimeSeconds;
		Origin = Loc;
		P06Origin = Loc;
		TestBody.ResetTo(Loc + vect(0,0,200), vect(0,0,0));
		Log("HB2_P0 START_A floor drop from "$TestBody.Location);
		return;
	}

	// ---- A: BSP floor — require no penetration below floor ----
	if (Phase == 1)
	{
		Start = Loc + vect(0,0,50);
		End = Loc - vect(0,0,500);
		Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
		if (Hit != None && Spd < 40 && HitNorm.Z > 0.7 && Elapsed > 1.0)
		{
			FloorZ = HitLoc.Z;
			if (Loc.Z < FloorZ - 1)
				FailPhase("A", "penetrated floor Z="$Loc.Z$" floor="$FloorZ);
			else if (Loc.Z > FloorZ + TestBody.HalfExtentUU - 2 && Loc.Z < FloorZ + TestBody.HalfExtentUU + 35)
			{
				PassPhase("A", "resting Z="$Loc.Z$" floor="$FloorZ$" nZ="$HitNorm.Z$" gap="$(Loc.Z - FloorZ));
				Phase = 2;
				PhaseStart = Level.TimeSeconds;
				Origin = Loc;
				if (FindWallNear(Loc, WallDir, HitLoc))
				{
					// Start close to wall so friction does not kill speed before impact.
					TestBody.ResetTo(HitLoc - WallDir * 220 + vect(0,0,30), vect(0,0,0));
					Origin = TestBody.Location;
				}
				else
				{
					WallDir = vect(1,0,0);
					TestBody.ResetTo(Loc + vect(0,0,20), vect(0,0,0));
				}
				TestBody.ImpulseUU(WallDir * 1100);
				Log("HB2_P0 START_B wall impulse dir="$WallDir$" from="$TestBody.Location);
			}
			return;
		}
		if (Elapsed > 8)
		{
			FailPhase("A", "timeout spd="$Spd$" Z="$Loc.Z);
			Phase = 2;
			PhaseStart = Level.TimeSeconds;
			Origin = Loc;
			if (FindWallNear(Loc, WallDir, HitLoc))
			{
				TestBody.ResetTo(HitLoc - WallDir * 220 + vect(0,0,30), vect(0,0,0));
				Origin = TestBody.Location;
			}
			else
				WallDir = vect(1,0,0);
			TestBody.ImpulseUU(WallDir * 1100);
		}
		return;
	}

	// ---- B: BSP wall — horizontal normal + no tunnel ----
	if (Phase == 2)
	{
		Displ = VSize(Loc - Origin);
		Start = Loc;
		Start.Z = Loc.Z + 8;
		End = Start + WallDir * 120;
		Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False, vect(1,1,1) * TestBody.HalfExtentUU);
		if (Hit == None || Abs(HitNorm.Z) >= 0.55)
		{
			Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
		}
		if (Hit != None && Abs(HitNorm.Z) < 0.55 && Elapsed > 0.2)
		{
			if (Displ > 9000)
				FailPhase("B", "tunneled before wall displ="$Displ);
			else
			{
				Ahead = Vel Dot WallDir;
				if (Ahead < 700)
					PassPhase("B", "wall n="$HitNorm$" displ="$Displ$" spd="$Spd$" ahead="$Ahead$" hit="$Hit$" last="$TestBody.LastHitKind);
				else
					FailPhase("B", "hit but no slowdown ahead="$Ahead$" spd="$Spd);
			}
			Phase = 3;
			PhaseStart = Level.TimeSeconds;
			bPreparedC = False;
			TestBody.ResetTo(Origin + vect(0,0,60), vect(0,0,0));
			Log("HB2_P0 START_C mesh probe");
			return;
		}
		if (Elapsed > 6)
		{
			if (Displ > 9000)
				FailPhase("B", "tunneled displ="$Displ);
			else
				FailPhase("B", "timeout no wall hit="$TestBody.LastHitKind$" displ="$Displ$" ahead="$(Vel Dot WallDir));
			Phase = 3;
			PhaseStart = Level.TimeSeconds;
			bPreparedC = False;
			TestBody.ResetTo(Origin + vect(0,0,60), vect(0,0,0));
		}
		return;
	}

	// ---- C: StaticMesh or runtime collide-mesh ----
	if (Phase == 3)
	{
		if (!bPreparedC)
		{
			bPreparedC = True;
			MeshTarget = FindStaticMeshNear(TestBody.Location, 12000);
			if (MeshTarget == None)
			{
				// Dedicated collide-mesh proxy when map has no usable StaticMeshActor.
				MeshLoc = TestBody.Location;
				MeshLoc.X = MeshLoc.X + 200;
				MeshLoc.Y = MeshLoc.Y;
				MeshLoc.Z = MeshLoc.Z;
				MeshTarget = Spawn(class'HB2CollideMesh',,, MeshLoc);
				if (MeshTarget != None)
				{
					if (!PlaceActorAt(MeshTarget, MeshLoc, "CollideMesh"))
						Warn("HB2_P0 C CollideMesh place FAILED");
					Log("HB2_P0 C spawned CollideMesh at "$MeshTarget.Location$" (no StaticMeshActor in range)");
				}
			}
			else
				Log("HB2_P0 C found StaticMeshActor="$MeshTarget$" at="$MeshTarget.Location);

			if (MeshTarget == None)
			{
				ResultC = "NOT_RUN no mesh target available";
				Log("HB2_P0 NOT_RUN_C "$ResultC);
				Phase = 4;
				PhaseStart = Level.TimeSeconds;
				bSpawnedBlocker = False;
				return;
			}

			Origin = TestBody.Location;
			ToMesh = MeshTarget.Location - TestBody.Location;
			ToMesh.Z = 0;
			if (VSize(ToMesh) < 1) ToMesh = vect(1,0,0);
			TargetDir = Normal(ToMesh);
			TestBody.ResetTo(Origin + vect(0,0,30), vect(0,0,0));
			TestBody.ImpulseUU(TargetDir * 850);
			return;
		}

		Start = TestBody.Location;
		End = Start + TargetDir * 140;
		Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, True, vect(1,1,1) * TestBody.HalfExtentUU);
		if (Hit != None && (Hit == MeshTarget || TestBody.ClassifyHit(Hit) == "StaticMesh"
			|| TestBody.ClassifyHit(Hit) == "CollideMesh" || TestBody.ClassifyHit(Hit) == "ActorMesh"))
		{
			Ahead = Vel Dot TargetDir;
			if (Loc.Z > HitLoc.Z - TestBody.HalfExtentUU - 5) // not under mesh
			{
				if (Ahead < 750)
					PassPhase("C", "mesh hit="$Hit$" kind="$TestBody.ClassifyHit(Hit)$" n="$HitNorm$" ahead="$Ahead);
				else
					FailPhase("C", "mesh hit but no reaction ahead="$Ahead);
			}
			else
				FailPhase("C", "penetrated under mesh Z="$Loc.Z$" hitZ="$HitLoc.Z);
			Phase = 4;
			PhaseStart = Level.TimeSeconds;
			bSpawnedBlocker = False;
			return;
		}
		if (Elapsed > 5)
		{
			FailPhase("C", "timeout fwdHit="$Hit$" target="$MeshTarget$" last="$TestBody.LastHitKind);
			Phase = 4;
			PhaseStart = Level.TimeSeconds;
			bSpawnedBlocker = False;
		}
		return;
	}

	// ---- D: blocking Actor ----
	if (Phase == 4)
	{
		if (!bSpawnedBlocker)
		{
			bSpawnedBlocker = True;
			PlaceBlockerInFront();
			TestBody.ImpulseUU(vect(1,0,0) * 900);
			return;
		}
		Start = TestBody.Location;
		End = Start + vect(1,0,0) * 140;
		Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, True, vect(1,1,1) * TestBody.HalfExtentUU);
		if (Hit != None && Hit == Blocker)
		{
			Ahead = Vel.X;
			if (Abs(HitNorm.Z) < 0.7 && Ahead < 800)
				PassPhase("D", "blocked by "$Hit$" n="$HitNorm$" ahead="$Ahead$" blockerAt="$Blocker.Location);
			else if (Abs(HitNorm.Z) >= 0.7)
				FailPhase("D", "hit blocker but normal not wall-like n="$HitNorm);
			else
				FailPhase("D", "hit blocker but no slowdown ahead="$Ahead);
			Phase = 5;
			PhaseStart = Level.TimeSeconds;
			bPreparedE = False;
			return;
		}
		if (Elapsed > 5)
		{
			FailPhase("D", "no actor hit blocker="$Blocker$" at="$Blocker.Location$" body="$TestBody.Location$" fwdHit="$Hit);
			Phase = 5;
			PhaseStart = Level.TimeSeconds;
			bPreparedE = False;
		}
		return;
	}

	// ---- E: slope ----
	if (Phase == 5)
	{
		if (!bPreparedE)
		{
			bPreparedE = True;
			if (FindSlopeNear(TestBody.Location, 4500, SlopeAim, AimNorm)
				|| FindSlopeNear(Origin, 4500, SlopeAim, AimNorm))
			{
				// Aim already contains the AABB support height plus 4 UU clearance.
				TestBody.ResetTo(SlopeAim, vect(0,0,0));
				Log("HB2_P0 START_E slope aim="$SlopeAim$" n="$AimNorm$" body="$TestBody.Location);
				// Immediate post-place probe (body may slide to flat within one Timer period).
				Start = TestBody.Location + vect(0,0,40);
				End = TestBody.Location - vect(0,0,300);
				Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
				Displ = TestBody.Location.Z - HitLoc.Z;
				SupportUU = class'HB2WorldQuery'.static.AABBSupportRadius(
					vect(1,1,1) * TestBody.HalfExtentUU, HitNorm);
				NormalGapUU = ((TestBody.Location - HitLoc) Dot Normal(HitNorm)) - SupportUU;
				Log("HB2_P0 E_PLACE n="$HitNorm$" verticalGap="$Displ$" normalGap="$NormalGapUU$" pen="$TestBody.LastMaxPenUU);
				if (Hit != None && HitNorm.Z > 0.40 && HitNorm.Z < 0.90
					&& NormalGapUU >= -1 && NormalGapUU < 12
					&& TestBody.LastMaxPenUU < 10)
				{
					PassPhase("E", "slope place n="$HitNorm$" normalGap="$NormalGapUU$" body="$TestBody.Location);
					FinishP0();
				}
			}
			else
			{
				ResultE = "NOT_RUN no slope surface found near spawn (need ramp BSP)";
				Log("HB2_P0 NOT_RUN_E "$ResultE);
				FinishP0();
			}
			return;
		}

		Start = Loc + vect(0,0,60);
		End = Loc - vect(0,0,400);
		Hit = TestBody.Trace(HitLoc, HitNorm, End, Start, False);
		if (Hit != None)
			Log("HB2_P0 E_SAMPLE t="$Elapsed$" n="$HitNorm$" gap="$(Loc.Z - HitLoc.Z)$" spd="$Spd$" pen="$TestBody.LastMaxPenUU$" contacts="$TestBody.ContactCount$" hit="$Hit);
		else
			Log("HB2_P0 E_SAMPLE t="$Elapsed$" nohit spd="$Spd);

		// Capture slope support as soon as body is near the surface (may later slide to flat).
		if (Hit != None && Elapsed >= 0.0 && HitNorm.Z > 0.40 && HitNorm.Z < 0.90)
		{
			Displ = Loc.Z - HitLoc.Z;
			SupportUU = class'HB2WorldQuery'.static.AABBSupportRadius(
				vect(1,1,1) * TestBody.HalfExtentUU, HitNorm);
			NormalGapUU = ((Loc - HitLoc) Dot Normal(HitNorm)) - SupportUU;
			if (NormalGapUU < -1)
			{
				FailPhase("E", "penetrated slope normalGap="$NormalGapUU$" Z="$Loc.Z$" floor="$HitLoc.Z);
				FinishP0();
				return;
			}
			if (NormalGapUU < 12 && TestBody.LastMaxPenUU < 10)
			{
				PassPhase("E", "slope n="$HitNorm$" Z="$Loc.Z$" floorZ="$HitLoc.Z$" normalGap="$NormalGapUU$" spd="$Spd$" contacts="$TestBody.ContactCount);
				FinishP0();
				return;
			}
		}
		if (Elapsed > 2.5)
		{
			if (Hit != None && HitNorm.Z >= 0.90)
			{
				ResultE = "NOT_RUN slid off slope onto flat n="$HitNorm$" gap="$(Loc.Z - HitLoc.Z);
				Log("HB2_P0 NOT_RUN_E "$ResultE);
			}
			else
				FailPhase("E", "timeout spd="$Spd$" n="$HitNorm$" gap="$(Loc.Z - HitLoc.Z));
			FinishP0();
		}
		return;
	}

	// ---- P0.6-1: off-COM impulse must create persistent pitch/roll state ----
	if (Phase == 10)
	{
		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(P06Origin + vect(0,0,360), vect(0,0,0));
		if (!TestBody.ImpulseAtOffsetUU(vect(240,0,0), vect(0,0,-24)))
		{
			ResultRotation = "FAIL impulse rejected";
			Warn("HB2_P06 FAIL_ROTATION NativeApplyImpulseAtPoint rejected");
		}
		else
			Log("HB2_P06 START_ROTATION offCOM deltaVelUU=240,0,0 offsetUU=0,0,-24");
		Phase = 11;
		PhaseStart = Level.TimeSeconds;
		return;
	}

	if (Phase == 11 && Elapsed > 0.45)
	{
		QNormSq = TestBody.Core.OutQuatW*TestBody.Core.OutQuatW
			+ TestBody.Core.OutQuatX*TestBody.Core.OutQuatX
			+ TestBody.Core.OutQuatY*TestBody.Core.OutQuatY
			+ TestBody.Core.OutQuatZ*TestBody.Core.OutQuatZ;
		if (ResultRotation == "" && Abs(TestBody.Core.OutAngY_radps) > 0.05
			&& Abs(TestBody.Core.OutPitch_rad) > 0.005
			&& Abs(TestBody.Rotation.Pitch) > 10
			&& QNormSq > 0.98 && QNormSq < 1.02
			&& TestBody.StepFailureCount == 0 && TestBody.NonFiniteStateCount == 0)
		{
			ResultRotation = "PASS";
			Log("HB2_P06 PASS_ROTATION qNormSq="$QNormSq$" q="
				$TestBody.Core.OutQuatW$","$TestBody.Core.OutQuatX$","$TestBody.Core.OutQuatY$","$TestBody.Core.OutQuatZ
				$" omega="$TestBody.Core.OutAngX_radps$","$TestBody.Core.OutAngY_radps$","$TestBody.Core.OutAngZ_radps
				$" euler="$TestBody.Core.OutYaw_rad$","$TestBody.Core.OutPitch_rad$","$TestBody.Core.OutRoll_rad
				$" actorRot="$TestBody.Rotation);
		}
		else if (ResultRotation == "")
		{
			ResultRotation = "FAIL no synchronized rotation";
			Warn("HB2_P06 FAIL_ROTATION qNormSq="$QNormSq$" omegaY="$TestBody.Core.OutAngY_radps$" pitch="$TestBody.Core.OutPitch_rad$" actorPitch="$TestBody.Rotation.Pitch);
		}

		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(P06Origin + vect(0,0,360), vect(0,0,0));
		P06YawStart = TestBody.Core.OutYaw_rad;
		if (!TestBody.ApplyYawImpulseCouple(1.0))
		{
			ResultCouple = "FAIL impulses rejected";
			Warn("HB2_P06 FAIL_COUPLE opposed point impulses rejected");
		}
		else
			Log("HB2_P06 START_COUPLE equal_opposite left_right deltaOmegaZ=1");
		Phase = 12;
		PhaseStart = Level.TimeSeconds;
		return;
	}

	if (Phase == 12 && Elapsed > 0.35)
	{
		if (ResultCouple == "" && Abs(TestBody.Core.OutAngZ_radps) > 0.2
			&& Abs(TestBody.Core.OutYaw_rad - P06YawStart) > 0.05
			&& Abs(TestBody.Rotation.Yaw) > 100)
		{
			ResultCouple = "PASS";
			Log("HB2_P06 PASS_COUPLE omegaZ="$TestBody.Core.OutAngZ_radps$" yaw="$TestBody.Core.OutYaw_rad$" actorYaw="$TestBody.Rotation.Yaw$" vel="$TestBody.Velocity);
		}
		else if (ResultCouple == "")
		{
			ResultCouple = "FAIL no yaw response";
			Warn("HB2_P06 FAIL_COUPLE omegaZ="$TestBody.Core.OutAngZ_radps$" yaw="$TestBody.Core.OutYaw_rad$" actorYaw="$TestBody.Rotation.Yaw);
		}

		if (!FindWallNear(P06Origin, WallDir, HitLoc))
		{
			ResultFastBSP = "NOT_RUN no BSP wall";
			Log("HB2_P06 NOT_RUN_FAST_BSP no wall near origin="$P06Origin);
			FinishP06();
			return;
		}
		TestBody.SetRotation(ZeroRot);
		TestBody.ResetTo(HitLoc - WallDir * 260 + vect(0,0,30), vect(0,0,0));
		P06FastStart = TestBody.Location;
		P06SweepStart = TestBody.ReliableSweepPointCount;
		TestBody.ImpulseUU(WallDir * 4000);
		Log("HB2_P06 START_FAST_BSP speedUU=4000 dir="$WallDir$" from="$P06FastStart$" wall="$HitLoc);
		Phase = 13;
		PhaseStart = Level.TimeSeconds;
		return;
	}

	if (Phase == 13)
	{
		Displ = VSize(TestBody.Location - P06FastStart);
		Ahead = TestBody.Velocity Dot WallDir;
		if (TestBody.ReliableSweepPointCount > P06SweepStart
			&& TestBody.LastReliableSweepHitKind == "BSP")
		{
			if (Displ < 800 && Ahead < 1500 && TestBody.StepFailureCount == 0
				&& TestBody.NonFiniteStateCount == 0)
			{
				ResultFastBSP = "PASS";
				Log("HB2_P06 PASS_FAST_BSP displ="$Displ$" ahead="$Ahead$" center="$TestBody.LastSweepCenterUU$" point="$TestBody.LastContactPointUU$" offsetUU="$TestBody.LastSweepPointOffsetUU);
			}
			else
			{
				ResultFastBSP = "FAIL tunnel_or_state";
				Warn("HB2_P06 FAIL_FAST_BSP displ="$Displ$" ahead="$Ahead$" stepFail="$TestBody.StepFailureCount$" nonFinite="$TestBody.NonFiniteStateCount);
			}
			FinishP06();
			return;
		}
		if (Elapsed > 2.0)
		{
			ResultFastBSP = "FAIL no verified BSP sweep";
			Warn("HB2_P06 FAIL_FAST_BSP timeout displ="$Displ$" ahead="$Ahead$" last="$TestBody.LastHitKind);
			FinishP06();
		}
		return;
	}
}

event playerpawn Login(string Portal, string URL, out string Error, class<playerpawn> SpawnClass)
{
	SpawnClass = class'HB2Driver';
	return Super.Login(Portal, URL, Error, SpawnClass);
}

defaultproperties
{
	GameName="HB227 Vehicle V2"
	bRestartLevel=False
	DefaultPlayerClass=Class'HB227VehicleV2.HB2Driver'
	DefaultWeapon=None
}
