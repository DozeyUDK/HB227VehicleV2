//=============================================================================
// HB2SpireDriveGate - scripted in-engine vehicle drive on SpireVillage.
// Opt-in only via HB2TestGame ?hb2spire=1. No OS/HID control or map mutation.
// The sweep logs actual Core3D tyre/chassis telemetry, not synthesized results.
//=============================================================================
class HB2SpireDriveGate expands Info;

var HB2Body TestBody;
var vector CarStart, CarForward;
var rotator CarRot;
var bool bFinished;
var int Phase, WaitTicks;
var string ResultSpawn, ResultDrive, ResultSteer, ResultBrake;
var string ResultReverse, ResultStable, ResultObstacle, ResultIdle, ResultFastSteer, ResultDiesel;
var string ResultNoThrottle, ResultDirectionChange;
var float NeutralInjectedRPM, NeutralFinalSpeedUU, NeutralDisplacementUU;
var float NeutralBaseSpeedUU, NeutralBaseDriftUU;
var float LeftYaw, RightYaw, BrakeStartSpeed, BrakeEndSpeed;
var float DriveDistanceUU, DrivePeakSpeedUU;
var float ReverseDistanceUU, ObstacleOnDistanceUU, ObstacleOffDistanceUU;
var int ObstacleOnHits, ObstacleOffHits;
var float PeakAzMps2, PeakPenUU;
var int WorstWheelCount, PeakChassisContacts, PeakObstacleContacts;
var vector IdleStartLoc;
var float IdleDriftUU, IdleEndSpeedMps, FastYawDelta, FastEffectiveSteer;
var int FastWheelLossSteps, FastGeomGlitches;
var float DieselLaunchDemand, DieselMidDemand, DieselTopDemand;

function PostBeginPlay()
{
    Super.PostBeginPlay();
    Phase = 0;
    WaitTicks = 0;
    ResultSpawn = "NOT_RUN";
    ResultDrive = "NOT_RUN";
    ResultSteer = "NOT_RUN";
    ResultBrake = "NOT_RUN";
    ResultReverse = "NOT_RUN";
    ResultStable = "NOT_RUN";
    ResultObstacle = "NOT_RUN";
    ResultIdle = "NOT_RUN";
    ResultFastSteer = "NOT_RUN";
    ResultDiesel = "NOT_RUN";
    ResultNoThrottle = "NOT_RUN";
    ResultDirectionChange = "NOT_RUN";
    WorstWheelCount = 4;
    Log("HB2_SPIRE START map="$Level$" physics=Core3D scripted_controls=WASD_sequence");
    SetTimer(0.30, True);
}

function bool FindVehicle()
{
    local HB2Body B;
    if (TestBody != None && !TestBody.bDeleteMe)
        return TestBody.bReady && TestBody.Core != None && TestBody.Core.bReady;
    foreach AllActors(class'HB2Body', B)
    {
        if (B != None && !B.bDeleteMe)
        {
            TestBody = B;
            return TestBody.bReady && TestBody.Core != None && TestBody.Core.bReady;
        }
    }
    return False;
}

// Conservative playable BSP site around the map's own PlayerStarts.
// No fixed SpireVillage coordinates or map edits. Report a missing site, never
// pretend a vehicle was able to drive.
function bool ProbeSite(vector Candidate, rotator Heading, out vector ComOut)
{
    local vector HitLoc, HitNorm, Floor, Probe, Attach;
    local Actor H;
    local float MinZ, MaxZ;
    local int i;

    Probe = Candidate + vect(0,0,280);
    H = TestBody.Trace(HitLoc, HitNorm, Candidate - vect(0,0,550),
        Probe, False);
    if (H == None || HitNorm.Z < 0.73)
        return False;
    Floor = HitLoc;
    ComOut = Floor + vect(0,0,1) * TestBody.ChassisSpawnHeightUU();
    H = TestBody.Trace(HitLoc, HitNorm, ComOut + vect(0,0,110),
        Floor + vect(0,0,20), False);
    if (H != None)
        return False;

    MinZ = 999999;
    MaxZ = -999999;
    for (i = 0; i < 4; ++i)
    {
        Attach = ComOut + (TestBody.SuspensionAttachmentUU[i] >> Heading);
        H = TestBody.Trace(HitLoc, HitNorm, Attach + vect(0,0,50),
            Attach - vect(0,0,220), False);
        if (H == None || HitNorm.Z < 0.60)
            return False;
        MinZ = FMin(MinZ, HitLoc.Z);
        MaxZ = FMax(MaxZ, HitLoc.Z);
    }
    return (MaxZ - MinZ <= 42.0);
}

