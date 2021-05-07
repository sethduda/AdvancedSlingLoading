/*
The MIT License (MIT)

Copyright (c) 2016 Seth Duda

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions 
of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.
*/

ASL_Advanced_Sling_Loading_Install = {
	if (!isNil "ASL_ROPE_INIT") exitWith {};		// Prevent advanced sling loading from installing twice
	ASL_ROPE_INIT = true;

	diag_log "Advanced Sling Loading Loading...";
	
	ASL_Rope_Get_Lift_Capability = {
		params [["_vehicle", objNull]];
		if (isNull _vehicle) exitWith {};
		private _slingLoadMaxCargoMass = getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> "slingLoadMaxCargoMass");
		if (_slingLoadMaxCargoMass <= 0) then {
			_slingLoadMaxCargoMass = ASL_DefaultLiftableMass;
		};
		_slingLoadMaxCargoMass;	
	};
	
	ASL_SLING_LOAD_POINT_CLASS_HEIGHT_OFFSET = [  
		["All", [-0.05, -0.05, -0.05]],  
		["CUP_CH47F_base", [-0.05, -2, -0.05]],  
		["CUP_AW159_Unarmed_Base", [-0.05, -0.06, -0.05]],
		["RHS_CH_47F", [-0.75, -2.6, -0.75]], 
		["rhsusf_CH53E_USMC", [-0.8, -1, -1.1]], 
		["rhsusf_CH53E_USMC_D", [-0.8, -1, -1.1]] 
	];
	
	ASL_Get_Sling_Load_Points = {
		params [["_vehicle", objNull]];
		if (isNull _vehicle) exitWith {};
		private _slingLoadPointsArray = [];
		private _cornerPoints = [_vehicle] call ASL_Get_Corner_Points;
		private _frontCenterPoint = (((_cornerPoints select 2) vectorDiff (_cornerPoints select 3)) vectorMultiply 0.5) vectorAdd (_cornerPoints select 3);
		private _rearCenterPoint = (((_cornerPoints select 0) vectorDiff (_cornerPoints select 1)) vectorMultiply 0.5) vectorAdd (_cornerPoints select 1);
		_rearCenterPoint = ((_frontCenterPoint vectorDiff _rearCenterPoint) vectorMultiply 0.2) vectorAdd _rearCenterPoint;
		_frontCenterPoint = ((_rearCenterPoint vectorDiff _frontCenterPoint) vectorMultiply 0.2) vectorAdd _frontCenterPoint;
		private _middleCenterPoint = ((_frontCenterPoint vectorDiff _rearCenterPoint) vectorMultiply 0.5) vectorAdd _rearCenterPoint;
		private _vehicleUnitVectorUp = vectorNormalized (vectorUp _vehicle);
		private _slingLoadPointHeightOffset = 0;
		{
			if (_vehicle isKindOf (_x select 0)) exitWith {
				_slingLoadPointHeightOffset = (_x select 1);
			};
		} forEach ASL_SLING_LOAD_POINT_CLASS_HEIGHT_OFFSET;
		private _slingLoadPoints = [];
		private ["_modelPoint",
			"_modelPointASL", 
			"_surfaceIntersectStartASL", 
			"_surfaceIntersectEndASL", 
			"_la", 
			"_lb", 
			"_n", 
			"_p0", 
			"_l",
			"_d",
			"_surfaces", 
			"_intersectionASL",
			"_intersectionObject"
		];
		{
			_modelPoint = _x;
			_modelPointASL = AGLToASL (_vehicle modelToWorldVisual _modelPoint);
			_surfaceIntersectStartASL = _modelPointASL vectorAdd (_vehicleUnitVectorUp vectorMultiply -5);
			_surfaceIntersectEndASL = _modelPointASL vectorAdd (_vehicleUnitVectorUp vectorMultiply 5);
			
			// Determine if the surface intersection line crosses below ground level
			// If if does, move surfaceIntersectStartASL above ground level (lineIntersectsSurfaces
			// doesn't work if starting below ground level for some reason
			// See: https://en.wikipedia.org/wiki/Line%E2%80%93plane_intersection
			_la = ASLToAGL _surfaceIntersectStartASL;
			_lb = ASLToAGL _surfaceIntersectEndASL;
			if (_la select 2 < 0 && _lb select 2 > 0) then {
				_n = [0, 0, 1];
				_p0 = [0, 0, 0.1];
				_l = (_la vectorFromTo _lb);
				if ((_l vectorDotProduct _n) != 0) then {
					_d = ((_p0 vectorAdd (_la vectorMultiply -1)) vectorDotProduct _n) / (_l vectorDotProduct _n);
					_surfaceIntersectStartASL = AGLToASL ((_l vectorMultiply _d) vectorAdd _la);
				};
			};
			
			_surfaces = lineIntersectsSurfaces [_surfaceIntersectStartASL, _surfaceIntersectEndASL, objNull, objNull, true, 100];
			_intersectionASL = [];
			{
				_intersectionObject = _x select 2;
				if (_intersectionObject == _vehicle) exitWith {
					_intersectionASL = _x select 0;
				};
			} forEach _surfaces;
			if (count _intersectionASL > 0) then {
				_intersectionASL = _intersectionASL vectorAdd ((_surfaceIntersectStartASL vectorFromTo _surfaceIntersectEndASL) vectorMultiply (_slingLoadPointHeightOffset select (count _slingLoadPoints)));
				_slingLoadPoints pushBack (_vehicle worldToModelVisual (ASLToAGL _intersectionASL));
			} else {
				_slingLoadPoints pushBack [];
			};
		} forEach [_frontCenterPoint, _middleCenterPoint, _rearCenterPoint];
		
		if (count (_slingLoadPoints select 1) > 0) then {
			_slingLoadPointsArray pushBack [_slingLoadPoints select 1];
			if (count (_slingLoadPoints select 0) > 0 && count (_slingLoadPoints select 2) > 0) then {
				if (((_slingLoadPoints select 0) distance (_slingLoadPoints select 2)) > 3) then {
					_slingLoadPointsArray pushBack [_slingLoadPoints select 0, _slingLoadPoints select 2];
					if (((_slingLoadPoints select 0) distance (_slingLoadPoints select 1)) > 3) then {
						_slingLoadPointsArray pushBack [_slingLoadPoints select 0, _slingLoadPoints select 1, _slingLoadPoints select 2];
					};	
				};	
			};
		};
		_slingLoadPointsArray;
	};
	
	ASL_Get_Corner_Points = {
		params [["_vehicle", objNull]];
		if (isNull _vehicle) exitWith {};
		private _widthFactor	= 0.5;
		private _lengthFactor	= 0.5;
		if (_vehicle isKindOf "Air") then {				 	// Correct width and length factor for air
			_widthFactor		= 0.3;
		};
		if (_vehicle isKindOf "Helicopter") then {
			_widthFactor		= 0.2;
			_lengthFactor		= 0.45;
		};
		private _centerOfMass 	= getCenterOfMass _vehicle;
		private _bbr			= boundingBoxReal _vehicle;
		private _p1				= _bbr select 0;
		private _p2				= _bbr select 1;
		private _maxWidth		= abs ((_p2 select 0) - (_p1 select 0));
		private _widthOffset	= ((_maxWidth / 2) - abs (_centerOfMass select 0)) * _widthFactor;
		private _maxLength		= abs ((_p2 select 1) - (_p1 select 1));
		private _lengthOffset	= ((_maxLength / 2) - abs (_centerOfMass select 1)) * _lengthFactor;
		private _maxHeight		= abs ((_p2 select 2) - (_p1 select 2));
		private _heightOffset	= _maxHeight / 6;
		private _rearCorner		= [(_centerOfMass select 0) + _widthOffset, (_centerOfMass select 1) - _lengthOffset, (_centerOfMass select 2) + _heightOffset];
		private _rearCorner2	= [(_centerOfMass select 0) - _widthOffset, (_centerOfMass select 1) - _lengthOffset, (_centerOfMass select 2) + _heightOffset];
		private _frontCorner	= [(_centerOfMass select 0) + _widthOffset, (_centerOfMass select 1) + _lengthOffset, (_centerOfMass select 2) + _heightOffset];
		private _frontCorner2	= [(_centerOfMass select 0) - _widthOffset, (_centerOfMass select 1) + _lengthOffset, (_centerOfMass select 2) + _heightOffset];
		[_rearCorner, _rearCorner2, _frontCorner, _frontCorner2];
	};
	
	ASL_Rope_Set_Mass = {
		private _object 	= [_this, 0] call BIS_fnc_param;
		private _mass 	= [_this, 1] call BIS_fnc_param;
		_object setMass _mass;
	};
	
	ASL_Rope_Adjust_Mass = {
		params [["_object", objNull], ["_vehicle", objNull], ["_ropes", []]];
		if (isNull _object || isNull _vehicle) exitWith {};
		private _lift = [_vehicle] call ASL_Rope_Get_Lift_Capability;
		private _maxLiftableMass = _lift * ASL_MaxLiftableMassFactor;
		private _originalMass = getMass _object;
		private _heavyLiftMinLift = missionNamespace getVariable ["ASL_HEAVY_LIFTING_MIN_LIFT_OVERRIDE", 5000];
		// diag_log formatText [
			// "%1%2%3%4%5%6%7%8%9%10%11", time, 
			// "s  (ASL_Rope_Adjust_Mass) _object: ",	_object,
			// "    _originalMass: ", _originalMass,
			// "    _vehicle: ", _vehicle,
			// "    _lift: ", _lift,
			// "    _heavyLiftMinLift: ", _heavyLiftMinLift
		// ];
		if (_originalMass >= _lift * 0.8 && _lift >= _heavyLiftMinLift && _originalMass <= _maxLiftableMass) then {
			private _originalMassSet = (getMass _object) == _originalMass;
			private ["_ends", "_endDistance", "_ropeLength"];
			while {_object in (ropeAttachedObjects _vehicle) && _originalMassSet} do {
				{
					_ends = ropeEndPosition _x;
					_endDistance = (_ends select 0) distance (_ends select 1);
					_ropeLength = ropeLength _x;
					if ((_ropeLength - 2) <= _endDistance && ((position _vehicle) select 2) > 0) then {
						[[_object, (_lift * 0.8 + ((_originalMass / _maxLiftableMass) * (_lift * 0.2)))], "ASL_Rope_Set_Mass", _object, true] call ASL_RemoteExec;
						_originalMassSet = false;
					};
				} forEach _ropes;
				sleep 0.1;
			};
			while {_object in (ropeAttachedObjects _vehicle)} do {
				sleep 0.5;
			};
			[[_object, _originalMass], "ASL_Rope_Set_Mass", _obj, true] call ASL_RemoteExec;
		};
	};
	
	/*
	 Constructs an array of all active (or inactive) rope indexes and position labels 
	 (e.g. [[rope index,"Front"], [rope index,"Rear"]]) for a specified vehicle
	*/
	ASL_Get_Active_Ropes = {
		params [["_vehicle", objNull], ["_active", false]];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Get_Ropes) _vehicle: ", _vehicle, "    _active: ", _active];
		if (isNull _vehicle) exitWith {false};
		private _activeRopes = [];
		private _existingRopes = _vehicle getVariable ["ASL_Ropes", []];
		private _ropeLabelSets = [
			[format[localize "STR_ASL_CENTER"]],
			[format[localize "STR_ASL_FRONT"], format[localize "STR_ASL_REAR"]],
			[format[localize "STR_ASL_FRONT"], format[localize "STR_ASL_CENTER"], format[localize "STR_ASL_REAR"]]
		];
		private _totalExistingRopes = count _existingRopes;
		private ["_ropeLabels"];
		{
			if ((_active && count _x > 0) || (!_active && count _x == 0)) then {
				_ropeLabels = _ropeLabelSets select (_totalExistingRopes - 1);
				_activeRopes pushBack [_foreachindex, _ropeLabels select _foreachindex];
			};
		} forEach _existingRopes;
		_activeRopes;
	};
	
	ASL_Get_Active_Ropes_With_Cargo = {
		params [["_vehicle", objNull], ["_unit", objNull]];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		private _activeRopesWithCargo = [];
		private _existingCargo = _vehicle getVariable ["ASL_Cargo", []];
		private _activeRopes = [_vehicle, true] call ASL_Get_Active_Ropes;
		private ["_cargo"];
		{
			_cargo = _existingCargo select (_x select 0);
			if (!isNull _cargo) then {
				if (!alive _cargo || ropeAttachedTo _cargo != _vehicle) exitWith {
					[_vehicle, _unit, _foreachindex] call ASL_Release_Cargo;  // in case cargo destroyed
				};
				_activeRopesWithCargo pushBack _x;
			};
		} forEach _activeRopes;
		_activeRopesWithCargo;
	};
	
	ASL_Get_Active_Ropes_Without_Cargo = {
		params [["_vehicle", objNull]];
		if (isNull _vehicle) exitWith {};
		private _activeRopesWithoutCargo = [];
		private _existingCargo = _vehicle getVariable ["ASL_Cargo", []];
		private _activeRopes = [_vehicle, true] call ASL_Get_Active_Ropes;
		// diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (ASL_Get_Active_Ropes_Without_Cargo) _vehicle: ", _vehicle, ", _existingCargo: ", _existingCargo, ", _activeRopes: ", _activeRopes];
		private ["_cargo"];
		{
			_cargo = _existingCargo select (_x select 0);
			if (isNull _cargo) then {
				_activeRopesWithoutCargo pushBack _x;
			};
		} forEach _activeRopes;
		// diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (ASL_Get_Active_Ropes_Without_Cargo) _activeRopesWithoutCargo: ", _activeRopesWithoutCargo];
		_activeRopesWithoutCargo;
	};
	
	ASL_Get_Ropes = {
		params [["_vehicle", objNull], "_ropesIndex"];
		if (isNull _vehicle) exitWith {};
		private _selectedRopes = [];
		private _allRopes = _vehicle getVariable ["ASL_Ropes", []];
		if (count _allRopes > _ropesIndex) then {
			_selectedRopes = _allRopes select _ropesIndex;
		};
		_selectedRopes;
	};
	
	ASL_Get_Ropes_Count = {
		params [["_vehicle", objNull]];
		if (isNull _vehicle) exitWith {};
		count (_vehicle getVariable ["ASL_Ropes", []]);
	};
	
	ASL_Get_Cargo = {
		params [["_vehicle", objNull], "_ropesIndex"];
		if (isNull _vehicle) exitWith {};
		private _selectedCargo = objNull;
		private _allCargo = _vehicle getVariable ["ASL_Cargo", []];
		if (count _allCargo > _ropesIndex) then {
			_selectedCargo = _allCargo select _ropesIndex;
		};
		_selectedCargo;
	};
	
	ASL_Get_Ropes_And_Cargo = {
		params [["_vehicle", objNull], "_ropesIndex"];
		if (isNull _vehicle) exitWith {};
		private _selectedCargo = (_this call ASL_Get_Cargo);
		private _selectedRopes = (_this call ASL_Get_Ropes);
		[_selectedRopes, _selectedCargo];
	};
	
	ASL_Extend_Ropes_Action_Check = {
		params [["_vehicle", objNull], ["_unit", objNull], ["_toGround", false]];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Extend_Ropes_Action_Check) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		if ([getConnectedUAV _unit, _unit] call ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Extend_Ropes_Action_Check) EXIT 1, can release: ", [getConnectedUAV _unit, _unit] call ASL_Can_Release_Cargo];
			[getConnectedUAV _unit, _toGround] call ASL_Can_Extend_Ropes
		};
		if (vehicle _unit == _vehicle && [_vehicle, _unit] call ASL_Is_Unit_Authorized) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Extend_Ropes_Action_Check) EXIT 2, can release: ", [_vehicle, _unit] call ASL_Can_Release_Cargo];
			[_vehicle, _toGround] call ASL_Can_Extend_Ropes
		};
		false
	};
	
	ASL_Is_Unit_Authorized = {
		params [["_vehicle", objNull], ["_unit", objNull]];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Is_Unit_Authorized) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		if (driver _vehicle == _unit && ASL_PilotsAuthorized || 
			gunner _vehicle == _unit && ASL_GunnersAuthorized || 
			_vehicle getCargoIndex _unit > -1 && ASL_PassengersAuthorized)
		exitWith {true};
		if !(ASL_CopilotsAuthorized) exitWith {false};
		private _cfg = configFile >> "CfgVehicles" >> typeOf(_vehicle);
		private _turrets = _cfg >> "turrets";
		private _isCopilot = false;
		for "_i" from 0 to (count _turrets - 1) do {
			private _turret = _turrets select _i;
			if (getNumber(_turret >> "iscopilot") == 1) exitWith {
				_isCopilot = ((_vehicle turretUnit [_i]) == _unit);				// check, if unit is copilot
			};
		};
		_isCopilot
	};
	
	ASL_Can_Extend_Ropes = {
		params [["_vehicle", objNull], ["_toGround", false]];
		if (isNull _vehicle) exitWith {false};
		if !([_vehicle] call ASL_Is_Supported_Vehicle) exitWith {false};
		private _allRopes = _vehicle getVariable ["ASL_Ropes", []];
		if (count _allRopes == 0) exitWith {false};
		if (count ([_vehicle, true] call ASL_Get_Active_Ropes) == 0) exitWith {false};
		private _exit = false;
		if (_toGround) then {
			// private _ropeEndHeight = ropeEndPosition (_allRopes #0 #0) #1 #2;
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Extend_Ropes) _vehicleHeight: ", _vehicleHeight, ", _ropeEndHeight: ", _ropeEndHeight];
			// if (_ropeEndHeight < ASL_ExtendShortenRopeLength) exitWith {_exit = true};
			if (ropeEndPosition (_allRopes #0 #0) #1 #2 < ASL_ExtendShortenRopeLength) exitWith {_exit = true};
			private _vehicleHeight = getPos _vehicle #2;
			if (_vehicleHeight < ASL_ExtendShortenRopeLength || _vehicleHeight > ASL_MaxRopeLength) then {_exit = true};
		};
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Extend_Ropes) _vehicle: ", _vehicle, "    _toGround: ", _toGround];
		if (_exit) exitWith {false};
		true;
	};

	ASL_Extend_Ropes_Action = {
		params [["_vehicle", objNull], ["_unit", objNull], ["_toGround", false]];
		diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (ASL_Extend_Ropes_Action) _vehicle: ", _vehicle, ", _unit: ", _unit, ", _toGround: ", _toGround];
		if (isNull _vehicle || isNull _unit) exitWith {};
		private _activeRopes = [_vehicle, true] call ASL_Get_Active_Ropes;
		private _canReleaseCargo = false;
		if (_toGround) then {
			_canReleaseCargo = [_vehicle, _unit] call ASL_Can_Release_Cargo;
		};
		private ["_messageText"];
		if (count _activeRopes == 1) exitWith {
			private _ropeLength = [_vehicle, _activeRopes #0 #0, _toGround] call ASL_Extend_Ropes;
			if (_ropeLength <= ASL_MaxRopeLength) exitWith {
				// private _messageText = format[localize "STR_ASL_ROPES_EXTENDED_TO", _ropeLength];
				_messageText = format[localize "STR_ASL_ROPES_EXTENDED_TO", _ropeLength];
				if (_toGround) then {_messageText = format[localize "STR_ASL_ROPES_EXTENDED_TO_G", _ropeLength]};
				if (_ropeLength == ASL_MaxRopeLength) then {
					_messageText = formatText ["%1%2", _messageText, " (max)"];
				};
				if (ASL_RopeMessagesAuthorized) then {hint _messageText};
				diag_log formatText ["%1%2%3%4%5%6%7%8%9", time, "s  (ASL_Extend_Ropes_Action) can release cargo: ", [_vehicle, _unit] call ASL_Can_Release_Cargo];
				if (_toGround && _canReleaseCargo) then {
					private _rope = (_vehicle getVariable "ASL_Ropes") #0 #0;
					private _cargo = (_vehicle getVariable "ASL_Cargo") #0;
					[_vehicle, _unit, _rope, _ropeLength, _cargo] spawn ASL_Release_Cargo_Near_Ground;
				};
			};
			if (!ASL_RopeMessagesAuthorized) exitWith {};
			hint format[localize "STR_ASL_ALREADY_MAX_LENGTH", ASL_MaxRopeLength];
		};
		[format[localize "STR_ASL_EXTEND"], "ASL_Extend_Ropes_Index_Action", _activeRopes, format[localize "STR_ASL_ROPE"], _vehicle, _unit, _toGround] call ASL_Show_Select_Ropes_Menu;
		private _extendedRopes = _vehicle getVariable ["ASL_Ropes_Change", []];
		// diag_log formatText ["%1%2%3%4%5%6%7%8%9", time, "s  (ASL_Extend_Ropes_Action) _extendedRopes: ", _extendedRopes, ", _activeRopes: ", _activeRopes];
		if (count _extendedRopes == 0) exitWith {};
		private ["_extendedRopeIndex", "_activeCargoRopes"];
		_messageText = format[localize "STR_ASL_ROPES_EXTENDED"];
		if (_toGround) then {
			// _messageText = formatText ["%1%2%3", _messageText, " ", format[localize "STR_ASL_ROPES_EXTENDED_TG"]];					
			_messageText = format[localize "STR_ASL_ROPES_EXTENDED_TG", _messageText];
			_activeCargoRopes = [_vehicle, _unit] call ASL_Get_Active_Ropes_With_Cargo;
		};
		{
			if (_x #1 <= ASL_MaxRopeLength) then {
				_extendedRopeIndex = _x #0;
				_messageText = formatText ["%1%2%3%4%5%6", _messageText, lineBreak, format[localize "STR_ASL_ROPES_EXTENDED_TO_IND", (_activeRopes select {_x #0 == _extendedRopeIndex}) #0 #1, _x #1]];					
				if (_x #1 == ASL_MaxRopeLength) then {
					_messageText = formatText ["%1%2", _messageText, " (max)"];
				};
				diag_log formatText [
					"%1%2%3%4%5%6%7%8%9", time,
					"s  (ASL_Extend_Ropes_Action) can release cargo: ", [_vehicle, _unit] call ASL_Can_Release_Cargo,
					", _extendedRopeIndex: ", _extendedRopeIndex
				];
				if (_toGround && _canReleaseCargo) then {
					private _rope = (_vehicle getVariable "ASL_Ropes") #_extendedRopeIndex #0;
					private _cargo = (_vehicle getVariable "ASL_Cargo") #_extendedRopeIndex;
					[_vehicle, _unit, _rope, _x #1, _cargo, _extendedRopeIndex] spawn ASL_Release_Cargo_Near_Ground;
				};
			} else {
				_messageText = formatText ["%1%2%3%4%5%6", _messageText, lineBreak, format[localize "STR_ASL_ALREADY_MAX_LENGTH", ASL_MaxRopeLength]];	
			};
		} forEach _extendedRopes;
		_messageText setAttributes ["align", "left"];
		if (ASL_RopeMessagesAuthorized) then {hint composeText [_messageText]};
		_vehicle setVariable ["ASL_Ropes_Change", nil];
	};
	
	ASL_Release_Cargo_Near_Ground = {
		params [["_vehicle", objNull], ["_unit", objNull], ["_rope", objNull], ["_ropeLength", 0], ["_cargo", objNull], ["_ropesIndex", 0]];
		diag_log formatText [
			"%1%2%3%4%5%6%7%8%9%10%11%12%13", time,
			"s  (ASL_Release_Cargo_Near_Ground) _vehicle: ", _vehicle,
			", _unit: ", _unit,
			", _rope: ", _rope,
			", _ropeLength: ", _ropeLength,
			", _cargo: ", _cargo
		];
		if (isNull _vehicle || isNull _unit || isNull _rope || _ropeLength == 0 || isNull _cargo) exitWith {};
		private _future = time + 60;
		sleep 1;
		while {
			!ropeUnwound _rope && 
			alive _vehicle &&
			time < _future && 
			ropeLength _rope < _ropeLength &&
			alive _cargo &&
			getPos _cargo #2 > 1
		} do {sleep 1};
		diag_log formatText [
			"%1%2%3%4%5%6%7%8%9%10%11%12%13", time,
			"s  (ASL_Release_Cargo_Near_Ground) EXIT LOOP! ropeUnwound: ", !ropeUnwound _rope,
			", alive _vehicle: ", alive _vehicle,
			", time < _future: ", time < _future,
			", ropeLength _rope < _ropeLength: ", ropeLength _rope < _ropeLength,
			", alive _cargo: ", alive _cargo,
			", getPos _cargo #2 > 1: ", getPos _cargo #2 > 1
		];
		if (!alive _vehicle || (getPos _cargo #2 > 5 && alive _cargo)) exitWith {};
		// [_vehicle, _unit] call ASL_Release_Cargo_Action;
		[_ropesIndex, _vehicle, _unit] call ASL_Release_Cargo_Index_Action;
	};

	ASL_Show_Select_Ropes_Menu = {
		params ["_title", "_functionName", "_ropesIndexAndLabelArray", ["_ropesLabel", format[localize "STR_ASL_ROPE"]], ["_vehicle", objNull], ["_unit", objNull], ["_toGround", false]];
		// diag_log formatText ["%1%2%3%4%5%6%7%8%9%10%11%12%13%14%15", time, "s  (ASL_Show_Select_Ropes_Menu) _title: ", _title, ", _functionName: ", _functionName, ", _ropesIndexAndLabelArray: ", _ropesIndexAndLabelArray, ", _ropesLabel: ", _ropesLabel, ", _vehicle: ", _vehicle, ", _unit: ", _unit, ", _toGround: ", _toGround];
		if (isNull _vehicle || isNull _unit) exitWith {};
		ASL_Show_Select_Ropes_Menu_Array = [[_title, false]];
		ASL_Vehicle = _vehicle;
		ASL_Unit = _unit;
		ASL_toGround = _toGround;
		{
			ASL_Show_Select_Ropes_Menu_Array pushBack [(_x #1) + " " + _ropesLabel, [0], "", -5, [["expression", "["+(str (_x select 0))+", ASL_Vehicle, ASL_Unit, ASL_toGround] call " + _functionName]], "1", "1"];
		} forEach _ropesIndexAndLabelArray;
		ASL_Show_Select_Ropes_Menu_Array pushBack [format[localize "STR_ASL_ALL"]  + " " + _ropesLabel, [0], "", -5, [["expression", "{[_x, ASL_Vehicle, ASL_Unit, ASL_toGround] call " + _functionName + "} forEach [0, 1, 2];"]], "1", "1"];
		showCommandingMenu "";
		showCommandingMenu "#USER:ASL_Show_Select_Ropes_Menu_Array";
		waitUntil {commandingMenu == ""};
	};
	
	ASL_Extend_Ropes_Index_Action = {
		params ["_ropesIndex", ["_vehicle", objNull], ["_unit", objNull], ["_toGround", false]];
		// diag_log formatText ["%1%2%3%4%5%6%7%8%9", time, "s  (ASL_Extend_Ropes_Index_Action) _ropesIndex: ", _ropesIndex, ", _vehicle: ", _vehicle, ", _unit: ", _unit, ", _toGround: ", _toGround];
		if (isNull _vehicle || isNull _unit) exitWith {};
		if (_ropesIndex >= 0 && !isNull _vehicle && [_vehicle, _toGround] call ASL_Can_Extend_Ropes) then {
			private _ropeLength = [_vehicle, _ropesIndex, _toGround] call ASL_Extend_Ropes;
			[_vehicle, _ropeLength, _ropesIndex] call ASL_Save_Rope_Change;
		};
	};
	
	ASL_Save_Rope_Change = {
		params [["_vehicle", objNull], ["_ropeLength", 0], ["_ropesIndex", 0]];
		if (isNull _vehicle) exitWith {};
		// diag_log formatText ["%1%2%3%4%5%6%7%8%9", time, "s  (ASL_Save_Rope_Change) _ropeLength: ", _ropeLength, ", _ropesIndex: ", _ropesIndex];
		private _existingRopes = [_vehicle, _ropesIndex] call ASL_Get_Ropes;
		if (count _existingRopes == 0 || _ropeLength == 0) exitWith {};
		private _changedRopes = _vehicle getVariable ["ASL_Ropes_Change", []];
		_changedRopes pushBack [_ropesIndex, _ropeLength];
		_vehicle setVariable ["ASL_Ropes_Change", _changedRopes];
	};
	
	ASL_Extend_Ropes = {
		params [["_vehicle", objNull], ["_ropesIndex", 0], ["_toGround", false]];
		if (isNull _vehicle) exitWith {};
		if !(local _vehicle) exitWith {[_this, "ASL_Extend_Ropes", _vehicle, true] call ASL_RemoteExec};
		private _existingRopes = [_vehicle, _ropesIndex] call ASL_Get_Ropes;
		if (count _existingRopes == 0) exitWith {0};
		private _ropeLength = ropeLength (_existingRopes select 0);
		if (_ropeLength >= ASL_MaxRopeLength) exitWith {ASL_MaxRopeLength + 1};
		private _unwindLength = ASL_ExtendShortenRopeLength;
		if (_toGround) then {
			_unwindLength = ceil((getPos _vehicle select 2) - _ropeLength + 5);
			/*
				'getPos' will return the height of the vehicle above the next object underneath. 
				So, if the vehicle has a sling load, it is likely the height will be measured false
				from vehicle to the sling load underneath. If there is a cargo, recalculate unwind
				length from sling load to ground.
			*/
			private _allCargo = _vehicle getVariable ["ASL_Cargo", []];
			private _cargo = _allCargo #_ropesIndex;
			if (isNull _cargo) exitWith {};
			_unwindLength = ceil(getPos _cargo select 2) + 3;
		};
		if (_ropeLength + _unwindLength > ASL_MaxRopeLength) then {
			_unwindLength = ASL_MaxRopeLength - _ropeLength;
		};
		diag_log formatText [
			"%1%2%3%4%5%6%7%8%9%10%11%12%13", time,
			"s  (ASL_Extend_Ropes) _unwindLength: ", _unwindLength,
			", vehicle height: ", getPos _vehicle select 2,
			", ASL_MaxRopeLength: ", ASL_MaxRopeLength,
			", _ropeLength: ", _ropeLength,
			", _ropesIndex: ", _ropesIndex
		];
		{
			ropeUnwind [_x, 3, _unwindLength, true];
		} forEach _existingRopes;
		_ropeLength = _ropeLength + _unwindLength;
		_ropeLength
	};
	
	ASL_Shorten_Ropes_Action_Check = {
		params [["_vehicle", objNull], ["_unit", objNull]];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Shorten_Ropes_Action_Check) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		if ([getConnectedUAV _unit, _unit] call ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Shorten_Ropes_Action_Check) EXIT 1, can release: ", [getConnectedUAV _unit, _unit] call ASL_Can_Release_Cargo];
			[getConnectedUAV _unit] call ASL_Can_Shorten_Ropes
		};
		if (vehicle _unit == _vehicle && [_vehicle, _unit] call ASL_Is_Unit_Authorized) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Shorten_Ropes_Action_Check) EXIT 2, can release: ", [_vehicle, _unit] call ASL_Can_Release_Cargo];
			[_vehicle] call ASL_Can_Shorten_Ropes
		};
		false
	};
	
	ASL_Can_Shorten_Ropes = {
		params ["_vehicle"];
		params [["_vehicle", objNull]];
		if (isNull _vehicle) exitWith {};
		if !([_vehicle] call ASL_Is_Supported_Vehicle) exitWith {false};
		if (count (_vehicle getVariable ["ASL_Ropes", []]) == 0) exitWith {false};
		if (count ([_vehicle, true] call ASL_Get_Active_Ropes) == 0) exitWith {false};
		true
	};
	
	ASL_Shorten_Ropes_Action = {
		params [["_vehicle", objNull], ["_unit", objNull]];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Extend_Ropes_Action) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		if !([_vehicle] call ASL_Can_Shorten_Ropes) exitWith {false};
		private _activeRopes = [_vehicle, true] call ASL_Get_Active_Ropes;
		if (count _activeRopes == 1) exitWith {
			private _ropeLength = [_vehicle, _activeRopes #0 #0] call ASL_Shorten_Ropes;
			if (!ASL_RopeMessagesAuthorized) exitWith {};
			if (_ropeLength >= ASL_MinRopeLength) exitWith {
				private _messageText = format[localize "STR_ASL_ROPES_SHORTENED_TO", _ropeLength];
				if (_ropeLength == ASL_MinRopeLength) then {
					_messageText = formatText ["%1%2", _messageText, " (min)"];
				};
				hint _messageText;
			};
			hint format[localize "STR_ASL_ALREADY_MIN_LENGTH", ASL_MinRopeLength];
		};
		[format[localize "STR_ASL_SHORTEN"], "ASL_Shorten_Ropes_Index_Action", _activeRopes, format[localize "STR_ASL_ROPE"], _vehicle, _unit] call ASL_Show_Select_Ropes_Menu;
		private _shortenedRopes = _vehicle getVariable ["ASL_Ropes_Change", []];
		if (count _shortenedRopes > 0) then {
			private _messageText = format[localize "STR_ASL_ROPES_SHORTENED"];
			private ["_shortenedRopesIndex"];
			{
				if (_x #1 >= ASL_MinRopeLength) then {
					_shortenedRopesIndex = _x#0;
					// _messageText = formatText ["%1%2%3%4%5%6", _messageText, lineBreak, format[localize "STR_ASL_ROPES_SHORTENED_TO_IND", _activeRopes select _x select 0 select 1, _x select 1]];
					_messageText = formatText ["%1%2%3%4%5%6", _messageText, lineBreak, format[localize "STR_ASL_ROPES_SHORTENED_TO_IND", (_activeRopes select {_x#0 == _shortenedRopesIndex})#0#1, _x#1]];						
					if (_x #1 == ASL_MinRopeLength) then {
						_messageText = formatText ["%1%2", _messageText, " (min)"];
					};
				} else {
					_messageText = formatText ["%1%2%3%4%5%6", _messageText, lineBreak, format[localize "STR_ASL_ALREADY_MIN_LENGTH", ASL_MinRopeLength]];	
				};
			} forEach _shortenedRopes;
			_messageText setAttributes ["align", "left"];
			if (ASL_RopeMessagesAuthorized) then {hint composeText [_messageText]};
			_vehicle setVariable ["ASL_Ropes_Change", nil];
		};
	};
	
	ASL_Shorten_Ropes_Index_Action = {
		params ["_ropesIndex", ["_vehicle", objNull], ["_unit", objNull]];
		if (isNull _vehicle || isNull _unit) exitWith {};
		if (_ropesIndex >= 0 && !isNull _vehicle && [_vehicle] call ASL_Can_Shorten_Ropes) then {
			private _ropeLength = [_vehicle, _ropesIndex] call ASL_Shorten_Ropes;
			[_vehicle, _ropeLength, _ropesIndex] call ASL_Save_Rope_Change;
		};
	};
	
	ASL_Shorten_Ropes = {
		params [["_vehicle", objNull], ["_ropesIndex", 0]];
		if (isNull _vehicle) exitWith {};
		if !(local _vehicle) exitWith {[_this,"ASL_Shorten_Ropes", _vehicle, true] call ASL_RemoteExec};
		private _existingRopes = [_vehicle, _ropesIndex] call ASL_Get_Ropes;
		private _ropeLength = -1;
		if (count _existingRopes > 0) then {
			_ropeLength = ropeLength (_existingRopes select 0);
			if (_ropeLength <= ASL_MinRopeLength) exitWith {
				if (ASL_MinRopeLengthDropCargo) then {
					_this call ASL_Release_Cargo;
				};
				_ropeLength = ASL_MinRopeLength - 1;
			}; 
			private _unwindLength = ASL_ExtendShortenRopeLength;
			if (_ropeLength - _unwindLength < 5) then {
				_unwindLength = _ropeLength - 5;
			}; 
			if (_ropeLength < 10) then {_unwindLength = 1};
			{
				ropeUnwind [_x, 3, -_unwindLength, true];
			} forEach _existingRopes;
			_ropeLength = _ropeLength - _unwindLength;
		};
		_ropeLength
	};
	
	ASL_Release_Cargo_Action_Check = {
		params [["_vehicle", objNull], ["_unit", objNull]];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Release_Cargo_Action_Check) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		if ([getConnectedUAV _unit, _unit] call ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Release_Cargo_Action_Check) EXIT 1, can release: ", [getConnectedUAV _unit, _unit] call ASL_Can_Release_Cargo];
			[getConnectedUAV _unit, _unit] call ASL_Can_Release_Cargo
		};
		if (vehicle _unit == _vehicle && [_vehicle, _unit] call ASL_Is_Unit_Authorized) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Release_Cargo_Action_Check) EXIT 2, can release: ", [_vehicle, _unit] call ASL_Can_Release_Cargo];
			[_vehicle, _unit] call ASL_Can_Release_Cargo
		};
		false
	};
	
	ASL_Can_Release_Cargo = {
		params [["_vehicle", objNull], ["_unit", objNull]];
		if (isNull _vehicle || isNull _unit) exitWith {};
		if !([_vehicle] call ASL_Is_Supported_Vehicle) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Release_Cargo) EXIT 1"];
			false
		};
		_existingRopes = _vehicle getVariable ["ASL_Ropes", []];
		if (count _existingRopes == 0) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Release_Cargo) EXIT 2"];
			false
		};
		private _activeRopes = [_vehicle, _unit] call ASL_Get_Active_Ropes_With_Cargo;		
		if (count _activeRopes == 0) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Release_Cargo) EXIT 3"];
			false
		};
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Release_Cargo) _existingRopes: ", _existingRopes];
		true
	};
	
	ASL_Release_Cargo_Action = {
		params [["_vehicle", objNull], ["_unit", objNull]];
		diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Release_Cargo_Action) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		if !([_vehicle, _unit] call ASL_Can_Release_Cargo) exitWith {false};
		private _activeRopes = [_vehicle, _unit] call ASL_Get_Active_Ropes_With_Cargo;	
		if (count _activeRopes == 1) exitWith {
			[_vehicle, _unit, (_activeRopes select 0) select 0] call ASL_Release_Cargo
		};
		[format[localize "STR_ASL_RELEASE"], "ASL_Release_Cargo_Index_Action", _activeRopes, format[localize "STR_ASL_CARGO"], _vehicle, _unit] call ASL_Show_Select_Ropes_Menu;
	};
	
	ASL_Release_Cargo_Index_Action = {
		params ["_ropesIndex", ["_vehicle", objNull], ["_unit", objNull]];
		diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (ASL_Release_Cargo_Index_Action) _vehicle: ", _vehicle, ", _unit: ", _unit, ", _ropesIndex: ", _ropesIndex];
		if (isNull _vehicle || isNull _unit) exitWith {};
		if (_ropesIndex >= 0 && [_vehicle, _unit] call ASL_Can_Release_Cargo) then {
			[_vehicle, _unit, _ropesIndex] call ASL_Release_Cargo;
		};
	};
	
	ASL_Release_Cargo = {
		params [["_vehicle", objNull], ["_unit", objNull], ["_ropesIndex", 0]];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		if !(local _vehicle) exitWith {[_this, "ASL_Release_Cargo", _vehicle, true] call ASL_RemoteExec};
		private _existingRopesAndCargo = [_vehicle, _ropesIndex] call ASL_Get_Ropes_And_Cargo;
		private _existingRopes = _existingRopesAndCargo select 0;
		private _existingCargo = _existingRopesAndCargo select 1; 
		{
			_existingCargo ropeDetach _x;
		} forEach _existingRopes;
		_existingCargo setVariable ["ASL_RopesIndex", nil, true];
		private _allCargo = _vehicle getVariable ["ASL_Cargo", []];
		_allCargo set [_ropesIndex, objNull];
		_vehicle setVariable ["ASL_Cargo", _allCargo, true];
		_this call ASL_Retract_Ropes;
	};
	
	ASL_Retract_Ropes_Action_Check = {
		params [["_vehicle", objNull], ["_unit", objNull]];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Retract_Ropes_Action_Check) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if ([getConnectedUAV _unit, _unit] call ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Retract_Ropes_Action_Check) EXIT 1"];
			[getConnectedUAV _unit, _unit] call ASL_Can_Retract_Ropes
		};
		if (vehicle _unit == _unit) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Retract_Ropes_Action_Check) EXIT 2"];
			[cursorTarget, _unit, true] call ASL_Can_Retract_Ropes
		}; 
		if (vehicle _unit == _vehicle && [_vehicle, _unit] call ASL_Is_Unit_Authorized) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Retract_Ropes_Action_Check) EXIT 3"];
			[_vehicle, _unit] call ASL_Can_Retract_Ropes
		};
		false
	};

	ASL_Can_Retract_Ropes = {
		params [["_vehicle", objNull], ["_unit", objNull], ["_distanceCheck", false]];
		if (isNull _vehicle || isNull _unit) exitWith {};
		if (_distanceCheck && _unit distance _vehicle > ASL_MaxDeployRetractDistance) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Retract_Ropes) EXIT 1"];
			false
		};
		if !([_vehicle] call ASL_Is_Supported_Vehicle) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Retract_Ropes) EXIT 2"];
			false
		};
		private _existingRopes = _vehicle getVariable ["ASL_Ropes", []];
		if (count _existingRopes == 0) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Retract_Ropes) EXIT 3"];
			false
		};
		private _activeRopes = [_vehicle] call ASL_Get_Active_Ropes_Without_Cargo;
		if (count _activeRopes == 0) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Retract_Ropes) EXIT 5"];
			false
		};
		true;
	};
	
	ASL_Retract_Ropes_Action = {
		params [["_vehicle", objNull], ["_unit", objNull]];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Retract_Ropes_Action) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if (isNull _vehicle || isNull _unit) exitWith {};
		private _activeRopes = [_vehicle] call ASL_Get_Active_Ropes_Without_Cargo;
		if (count _activeRopes == 1) exitWith {		
			diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Retract_Ropes_Action) inactive ropes: ", [_vehicle] call ASL_Get_Active_Ropes, ", existing ropes: ", _vehicle getVariable ["ASL_Ropes", []]];
			[_vehicle, _unit, (_activeRopes select 0) select 0] call ASL_Retract_Ropes;
			if (!ASL_RopeMessagesAuthorized) exitWith {};
			hint format[localize "STR_ASL_ROPES_RETRACTED"];
			[] spawn {
				sleep 3;
				hintSilent "";
			};
		};
		[format[localize "STR_ASL_RETRACT"], "ASL_Retract_Ropes_Index_Action", _activeRopes, format[localize "STR_ASL_ROPE"], _vehicle, _unit] call ASL_Show_Select_Ropes_Menu;
	};
	
	ASL_Retract_Ropes_Index_Action = {
		params ["_ropesIndex", ["_vehicle", objNull], ["_unit", objNull]];
		// diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (ASL_Retract_Ropes_Index_Action) _unit: ", _unit, ", _vehicle: ", _vehicle, ", _ropesIndex: ", _ropesIndex];
		if (isNull _vehicle || isNull _unit) exitWith {};
		// if (_ropesIndex >= 0 && [_vehicle, _unit] call ASL_Can_Retract_Ropes) then {
		if (_ropesIndex >= 0) then {
			[_vehicle, _unit, _ropesIndex] call ASL_Retract_Ropes;
		};
	};
	
	ASL_Retract_Ropes = {
		// params [["_vehicle", objNull], ["_unit", objNull], ["_ropesIndex", 0], ["_hadCargo", false]];
		params [["_vehicle", objNull], ["_unit", objNull], ["_ropesIndex", 0]];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		if !(local _vehicle) exitWith {[_this, "ASL_Retract_Ropes", _vehicle, true] call ASL_RemoteExec};
		private _existingRopesAndCargo = [_vehicle, _ropesIndex] call ASL_Get_Ropes_And_Cargo;
		private _existingRopes = _existingRopesAndCargo select 0;
		private _existingCargo = _existingRopesAndCargo select 1; 
		private _cargoArray = ropeAttachedObjects _vehicle;
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Retract_Ropes) _vehicle: ", _vehicle, "    _cargoArray: ", _cargoArray];
		if (count _cargoArray > 0) then {
			private _helper = (_cargoArray select {_x getVariable ["ASL_Ropes_Pick_Up_Helper", false]}) select 0;
			if (isNil {_helper}) exitWith {};
			// if (!isNull _helper) then {
			private _ropeHolder = attachedTo _helper;
			if (!isNull _ropeHolder) then {_unit = _ropeHolder};
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Retract_Ropes) _helper: ", _helper, "    _ropeHolder: ", _ropeHolder];
			// };
		};
		if (isNull _existingCargo) then {
			[_vehicle, _unit, _ropesIndex] call ASL_Drop_Ropes;
			diag_log formatText [
				"%1%2%3%4%5%6%7%8%9%10%11%12", time,
				"s  (ASL_Retract_Ropes) _existingRopes: ", _existingRopes,
				// ", Ropes_Without_Cargo: ", [_vehicle] call ASL_Get_Active_Ropes_Without_Cargo,
				// ", _allRopes: ", _vehicle getVariable ["ASL_Ropes", []],
				", _activeRopes: ", [_vehicle, true] call ASL_Get_Active_Ropes,
				", _inactiveRopes: ", [_vehicle] call ASL_Get_Active_Ropes
			];
			{
				[_x, _vehicle] spawn {
					params ["_rope", "_vehicle"];
					if (isNull _rope || isNull _vehicle) exitWith {};
					private _future = time + 25;
					ropeUnwind [_rope, 3, 0];
					while {!ropeUnwound _rope && alive _vehicle && time < _future} do {sleep 1};
					ropeDestroy _rope;
				};
			} forEach _existingRopes;
			private _allRopes = _vehicle getVariable ["ASL_Ropes", []];
			_allRopes set [_ropesIndex, []];
			_vehicle setVariable ["ASL_Ropes", _allRopes, true];
		};
		private _activeRopes = [_vehicle, true] call ASL_Get_Active_Ropes;
		if (count _activeRopes == 0) then {
			_vehicle setVariable ["ASL_Ropes", nil, true];
		};
	};
	
	ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit = {
		params [["_UAV", objNull], ["_unit", objNull]];
		if (isNull _UAV || isNull _unit) exitWith {false};
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit) _UAV: ", _UAV, "    _unit: ", _unit];
		if (UAVControl _UAV select 0 == _unit && (UAVControl _UAV select 1 == "GUNNER" || UAVControl _UAV select 1 == "DRIVER")) exitWith {
			// diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit) EXIT 1: unit is UAV gunner or driver"];
			true
		};
		false
	};
	
	ASL_Deploy_Ropes_Action_Check = {
		params [["_vehicle", objNull], ["_unit", objNull]];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Deploy_Ropes_Action_Check) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if ([getConnectedUAV _unit, _unit] call ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Deploy_Ropes_Action_Check) EXIT 1"];
			[getConnectedUAV _unit, _unit] call ASL_Can_Deploy_Ropes
		};
		if (vehicle _unit == _unit) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Deploy_Ropes_Action_Check) EXIT 2"];
			[cursorTarget, _unit, true] call ASL_Can_Deploy_Ropes
		}; 
		if (vehicle _unit == _vehicle && [_vehicle, _unit] call ASL_Is_Unit_Authorized) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Deploy_Ropes_Action_Check) EXIT 3"];
			[_vehicle, _unit] call ASL_Can_Deploy_Ropes
		};
		false
	};
	
	ASL_Can_Deploy_Ropes = {
		params [["_vehicle", objNull], ["_unit", objNull], ["_distanceCheck", false]];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		if (_distanceCheck && _unit distance _vehicle > ASL_MaxDeployRetractDistance) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Deploy_Ropes) EXIT 1"];
			false
		};
		if !([_vehicle] call ASL_Is_Supported_Vehicle) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Deploy_Ropes) EXIT 2"];
			false
		};
		private _existingVehicle = _unit getVariable ["ASL_Ropes_Vehicle", []];
		if (count _existingVehicle > 0) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Deploy_Ropes) EXIT 3"];
			false
		};
		if (getPos _vehicle select 2 > ASL_MaxRopeDeployHeight) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Deploy_Ropes) EXIT 4"];
			false
		};
		_existingRopes = _vehicle getVariable ["ASL_Ropes", []];
		if (count _existingRopes == 0) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Deploy_Ropes) EXIT 5"];
			true
		};
		private _activeRopes = [_vehicle, true] call ASL_Get_Active_Ropes;
		if (count _existingRopes > 0 && (count _existingRopes) == (count _activeRopes)) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Deploy_Ropes) EXIT 6"];
			false
		};
		true
	};
	
	ASL_Deploy_Ropes_Action = {
		params [["_vehicle", objNull], ["_unit", objNull]];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Deploy_Ropes_Action) _this: ", _this];
		if (isNull _vehicle || isNull _unit) exitWith {};
		if (locked _vehicle > 1 && !(missionNamespace getVariable ["ASL_LOCKED_VEHICLES_ENABLED", false])) exitWith {
			[format[localize "STR_ASL_CANNOT_DEPLOY"], false] call ASL_Hint;
		};
		private _inactiveRopes = [_vehicle] call ASL_Get_Active_Ropes;
		
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Deploy_Ropes_Action) _inactiveRopes: ", _inactiveRopes];
		if (count _inactiveRopes > 0) exitWith {
			if (count _inactiveRopes > 1) then {
				[format[localize "STR_ASL_DEPLOY"], "ASL_Deploy_Ropes_Index_Action", _inactiveRopes, _vehicle, _unit] call ASL_Show_Select_Ropes_Menu;
			} else {
				[_vehicle, _unit, (_inactiveRopes select 0) select 0] call ASL_Deploy_Ropes_Index;
			};
		};
		private _slingLoadPoints = [_vehicle] call ASL_Get_Sling_Load_Points;
		// diag_log formatText ["%1%2%3%4%5%6%7%8%9%10", time, "s  (ASL_Deploy_Ropes_Action) _slingLoadPoints: ", _slingLoadPoints, ", _unit: ", _unit];
		if (count _slingLoadPoints == 1) exitWith {
			[_vehicle, _unit] call ASL_Deploy_Ropes;
		};
		// _unit setVariable ["ASL_Deploy_Count_Vehicle", _vehicle];
		ASL_Deploy_Ropes_Count_Menu = [[format[localize "STR_ASL_ROPES"], false]];
		ASL_Vehicle = _vehicle;
		ASL_Unit = _unit;
		ASL_Deploy_Ropes_Count_Menu pushBack [format[localize "STR_ASL_SINGLE"], [0], "", -5, [["expression", "[1, ASL_Vehicle, ASL_Unit] call ASL_Deploy_Ropes_Count_Action"]], "1", "1"];	
		if (count _slingLoadPoints > 1) then {
			ASL_Deploy_Ropes_Count_Menu pushBack [format[localize "STR_ASL_DOUBLE"], [0], "", -5, [["expression", "[2, ASL_Vehicle, ASL_Unit] call ASL_Deploy_Ropes_Count_Action"]], "1", "1"];
		};
		if (count _slingLoadPoints > 2) then {
			ASL_Deploy_Ropes_Count_Menu pushBack [format[localize "STR_ASL_TRIPLE"], [0], "", -5, [["expression", "[3, ASL_Vehicle, ASL_Unit] call ASL_Deploy_Ropes_Count_Action"]], "1", "1"];
		};
		showCommandingMenu "";
		showCommandingMenu "#USER:ASL_Deploy_Ropes_Count_Menu";
	};
	
	ASL_Deploy_Ropes_Index_Action = {
		params ["_ropesIndex", ["_vehicle", objNull], ["_unit", objNull]];
		if (isNull _vehicle || isNull _unit) exitWith {};
		if (_ropesIndex >= 0 && !isNull _vehicle && [_vehicle, _unit] call ASL_Can_Deploy_Ropes) then {
			[_vehicle, _unit, _ropesIndex] call ASL_Deploy_Ropes_Index;
		};
	};
	
	ASL_Deploy_Ropes_Count_Action = {
		params ["_count", ["_vehicle", objNull], ["_unit", objNull]];
		// diag_log formatText ["%1%2%3%4%5%6%7%8%9%10", time, "s  (ASL_Deploy_Ropes_Count_Action) _count: ", _count, ", ASL_ParamMenuUnit: ", ASL_ParamMenuUnit];
		if (_count > 0 && !isNull _vehicle && [_vehicle, _unit] call ASL_Can_Deploy_Ropes) then {
			[_vehicle, _unit, _count] call ASL_Deploy_Ropes;
		};
	};
	
	ASL_Deploy_Ropes = {
		params [["_vehicle", objNull], ["_unit", objNull], ["_cargoCount", 1]];
		if (isNull _vehicle || isNull _unit) exitWith {false};
		if !(local _vehicle) exitWith {[_this, "ASL_Deploy_Ropes", _vehicle, true] call ASL_RemoteExec};
		private _existingRopes = _vehicle getVariable ["ASL_Ropes", []];
		if (count _existingRopes > 0) exitWith {
			if (_unit == player) then {[[format[localize "STR_ASL_ALREADY"], false], "ASL_Hint", _unit] call ASL_RemoteExec};
		};
		private _slingLoadPoints = [_vehicle] call ASL_Get_Sling_Load_Points;
		if (count _slingLoadPoints == 0) exitWith {
			if (_unit == player) then {[[format[localize "STR_ASL_DOESNT_SUPPORT"], false], "ASL_Hint", _unit] call ASL_RemoteExec};
		};
		if (count _slingLoadPoints < _cargoCount) exitWith {
			if (_unit == player) then {[[format[localize "STR_ASL_DOESNT_SUPPORT_X", _cargoCount], false], "ASL_Hint", _unit] call ASL_RemoteExec};
		};
		private _cargoRopes = [];
		private _cargo = [];
		for "_i" from 0 to (_cargoCount - 1) do {
			_cargoRopes pushBack [];
			_cargo pushBack objNull;
		};
		_vehicle setVariable ["ASL_Ropes", _cargoRopes, true];
		_vehicle setVariable ["ASL_Cargo", _cargo, true];
		for "_i" from 0 to (_cargoCount - 1) do	{
			[_vehicle, _unit, _i] call ASL_Deploy_Ropes_Index;
		};
	};
	
	ASL_Deploy_Ropes_Index = {
		params [["_vehicle", objNull], ["_unit", objNull], ["_ropesIndex", 0]];
		if (isNull _vehicle || isNull _unit) exitWith {};
		if !(local _vehicle) exitWith {[_this, "ASL_Deploy_Ropes_Index", _vehicle, true] call ASL_RemoteExec};
		private _existingRopes = [_vehicle, _ropesIndex] call ASL_Get_Ropes;
		if (count _existingRopes > 0) exitWith {};
		private _existingRopesCount = [_vehicle] call ASL_Get_Ropes_Count;
		private _slingLoadPoints = [_vehicle] call ASL_Get_Sling_Load_Points;
		private _cargoRopes = [];
		for "_i" from 1 to 4 do {
			_cargoRopes pushBack ropeCreate [_vehicle, (_slingLoadPoints select (_existingRopesCount - 1)) select _ropesIndex, 0]; 
		};
		{
			_x setVariable ["ASL_Ropes_Vehicle", [_vehicle, _ropesIndex], true];   	// memory vehicle and rope index on each rope 
			ropeUnwind [_x, 5, ASL_InitialDeployRopeLength];
		} forEach _cargoRopes;
		private _allRopes = _vehicle getVariable ["ASL_Ropes", []];
		_allRopes set [_ropesIndex, _cargoRopes];
		_vehicle setVariable ["ASL_Ropes", _allRopes, true];
		[_vehicle] spawn ASL_Rope_Monitor_Vehicle;
		if (!ASL_RopeMessagesAuthorized) exitWith {};
		hint format[localize "STR_ASL_ROPES_DEPLOYED", ASL_InitialDeployRopeLength];
	};
	
	ASL_Rope_Monitor_Vehicle = {
		params [["_vehicle", objNull]];
		if (isNull _vehicle) exitWith {};
		if (_vehicle getVariable ["ASL_Vehicle_Rope_Monitor", false]) exitWith {};  // leave, if vehicle is already monitoring rope ends
		_vehicle setVariable ["ASL_Vehicle_Rope_Monitor", true, true];
		// diag_log formatText ["%1%2%3%4%5%6%7%8%9%10", time, "s  (ASL_Rope_Monitor_Vehicle) _vehicle: ", _vehicle, ", started rope end monitoring"];
		private ["_allRopes", "_ropeBundle", "_rope", "_nearbyUnits", "_unitRopes"];
		while {alive _vehicle && !(isNil{_vehicle getVariable "ASL_Ropes"})} do {
			_allRopes = _vehicle getVariable ["ASL_Ropes", []];
			// diag_log formatText ["%1%2%3%4%5%6%7%8%9%10", time, "s  (ASL_Rope_Monitor_Vehicle) _allRopes: ", _allRopes];
			{
				_ropeBundle = _x;
				{
					_rope = _x;
					_nearbyUnits = ((ropeEndPosition _rope select 1) nearObjects (ASL_RopeHandlingDistance + 10)) select {_x isKindOf "CAManBase" && side _x == side player && vehicle _x == _x};
					// hintSilent formatText ["%1%2%3%4%5", time, "s  (ASL_Rope_Monitor_Vehicle) _nearbyUnits: ", _nearbyUnits];
					{
						_unitRopes = _x getVariable ["ASL_Ropes_Near_Unit", []];
						if (_unitRopes find _rope == -1) then {
							_unitRopes pushBack _rope;
							_x setVariable ["ASL_Ropes_Near_Unit", _unitRopes];
						};
						// hintSilent formatText ["%1%2%3%4%5", time, "s  (ASL_Rope_Monitor_Vehicle) unit: ", _x, ", _unitRopes: ", _unitRopes];
						[_x] spawn ASL_Rope_Monitor_Unit;
					} forEach _nearbyUnits;
				} forEach _ropeBundle;
			} forEach _allRopes;
			sleep 1;
		};
		_vehicle setVariable ["ASL_Vehicle_Rope_Monitor", nil, true];
	};
	
	ASL_Rope_Monitor_Unit = {
		params [["_unit", objNull]];
		if (isNull _unit) exitWith {};
		if (_unit getVariable ["ASL_Unit_Rope_Monitor", false]) exitWith {};  		// leave, if unit is already monitoring ror rope ends
		_unit setVariable ["ASL_Unit_Rope_Monitor", true];							// raise unit rope monitor flag
		diag_log formatText ["%1%2%3%4%5%6%7%8%9%10", time, "s  (ASL_Rope_Monitor_Unit) _unit: ", _unit, ", started rope end monitoring"];
		if (isNil{_unit getVariable "ASL_ActionID_Pickup"}) then {					// add pickup action to unit
			private _actionID = _unit addAction [
				format[localize "STR_ASL_PICKUP"],									// Title
				{[_this select 0] call ASL_Pickup_Ropes_Action;},					// Script
				nil,																// Arguments
				0,																	// Priority
				false,																// showWindow
				true,																// hideOnUse
				"",																	// Shortcut
				"[_this] call ASL_Pickup_Ropes_Action_Check"						// Condition
			];
			_unit setVariable ["ASL_ActionID_Pickup", _actionID];
		};
		private ["_unitRopes", "_index"];
		while {alive _unit && (count(_unit getVariable ["ASL_Ropes_Near_Unit", []]) > 0)} do {
			_unitRopes = _unit getVariable "ASL_Ropes_Near_Unit";
			// diag_log formatText ["%1%2%3%4%5%6%7%8%9%10", time, "s  (ASL_Rope_Monitor_Unit) _unitRopes: ", _unitRopes];
			// hintSilent formatText ["%1%2%3%4%5%6%7", "unit: ", _unit, lineBreak, "Ropes: ", lineBreak, _unitRopes];
			if (objNull in _unitRopes) then {
				_unitRopes = _unitRopes - [objNull];
				_unit setVariable ["ASL_Ropes_Near_Unit", _unitRopes];
			};
			{
				if (!alive _x || (_unit distance (ropeEndPosition _x select 1) > (ASL_RopeHandlingDistance + 15) && _unitRopes find _x != -1)) then {
					_index = _unitRopes find _x;
					if (_index == -1) exitWith {};
					_unitRopes deleteAt _index;
					_unit setVariable ["ASL_Ropes_Near_Unit", _unitRopes];
				};
			} forEach _unitRopes;
			sleep 0.1;
		};
		[_unit, ["ASL_ActionID_Pickup"]] call ASL_Remove_Actions;					// if no rope ends near, remove pickup action from unit
		_unit setVariable ["ASL_Ropes_Near_Unit", nil];								// annil unit rope array
		_unit setVariable ["ASL_Unit_Rope_Monitor", nil];							// annil unit rope monitor flag
	};
	
	ASL_Pickup_Ropes_Action_Check = {
		params [["_unit", objNull]];
		if (isNull _unit) exitWith {false};
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Pickup_Ropes_Action_Check) _target: ", _target, ", _this: ", _this];
		if (vehicle _unit != _unit) exitWith {false};
		if !(isNil{_unit getVariable "ASL_Ropes_Pick_Up_Helper"}) exitWith {false};
		private _unitRopes = _unit getVariable "ASL_Ropes_Near_Unit";
		if (objNull in _unitRopes) then {
			_unitRopes = _unitRopes - [objNull];
			_unit setVariable ["ASL_Ropes_Near_Unit", _unitRopes];
		};	
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Pickup_Ropes_Action_Check) _unitRopes: ", _unitRopes];
		private _pickup = false;		
		private _ropeHandlingDistance = ASL_RopeHandlingDistance;
		if (_unit != player) then {_ropeHandlingDistance = _ropeHandlingDistance + 5};
		{
			if (alive _x && (_unit distance (ropeEndPosition _x select 1) < _ropeHandlingDistance)) exitWith {_pickup = true};
		} forEach _unitRopes;
		_pickup
	};
	
	ASL_Pickup_Ropes_Action = {
		params [["_unit", objNull]];
		if (isNull _unit) exitWith {};
		private _unitRopes = _unit getVariable "ASL_Ropes_Near_Unit";
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Pickup_Ropes_Action) unit: ", _unit, ", _unitRopes: ", _unitRopes];
		// hintSilent formatText ["%1%2%3%4%5", time, "s  (ASL_Pickup_Ropes_Action) unit: ", _unit, ", _unitRopes: ", _unitRopes];
		private _closestRope = objNull;
		
		private _ropeHandlingDistance = ASL_RopeHandlingDistance;
		if (_unit != player) then {_ropeHandlingDistance = _ropeHandlingDistance + 5};
		private _closestDistance = _ropeHandlingDistance + 100;
		{
			_distance = _unit distance (ropeEndPosition _x select 1);
			if (_x != objNull && _distance < _ropeHandlingDistance && _distance < _closestDistance) then {
				_closestRope = _x;
			};
		} forEach _unitRopes;
		
		// private _closestDistance = ASL_RopeHandlingDistance + 100;
		// {
			// _distance = _unit distance (ropeEndPosition _x select 1);
			// if (_x != objNull && _distance < ASL_RopeHandlingDistance && _distance < _closestDistance) then {
				// _closestRope = _x;
			// };
		// } forEach _unitRopes;
		if (isNull _closestRope) exitWith {};
		private _vehicle = (_closestRope getVariable "ASL_Ropes_Vehicle") select 0;
		if (isNull _vehicle) exitWith {};
		if (locked _vehicle > 1 && !(missionNamespace getVariable ["ASL_LOCKED_VEHICLES_ENABLED", false])) exitWith {
			[format[localize "STR_ASL_CANT_PICKUP"], false] call ASL_Hint;
		};
		private _ropesIndex = (_closestRope getVariable "ASL_Ropes_Vehicle") select 1;
		[_vehicle, _unit, _ropesIndex] call ASL_Pickup_Ropes;
	};
	
	ASL_Pickup_Ropes = {
		params [["_vehicle", objNull], ["_unit", objNull], ["_ropesIndex", 0]];
		if (isNull _vehicle || isNull _unit) exitWith {};
		if !(local _vehicle) exitWith {[_this, "ASL_Pickup_Ropes", _vehicle, true] call ASL_RemoteExec};
		private _existingRopesAndCargo = [_vehicle, _ropesIndex] call ASL_Get_Ropes_And_Cargo;
		private _existingRopes = _existingRopesAndCargo select 0;
		private _existingCargo = _existingRopesAndCargo select 1;
		if (!isNull _existingCargo) then {
			{
				_existingCargo ropeDetach _x;
			} forEach _existingRopes;
			private _allCargo = _vehicle getVariable ["ASL_Cargo", []];
			_allCargo set [_ropesIndex, objNull];
			_vehicle setVariable ["ASL_Cargo", _allCargo, true];
		};
		private _helper = "Land_Can_V2_F" createVehicle position _unit;
		_helper setVariable ["ASL_Ropes_Pick_Up_Helper", true, true];
		{
			[_helper, [0, 0, 0], [0, 0, -1]] ropeAttachTo _x;
			_helper attachTo [_unit, [-0.1, 0.1, 0.15], "Pelvis"];
		} forEach _existingRopes;
		hideObjectGlobal _helper;
		_unit setVariable ["ASL_Ropes_Vehicle", [_vehicle, _ropesIndex], true];
		_unit setVariable ["ASL_Ropes_Pick_Up_Helper", _helper, true];
		private ["_actionID"];
		if (isNil{_unit getVariable "ASL_ActionID_Attach"}) then {		
			_actionID = _unit addAction [								// add 'attach to' action, once unit has picked up some ropes
				format[localize "STR_ASL_ATTACH"],						// Title
				{[_this select 0] call ASL_Attach_Ropes_Action;},		// Script
				nil,													// Arguments
				0,														// Priority
				false,													// showWindow
				true,													// hideOnUse
				"",														// Shortcut
				"[_this] call ASL_Attach_Ropes_Action_Check"			// Condition
			];
			_unit setVariable ["ASL_ActionID_Attach", _actionID];
		};		
		if (isNil{_unit getVariable "ASL_ActionID_Drop"}) then {		
			_actionID = _unit addAction [								// add 'drop ropes' action, once unit has picked up some ropes
				format[localize "STR_ASL_DROP"],						// Title
				{[_this select 0] call ASL_Drop_Ropes_Action;},			// Script
				nil,													// Arguments
				0,														// Priority
				false,													// showWindow
				true,													// hideOnUse
				"",														// Shortcut
				"[_this] call ASL_Drop_Ropes_Action_Check"				// Condition
			];
			_unit setVariable ["ASL_ActionID_Drop", _actionID];
		};
	};
	
	ASL_Attach_Ropes_Action_Check = {
		params [["_unit", objNull]];
		if (isNull _unit) exitWith {false};
		private _cargo = cursorTarget;
		private _vehicle = (_unit getVariable ["ASL_Ropes_Vehicle", [objNull, 0]]) select 0;
		private _ropeHandlingDistance = ASL_RopeHandlingDistance;
		if (_unit != player) then {_ropeHandlingDistance = _ropeHandlingDistance + 5};   // AI gets a higher range, as AI's do not get close enough to vehicles		
		// [_vehicle, _cargo] call ASL_Is_Supported_Cargo && vehicle _unit == _unit && _unit distance _cargo < ASL_RopeHandlingDistance && _vehicle != _cargo;	
		if (vehicle _unit != _unit || _unit distance _cargo > _ropeHandlingDistance || _vehicle == _cargo || !alive _cargo) exitWith {false};
		[_vehicle, _cargo] call ASL_Is_Supported_Cargo
		// [_vehicle, _cargo] call ASL_Is_Supported_Cargo && 
		// vehicle _unit == _unit && 
		// _unit distance _cargo < _ropeHandlingDistance && 
		// _vehicle != _cargo &&
		// alive _cargo;
	};
	
	ASL_Attach_Ropes_Action = {
		params [["_unit", objNull]];
		if (isNull _unit) exitWith {};
		private _cargo = cursorTarget;
		private _vehicle = (_unit getVariable ["ASL_Ropes_Vehicle", [objNull, 0]]) select 0;
		if (locked _cargo > 1 && !(missionNamespace getVariable ["ASL_LOCKED_VEHICLES_ENABLED", false])) exitWith {
			[format[localize "STR_ASL_CANT_ATTACH"], false] call ASL_Hint;
		};
		private _canBeAttached = true;
		if !(missionNamespace getVariable ["ASL_EXILE_SAFEZONE_ENABLED", false]) then {
			if (!isNil "ExilePlayerInSafezone") then {
				if (ExilePlayerInSafezone) then {
					[format[localize "STR_ASL_CANT_SAFE"], false] call ASL_Hint;
					_canBeAttached = false;
				};
			};
		};
		if (_canBeAttached) then {
			[_cargo, _unit] call ASL_Attach_Ropes;
		};
	};
	
	ASL_Attach_Ropes = {
		params [["_cargo", objNull], ["_unit", objNull]];
		if (isNull _cargo || isNull _unit) exitWith {};
		private _vehicleWithIndex = _unit getVariable ["ASL_Ropes_Vehicle", [objNull, 0]];
		private _vehicle = _vehicleWithIndex select 0;
		if (isNull _vehicle) exitWith {};
		if !(local _vehicle) exitWith {[_this, "ASL_Attach_Ropes", _vehicle, true] call ASL_RemoteExec};
		private _ropes = [_vehicle, _vehicleWithIndex select 1] call ASL_Get_Ropes;
		if (count _ropes != 4) exitWith {};
		private _attachmentPoints = [_cargo] call ASL_Get_Corner_Points;
		private _ropeLength = (ropeLength (_ropes select 0));
		private _objDistance = (_cargo distance _vehicle) + 2;
		if (_objDistance > _ropeLength) then {
			[[format[localize "STR_ASL_TOO_SHORT"], false], "ASL_Hint", _unit] call ASL_RemoteExec;
		} else {		
			private _ropesIndex = _vehicleWithIndex select 1;
			_cargo setVariable ["ASL_RopesIndex", _ropesIndex, true];
			[_vehicle, _unit] call ASL_Drop_Ropes;
			for "_i" from 0 to 3 do {
				[_cargo, _attachmentPoints select _i, [0, 0, -1]] ropeAttachTo (_ropes select _i);
			};
			private _allCargo = _vehicle getVariable ["ASL_Cargo", []];
			_allCargo set [(_vehicleWithIndex select 1), _cargo];
			_vehicle setVariable ["ASL_Cargo", _allCargo, true];
			if (missionNamespace getVariable ["ASL_HEAVY_LIFTING_ENABLED", true]) then {
				[_cargo, _vehicle, _ropes] spawn ASL_Rope_Adjust_Mass;		
			};
			[_unit, ["ASL_ActionID_Attach", "ASL_ActionID_Drop"]] call ASL_Remove_Actions;		// remove 'drop ropes' and 'attach ropes' actions, once unit has attached ropes to some cargo
			_unit setVariable ["ASL_Ropes_Vehicle", nil, true];
			_unit setVariable ["ASL_Ropes_Pick_Up_Helper", nil, true];
		};
	};
	
	ASL_Drop_Ropes_Action_Check = {
		params [["_unit", objNull]];
		if (isNull _unit) exitWith {false};
		count (_unit getVariable ["ASL_Ropes_Vehicle", []]) > 0 && vehicle _unit == _unit;
	};
	
	ASL_Drop_Ropes_Action = {
		params [["_unit", objNull]];
		if (isNull _unit) exitWith {false};
		private _vehicleAndIndex = _unit getVariable ["ASL_Ropes_Vehicle", []];
		if (count _vehicleAndIndex == 2) then {
			[_vehicleAndIndex select 0, _unit, _vehicleAndIndex select 1] call ASL_Drop_Ropes;
		};
	};
	
	ASL_Drop_Ropes = {
		params [["_vehicle", objNull], ["_unit", objNull], ["_ropesIndex", 0]];
		if (isNull _vehicle || isNull _unit) exitWith {};
		if !(local _vehicle) exitWith {[_this, "ASL_Drop_Ropes", _vehicle, true] call ASL_RemoteExec};
		private _helper = (_unit getVariable ["ASL_Ropes_Pick_Up_Helper", objNull]);
		if (!isNull _helper) then {
			private _existingRopes = [_vehicle, _ropesIndex] call ASL_Get_Ropes;		
			{
				_helper ropeDetach _x;
			} forEach _existingRopes;
			detach _helper;
			deleteVehicle _helper;
		};
		[_unit, ["ASL_ActionID_Attach", "ASL_ActionID_Drop"]] call ASL_Remove_Actions;		// remove 'drop ropes' and 'attach ropes' actions, once unit has attached ropes to some cargo
		_unit setVariable ["ASL_Ropes_Vehicle", nil, true];
		_unit setVariable ["ASL_Ropes_Pick_Up_Helper", nil, true];
	};

	ASL_SUPPORTED_VEHICLES = [
		"Helicopter",
		"VTOL_Base_F"
	];
	
	ASL_Is_Supported_Vehicle = {
		params [["_vehicle", objNull]];
		if (isNull _vehicle) exitWith {false};
		private _isSupported = false;
		{
			if (_vehicle isKindOf _x) exitWith {_isSupported = true};
		} forEach (missionNamespace getVariable ["ASL_SUPPORTED_VEHICLES_OVERRIDE", ASL_SUPPORTED_VEHICLES]);
		_isSupported;
	};
	
	ASL_SLING_RULES = [
		["All", "CAN_SLING", "All"]
	];
	
	ASL_Is_Supported_Cargo = {
		params [["_vehicle", objNull], ["_cargo", objNull]];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Is_Supported_Cargo)		_vehicle: ", _vehicle, ", _cargo: ", _cargo];
		if (isNull _vehicle || isNull _cargo) exitWith {false};
		private _canSling = false;
		{
			if (_vehicle isKindOf (_x select 0) && _cargo isKindOf (_x select 2) && (toUpper (_x select 1)) == "CAN_SLING") exitWith {_canSling = true};
		} forEach (missionNamespace getVariable ["ASL_SLING_RULES_OVERRIDE", ASL_SLING_RULES]);	
		_canSling
	};
	
	ASL_Hint = {
		params ["_msg", ["_isSuccess", true]];
		if (!isNil "ExileClient_gui_notification_event_addNotification") then {
			if (_isSuccess) then {
				[format[localize "STR_ASL_SUCCESS"], [_msg]] call ExileClient_gui_notification_event_addNotification; 
			} else {
				[format[localize "STR_ASL_WHOOPS"], [_msg]] call ExileClient_gui_notification_event_addNotification; 
			};
		} else {
			hint _msg;
		};
	};

	ASL_Switch_Vehicles_Actions = {
		{
			[_x] call ASL_Add_Vehicle_Actions;
		} foreach vehicles;
	};

	ASL_Add_Vehicle_Actions = {
		params [["_vehicle", objNull]];
		if (isNull _vehicle) exitWith {};
		private _exit = true;
		{
			if (_vehicle isKindOf _x && getMass _vehicle > ASL_MinVehicleMass) exitWith {_exit = false};
		} foreach ASL_SUPPORTED_VEHICLES;
		// diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (ASL_Add_Vehicle_Actions)	_vehicle: ", _vehicle, ", mass: ", getMass _vehicle, ", min: ", ASL_MinVehicleMass];
		if (_exit) exitWith {
			[_vehicle, ["ASL_ActionID_Deploy", "ASL_ActionID_Retract", "ASL_ActionID_Extend", "ASL_ActionID_Shorten", "ASL_ActionID_Release"]] call ASL_Remove_Actions;
		};
		private ["_actionID"];
		if (isNil{_vehicle getVariable "ASL_ActionID_Deploy"}) then {
			_actionID = _vehicle addAction [
				format[localize "STR_ASL_DEPLOY"],										// Title
				{[_this select 0, _this select 1] call ASL_Deploy_Ropes_Action},		// Script
				nil,																	// Arguments
				0,																		// Priority
				false,																	// showWindow
				true,																	// hideOnUse
				"",																		// Shortcut
				"[_target, _this] call ASL_Deploy_Ropes_Action_Check"					// Condition
			];
			_vehicle setVariable ["ASL_ActionID_Deploy", _actionID];
		};
		if (isNil{_vehicle getVariable "ASL_ActionID_Retract"}) then {
			_actionID = _vehicle addAction [
				format[localize "STR_ASL_RETRACT"],										// Title
				{[_this select 0, _this select 1] call ASL_Retract_Ropes_Action;},		// Script
				nil,																	// Arguments
				0,																		// Priority
				false,																	// showWindow
				true,																	// hideOnUse
				"",																		// Shortcut
				"[_target, _this] call ASL_Retract_Ropes_Action_Check"					// Condition
			];
			_vehicle setVariable ["ASL_ActionID_Retract", _actionID];
		};
		if (isNil{_vehicle getVariable "ASL_ActionID_Extend"}) then {
			_actionID = _vehicle addAction [
				format[localize "STR_ASL_EXTEND"],										// Title
				{[_this select 0, _this select 1] call ASL_Extend_Ropes_Action},		// Script
				nil,																	// Arguments
				0,																		// Priority
				false,																	// showWindow
				true,																	// hideOnUse
				"",																		// Shortcut
				"[_target, _this] call ASL_Extend_Ropes_Action_Check"					// Condition
			];
			_vehicle setVariable ["ASL_ActionID_Extend", _actionID];
		};
		if (isNil{_vehicle getVariable "ASL_ActionID_ExtendTG"}) then {
			_actionID = _vehicle addAction [
				format[localize "STR_ASL_EXTEND_TG"],									// Title
				{[_this select 0, _this select 1, true] call ASL_Extend_Ropes_Action},	// Script
				nil,																	// Arguments
				0,																		// Priority
				false,																	// showWindow
				true,																	// hideOnUse
				"",																		// Shortcut
				"[_target, _this, true] call ASL_Extend_Ropes_Action_Check"				// Condition
			];
			_vehicle setVariable ["ASL_ActionID_ExtendTG", _actionID];
		};
		if (isNil{_vehicle getVariable "ASL_ActionID_Shorten"}) then {
			_actionID = _vehicle addAction [
				format[localize "STR_ASL_SHORTEN"],										// Title
				{[_this select 0, _this select 1] call ASL_Shorten_Ropes_Action},		// Script
				nil,																	// Arguments
				0,																		// Priority
				false,																	// showWindow
				true,																	// hideOnUse
				"",																		// Shortcut
				"[_target, _this] call ASL_Shorten_Ropes_Action_Check"					// Condition
			];
			_vehicle setVariable ["ASL_ActionID_Shorten", _actionID];
		};
		if (isNil{_vehicle getVariable "ASL_ActionID_Release"}) then {
			_actionID = _vehicle addAction [
				format[localize "STR_ASL_RELEASE"],										// Title
				{[_this select 0, _this select 1] call ASL_Release_Cargo_Action},		// Script
				nil,																	// Arguments
				0,																		// Priority
				false,																	// showWindow
				true,																	// hideOnUse
				"",																		// Shortcut
				"[_target, _this] call ASL_Release_Cargo_Action_Check"					// Condition
			];
			_vehicle setVariable ["ASL_ActionID_Release", _actionID];
		};
	};

	ASL_Remove_Actions = {
		params [["_object", objNull], ["_actions", []]];
		diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Remove_Actions) _object: ", _object, "    _actions: ", _actions];
		if (isNull _object || count _actions == 0) exitWith {};
		private ["_actionID"];
		{
			_actionID = _object getVariable [_x, -1];
			diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Remove_Actions) removing _actionID: ", _actionID];
			if (_actionID > -1) then {
				_object removeAction _actionID;
				_object setVariable [_x, nil];
			};
		} forEach _actions;
	};
	
	if (!isDedicated) then {
		["Air", "init", {_this call ASL_Add_Vehicle_Actions}, true] call CBA_fnc_addClassEventHandler; // adds init event to all air vehicles; has to be run preinit!
	};
	
	ASL_RemoteExec = {
		params ["_params", "_functionName", "_target", ["_isCall", false]];
		if (!isNil "ExileClient_system_network_send") then {
			["AdvancedSlingLoadingRemoteExecClient", [_params, _functionName, _target, _isCall]] call ExileClient_system_network_send;
		} else {
			if (_isCall) then {
				_params remoteExecCall [_functionName, _target];
			} else {
				_params remoteExec [_functionName, _target];
			};
		};
	};
	
	ASL_RemoteExecServer = {
		params ["_params", "_functionName", ["_isCall", false]];
		if (!isNil "ExileClient_system_network_send") then {
			["AdvancedSlingLoadingRemoteExecServer", [_params, _functionName, _isCall]] call ExileClient_system_network_send;
		} else {
			if (_isCall) then {
				_params remoteExecCall [_functionName, 2];
			} else {
				_params remoteExec [_functionName, 2];
			};
		};
	};
	
	if (isServer) then {
		ExileServer_AdvancedSlingLoading_network_AdvancedSlingLoadingRemoteExecServer = {
			params ["_sessionId", "_messageParameters", ["_isCall", false]];
			_messageParameters params ["_params", "_functionName"];
			if (_functionName in ASL_SUPPORTED_REMOTEEXECSERVER_FUNCTIONS) then {
				if (_isCall) then {
					_params call (missionNamespace getVariable [_functionName, {}]);
				} else {
					_params spawn (missionNamespace getVariable [_functionName, {}]);
				};
			};
		};
		ASL_SUPPORTED_REMOTEEXECCLIENT_FUNCTIONS = [
			"ASL_Pickup_Ropes", 
			"ASL_Deploy_Ropes_Index", 
			"ASL_Rope_Set_Mass", 
			"ASL_Extend_Ropes", 
			"ASL_Shorten_Ropes", 
			"ASL_Release_Cargo", 
			"ASL_Retract_Ropes", 
			"ASL_Deploy_Ropes", 
			"ASL_Hint", 
			"ASL_Attach_Ropes", 
			"ASL_Drop_Ropes"
		];
		ExileServer_AdvancedSlingLoading_network_AdvancedSlingLoadingRemoteExecClient = {
			params ["_sessionId", "_messageParameters"];
			_messageParameters params ["_params", "_functionName", "_target", ["_isCall", false]];
			if (_functionName in ASL_SUPPORTED_REMOTEEXECCLIENT_FUNCTIONS) then {
				if (_isCall) then {
					_params remoteExecCall [_functionName, _target];
				} else {
					_params remoteExec [_functionName, _target];
				};
			};
		};
		
		// Install Advanced Sling Loading on all clients (plus JIP)
		publicVariable "ASL_Advanced_Sling_Loading_Install";
		remoteExecCall ["ASL_Advanced_Sling_Loading_Install", -2, true];
	};
	
	diag_log "Advanced Sling Loading Loaded";
};

