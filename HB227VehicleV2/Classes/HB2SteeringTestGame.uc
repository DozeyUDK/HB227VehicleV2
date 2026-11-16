class HB2SteeringTestGame expands HB2TestGame;

var bool bTestUnderPower, bTestTerrain;
var float TestGas, TestCornerAccel, TestSteer;

event InitGame(string Options, out string Error)
{
	Super.InitGame(Options, Error);
	bTestUnderPower = ParseOption(Options, "hb2power") == "1";
	TestGas = FClamp(float(ParseOption(Options, "hb2gas")), 0.0, 1.0);
	if (bTestUnderPower && TestGas <= 0.0)
		TestGas = 0.35;
	TestCornerAccel = FClamp(float(ParseOption(Options, "hb2accel")), 0.0, 8.0);
	TestSteer = float(ParseOption(Options, "hb2steer"));
	if (TestSteer <= 0.0 || TestSteer > 1.0)
		TestSteer = 1.0;
	bTestTerrain = ParseOption(Options, "hb2terrain") == "1";
}

// A dedicated, local test game. The stock HB2TestGame remains the manual entry point.
function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0.25, False);
}

function bool FindLane(vector Anchor, int Yaw, out vector Start, out rotator Heading)
{
	local vector Along, Across, Pos, HitLoc, HitNorm;
	local float FloorZ;
	local int i, j;

	Heading.Yaw = Yaw;
	Along = vector(Heading);
	Across = vect(0,0,1) Cross Along;
	for (i = -1; i <= 8; ++i)
	{
		for (j = -2; j <= 2; ++j)
		{
			Pos = Anchor + Along * (i * 180.0) + Across * (j * 170.0);
			if (Trace(HitLoc, HitNorm, Pos - vect(0,0,250),
				Pos + vect(0,0,200), False, vect(0,0,0), True, 0, 6) == None
				|| HitNorm.Z < 0.995)
				return False;
			if (i == -1 && j == -2)
				FloorZ = HitLoc.Z;
			else if (Abs(HitLoc.Z - FloorZ) > 1.0)
				return False;
			if (Trace(HitLoc, HitNorm, Pos + vect(0,0,155),
				Pos + vect(0,0,25), False, vect(0,0,0), True, 0, 6) != None)
				return False;
		}
	}
	Start = Anchor;
	Start.Z = FloorZ;
	return True;
}

function bool LocateLane(out vector Start, out rotator Heading)
{
	local PlayerStart PS;
	local vector Anchor;
	local int X, Y, Turn;

	// First try the level floor found in the SpireVillage manual trace.
	if (Left(string(Level), Len("SpireVillage")) ~= "SpireVillage")
	{
		Anchor.X = -17280;
		Anchor.Y = 14370;
		Anchor.Z = -7884.5;
		if (FindLane(Anchor, 0, Start, Heading))
			return True;
	}
	foreach AllActors(class'PlayerStart', PS)
	{
		for (X = -3; X <= 3; ++X)
			for (Y = -3; Y <= 3; ++Y)
			{
				Anchor = PS.Location;
				Anchor.X += X * 240;
				Anchor.Y += Y * 240;
				for (Turn = 0; Turn < 4; ++Turn)
					if (FindLane(Anchor, Turn * 16384, Start, Heading))
						return True;
			}
	}
	return False;
}

function float MotionAngle(vector FromVel, vector ToVel)
{
	local float Along, Across;
	FromVel.Z = 0;
	ToVel.Z = 0;
	FromVel = Normal(FromVel);
	ToVel = Normal(ToVel);
	Along = FromVel Dot ToVel;
	FromVel = FromVel Cross ToVel;
	Across = FromVel.Z;
	if (Along <= 0.0)
		return 0.0;
	return Atan(Across / Along);
}

