//=============================================================================
// HB2WorldQuery — Engine Trace as the collision bridge (no PhysX, no extra DLL).
// Honest limits: Extent is AABB vs world / vertical cylinder vs actors — not a rotating OBB
// and not a sphere. Trace(..., Extent=(R,R,R)) is a box sweep, never a swept sphere.
// 227k has no wheel-radius sphere cast. Wheel contacts therefore use a zero-extent
// disc probe set (centre, ±0.55R/±0.80R along roll, ±0.30R along axle), pick one
// contact, and fall back to a small AABB seam catch with zero-extent surface verify.
//=============================================================================
class HB2WorldQuery expands Object;

// UU per metre (Unreal convention ≈ 52.5). Documented conversion for Core3D SI units.
static final function float UUToM(float UU)
{
	return UU / 52.5;
}

static final function float MToUU(float M)
{
	return M * 52.5;
}

static final function vector UUToMVec(vector V)
{
	return V * (1.0 / 52.5);
}

static final function vector MToUUVec(vector V)
{
	return V * 52.5;
}

// P2.9: vehicle physics traces must not hit Pawn first and hide BSP/movers
// behind them. OldUnreal TraceFlags (Actor.uc): TRACE_Pawns=0x01,
// TRACE_Movers=0x02, TRACE_Level=0x04, TRACE_Others=0x10, TRACE_Blocking=0x40,
// TRACE_Volumes=0x2000. Explicit flags override the engine default that
// always ORs TRACE_Pawns into Trace().
static final function int VehicleTraceFlags(bool bTraceActors)
{
	if (bTraceActors)
		return 0x02 | 0x04 | 0x10 | 0x40 | 0x2000; // Movers|Level|Others|Blocking|Volumes
	return 0x02 | 0x04; // Movers|Level only
}

static final function bool VehicleTraceFlagsIncludePawns(int Flags)
{
	return (Flags & 0x01) != 0;
}

// Axis-aligned box proxy used by Trace(..., Extent). UE227's non-zero Extent
// query does not rotate. The caller must pass an AABB that contains the
// rotated OBB (sum |R_ij| * half_j), not a fixed cube.
static final function float AABBSupportRadius(vector ExtentUU, vector NormalWorld)
{
	NormalWorld = Normal(NormalWorld);
	return ExtentUU.X * Abs(NormalWorld.X)
		+ ExtentUU.Y * Abs(NormalWorld.Y)
		+ ExtentUU.Z * Abs(NormalWorld.Z);
}

static final function vector AABBSupportPoint(
	vector CenterUU,
	vector ExtentUU,
	vector NormalWorld)
{
	local vector P;
	P = CenterUU;
	// Point of the AABB furthest opposite the world normal.
	if (NormalWorld.X > 0) P.X -= ExtentUU.X;
	else if (NormalWorld.X < 0) P.X += ExtentUU.X;
	if (NormalWorld.Y > 0) P.Y -= ExtentUU.Y;
	else if (NormalWorld.Y < 0) P.Y += ExtentUU.Y;
	if (NormalWorld.Z > 0) P.Z -= ExtentUU.Z;
	else if (NormalWorld.Z < 0) P.Z += ExtentUU.Z;
	return P;
}

// Support radius of the rotated box along a world normal. Detection remains
// the engine AABB sweep; this is only used for penetration of a verified plane.
static final function float OBBSupportRadius(vector ExtentUU, rotator BodyRot, vector NormalWorld)
{
	local vector NLocal;
	NLocal = Normal(NormalWorld) << BodyRot;
	return ExtentUU.X * Abs(NLocal.X)
		+ ExtentUU.Y * Abs(NLocal.Y)
		+ ExtentUU.Z * Abs(NLocal.Z);
}

// Resultant of a uniform face-plane contact: COM projected onto the plane.
// An AABB/OBB support vertex is a corner and is not used as the moment arm.
static final function vector ProjectOnPlane(vector PointUU, vector PlanePointUU, vector NormalWorld)
{
	NormalWorld = Normal(NormalWorld);
	return PointUU - NormalWorld * ((PointUU - PlanePointUU) Dot NormalWorld);
}

