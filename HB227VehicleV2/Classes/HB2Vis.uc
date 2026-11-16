//=============================================================================
// HB2Vis — cosmetic mesh only. Not in the Core3D / sweep manifold.
//=============================================================================
class HB2Vis expands Actor;

// Bulldog vertex meshes and skins from the U2Vehicles export. See ALPHA-CHECKLIST.md.
#exec TEXTURE IMPORT NAME=HB227BulldogSkin FILE=Textures\Bulldogskin.pcx GROUP=Skins MIPS=ON FLAGS=0
#exec TEXTURE IMPORT NAME=HB227BDHeadlights FILE=Textures\BDHeadlights.pcx GROUP=Skins MIPS=ON FLAGS=0
#exec TEXTURE IMPORT NAME=HB227BDTailOff FILE=Textures\BDTailOff.pcx GROUP=Skins MIPS=ON FLAGS=0
#exec MESH IMPORT MESH=HB227BulldogBody ANIVFILE=Models\BulldogBodyMesh_a.3d DATAFILE=Models\BulldogBodyMesh_d.3d X=0 Y=0 Z=0
#exec MESH ORIGIN MESH=HB227BulldogBody X=0 Y=0 Z=-32 YAW=0 PITCH=0 ROLL=0
#exec MESH SEQUENCE MESH=HB227BulldogBody SEQ=All STARTFRAME=0 NUMFRAMES=1
#exec MESHMAP NEW MESHMAP=HB227BulldogBody MESH=HB227BulldogBody
#exec MESHMAP SCALE MESHMAP=HB227BulldogBody X=0.842 Y=0.842 Z=1.684
#exec MESHMAP SETTEXTURE MESHMAP=HB227BulldogBody NUM=0 TEXTURE=HB227BulldogSkin
#exec MESHMAP SETTEXTURE MESHMAP=HB227BulldogBody NUM=1 TEXTURE=HB227BDTailOff
#exec MESHMAP SETTEXTURE MESHMAP=HB227BulldogBody NUM=2 TEXTURE=HB227BDHeadlights
#exec MESH IMPORT MESH=HB227BulldogWheel ANIVFILE=Models\BulldogWheelMesh_a.3d DATAFILE=Models\BulldogWheelMesh_d.3d X=0 Y=0 Z=0
#exec MESH ORIGIN MESH=HB227BulldogWheel X=0 Y=0 Z=0 YAW=0 PITCH=0 ROLL=0
#exec MESH SEQUENCE MESH=HB227BulldogWheel SEQ=All STARTFRAME=0 NUMFRAMES=1
#exec MESHMAP NEW MESHMAP=HB227BulldogWheel MESH=HB227BulldogWheel
#exec MESHMAP SCALE MESHMAP=HB227BulldogWheel X=0.40 Y=0.40 Z=0.80
#exec MESHMAP SETTEXTURE MESHMAP=HB227BulldogWheel NUM=0 TEXTURE=HB227BulldogSkin
#exec MESH IMPORT MESH=HB227BulldogWheelR ANIVFILE=Models\BulldogWheelRMesh_a.3d DATAFILE=Models\BulldogWheelRMesh_d.3d X=0 Y=0 Z=0
#exec MESH ORIGIN MESH=HB227BulldogWheelR X=0 Y=0 Z=0 YAW=0 PITCH=0 ROLL=0
#exec MESH SEQUENCE MESH=HB227BulldogWheelR SEQ=All STARTFRAME=0 NUMFRAMES=1
#exec MESHMAP NEW MESHMAP=HB227BulldogWheelR MESH=HB227BulldogWheelR
#exec MESHMAP SCALE MESHMAP=HB227BulldogWheelR X=0.40 Y=0.40 Z=0.80
#exec MESHMAP SETTEXTURE MESHMAP=HB227BulldogWheelR NUM=0 TEXTURE=HB227BulldogSkin

var vector MeshLocalMin;
var vector MeshLocalMax;
var vector MeshLocalCenter;
var vector MeshLocalSize;
var string MeshName;
var bool bMeshMeasured;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
}

function ApplyMeshCar01()
{
	local Mesh M;
	local Texture T;
	M = Mesh(DynamicLoadObject("BotPack.car01M", class'Mesh', True));
	if (M == None)
	{
		DrawType = DT_Sprite;
		Texture = Texture'Engine.S_Actor';
		MeshName = "sprite_fallback";
		Warn("HB2: BotPack.car01M missing — sprite fallback");
		return;
	}
	Mesh = M;
	DrawType = DT_Mesh;
	bHidden = False;
	AmbientGlow = 48;
	MeshName = "BotPack.car01M";
	T = Texture(DynamicLoadObject("BotPack.Jcar1", class'Texture', True));
	if (T != None)
	{
		Skin = T;
		MultiSkins[1] = T;
	}
}

function bool ApplyMeshBulldog()
{
	Mesh = Mesh'HB227BulldogBody';
	DrawType = DT_Mesh;
	bHidden = False;
	AmbientGlow = 64;
	ScaleGlow = 1.0;
	MeshName = string(Mesh);
	Skin = Texture'HB227BulldogSkin';
	MultiSkins[0] = Skin;
	return True;
}