function float MeasureTurn(float Kmh, float Steer, vector Start, rotator Heading)
{
	local vector Forward, Vel, PreviousVel, PosM, Nudge;
	local float DT, TargetMps, Speed, Assist, Angle, Distance, MinSpeed, MaxSpeed;
	local float FrontTorque, RearTorque, AngleStep, Radius;
	local int i, Samples, Bad, InitialFailures;

	DT = 1.0 / 60.0;
	TargetMps = Kmh / 3.6;
	Forward = vector(Heading);
	// Begin each run with a fresh body and independent tyre/drivetrain state.
	if (TestBody != None)
		TestBody.Destroy();
	TestBody = Spawn(class'HB2Body',,, Start, Heading);
	if (TestBody == None || !TestBody.bReady)
	{
		Log("HB2_STEER_RUN kmh="$Kmh$" steer="$Steer$" result=SPAWN_FAIL");
		return 0.0;
	}
	TestBody.bPawnCrushEnabled = False;
	TestBody.bMeasureTireYaw = True;
	if (TestCornerAccel > 0.0)
	{
		TestBody.MaxCorneringAccelMps2 = TestCornerAccel;
		TestBody.HighSpeedCorneringAccelMps2 = TestCornerAccel;
	}
	TestBody.ResetTo(Start, Forward * class'HB2WorldQuery'.static.MToUU(TargetMps));
	// The vehicle starts already moving. Seed the matching rolling wheel
	// speed and engaged gear so the test does not begin with a clutch dump.
	if (TestGas > 0.0)
	{
		for (i = 0; i < 4; ++i)
			TestBody.WheelOmegaRadps[i] = TargetMps
				/ class'HB2WorldQuery'.static.UUToM(TestBody.WheelRadiusUU[i]);
		TestBody.ForwardGear = 2;
		if (Kmh >= 28.44)
			TestBody.ForwardGear = 3;
		if (Kmh >= 37.44)
			TestBody.ForwardGear = 4;
		TestBody.LastEngagedDirection = 1;
	}
	InitialFailures = TestBody.StepFailureCount + TestBody.ActorSyncFailureCount
		+ TestBody.NonFiniteStateCount;
	MinSpeed = 100.0;
	for (i = 0; i < 114; ++i)
	{
		Vel = TestBody.Velocity;
		Vel.Z = 0;
		Speed = class'HB2WorldQuery'.static.UUToM(VSize(Vel));
		// The speed controller acts at COM along the current path.
		// Powered runs keep drive torque active while COM speed is regulated.
		Assist = FClamp((TargetMps - Speed) * 14.0, -7.0, 7.0);
		Nudge = Normal(Vel) * (Assist * TestBody.MassKg * DT);
		PosM = class'HB2WorldQuery'.static.UUToMVec(TestBody.Location);
		if (!TestBody.Core.NativeApplyImpulseAtPoint(
			Nudge.X, Nudge.Y, Nudge.Z, PosM.X, PosM.Y, PosM.Z))
			Bad++;
		if (i >= 12)
			TestBody.LastSteer = Steer * TestSteer;
		TestBody.LastGas = TestGas;
		TestBody.PumpPhysics(DT, DT);
		if (i >= 30 && i % 15 == 0)
			Log("HB2_STEER_SAMPLE kmh="$Kmh$" steer="$Steer$" step="$i
				$" speedMps="$Speed$" frontNm="$TestBody.LastFrontTireYawNm
				$" rearNm="$TestBody.LastRearTireYawNm
				$" yawRadps="$TestBody.Core.OutAngZ_radps
				$" steerRad="$TestBody.LastEffectiveSteerRad
				$" wheels="$TestBody.LastCoastGroundWheels$" contacts="$TestBody.ContactCount);
		if (i >= 30)
		{
			if (TestBody.LastCoastGroundWheels != 4 || TestBody.ContactCount != 0)
				Bad++;
			AngleStep = MotionAngle(PreviousVel, Vel) * Steer;
			Angle += AngleStep;
			Distance += Speed * DT;
			MinSpeed = FMin(MinSpeed, Speed);
			MaxSpeed = FMax(MaxSpeed, Speed);
			FrontTorque += TestBody.LastFrontTireYawNm;
			RearTorque += TestBody.LastRearTireYawNm;
			Samples++;
		}
		PreviousVel = Vel;
	}
	if (Angle > 0.01)
		Radius = Distance / Angle;
	if (TestBody.StepFailureCount + TestBody.ActorSyncFailureCount
		+ TestBody.NonFiniteStateCount != InitialFailures)
		Bad++;
	if (Abs(MinSpeed - TargetMps) > 0.6 || Abs(MaxSpeed - TargetMps) > 0.6)
		Bad++;
	Log("HB2_STEER_RUN kmh="$Kmh$" steer="$Steer$" radiusM="$Radius
		$" minKmh="$(MinSpeed * 3.6)$" maxKmh="$(MaxSpeed * 3.6)
		$" frontMeanNm="$(FrontTorque / Samples)$" rearMeanNm="$(RearTorque / Samples)
		$" invalidSteps="$Bad$" samples="$Samples);
	if (Bad != 0)
		return 0.0;
	return Radius;
}

