[
	"ASL_MaxRopeLength",																	// internal setting name, should always contain a tag! This will be the global variable which takes the value of the setting.
	"SLIDER",																				// setting type
	[format[localize "STR_ASL_MAX_LENGTH"], format[localize "STR_ASL_MAX_LENGTH_TIP"]],		// [setting name, tooltip]
	format[localize "STR_ASL_TITLE"],														// pretty name of the category where the setting can be found. Can be stringtable entry.
	[30, 100, 100, 0],																		// data for this setting: [_min, _max, _default, _trailingDecimals]
    true,																					// "_isGlobal" flag. Set this to true to always have this setting synchronized between all clients in multiplayer
	{ASL_MaxRopeLength = round(ASL_MaxRopeLength)}											// code executed on option changed AND on init
] call CBA_fnc_addSetting;
[
	"ASL_MaxDeployRetractDistance",
	"SLIDER",
	[format[localize "STR_ASL_MAX_DIST"], format[localize "STR_ASL_MAX_DIST_TIP"]],
	format[localize "STR_ASL_TITLE"],
	[3, 30, 10, 0],
    true,
	{ASL_MaxDeployRetractDistance = round(ASL_MaxDeployRetractDistance)}
] call CBA_fnc_addSetting;
[
	"ASL_PilotsAuthorized",
    "CHECKBOX",
	[format[localize "STR_ASL_PILOT"], format[localize "STR_ASL_PILOT_TIP"]],
	format[localize "STR_ASL_TITLE"],
	true,																					// default setting
    true
] call CBA_fnc_addSetting;
[
	"ASL_CopilotsAuthorized", 
    "CHECKBOX",
	[format[localize "STR_ASL_COPILOT"], format[localize "STR_ASL_COPILOT_TIP"]],
	format[localize "STR_ASL_TITLE"],
	true,
    true
] call CBA_fnc_addSetting;
[
	"ASL_GunnersAuthorized",
    "CHECKBOX",
	[format[localize "STR_ASL_GUNNER"], format[localize "STR_ASL_GUNNER_TIP"]],
	format[localize "STR_ASL_TITLE"],
	false,
    true
] call CBA_fnc_addSetting;
[
	"ASL_PassengersAuthorized",
    "CHECKBOX",
	[format[localize "STR_ASL_PASSENGER"], format[localize "STR_ASL_PASSENGER_TIP"]],
	format[localize "STR_ASL_TITLE"],
	false,
    true
] call CBA_fnc_addSetting;
[
	"ASL_MaxRopeDeployHeight",
	"SLIDER",
	[format[localize "STR_ASL_MAX_DEPLOY_HEIGHT"], format[localize "STR_ASL_MAX_DEPLOY_HEIGHT_TIP"]],
	format[localize "STR_ASL_TITLE"],
	[0, 1000, 100, 0],
    true,
	{ASL_MaxRopeDeployHeight = round(ASL_MaxRopeDeployHeight)}
] call CBA_fnc_addSetting;
[
	"ASL_MinVehicleMass",
	"SLIDER",
	[format[localize "STR_ASL_MIN_MASS"], format[localize "STR_ASL_MIN_MASS_TIP"]],
	format[localize "STR_ASL_TITLE"],
	[0, 2000, 0, 0],
    true,
	{
		if (time < 3) exitWith {};			// the switch function is ment to run only on changes made by players, not on game init
		[] call ASL_Switch_Vehicles_Actions
	}
] call CBA_fnc_addSetting;
[
	"ASL_InitialDeployRopeLength",
	"SLIDER",
	[format[localize "STR_ASL_INITIAL_DEPLOY"], format[localize "STR_ASL_INITIAL_DEPLOY_TIP"]],
	format[localize "STR_ASL_TITLE"],
	[5, ASL_MaxRopeLength - 10, 15, 0],
    true,
	{
		if (ASL_InitialDeployRopeLength > ASL_MaxRopeLength - 10) then {
			ASL_InitialDeployRopeLength = ASL_MaxRopeLength - 10;
		};
		ASL_InitialDeployRopeLength = round(ASL_InitialDeployRopeLength);
	}
] call CBA_fnc_addSetting;
[
	"ASL_ExtendShortenRopeLength",
	"SLIDER",
	[format[localize "STR_ASL_EXTEND_SHORTEN"], format[localize "STR_ASL_EXTEND_SHORTEN_TIP"]],
	format[localize "STR_ASL_TITLE"],
	[1, 25, 5, 0],
    true,
	{ASL_ExtendShortenRopeLength = round(ASL_ExtendShortenRopeLength)}
] call CBA_fnc_addSetting;
[
	"ASL_DefaultLiftableMass",
	"SLIDER",
	[format[localize "STR_ASL_DEFAULT_MASS"], format[localize "STR_ASL_DEFAULT_MASS_TIP"]],
	format[localize "STR_ASL_TITLE"],
	[500, 10000, 4000, 0],
    true
] call CBA_fnc_addSetting;
[
	"ASL_MaxLiftableMassFactor",
	"SLIDER",
	[format[localize "STR_ASL_MAX_MASS"], format[localize "STR_ASL_MAX_MASS_TIP"]],
	format[localize "STR_ASL_TITLE"],
	[1, 20, 8, 0],
    true,
	{ASL_MaxLiftableMassFactor = round(ASL_MaxLiftableMassFactor)}
] call CBA_fnc_addSetting;
[
	"ASL_MinRopeLengthDropCargo",
    "CHECKBOX",
	[format[localize "STR_ASL_MIN_MASS_DROP"], format[localize "STR_ASL_MIN_MASS_DROP_TIP"]],
	format[localize "STR_ASL_TITLE"],
	false,
    true
] call CBA_fnc_addSetting;
[
	"ASL_RopeHandlingDistance",
	"SLIDER",
	[format[localize "STR_ROPE_HANDLING_DIST"], format[localize "STR_ROPE_HANDLING_DIST_TIP"]],
	format[localize "STR_ASL_TITLE"],
	[2, 20, 5, 0],
    true,
	{ASL_RopeHandlingDistance = round(ASL_RopeHandlingDistance)}
] call CBA_fnc_addSetting;
[
	"ASL_RopeMessagesAuthorized",
    "CHECKBOX",
	[format[localize "STR_ROPE_MESSAGES"], format[localize "STR_ROPE_MESSAGES_TIP"]],
	format[localize "STR_ASL_TITLE"],
	true,
    true
] call CBA_fnc_addSetting;