function bool FindStartingSite()
{
    local PlayerStart PS;
    local vector Position, Fwd, Probe;
    local rotator R;
    local int i;

    foreach AllActors(class'PlayerStart', PS)
    {
        R = PS.Rotation;
        R.Pitch = 0;
        R.Roll = 0;
        Fwd = vector(R);
        for (i = 0; i < 4; ++i)
        {
            if (i == 0) Probe = PS.Location + Fwd * 210;
            else if (i == 1) Probe = PS.Location;
            else if (i == 2) Probe = PS.Location - Fwd * 210;
            else Probe = PS.Location + Fwd * 105;
            if (!ProbeSite(Probe, R, Position))
                continue;
            CarRot = R;
            CarStart = Position;
            CarForward = Normal(Fwd);
            Log("HB2_SPIRE SITE ps="$PS$" psLoc="$PS.Location
                $" com="$CarStart$" facing="$CarForward);
            return True;
        }
    }

    R = TestBody.Rotation;
    R.Pitch = 0;
    R.Roll = 0;
    if (ProbeSite(TestBody.Location, R, Position))
    {
        CarRot = R;
        CarStart = Position;
        CarForward = Normal(vector(R));
        Log("HB2_SPIRE SITE fallback_body com="$CarStart$" facing="$CarForward);
        return True;
    }
    return False;
}

function bool ResetRun(vector InitialVelUU)
{
    TestBody.SetRotation(CarRot);
    TestBody.ResetTo(CarStart, InitialVelUU);
    TestBody.LastGas = 0;
    TestBody.LastSteer = 0;
    TestBody.LastBrake = 0;
    return VSize(TestBody.Location - CarStart) < 5.0;
}

function float VehicleSpeedUU()
{
    return VSize(TestBody.Velocity);
}

function SampleState()
{
    if (TestBody.WheelContactCount < WorstWheelCount)
        WorstWheelCount = TestBody.WheelContactCount;
    if (TestBody.ContactCount > PeakChassisContacts)
        PeakChassisContacts = TestBody.ContactCount;
    if (TestBody.WheelObstacleContactCount > PeakObstacleContacts)
        PeakObstacleContacts = TestBody.WheelObstacleContactCount;
    if (Abs(TestBody.LastVertAccelMps2) > PeakAzMps2)
        PeakAzMps2 = Abs(TestBody.LastVertAccelMps2);
    if (TestBody.LastMaxPenUU > PeakPenUU)
        PeakPenUU = TestBody.LastMaxPenUU;
}

function DriveFor(float Seconds, float Gas, float Steer, float Brake)
{
    local int Steps, i;
    Steps = int(Seconds * 60 + 0.5);
    for (i = 0; i < Steps; ++i)
    {
        TestBody.LastGas = Gas;
        TestBody.LastSteer = Steer;
        TestBody.LastBrake = Brake;
        TestBody.bDriverActive = (Abs(Gas) > 0.05 || Abs(Steer) > 0.05 || Brake > 0.05);
        TestBody.PumpPhysics(1.0 / 60.0, 1.0 / 60.0);
        SampleState();
    }
}

function float SignedYawDelta(float StartYaw, float EndYaw)
{
    local float Delta;
    Delta = EndYaw - StartYaw;
    while (Delta > 3.14159265)
        Delta -= 6.2831853;
    while (Delta < -3.14159265)
        Delta += 6.2831853;
    return Delta;
}