function Timer()
{
	local vector Start;
	local rotator Heading;
	local float L20, L35, L48, R20, R35, R48;
	local bool bPass;

	if (bTestTerrain)
	{
		RunTerrain();
		return;
	}
	if (!LocateLane(Start, Heading))
	{
		Log("HB2_STEER_GATE result=NO_FLAT_LANE");
		return;
	}
	TestBody = Spawn(class'HB2Body',,, Start + vect(0,0,100), Heading);
	if (TestBody == None || !TestBody.bReady)
	{
		Log("HB2_STEER_GATE result=SPAWN_FAIL");
		return;
	}
	Start.Z += TestBody.ChassisSpawnHeightUU();
	TestBody.Destroy();
	TestBody = None;
	Log("HB2_STEER_SITE start="$Start$" heading="$Heading$" gas="$TestGas$" cornerAccel="$TestCornerAccel$" demand="$TestSteer);
	L20 = MeasureTurn(20.0, -1.0, Start, Heading);
	L35 = MeasureTurn(35.0, -1.0, Start, Heading);
	L48 = MeasureTurn(48.0, -1.0, Start, Heading);
	R20 = MeasureTurn(20.0, 1.0, Start, Heading);
	R35 = MeasureTurn(35.0, 1.0, Start, Heading);
	R48 = MeasureTurn(48.0, 1.0, Start, Heading);
	bPass = L20 > 0.0 && L35 > L20 && L48 > L35
		&& R20 > 0.0 && R35 > R20 && R48 > R35;
	Log("HB2_STEER_GATE pass="$bPass$" left="$L20$","$L35$","$L48
		$" right="$R20$","$R35$","$R48);
}

