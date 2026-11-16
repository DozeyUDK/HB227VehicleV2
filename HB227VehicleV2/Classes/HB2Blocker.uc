//=============================================================================
// HB2Blocker — simple blocking Actor for P0 Test D.
//=============================================================================
class HB2Blocker expands Actor;

defaultproperties
{
	DrawType=DT_Sprite
	Texture=Texture'Engine.S_Actor'
	bHidden=False
	bStatic=False
	bMovable=True
	bCollideActors=False
	bCollideWorld=False
	bBlockActors=True
	bBlockPlayers=True
	bBlockZeroExtentTraces=True
	bBlockNonZeroExtentTraces=True
	CollisionRadius=30
	CollisionHeight=40
	Physics=PHYS_None
}
