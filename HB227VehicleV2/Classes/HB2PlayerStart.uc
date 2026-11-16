//=============================================================================
// HB2PlayerStart — sandbox spawn that can also be created at runtime.
// Stock Engine.PlayerStart is bStatic/bNoDelete and may fail map load if
// placed in solid / outside the playable BSP void.
//=============================================================================
class HB2PlayerStart expands PlayerStart;

defaultproperties
{
	bStatic=False
	bNoDelete=False
	bCollideWhenPlacing=False
	bCollideActors=False
	bCollideWorld=False
	bBlockActors=False
	bBlockPlayers=False
	bEnabled=True
	bSinglePlayerStart=True
	bCoopStart=True
	bDirectional=True
}
