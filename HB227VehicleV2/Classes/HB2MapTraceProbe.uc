//=============================================================================
// HB2MapTraceProbe — map Trace/Extent diagnostics only (no physics/solver changes).
// Spawned by HB2TestGame when ?hb2maptrace=1.
//=============================================================================
class HB2MapTraceProbe expands Info;

var int Phase;
var string ResultFloor, ResultRamp, ResultWall;
var string ResultFloorExt, ResultRampExt, ResultWallExt;
var string ResultPSDiag;
var bool bDone;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	Phase = 0;
	bDone = False;
	SetTimer(0.35, True);
	Log("HB2_MAPTRACE probe armed");
}

function Timer()
{
	if (bDone)
	{
		SetTimer(0, False);
		return;
	}
	if (Phase == 0)
	{
		DiagnosePlayerStarts();
		Phase = 1;
		return;
	}
	if (Phase == 1)
	{
		RunFloorTrace();
		Phase = 2;
		return;
	}
	if (Phase == 2)
	{
		RunRampTrace();
		Phase = 3;
		return;
	}
	if (Phase == 3)
	{
		RunWallTrace();
		Phase = 4;
		return;
	}
	if (Phase == 4)
	{
		Log("HB2_MAPTRACE GATE_DONE floor="$ResultFloor$" floorExt="$ResultFloorExt$
			" ramp="$ResultRamp$" rampExt="$ResultRampExt$
			" wall="$ResultWall$" wallExt="$ResultWallExt$
			" playerStart="$ResultPSDiag);
		bDone = True;
		SetTimer(0, False);
	}
}

function DiagnosePlayerStarts()
{
	local PlayerStart PS;
	local NavigationPoint Nav;
	local Actor A;
	local int LiveCount, NavCount, ActorCount;
	local vector Probe, HitLoc, HitNorm, Up;
	local Actor Hit;
	local string PackName;
	local Object Obj;
	local int i;
	local string Names[6];
	local vector Locs[6];
	local bool bFT;

	LiveCount = 0;
	foreach AllActors(class'PlayerStart', PS)
	{
		Log("HB2_MAPTRACE PS_LIVE name="$PS.Name$" class="$PS.Class$" loc="$PS.Location$
			" enabled="$PS.bEnabled$" single="$PS.bSinglePlayerStart$" coop="$PS.bCoopStart$
			" bStatic="$PS.bStatic$" bNoDelete="$PS.bNoDelete$" bDeleteMe="$PS.bDeleteMe$
			" bCollideWhenPlacing="$PS.bCollideWhenPlacing$" regionZone="$PS.Region.ZoneNumber);
		// Count only stock Engine starts — exclude runtime HB2PlayerStart fallback.
		if (!PS.IsA('HB2PlayerStart'))
			LiveCount++;
	}

	NavCount = 0;
	foreach AllActors(class'NavigationPoint', Nav)
		NavCount++;
	ActorCount = 0;
	foreach AllActors(class'Actor', A)
		ActorCount++;

	// Package object lookup (exists in .unr even if not in live actor list).
	PackName = string(Level.Outer.Name);
	Names[0] = "PlayerStart0"; Locs[0] = vect(-3235.26,-523.215,1743.2);
	Names[1] = "PlayerStart1"; Locs[1] = vect(1.65726,1.68886,241.198);
	Names[2] = "PlayerStart2"; Locs[2] = vect(-2606.05,243.189,273.198);
	Names[3] = "PlayerStart3"; Locs[3] = vect(-3647.34,521.755,305.198);
	Names[4] = "PlayerStart4"; Locs[4] = vect(-2962.67,-356.765,337.198);
	Names[5] = "PlayerStart5"; Locs[5] = vect(-4350.44,-843.681,369.198);

	Log("HB2_MAPTRACE PS_COUNTS livePlayerStarts="$LiveCount$" navigationPoints="$NavCount$" allActors="$ActorCount$" package="$PackName);

	for (i = 0; i < 6; ++i)
	{
		// DynamicLoadObject can resolve package-resident actors even if not in AllActors.
		Obj = DynamicLoadObject(PackName$"."$Names[i], class'PlayerStart', True);
		Log("HB2_MAPTRACE PS_OBJ "$Names[i]$" dynLoad="$Obj);
		if (PlayerStart(Obj) != None)
		{
			PS = PlayerStart(Obj);
			Log("HB2_MAPTRACE PS_OBJDETAIL "$Names[i]$" loc="$PS.Location$
				" bDeleteMe="$PS.bDeleteMe$" bHidden="$PS.bHidden$
				" enabled="$PS.bEnabled$" single="$PS.bSinglePlayerStart$
				" regionZone="$PS.Region.ZoneNumber$" bStatic="$PS.bStatic);
		}

		Probe = Locs[i];
		Up = Probe + vect(0,0,200);
		bFT = FastTrace(Up, Probe);
		Hit = Trace(HitLoc, HitNorm, Probe - vect(0,0,400), Up, False);
		Log("HB2_MAPTRACE PS_SITE "$Names[i]$" site="$Probe$
			" fastTraceUp="$bFT$" downHit="$Hit$" downLoc="$HitLoc$" downN="$HitNorm$
			" gapZ="$(Probe.Z - HitLoc.Z));
	}

	if (LiveCount > 0)
		ResultPSDiag = "PASS stockLive="$LiveCount$" (Engine.PlayerStart in AllActors)";
	else
		ResultPSDiag = "FAIL stockLive=0; UCC lists PlayerStart0-5 in .unr but AllActors+DynamicLoadObject see none after LoadMap — destroyed/not spawned into world (HB2PlayerStart fallback is separate)";
	Log("HB2_MAPTRACE PS_VERDICT "$ResultPSDiag);
}

