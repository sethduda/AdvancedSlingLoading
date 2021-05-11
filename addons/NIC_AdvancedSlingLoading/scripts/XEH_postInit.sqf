[
	format[localize "STR_ASL_TITLE"],															// name of mod
	"ASL_DropCargoKey",																			// id of the key action
	[format[localize "STR_DROP_CARGO_KEY"], format[localize "STR_DROP_CARGO_KEY_TIP"]],			// [name of key bind action, tool tip]
	{
		if (vehicle player == player || !([vehicle player, player] call ASL_Is_Unit_Authorized)) exitWith {};
		private _allCargo = vehicle player getVariable ["ASL_Cargo", []];
		{
			[vehicle player, player, _foreachindex] call ASL_Release_Cargo;
		} forEach _allCargo;
	},																							// code executed on key down
	{false},																					// code executed on key up
	[0x20, [false, true, false]]																// [key for starting action, [shift, ctrl, alt] (additional key to be pressed)]	
] call CBA_fnc_addKeybind;
