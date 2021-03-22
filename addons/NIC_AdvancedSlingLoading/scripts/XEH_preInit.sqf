[
	"ASL_MaxRopeLength",																	// internal setting name, should always contain a tag! This will be the global variable which takes the value of the setting.
	"SLIDER",																				// setting type
	[format[localize "STR_ASL_MAX_LENGTH"], format[localize "STR_ASL_MAX_LENGTH_TIP"]],		// [setting name, tooltip]
	format[localize "STR_ASL_TITLE"],														// pretty name of the category where the setting can be found. Can be stringtable entry.
	[30, 150, 100, 0],																		// data for this setting: [_min, _max, _default, _trailingDecimals]
    true																					// "_isGlobal" flag. Set this to true to always have this setting synchronized between all clients in multiplayer
] call CBA_fnc_addSetting;

[
	"ASL_MaxDeployRetractDistance",
	"SLIDER",
	[format[localize "STR_ASL_MAX_DIST"], format[localize "STR_ASL_MAX_DIST_TIP"]],
	format[localize "STR_ASL_TITLE"],
	[3, 30, 10, 0],
    true
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
    true
] call CBA_fnc_addSetting;

[
	"ASL_MinVehicleMass",
	"SLIDER",
	[format[localize "STR_ASL_MIN_MASS"], format[localize "STR_ASL_MIN_MASS_TIP"]],
	format[localize "STR_ASL_TITLE"],
	[0, 2000, 0, 0],
    true,
	{[] call ASL_Switch_Vehicle_Actions;}													// code executed on option changed AND on init
] call CBA_fnc_addSetting;