// Four corners of the OBB face most opposed to NormalWorld. Detection remains
// AABB; these points are only a manifold on an already verified plane.
static final function OBBFaceCorners(
	vector CenterUU,
	vector ExtentUU,
	rotator BodyRot,
	vector NormalWorld,
	out vector C0,
	out vector C1,
	out vector C2,
	out vector C3)
{
	local vector NLocal, L;
	local float hx, hy, hz, ax, ay, az, dx, dy, dz;

	NLocal = Normal(NormalWorld) << BodyRot;
	hx = ExtentUU.X;
	hy = ExtentUU.Y;
	hz = ExtentUU.Z;
	ax = -1.0;
	if (NLocal.X > 0)
		ax = -1.0;
	else if (NLocal.X < 0)
		ax = 1.0;
	else
		ax = 0.0;
	ay = -1.0;
	if (NLocal.Y > 0)
		ay = -1.0;
	else if (NLocal.Y < 0)
		ay = 1.0;
	else
		ay = 0.0;
	az = -1.0;
	if (NLocal.Z > 0)
		az = -1.0;
	else if (NLocal.Z < 0)
		az = 1.0;
	else
		az = 0.0;
	dx = Abs(NLocal.X);
	dy = Abs(NLocal.Y);
	dz = Abs(NLocal.Z);
	if (dx >= dy && dx >= dz)
	{
		if (ax == 0)
			ax = -1.0;
		L.X = ax * hx; L.Y = hy; L.Z = hz; C0 = CenterUU + (L >> BodyRot);
		L.X = ax * hx; L.Y = hy; L.Z = -hz; C1 = CenterUU + (L >> BodyRot);
		L.X = ax * hx; L.Y = -hy; L.Z = hz; C2 = CenterUU + (L >> BodyRot);
		L.X = ax * hx; L.Y = -hy; L.Z = -hz; C3 = CenterUU + (L >> BodyRot);
	}
	else if (dy >= dx && dy >= dz)
	{
		if (ay == 0)
			ay = -1.0;
		L.X = hx; L.Y = ay * hy; L.Z = hz; C0 = CenterUU + (L >> BodyRot);
		L.X = hx; L.Y = ay * hy; L.Z = -hz; C1 = CenterUU + (L >> BodyRot);
		L.X = -hx; L.Y = ay * hy; L.Z = hz; C2 = CenterUU + (L >> BodyRot);
		L.X = -hx; L.Y = ay * hy; L.Z = -hz; C3 = CenterUU + (L >> BodyRot);
	}
	else
	{
		if (az == 0)
			az = -1.0;
		L.X = hx; L.Y = hy; L.Z = az * hz; C0 = CenterUU + (L >> BodyRot);
		L.X = hx; L.Y = -hy; L.Z = az * hz; C1 = CenterUU + (L >> BodyRot);
		L.X = -hx; L.Y = hy; L.Z = az * hz; C2 = CenterUU + (L >> BodyRot);
		L.X = -hx; L.Y = -hy; L.Z = az * hz; C3 = CenterUU + (L >> BodyRot);
	}
}

// Point/line ground query. Returns True on hit.
static final function bool GroundQuery(
	Actor Context,
	vector StartUU,
	vector DirUnit,
	float MaxDistUU,
	bool bTraceActors,
	out vector HitLocUU,
	out vector HitNorm,
	out float HitDistUU,
	out Actor HitActor)
{
	local vector End;
	local Actor Hit;

	HitDistUU = 0;
	HitActor = None;
	if (Context == None || MaxDistUU <= 0)
		return False;
	DirUnit = Normal(DirUnit);
	End = StartUU + DirUnit * MaxDistUU;
	// Extent=0, bTraceBSP=True, BSPTraceFlags=0, TraceFlags=vehicle (no pawns).
	Hit = Context.Trace(HitLocUU, HitNorm, End, StartUU, bTraceActors,
		vect(0,0,0), True, 0, VehicleTraceFlags(bTraceActors));
	if (Hit == None)
		return False;
	HitActor = Hit;
	HitDistUU = VSize(HitLocUU - StartUU);
	return True;
}