if (isServer) then {
	if (isNil "ASL_MaxRopeLength") then {ASL_MaxRopeLength 							= 100};		// maximum rope length in meter (As of Arma v2.04, this limit is hardcoded. No ropes longer than 100 m can be created or unwound)
	if (isNil "ASL_MinRopeLength") then {ASL_MinRopeLength 							= 2};		// minimum rope length in meter
	if (isNil "ASL_MaxDeployRetractDistance") then {ASL_MaxDeployRetractDistance 	= 10};		// maximum rope deploy, retract distance in meter (when player is on foot)
	if (isNil "ASL_PilotsAuthorized") then {ASL_PilotsAuthorized 					= true};	// pilots authorized to manipulate ropes
	if (isNil "ASL_CopilotsAuthorized") then {ASL_CopilotsAuthorized 				= true};	// copilots authorized to manipulate ropes
	if (isNil "ASL_GunnersAuthorized") then {ASL_GunnersAuthorized 					= false};	// gunners authorized to manipulate ropes
	if (isNil "ASL_PassengersAuthorized") then {ASL_PassengersAuthorized 			= false};	// passengers authorized to manipulate ropes
	if (isNil "ASL_MaxRopeDeployHeight") then {ASL_MaxRopeDeployHeight 				= 100};		// maximum height in meter the action 'Deploy Cargo Ropes' is available
	if (isNil "ASL_MinVehicleMass") then {ASL_MinVehicleMass 						= 0};		// minimum mass a vehicle has to have to be able to deploy ropes
	if (isNil "ASL_RopeHandlingDistance") then {ASL_RopeHandlingDistance 			= 5};		// maximum distance in meter a unit has to be from a rope end to be able to pick up the rope
	if (isNil "ASL_InitialDeployRopeLength") then {ASL_InitialDeployRopeLength 		= 15};		// initial rope length in meter, when rope is deployed
	if (isNil "ASL_ExtendShortenRopeLength") then {ASL_ExtendShortenRopeLength 		= 5};		// rope length in meter, when rope is extended / shortened
	if (isNil "ASL_DefaultLiftableMass") then {ASL_DefaultLiftableMass 				= 4000};	// default mass in kg, which can be lifted
	if (isNil "ASL_MaxLiftableMassFactor") then {ASL_MaxLiftableMassFactor 			= 8};		// maximum liftable mass factor (ASL_Rope_Get_Lift_Capability * ASL_MaxLiftableMassFactor)
	if (isNil "ASL_MinRopeLengthDropCargo") then {ASL_MinRopeLengthDropCargo 		= false};	// drop cargo, when minimum rope length is reached, and ropes are shortened once more
	if (isNil "ASL_RopeMessagesAuthorized") then {ASL_RopeMessagesAuthorized 		= true};	// hint players informations about rope changes
	[] call ASL_Advanced_Sling_Loading_Install;
};