function LogTraceResult(string Tag, bool bExtent, vector Start, vector End, Actor Hit, vector HitLoc, vector HitNorm)
{
	local float Dist;
	local string Kind, Verdict;
	local float AbsN;

	Dist = VSize(HitLoc - Start);
	if (Hit == None)
	{
		Kind = "None";
		Verdict = "FAIL no hit";
	}
	else if (Hit == Level)
	{
		Kind = "BSP";
		Verdict = "PASS";
	}
	else if (Hit.IsA('StaticMeshActor') || Hit.bIsStaticMesh)
		Kind = "StaticMesh";
	else if (Hit.Mesh != None)
		Kind = "MeshActor";
	else
		Kind = "Actor:"$Hit.Class;

	AbsN = Abs(HitNorm.X) + Abs(HitNorm.Y) + Abs(HitNorm.Z);
	Log("HB2_MAPTRACE "$Tag$" extent="$bExtent$" start="$Start$" end="$End$
		" hitActor="$Hit$" kind="$Kind$" hitLoc="$HitLoc$" hitNormal="$HitNorm$
		" distUU="$Dist$" nLen="$AbsN$" verdict="$Verdict);
}

function RunFloorTrace()
{
	local vector Start, End, HitLoc, HitNorm, Ext;
	local Actor Hit;
	local float Dist;

	Start = vect(0,0,280);
	End = vect(0,0,-400);
	Hit = Trace(HitLoc, HitNorm, End, Start, False);
	LogTraceResult("FLOOR_LINE", False, Start, End, Hit, HitLoc, HitNorm);

	if (Hit == Level && HitNorm.Z > 0.85)
	{
		Dist = VSize(HitLoc - Start);
		ResultFloor = "PASS actor=Level nZ="$HitNorm.Z$" dist="$Dist$" hitZ="$HitLoc.Z;
	}
	else if (Hit == None)
		ResultFloor = "FAIL no floor hit";
	else
		ResultFloor = "FAIL hit="$Hit$" n="$HitNorm$" (want Level + nZ>0.85)";

	Ext = vect(24,24,24);
	Hit = Trace(HitLoc, HitNorm, End, Start, False, Ext);
	LogTraceResult("FLOOR_EXTENT", True, Start, End, Hit, HitLoc, HitNorm);
	if (Hit == Level && HitNorm.Z > 0.7)
		ResultFloorExt = "PASS actor=Level nZ="$HitNorm.Z$" hitLoc="$HitLoc;
	else
		ResultFloorExt = "FAIL hit="$Hit$" n="$HitNorm;

	Log("HB2_MAPTRACE FLOOR_SUMMARY line="$ResultFloor$" extent="$ResultFloorExt);
}

