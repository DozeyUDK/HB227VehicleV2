/*=============================================================================
	HB227NativeBridgePrivate.h
=============================================================================*/
#pragma once

#include "Engine.h"
#include "HBVehicleCore.h"
#include "HBVehicleCore3D.h"
#include "HB227NativeBridgeClasses.h"

struct FHBVRuntime
{
	HBV_Config Config;
	HBV_State State;
	HBV_Input Input;
	HBV_Telemetry Telemetry;
};

struct FHBV3Runtime
{
	HBV3_Config Config;
	HBV3_State State;
	HBV3_Contact Contacts[HBV3_MAX_CONTACTS];
	INT ContactCount;
	UBOOL ContactOverflow;
	HBV3_Telemetry Telemetry;
	HBV3_SuspensionConfig SuspensionConfigs[HBV3_SUSPENSION_POINTS];
	HBV3_SuspensionHit SuspensionHits[HBV3_SUSPENSION_POINTS];
	HBV3_SuspensionOutput SuspensionOutputs[HBV3_SUSPENSION_POINTS];
	UBOOL SuspensionConfigured[HBV3_SUSPENSION_POINTS];
	HBV3_SuspensionTotals PreparedSuspension;
	UBOOL SuspensionPrepared;
};