function MeasureTerrain(string Tag, vector Anchor, int Yaw, float Kmh, float Steer, float Gas, int Steps)
{
	local vector Floor, N, Pos, Vel, Start;
	local rotator Heading;
	local float DT, Speed, PreSpeed, FirstContactAt, FirstLossAt;
	local float MaxRoll, MaxYaw, PreContactRoll, SpeedAfter, MaxPen;
	local int i, MinWheels, Hits, Failures;

	if (Trace(Floor, N, Anchor - vect(0,0,280), Anchor + vect(0,0,200),
		False, vect(0,0,0), True, 0, 6) == None || N.Z < 0.95)
	{
		Log("HB2_TERRAIN_RUN case="$Tag$" result=BAD_START");
		return;
	}
	if (TestBody != None)
		TestBody.Destroy();
	Heading.Yaw = Yaw;
	TestBody = Spawn(class'HB2Body',,, Floor + vect(0,0,126), Heading);
	if (TestBody == None || !TestBody.bReady)
	{
		Log("HB2_TERRAIN_RUN case="$Tag$" result=SPAWN_FAIL");
		return;
	}
	TestBody.bPawnCrushEnabled = False;
	TestBody.bMeasureTireYaw = True;
	if (TestCornerAccel > 0.0)
	{
		TestBody.MaxCorneringAccelMps2 = TestCornerAccel;
		TestBody.HighSpeedCorneringAccelMps2 = TestCornerAccel;
	}
	Start = Floor;
	Start.Z += TestBody.ChassisSpawnHeightUU();
	DT = 1.0 / 60.0;
	TestBody.ResetTo(Start, vector(Heading) * class'HB2WorldQuery'.static.MToUU(Kmh / 3.6));
	FirstContactAt = -1.0;
	FirstLossAt = -1.0;
	MinWheels = 4;
	for (i = 0; i < Steps; i++)
	{
		Vel = TestBody.Velocity;
		Vel.Z = 0;
		PreSpeed = class'HB2WorldQuery'.static.UUToM(VSize(Vel)) * 3.6;
		TestBody.LastSteer = 0.0;
		if (i >= 10)
			TestBody.LastSteer = Steer * TestSteer;
		TestBody.LastGas = Gas;
		TestBody.PumpPhysics(DT, DT);
		Vel = TestBody.Velocity;
		Vel.Z = 0;
		Speed = class'HB2WorldQuery'.static.UUToM(VSize(Vel)) * 3.6;
		Pos = TestBody.Location;
		MaxRoll = FMax(MaxRoll, Abs(TestBody.Core.OutRoll_rad));
		MaxYaw = FMax(MaxYaw, Abs(TestBody.Core.OutAngZ_radps));
		MaxPen = FMax(MaxPen, TestBody.LastMaxPenUU);
		if (i >= 10 && TestBody.LastCoastGroundWheels < MinWheels)
		{
			MinWheels = TestBody.LastCoastGroundWheels;
			if (FirstLossAt < 0.0)
				FirstLossAt = i * DT;
		}
		if (FirstContactAt < 0.0 && TestBody.ContactCount == 0)
			PreContactRoll = FMax(PreContactRoll, Abs(TestBody.Core.OutRoll_rad));
		if (TestBody.LastHitKind == "BSP" && TestBody.ContactCount > 0)
		{
			Hits++;
			if (FirstContactAt < 0.0)
			{
				FirstContactAt = i * DT;
				SpeedAfter = Speed;
				Log("HB2_TERRAIN_CONTACT case="$Tag$" at="$FirstContactAt
					$" xy="$Pos.X$","$Pos.Y$" beforeKmh="$PreSpeed$" afterKmh="$Speed
					$" yawRadps="$TestBody.Core.OutAngZ_radps$" rollRad="$TestBody.Core.OutRoll_rad
					$" penUU="$TestBody.LastMaxPenUU$" normal="$TestBody.LastContactNormal);
			}
		}
	}
	Failures = TestBody.StepFailureCount + TestBody.ActorSyncFailureCount
		+ TestBody.NonFiniteStateCount;
	Log("HB2_TERRAIN_RUN case="$Tag$" start="$Start$" steer="$Steer$" targetKmh="$Kmh
		$" gas="$Gas$" minWheels="$MinWheels$" firstLossSec="$FirstLossAt$" firstBspSec="$FirstContactAt
		$" bspSteps="$Hits$" preContactRollRad="$PreContactRoll$" maxRollRad="$MaxRoll
		$" maxYawRadps="$MaxYaw$" maxPenUU="$MaxPen$" speedAfterContactKmh="$SpeedAfter
		$" endKmh="$Speed$" end="$TestBody.Location$" failures="$Failures);
}

function RunTerrain()
{
	local vector Start;
	Start.X = -16660.0;
	Start.Y = 12100.0;
	Start.Z = -7810.0;
	MeasureTerrain("rock_straight", Start, 49152, 46.0, 0.0, 1.0, 270);
	MeasureTerrain("rock_left", Start, 49152, 46.0, -1.0, 1.0, 270);
	Start.X = -13300.0;
	Start.Y = 11586.0;
	MeasureTerrain("wall", Start, 32768, 46.0, 0.0, 0.0, 110);
	if (TestBody != None)
		TestBody.Destroy();
	Log("HB2_TERRAIN_GATE done=True");
}