function RunRampTrace()
{
	local int i, ix, iy;
	local vector Start, End, HitLoc, HitNorm, Dir, Center, Ext, BestLoc, BestN;
	local Actor Hit, BestHit;
	local float BestScore, Score, Dist, Deg;
	local bool bFound;

	// Search near flat center and toward western rock/ramp area (where Editor starts were placed).
	bFound = False;
	BestScore = -1;

	for (i = 0; i < 36; ++i)
	{
		Dir.X = Cos(i * 3.14159265 / 18.0);
		Dir.Y = Sin(i * 3.14159265 / 18.0);
		Dir.Z = 0;
		Start = vect(0,0,220) + Dir * (400 + (i % 4) * 500);
		End = Start - vect(0,0,800);
		Hit = Trace(HitLoc, HitNorm, End, Start, False);
		if (Hit == Level && HitNorm.Z > 0.35 && HitNorm.Z < 0.92)
		{
			Score = 1.0 - Abs(HitNorm.Z - 0.7);
			if (Score > BestScore)
			{
				BestScore = Score;
				BestHit = Hit;
				BestLoc = HitLoc;
				BestN = HitNorm;
				bFound = True;
			}
		}
	}

	// Grid around western starts / Brush4 X=-256
	Center = vect(-2800,0,400);
	for (ix = -6; ix <= 6; ++ix)
	{
		for (iy = -6; iy <= 6; ++iy)
		{
			Start.X = Center.X + ix * 220;
			Start.Y = Center.Y + iy * 220;
			Start.Z = 500;
			End = Start - vect(0,0,1200);
			Hit = Trace(HitLoc, HitNorm, End, Start, False);
			if (Hit == Level && HitNorm.Z > 0.35 && HitNorm.Z < 0.92)
			{
				Score = 1.0 - Abs(HitNorm.Z - 0.65);
				if (Score > BestScore)
				{
					BestScore = Score;
					BestHit = Hit;
					BestLoc = HitLoc;
					BestN = HitNorm;
					bFound = True;
				}
			}
		}
	}

	if (!bFound)
	{
		ResultRamp = "FAIL no BSP slope normal (0.35<nZ<0.92) found in probe";
		ResultRampExt = "NOT_RUN";
		Log("HB2_MAPTRACE RAMP_SUMMARY "$ResultRamp);
		return;
	}

	Start = BestLoc + BestN * 80;
	End = BestLoc - BestN * 200;
	Hit = Trace(HitLoc, HitNorm, End, Start, False);
	LogTraceResult("RAMP_LINE", False, Start, End, Hit, HitLoc, HitNorm);
	Dist = VSize(HitLoc - Start);
	// Incline from vertical: atan(|n_xy|/nZ). No Acos in UC math set.
	if (HitNorm.Z > 0.01)
		Deg = Atan(Sqrt(HitNorm.X * HitNorm.X + HitNorm.Y * HitNorm.Y) / HitNorm.Z) * (180.0 / 3.14159265);
	else
		Deg = 90;

	if (Hit == Level && HitNorm.Z > 0.35 && HitNorm.Z < 0.92)
		ResultRamp = "PASS actor=Level n="$HitNorm$" nZ="$HitNorm.Z$" approxDeg="$Deg$" dist="$Dist$" hitLoc="$HitLoc$" collision=YES";
	else
		ResultRamp = "FAIL after refine hit="$Hit$" n="$HitNorm;

	Ext = vect(24,24,24);
	Hit = Trace(HitLoc, HitNorm, End, Start, False, Ext);
	LogTraceResult("RAMP_EXTENT", True, Start, End, Hit, HitLoc, HitNorm);
	if (Hit == Level && HitNorm.Z > 0.30 && HitNorm.Z < 0.95)
	{
		if (HitNorm.Z > 0.01)
			Deg = Atan(Sqrt(HitNorm.X * HitNorm.X + HitNorm.Y * HitNorm.Y) / HitNorm.Z) * (180.0 / 3.14159265);
		else
			Deg = 90;
		ResultRampExt = "PASS actor=Level nZ="$HitNorm.Z$" hitLoc="$HitLoc$" approxDeg="$Deg;
	}
	else
		ResultRampExt = "FAIL hit="$Hit$" n="$HitNorm;

	Log("HB2_MAPTRACE RAMP_SUMMARY line="$ResultRamp$" extent="$ResultRampExt$" bestSite="$BestLoc$" bestN="$BestN);
}