function FinishRun()
{
    if (bFinished)
        return;
    bFinished = True;
    SetTimer(0, False);
    TestBody.LastGas = 0;
    TestBody.LastSteer = 0;
    TestBody.LastBrake = 0;
    TestBody.bDriverActive = False;
    if (TestBody.StepFailureCount == 0 && TestBody.ActorSyncFailureCount == 0
        && TestBody.NonFiniteStateCount == 0)
        ResultStable = "PASS";
    else
        ResultStable = "FAIL";

    Log("HB2_SPIRE METRICS driveUU="$DriveDistanceUU
        $" maxSpeedUU="$DrivePeakSpeedUU$" leftYaw="$LeftYaw$" rightYaw="$RightYaw
        $" brakePreUU="$BrakeStartSpeed$" brakePostUU="$BrakeEndSpeed
        $" reverseUU="$ReverseDistanceUU$" obstacleOnUU="$ObstacleOnDistanceUU
        $" obstacleOffUU="$ObstacleOffDistanceUU$" onHits="$ObstacleOnHits
        $" offHits="$ObstacleOffHits$" minWheels="$WorstWheelCount
        $" maxChassisN="$PeakChassisContacts$" maxObstacleN="$PeakObstacleContacts
        $" peakAbsAz="$PeakAzMps2$" peakPenUU="$PeakPenUU
        $" idleDriftUU="$IdleDriftUU$" idleSpeedMps="$IdleEndSpeedMps
        $" fastYaw="$FastYawDelta$" fastSteerRad="$FastEffectiveSteer
        $" fastLostStep="$FastWheelLossSteps$" fastGeomReject="$FastGeomGlitches
        $" dieselA0="$DieselLaunchDemand$" dieselA12="$DieselMidDemand
        $" dieselA25="$DieselTopDemand$" idleInjected="$NeutralInjectedRPM
        $" neutralSpeedUU="$NeutralFinalSpeedUU$" neutralMoveUU="$NeutralDisplacementUU
        $" neutralBaseSpeedUU="$NeutralBaseSpeedUU$" neutralBaseDriftUU="$NeutralBaseDriftUU);
    Log("HB2_SPIRE GATE_DONE spawn="$ResultSpawn$" drive="$ResultDrive
        $" steer="$ResultSteer$" brake="$ResultBrake$" reverse="$ResultReverse
        $" stable="$ResultStable$" obstacle="$ResultObstacle
        $" idle="$ResultIdle$" fastSteer="$ResultFastSteer$" diesel="$ResultDiesel
        $" noThrottle="$ResultNoThrottle$" directionChange="$ResultDirectionChange
        $" stepFail="$TestBody.StepFailureCount
        $" syncFail="$TestBody.ActorSyncFailureCount
        $" nonFinite="$TestBody.NonFiniteStateCount);
}

