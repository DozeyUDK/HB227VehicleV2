//=============================================================================
// HB2Input — PlayerInteraction WASD (pattern: HB227NativeInput).
// Stock User.ini: W/S = Axis aBaseY ±300, A/D = Axis aStrafe ±300.
// PlayerWalking.PlayerTick overrides pawn tick — requires bPlayerTick=True.
//=============================================================================
class HB2Input extends PlayerInteraction;

var HB2Body Body;
var HB2Driver DriverPawn;
var bool bShowHud;
var float NextInputLogTime;
var float LastGas, LastSteer, LastBrake;
var float HudRawY, HudRawF, HudRawS;
var int InputLogSeq;

function AttachToBody(HB2Body B, HB2Driver D)
{
	Body = B;
	DriverPawn = D;
	bShowHud = True;
	NextInputLogTime = 0;
	InputLogSeq = 0;
	LastGas = 999;
	LastSteer = 999;
	LastBrake = 999;
	Log("HB2: Input attached (bPlayerTick=True, axis/300, bWas fallbacks)");
}

event bool PlayerTick(float DeltaTime)
{
	local float Gas, Steer, Brake, ForwardAxis, StrafeAxis;
	local float RawABaseY, RawAForward, RawAStrafe;
	local float SpdBefore, SpdAfter;
	local bool bFromAxis, bChanged, bAuto;

	if (Body == None || PlayerOwner == None || DriverPawn == None)
		return False;
	if (!DriverPawn.bEntered)
		return False;

	// Auto P0 owns the body — do not fight resets/impulses.
	bAuto = (HB2TestGame(PlayerOwner.Level.Game) != None
		&& (HB2TestGame(PlayerOwner.Level.Game).bP0
			|| HB2TestGame(PlayerOwner.Level.Game).bP1
			|| HB2TestGame(PlayerOwner.Level.Game).bP2
			|| HB2TestGame(PlayerOwner.Level.Game).bP21
			|| HB2TestGame(PlayerOwner.Level.Game).bP22
			|| HB2TestGame(PlayerOwner.Level.Game).bP23));
	if (bAuto)
	{
		PlayerOwner.SetLocation(Body.Location + vect(0,0,80));
		return False;
	}

	RawABaseY = PlayerOwner.aBaseY;
	RawAForward = PlayerOwner.aForward;
	RawAStrafe = PlayerOwner.aStrafe;
	HudRawY = RawABaseY;
	HudRawF = RawAForward;
	HudRawS = RawAStrafe;

	Gas = 0;
	bFromAxis = False;
	ForwardAxis = RawABaseY;
	if (Abs(ForwardAxis) < 1)
		ForwardAxis = RawAForward;
	if (DriverPawn.bInvertThrottleAxis)
		ForwardAxis = -ForwardAxis;
	if (Abs(ForwardAxis) > 40)
	{
		Gas = FClamp(ForwardAxis / 300.0, -1.0, 1.0);
		bFromAxis = True;
	}
	else if (PlayerOwner.bWasForward)
		Gas = 1.0;
	else if (PlayerOwner.bWasBack)
		Gas = -1.0;

	StrafeAxis = RawAStrafe;
	if (DriverPawn.bInvertSteerAxis)
		StrafeAxis = -StrafeAxis;
	Steer = 0;
	if (Abs(StrafeAxis) > 40)
		Steer = FClamp(StrafeAxis / 300.0, -1.0, 1.0);
	else if (PlayerOwner.bWasLeft)
		Steer = -1.0;
	else if (PlayerOwner.bWasRight)
		Steer = 1.0;

	Brake = 0;
	if (PlayerOwner.bPressedJump || PlayerOwner.bDuck != 0)
		Brake = 1.0;

	// Suppress pawn locomotion after reading axes.
	PlayerOwner.aForward = 0;
	PlayerOwner.aStrafe = 0;
	PlayerOwner.aUp = 0;
	PlayerOwner.aBaseY = 0;
	PlayerOwner.aBaseX = 0;
	PlayerOwner.bPressedJump = False;
	PlayerOwner.bDuck = 0;

	SpdBefore = VSize(Body.Velocity);
	Body.ApplyDriverInput(Gas, Steer, Brake, DeltaTime);
	SpdAfter = VSize(Body.Velocity);

	bChanged = (Abs(Gas - LastGas) > 0.05) || (Abs(Steer - LastSteer) > 0.05)
		|| (Abs(Brake - LastBrake) > 0.05)
		|| (Abs(RawABaseY) > 20) || (Abs(RawAStrafe) > 20);

	if (bChanged || PlayerOwner.Level.TimeSeconds >= NextInputLogTime)
	{
		if (Abs(Gas) > 0.05 || Abs(Steer) > 0.05 || Brake > 0.05)
			NextInputLogTime = PlayerOwner.Level.TimeSeconds + 0.25;
		else
			NextInputLogTime = PlayerOwner.Level.TimeSeconds + 1.0;
		InputLogSeq++;
		LastGas = Gas;
		LastSteer = Steer;
		LastBrake = Brake;
		Log("HB2_INPUT t="$PlayerOwner.Level.TimeSeconds$" seq="$InputLogSeq$
			" RAW aY="$RawABaseY$" aF="$RawAForward$" aS="$RawAStrafe$
			" bWasF/B/L/R="$PlayerOwner.bWasForward$PlayerOwner.bWasBack$
			PlayerOwner.bWasLeft$PlayerOwner.bWasRight$
			" entered="$DriverPawn.bEntered$" fromAxis="$bFromAxis$
			" → gas="$Gas$" steer="$Steer$" brake="$Brake$
			" spd0="$SpdBefore$" spd1="$SpdAfter$
			" pendingImp="$Body.PendingImpulseUU$
			" yaw="$Body.Core.OutYaw_rad$" mode="$Body.SteerMode);
	}

	PlayerOwner.SetLocation(Body.Location + vect(0,0,80));
	return False;
}