function RunWallTrace()
{
	local int i, h;
	local float Height;
	local vector Start, End, HitLoc, HitNorm, Dir, Ext;
	local Actor Hit;
	local float Dist, BestDist, BestAbsZ;
	local bool bFound;
	local vector BestLoc, BestN, BestStart;
	local Actor BestHit;

	bFound = False;
	BestDist = 999999;
	BestAbsZ = 1;

	// Multi-height rings — rocky basin faces are often steep slopes, not perfect verticals.
	for (h = 0; h < 5; ++h)
	{
		if (h == 0) Height = 80;
		else if (h == 1) Height = 160;
		else if (h == 2) Height = 280;
		else if (h == 3) Height = 420;
		else Height = 600;
		Start = vect(0,0,1) * Height;
		for (i = 0; i < 24; ++i)
		{
			Dir.X = Cos(i * 3.14159265 / 12.0);
			Dir.Y = Sin(i * 3.14159265 / 12.0);
			Dir.Z = 0;
			End = Start + Dir * 8000;
			Hit = Trace(HitLoc, HitNorm, End, Start, False);
			if (Hit == Level && Abs(HitNorm.Z) < 0.72)
			{
				Dist = VSize(HitLoc - Start);
				// Prefer more vertical faces; then nearer hits.
				if (Abs(HitNorm.Z) < BestAbsZ - 0.02 || (Abs(Abs(HitNorm.Z) - BestAbsZ) < 0.02 && Dist < BestDist))
				{
					BestAbsZ = Abs(HitNorm.Z);
					BestDist = Dist;
					BestHit = Hit;
					BestLoc = HitLoc;
					BestN = HitNorm;
					BestStart = Start;
					bFound = True;
				}
			}
		}
	}

	if (!bFound)
	{
		ResultWall = "FAIL no steep BSP face (Abs(nZ)<0.72) within 8000 UU from origin ring";
		ResultWallExt = "NOT_RUN";
		Log("HB2_MAPTRACE WALL_SUMMARY "$ResultWall);
		return;
	}

	End = BestStart + Normal(BestLoc - BestStart) * (BestDist + 50);
	Hit = Trace(HitLoc, HitNorm, End, BestStart, False);
	LogTraceResult("WALL_LINE", False, BestStart, End, Hit, HitLoc, HitNorm);
	Dist = VSize(HitLoc - BestStart);
	if (Hit == Level && Abs(HitNorm.Z) < 0.55)
		ResultWall = "PASS actor=Level n="$HitNorm$" Abs(nZ)="$Abs(HitNorm.Z)$" dist="$Dist$" hitLoc="$HitLoc$" collision=YES";
	else
		ResultWall = "FAIL hit="$Hit$" n="$HitNorm;

	Ext = vect(24,24,24);
	Hit = Trace(HitLoc, HitNorm, End, BestStart, False, Ext);
	LogTraceResult("WALL_EXTENT", True, BestStart, End, Hit, HitLoc, HitNorm);
	if (Hit == Level && Abs(HitNorm.Z) < 0.70)
		ResultWallExt = "PASS actor=Level n="$HitNorm$" dist="$(VSize(HitLoc - BestStart))$" hitLoc="$HitLoc;
	else
		ResultWallExt = "FAIL hit="$Hit$" n="$HitNorm;

	Log("HB2_MAPTRACE WALL_SUMMARY line="$ResultWall$" extent="$ResultWallExt);
}

defaultproperties
{
	bHidden=True
}