function Timer()
{
    local float Yaw0;
    local vector StartLoc;

    if (bFinished)
        return;
    if (!FindVehicle())
    {
        WaitTicks++;
        if (WaitTicks > 36)
        {
            Warn("HB2_SPIRE FAIL no ready HB2Body after spawn timeout");
            bFinished = True;
            SetTimer(0, False);
            Log("HB2_SPIRE GATE_DONE spawn=FAIL drive=NOT_RUN steer=NOT_RUN brake=NOT_RUN reverse=NOT_RUN stable=FAIL obstacle=NOT_RUN idle=NOT_RUN fastSteer=NOT_RUN diesel=NOT_RUN noThrottle=NOT_RUN directionChange=NOT_RUN stepFail=0 syncFail=0 nonFinite=0");
        }
        return;
    }

    if (Phase == 0)
    {
        if (!FindStartingSite() || !ResetRun(vect(0,0,0)))
        {
            Warn("HB2_SPIRE FAIL no drivable site around PlayerStarts");
            ResultSpawn = "FAIL";
            FinishRun();
            return;
        }
        ResultSpawn = "PASS";
        Phase = 1;
        return;
    }

    if (Phase == 1)
    {
        ResetRun(vect(0,0,0));
        DrivePeakSpeedUU = 0;
        StartLoc = TestBody.Location;
        DriveFor(4.0, 0.70, 0.0, 0.0);
        DriveDistanceUU = (TestBody.Location - StartLoc) Dot CarForward;
        DrivePeakSpeedUU = VehicleSpeedUU();
        ResultDrive = "FAIL";
        if (DriveDistanceUU > 45.0 && DrivePeakSpeedUU > 40.0)
            ResultDrive = "PASS";
        Log("HB2_SPIRE DRIVE displacementUU="$DriveDistanceUU
            $" endSpeedUU="$DrivePeakSpeedUU$" result="$ResultDrive);
        Phase = 2;
        return;
    }

    if (Phase == 2)
    {
        ResetRun(vect(0,0,0));
        DriveFor(1.5, 0.60, 0.0, 0.0);
        Yaw0 = TestBody.Core.OutYaw_rad;
        DriveFor(2.5, 0.55, -0.65, 0.0);
        LeftYaw = SignedYawDelta(Yaw0, TestBody.Core.OutYaw_rad);
        Phase = 3;
        return;
    }

    if (Phase == 3)
    {
        ResetRun(vect(0,0,0));
        DriveFor(1.5, 0.60, 0.0, 0.0);
        Yaw0 = TestBody.Core.OutYaw_rad;
        DriveFor(2.5, 0.55, 0.65, 0.0);
        RightYaw = SignedYawDelta(Yaw0, TestBody.Core.OutYaw_rad);
        ResultSteer = "FAIL";
        if (LeftYaw * RightYaw < -0.001
            && Abs(LeftYaw) > 0.04 && Abs(RightYaw) > 0.04)
            ResultSteer = "PASS";
        Log("HB2_SPIRE STEER leftYaw="$LeftYaw$" rightYaw="$RightYaw
            $" result="$ResultSteer);
        Phase = 4;
        return;
    }

    if (Phase == 4)
    {
        ResetRun(vect(0,0,0));
        DriveFor(3.0, 0.80, 0.0, 0.0);
        BrakeStartSpeed = VehicleSpeedUU();
        DriveFor(2.0, 0.0, 0.0, 1.0);
        BrakeEndSpeed = VehicleSpeedUU();
        ResultBrake = "FAIL";
        if (BrakeStartSpeed > 40.0 && BrakeEndSpeed < BrakeStartSpeed * 0.85)
            ResultBrake = "PASS";
        Log("HB2_SPIRE BRAKE fromUU="$BrakeStartSpeed
            $" toUU="$BrakeEndSpeed$" result="$ResultBrake);
        Phase = 5;
        return;
    }

    if (Phase == 5)
    {
        ResetRun(vect(0,0,0));
        StartLoc = TestBody.Location;
        DriveFor(3.0, -0.65, 0.0, 0.0);
        ReverseDistanceUU = (TestBody.Location - StartLoc) Dot CarForward;
        ResultReverse = "FAIL";
        if (ReverseDistanceUU < -30.0)
            ResultReverse = "PASS";
        Log("HB2_SPIRE REVERSE signedUU="$ReverseDistanceUU
            $" result="$ResultReverse);
        Phase = 6;
        return;
    }

    if (Phase == 6)
    {
        ResetRun(CarForward * 300.0);
        TestBody.bWheelObstacleContactsEnabled = True;
        ObstacleOnHits = TestBody.WheelObstacleContactTotal;
        DriveFor(2.0, 0.60, 0.0, 0.0);
        ObstacleOnDistanceUU = (TestBody.Location - CarStart) Dot CarForward;
        ObstacleOnHits = TestBody.WheelObstacleContactTotal - ObstacleOnHits;
        Phase = 7;
        return;
    }

    if (Phase == 7)
    {
        ResetRun(CarForward * 300.0);
        TestBody.bWheelObstacleContactsEnabled = False;
        ObstacleOffHits = TestBody.WheelObstacleContactTotal;
        DriveFor(2.0, 0.60, 0.0, 0.0);
        ObstacleOffDistanceUU = (TestBody.Location - CarStart) Dot CarForward;
        ObstacleOffHits = TestBody.WheelObstacleContactTotal - ObstacleOffHits;
        TestBody.bWheelObstacleContactsEnabled = True;
        if (ObstacleOnHits > 0 && ObstacleOffHits == 0)
            ResultObstacle = "PASS";
        else if (ObstacleOnHits == 0 && ObstacleOffHits == 0)
            ResultObstacle = "NOT_RUN";
        else
            ResultObstacle = "FAIL";
        Log("HB2_SPIRE OBSTACLE onHits="$ObstacleOnHits
            $" offHits="$ObstacleOffHits$" onDistUU="$ObstacleOnDistanceUU
            $" offDistUU="$ObstacleOffDistanceUU$" result="$ResultObstacle);
        Phase = 8;
        return;
    }

    if (Phase == 8)
    {
        ResetRun(vect(0,0,0));
        // Exclude initial spring settling from the idle drift measurement.
        DriveFor(3.0, 0.0, 0.0, 0.0);
        IdleStartLoc = TestBody.Location;
        Phase = 9;
        return;
    }

    if (Phase >= 9 && Phase <= 17)
    {
        DriveFor(10.0, 0.0, 0.0, 0.0);
        StartLoc = TestBody.Location - IdleStartLoc;
        StartLoc.Z = 0;
        IdleDriftUU = VSize(StartLoc);
        IdleEndSpeedMps = class'HB2WorldQuery'.static.UUToM(VehicleSpeedUU());
        Log("HB2_SPIRE IDLE simSec="$((Phase - 8) * 10)
            $" horizontalDriftUU="$IdleDriftUU
            $" speedMps="$IdleEndSpeedMps
            $" wheels="$TestBody.WheelContactCount);
        if (Phase == 17)
        {
            ResultIdle = "FAIL";
            if (IdleDriftUU < 3.0 && IdleEndSpeedMps < 0.02)
                ResultIdle = "PASS";
            Phase = 18;
        }
        else
            Phase++;
        return;
    }

    if (Phase == 18)
    {
        // ~15.2 m/s initial highway-speed steering; logs contact loss and
        // actual yaw, unlike a low-speed steering-only confidence check.
        ResetRun(CarForward * 800.0);
        WaitTicks = TestBody.SuspensionContactLossStepCount;
        FastGeomGlitches = TestBody.WheelGeomGlitchCount;
        Yaw0 = TestBody.Core.OutYaw_rad;
        DriveFor(1.5, 0.25, 0.65, 0.0);
        FastYawDelta = SignedYawDelta(Yaw0, TestBody.Core.OutYaw_rad);
        FastWheelLossSteps = TestBody.SuspensionContactLossStepCount - WaitTicks;
        FastGeomGlitches = TestBody.WheelGeomGlitchCount - FastGeomGlitches;
        FastEffectiveSteer = TestBody.LastEffectiveSteerRad;
        ResultFastSteer = "FAIL";
        if (Abs(FastYawDelta) > 0.025 && TestBody.WheelContactCount >= 2)
            ResultFastSteer = "PASS";
        Log("HB2_SPIRE FAST_STEER initialSpeedUU=800 yawDelta="$FastYawDelta
            $" effectiveSteerRad="$FastEffectiveSteer
            $" wheelLossSteps="$FastWheelLossSteps
            $" geomReject="$FastGeomGlitches
            $" endWheels="$TestBody.WheelContactCount
            $" result="$ResultFastSteer);
        Phase = 19;
        return;
    }

    if (Phase == 19)
    {
        // Read the live rigid body's velocity-dependent tractive demand.
        // Only tests the drive curve; no invented gear/RPM/torque mechanics.
        ResetRun(vect(0,0,0));
        DieselLaunchDemand = TestBody.DesiredDriveAccelMps2();
        ResetRun(CarForward * 630.0); // 12 m/s
        DieselMidDemand = TestBody.DesiredDriveAccelMps2();
        ResetRun(CarForward * 1312.5); // 25 m/s
        DieselTopDemand = TestBody.DesiredDriveAccelMps2();
        ResultDiesel = "FAIL";
        if (DieselLaunchDemand > 5.50
            && DieselMidDemand > 3.0
            && DieselMidDemand < DieselLaunchDemand
            && DieselTopDemand < 0.05)
            ResultDiesel = "PASS";
        Log("HB2_SPIRE DIESEL a0="$DieselLaunchDemand
            $" a12="$DieselMidDemand$" a25="$DieselTopDemand
            $" result="$ResultDiesel);
        Phase = 20;
        return;
    }

    if (Phase == 20)
    {
        // Reproduce the user's ghost-drive condition: inject an angular
        // wheel overspeed with throttle=0 on grounded tyres.
        ResetRun(vect(0,0,0));
        DriveFor(0.2, 0.0, 0.0, 0.0);
        StartLoc = TestBody.Location;
        DriveFor(2.0, 0.0, 0.0, 0.0);
        NeutralBaseDriftUU = VSize(TestBody.Location - StartLoc);
        NeutralBaseSpeedUU = VehicleSpeedUU();
        ResetRun(vect(0,0,0));
        DriveFor(0.2, 0.0, 0.0, 0.0);
        TestBody.WheelOmegaRadps[0] = 50.0;
        TestBody.WheelOmegaRadps[1] = 50.0;
        TestBody.WheelOmegaRadps[2] = 50.0;
        TestBody.WheelOmegaRadps[3] = 50.0;
        NeutralInjectedRPM = 50.0;
        StartLoc = TestBody.Location;
        DriveFor(2.0, 0.0, 0.0, 0.0);
        NeutralDisplacementUU = VSize(TestBody.Location - StartLoc);
        NeutralFinalSpeedUU = VehicleSpeedUU();
        ResultNoThrottle = "FAIL";
        if (Abs(NeutralDisplacementUU - NeutralBaseDriftUU) < 3.0
            && Abs(NeutralFinalSpeedUU - NeutralBaseSpeedUU) < 6.0
            && Abs(TestBody.WheelOmegaRadps[0]) < 2.0
            && TestBody.EngineRPM <= TestBody.EngineIdleRPM + 25.0
            && TestBody.SoundPitch <= 65
            && TestBody.WheelDriveTorqueNm[0] == 0.0)
            ResultNoThrottle = "PASS";
        Log("HB2_SPIRE NO_THROTTLE injectedOmega=50 duration=2"
            $" movedUU="$NeutralDisplacementUU
            $" endSpeedUU="$NeutralFinalSpeedUU
            $" baselineUU="$NeutralBaseDriftUU
            $" baselineSpeedUU="$NeutralBaseSpeedUU
            $" omega="$TestBody.WheelOmegaRadps[0]
            $" engineRPM="$TestBody.EngineRPM
            $" pitch="$TestBody.SoundPitch
            $" driveTorque="$TestBody.WheelDriveTorqueNm[0]
            $" result="$ResultNoThrottle);
        Phase = 21;
        return;
    }

    if (Phase == 21)
    {
        ResetRun(vect(0,0,0));
        DriveFor(1.0, 0.80, 0.0, 0.0);
        DriveFor(0.8, -0.80, 0.0, 0.0);
        ResultDirectionChange = "FAIL";
        if (TestBody.DriveDirection == -1
            && TestBody.ForwardGear == 1
            && TestBody.WheelDriveTorqueNm[0] <= 0.0
            && TestBody.EngineRPM >= TestBody.EngineIdleRPM
            && TestBody.EngineRPM <= TestBody.EngineRedlineRPM)
            ResultDirectionChange = "PASS";
        Log("HB2_SPIRE REVERSE_MODE dir="$TestBody.DriveDirection
            $" gear="$TestBody.ForwardGear
            $" rpm="$TestBody.EngineRPM$" torqueNm="$TestBody.WheelDriveTorqueNm[0]
            $" pitch="$TestBody.SoundPitch$" result="$ResultDirectionChange);
        DriveFor(2.0, 0.0, 0.0, 0.0);
        if (TestBody.EngineRPM > TestBody.EngineIdleRPM + 25.0
            || TestBody.SoundPitch > 65
            || TestBody.WheelDriveTorqueNm[0] != 0.0)
            ResultDirectionChange = "FAIL";
        Log("HB2_SPIRE REVERSE_RELEASE rpm="$TestBody.EngineRPM
            $" pitch="$TestBody.SoundPitch
            $" torqueNm="$TestBody.WheelDriveTorqueNm[0]
            $" result="$ResultDirectionChange);
        FinishRun();
        return;
    }
}

defaultproperties
{
    bHidden=True
    bStatic=False
    bNoDelete=False
    RemoteRole=ROLE_None
}