// Swept AABB (Extent). Returns True if blocked before End.
static final function bool SweepExtent(
	Actor Context,
	vector StartUU,
	vector EndUU,
	vector ExtentUU,
	bool bTraceActors,
	out vector HitLocUU,
	out vector HitNorm,
	out float HitTime,
	out Actor HitActor)
{
	local Actor Hit;
	local float PathLen;

	HitTime = 1.0;
	HitActor = None;
	if (Context == None)
		return False;
	Hit = Context.Trace(HitLocUU, HitNorm, EndUU, StartUU, bTraceActors,
		ExtentUU, True, 0, VehicleTraceFlags(bTraceActors));
	if (Hit == None)
		return False;
	HitActor = Hit;
	PathLen = VSize(EndUU - StartUU);
	if (PathLen > 0.001)
		HitTime = VSize(HitLocUU - StartUU) / PathLen;
	else
		HitTime = 0;
	return True;
}

// A non-zero Extent Trace returns the swept proxy location at impact on the
// tested 227k paths; it is not a world surface point. Verify that interpretation
// per hit with a zero-extent trace along the returned normal, and expose only
// that second trace as a physical contact point. A failed verification is an
// explicit caller-visible fallback, never an invented lever arm.
static final function bool ResolveSweepSurfacePoint(
	Actor Context,
	Actor ExpectedHit,
	vector HitCenterUU,
	vector HitNorm,
	vector ExtentUU,
	bool bTraceActors,
	out vector SurfacePointUU,
	out vector SurfaceNorm,
	out float CenterToSurfaceUU)
{
	local vector Start, End, N;
	local Actor SurfaceHit;
	local float SupportUU;

	CenterToSurfaceUU = 0;
	SurfacePointUU = HitCenterUU;
	SurfaceNorm = HitNorm;
	if (Context == None || ExpectedHit == None || VSize(HitNorm) < 0.5)
		return False;

	N = Normal(HitNorm);
	SupportUU = AABBSupportRadius(ExtentUU, N);
	Start = HitCenterUU + N * 3.0;
	End = HitCenterUU - N * (SupportUU + 12.0);
	SurfaceHit = Context.Trace(SurfacePointUU, SurfaceNorm, End, Start, bTraceActors,
		vect(0,0,0), True, 0, VehicleTraceFlags(bTraceActors));
	if (SurfaceHit == None || SurfaceHit != ExpectedHit)
		return False;
	SurfaceNorm = Normal(SurfaceNorm);
	if ((SurfaceNorm Dot N) < 0.75)
		return False;

	CenterToSurfaceUU = (HitCenterUU - SurfacePointUU) Dot N;
	if (CenterToSurfaceUU < 0.25 || CenterToSurfaceUU > SupportUU + 10.0)
		return False;
	return True;
}


// P2.6a: validate that an OBB contact projected onto the support plane also
// lies on a *finite* piece of BSP. The sweep gives an infinite-plane candidate;
// without this check, points outside the polygon can cause invisible walls.
// The mesh opt-in uses the same finite-face check with world-actor tracing.
static final function bool VerifyBSPContactFootprint(
	Actor Context,
	Actor ExpectedHit,
	vector PointUU,
	vector PlanePointUU,
	vector PlaneNormal,
	optional bool bVerifyMeshes)
{
	local vector N, Start, End, ActualPoint, ActualNormal;
	local Actor ActualHit;
	local bool bMesh;
	if (Context == None || ExpectedHit == None)
		return False;
	if (ExpectedHit != Context.Level)
	{
		bMesh=bVerifyMeshes && (ExpectedHit.IsA('StaticMeshActor') || ExpectedHit.bIsStaticMesh);
		if (!bMesh) return True;
	}
	if (VSize(PlaneNormal) < 0.5)
		return False;
	N = Normal(PlaneNormal);
	Start = PointUU + N * 8.0;
	End = PointUU - N * 8.0;
	// BSP footprint verify: level/movers only — never pawns.
	ActualHit = Context.Trace(ActualPoint, ActualNormal, End, Start, bMesh,
		vect(0,0,0), True, 0, VehicleTraceFlags(bMesh));
	if (ActualHit != ExpectedHit || VSize(ActualNormal) < 0.5)
		return False;
	if ((Normal(ActualNormal) Dot N) < 0.98)
		return False;
	if (Abs((ActualPoint - PlanePointUU) Dot N) > 2.0)
		return False;
	if (VSize(ActualPoint - PointUU) > 3.0)
		return False;
	return True;
}