event bool PostRender(Canvas Canvas)
{
	local string Line;
	if (Body == None || PlayerOwner == None || Canvas == None)
		return False;
	if (DriverPawn == None || !DriverPawn.bEntered)
		return False;
	if (!bShowHud)
	{
		if (Body.bDrawChassisDebug)
			Body.DrawChassisDebug(Canvas);
		return False;
	}
	Canvas.Font = Canvas.SmallFont;
	Canvas.DrawColor.R = 180;
	Canvas.DrawColor.G = 255;
	Canvas.DrawColor.B = 180;
	Canvas.SetPos(12, 72);
	Line = "HB2 INPUT aY="$int(HudRawY)$" aS="$int(HudRawS)$
		" gas="$Body.LastGas$" str="$Body.LastSteer$" brk="$Body.LastBrake;
	Canvas.DrawText(Line, False);
	Canvas.SetPos(12, 88);
	Line = "spd="$int(VSize(Body.Velocity))$" contacts="$Body.ContactCount$
		" hit="$Body.LastHitKind$" ctrl="$Body.ControlProfile$" F3=HUD F4=OBB";
	Canvas.DrawText(Line, False);
	Canvas.SetPos(12, 104);
	Line = "physOBB="$int(2.0*Body.ChassisHalfUU.X)$"x"$int(2.0*Body.ChassisHalfUU.Y)$"x"$int(2.0*Body.ChassisHalfUU.Z)
		$" profile="$Body.ChassisProfile$" chassisMode="$Body.LastChassisContactMode
		$" tires="$Body.LastTireActiveCount$" mu="$Body.LastTireMaxMuUtil
		$" visWheels="$Body.bVisualWheelsEnabled;
	Canvas.DrawText(Line, False);
	if (Body.Vis != None && Body.Vis.bMeshMeasured)
	{
		Canvas.SetPos(12, 120);
		Line = "visAABB="$int(Body.Vis.MeshLocalSize.X)$"x"$int(Body.Vis.MeshLocalSize.Y)$"x"$int(Body.Vis.MeshLocalSize.Z)
			$" mesh="$Body.Vis.MeshName$" scale="$Body.Vis.DrawScale;
		Canvas.DrawText(Line, False);
		Canvas.SetPos(12, 136);
		if (Body.Vis.MeshLocalSize.Z > 2.0 * Body.ChassisHalfUU.Z + 4.0
			|| Body.Vis.MeshLocalSize.X > 2.0 * Body.ChassisHalfUU.X + 8.0)
			Line = "VIS beyond OBB = cosmetic clip, not chassis penetration";
		else
			Line = "VIS inside/near OBB; cyan=phys OBB orange=mesh AABB";
		Canvas.DrawText(Line, False);
	}
	Canvas.SetPos(12, 153);
	Line = "4WD="$Body.bTorque4WDEnabled$" dir="$Body.DriveDirection$" gear="$Body.ForwardGear
		$" RPM="$int(Body.EngineRPM)$" pitch="$int(Body.SoundPitch)
		$" speedKmH="
		$int(VSize(Body.Velocity) / 52.5 * 3.6)
		$" omega FL/FR="$int(Body.WheelOmegaRadps[0])
		$"/"$int(Body.WheelOmegaRadps[1]);
	Canvas.DrawText(Line, False);
	Canvas.SetPos(12, 169);
	Line = "anti-roll="$Body.bAntiRollEnabled
		$" fN="$int(Body.LastAntiRollFrontN)
		$" rN="$int(Body.LastAntiRollRearN)
		$" slip="$Body.LastDriveMaxWheelSlipMps;
	Canvas.DrawText(Line, False);
	if (Body.bDrawChassisDebug)
		Body.DrawChassisDebug(Canvas);
	return False;
}

event bool KeyEvent(Actor.EInputKey Key, Actor.EInputAction Action, float Delta)
{
	if (Body == None || PlayerOwner == None)
		return False;
	if (Key == IK_F3 && Action == IST_Press)
	{
		bShowHud = !bShowHud;
		PlayerOwner.ClientMessage("HB2 HUD="$bShowHud, 'Event');
		return True;
	}
	if (Key == IK_F4 && Action == IST_Press && Body != None)
	{
		Body.bDrawChassisDebug = !Body.bDrawChassisDebug;
		PlayerOwner.ClientMessage("HB2 OBB debug="$Body.bDrawChassisDebug, 'Event');
		return True;
	}
	return False;
}

defaultproperties
{
	Priority=50
	bPlayerTick=True
	// HB2Driver is the single authoritative camera owner.
	bPlayerCalcView=False
	bKeyEvent=True
	bPostRender=True
	bShowHud=True
}