function MeasureRenderBox()
{
	local BoundingBox B;
	local rotator Saved;
	Saved = Rotation;
	SetRotation(rot(0,0,0));
	B = GetBoundingBox(True);
	SetRotation(Saved);
	MeshLocalMin = B.Min - Location;
	MeshLocalMax = B.Max - Location;
	MeshLocalCenter = (MeshLocalMin + MeshLocalMax) * 0.5;
	MeshLocalSize = MeshLocalMax - MeshLocalMin;
	bMeshMeasured = True;
}

function ApplyChassisVisual(vector HalfUU, string Profile)
{
	local float NativeLen, WantLen;
	local vector Zero3;

	Zero3.X = 1; Zero3.Y = 1; Zero3.Z = 1;
	DrawScale3D = Zero3;
	PrePivot = vect(0,0,0);
	bMeshMeasured = False;

	if (Profile == "p15_vehicle" && ApplyMeshBulldog())
	{
		DrawScale = 1.0;
		MeasureRenderBox();
		NativeLen = MeshLocalSize.X;
		WantLen = 2.0 * HalfUU.X;
		if (NativeLen > 4.0 && WantLen > 4.0)
			DrawScale = DrawScale * (WantLen / NativeLen);
		DrawScale3D = Zero3;
		MeasureRenderBox();
		PrePivot = MeshLocalCenter;
		MeasureRenderBox();
	}
	else
	{
		ApplyMeshCar01();
		DrawScale = 0.35;
		DrawScale3D = Zero3;
		MeasureRenderBox();
	}

	Log("HB2_VIS mesh="$MeshName$" profile="$Profile
		$" drawScale="$DrawScale$" drawScale3D="$DrawScale3D
		$" prePivot="$PrePivot
		$" meshMin="$MeshLocalMin$" meshMax="$MeshLocalMax
		$" meshSize="$MeshLocalSize$" meshCenter="$MeshLocalCenter
		$" physSize="$(2.0*HalfUU.X)$","$(2.0*HalfUU.Y)$","$(2.0*HalfUU.Z)
		$" axes=Xfwd,Yright,Zup");
}

function bool ApplyMeshBulldogWheel(bool bRight)
{
	if (bRight)
		Mesh = Mesh'HB227BulldogWheelR';
	else
		Mesh = Mesh'HB227BulldogWheel';
	DrawType = DT_Mesh;
	bHidden = False;
	AmbientGlow = 48;
	ScaleGlow = 1.0;
	MeshName = string(Mesh);
	Skin = Texture'HB227BulldogSkin';
	MultiSkins[0] = Skin;
	return True;
}


// Uniform DrawScale only. Visual radius is fitted to the physical wheel
// radius so the mesh sits on the contact, not a DrawScale3D squash.
function bool ApplyWheelVisual(bool bRight, float RadiusUU)
{
	local float NativeDim, WantDim;
	local vector Zero3;

	Zero3.X = 1; Zero3.Y = 1; Zero3.Z = 1;
	DrawScale3D = Zero3;
	PrePivot = vect(0,0,0);
	bMeshMeasured = False;
	if (!ApplyMeshBulldogWheel(bRight))
		return False;
	DrawScale = 1.0;
	MeasureRenderBox();
	NativeDim = MeshLocalSize.Z;
	if (MeshLocalSize.X > NativeDim)
		NativeDim = MeshLocalSize.X;
	WantDim = 2.0 * RadiusUU;
	if (NativeDim > 1.0 && WantDim > 1.0)
		DrawScale = WantDim / NativeDim;
	DrawScale3D = Zero3;
	MeasureRenderBox();
	PrePivot = MeshLocalCenter;
	MeasureRenderBox();
	Log("HB2_VIS_WHEEL mesh="$MeshName$" right="$bRight
		$" drawScale="$DrawScale$" drawScale3D="$DrawScale3D
		$" prePivot="$PrePivot$" meshSize="$MeshLocalSize
		$" wantDiamUU="$WantDim$" physRadiusUU="$RadiusUU);
	return True;
}

function ApplyMarker(bool bFront)
{
	Mesh = None;
	DrawType = DT_Sprite;
	bHidden = False;
	Texture = Texture'Engine.S_Actor';
	DrawScale3D.X = 1; DrawScale3D.Y = 1; DrawScale3D.Z = 1;
	if (bFront)
	{
		DrawScale = 0.55;
		AmbientGlow = 255;
		ScaleGlow = 2.0;
	}
	else
	{
		DrawScale = 0.32;
		AmbientGlow = 36;
		ScaleGlow = 0.55;
	}
}

defaultproperties
{
	bStatic=False
	bMovable=True
	bCollideWorld=False
	bCollideActors=False
	bBlockActors=False
	bBlockPlayers=False
	Physics=PHYS_None
	DrawType=DT_None
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	DrawScale3D=(X=1.000,Y=1.000,Z=1.000)
}
