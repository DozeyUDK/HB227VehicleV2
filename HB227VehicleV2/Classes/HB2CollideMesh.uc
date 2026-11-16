//=============================================================================
// HB2CollideMesh — runtime mesh block for P0 Test C when no StaticMeshActor in map.
// Uses Engine mesh collision (bUseMeshCollision), not PhysX.
//=============================================================================
class HB2CollideMesh expands Actor;

simulated function PostBeginPlay()
{
	local Mesh M;
	Super.PostBeginPlay();
	M = Mesh(DynamicLoadObject("BotPack.car01M", class'Mesh', True));
	if (M != None)
	{
		Mesh = M;
		DrawType = DT_Mesh;
		DrawScale = 0.8;
		Log("HB2: CollideMesh mesh="$M);
	}
	else
	{
		DrawType = DT_Sprite;
		Texture = Texture'Engine.S_Actor';
		Warn("HB2: CollideMesh mesh missing — collision cylinder only");
	}
}

defaultproperties
{
	bStatic=False
	bMovable=True
	bHidden=False
	bCollideActors=False
	bCollideWorld=False
	bBlockActors=True
	bBlockPlayers=True
	bBlockZeroExtentTraces=True
	bBlockNonZeroExtentTraces=True
	bUseMeshCollision=True
	CollisionRadius=40
	CollisionHeight=30
	Physics=PHYS_None
	DrawType=DT_Sprite
	RemoteRole=ROLE_None
}
