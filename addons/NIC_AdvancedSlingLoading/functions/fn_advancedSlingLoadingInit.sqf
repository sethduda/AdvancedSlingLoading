/*
The MIT License (MIT)

Copyright (c) 2016 Seth Duda

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

ASL_Advanced_Sling_Loading_Install = {
	
	// Prevent advanced sling loading from installing twice
	if (!isNil "ASL_ROPE_INIT") exitWith {};
	ASL_ROPE_INIT = true;
	
	diag_log "Advanced Sling Loading Loading...";
	
	ASL_Rope_Get_Lift_Capability = {
		params ["_vehicle"];
		private _slingLoadMaxCargoMass = getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> "slingLoadMaxCargoMass");
		if (_slingLoadMaxCargoMass <= 0) then {
			_slingLoadMaxCargoMass = 4000;
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
		params ["_vehicle"];
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
			if (_vehicle isKindOf (_x select 0)) then {
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
	
	ASL_Rope_Set_Mass = {
		private _obj = [_this, 0] call BIS_fnc_param;
		private _mass = [_this, 1] call BIS_fnc_param;
		_obj setMass _mass;
	};
	
	ASL_Rope_Adjust_Mass = {
		params ["_obj", "_heli", ["_ropes", []]];
		private _lift = [_heli] call ASL_Rope_Get_Lift_Capability;
		private _maxLiftableMass = _lift * 8;
		private _originalMass = getMass _obj;
		private _heavyLiftMinLift = missionNamespace getVariable ["ASL_HEAVY_LIFTING_MIN_LIFT_OVERRIDE", 5000];
		// diag_log formatText ["%1%2%3%4%5%6%7%8%9%10%11", time, "s  (ASL_Rope_Adjust_Mass) _obj: ", _obj, "    _originalMass: ", _originalMass, "    _heli: ", _heli, "    _lift: ", _lift, "    _heavyLiftMinLift: ", _heavyLiftMinLift];
		if (_originalMass >= ((_lift)*0.8) && _lift >= _heavyLiftMinLift && _originalMass <= _maxLiftableMass) then {
			private _originalMassSet = (getMass _obj) == _originalMass;
			private ["_ends", "_endDistance", "_ropeLength"];
			while {_obj in (ropeAttachedObjects _heli) && _originalMassSet} do {
				{
					_ends = ropeEndPosition _x;
					_endDistance = (_ends select 0) distance (_ends select 1);
					_ropeLength = ropeLength _x;
					if ((_ropeLength - 2) <= _endDistance && ((position _heli) select 2) > 0) then {
						[[_obj, (_lift * 0.8 + ((_originalMass / _maxLiftableMass) * (_lift * 0.2)))],"ASL_Rope_Set_Mass",_obj,true] call ASL_RemoteExec;
						_originalMassSet = false;
					};
				} forEach _ropes;
				sleep 0.1;
			};
			while {_obj in (ropeAttachedObjects _heli)} do {
				sleep 0.5;
			};
			[[_obj, _originalMass], "ASL_Rope_Set_Mass", _obj, true] call ASL_RemoteExec;
		};	
	};
	
	/*
	 Constructs an array of all active rope indexes and position labels (e.g. [[rope index,"Front"],[rope index,"Rear"]])
	 for a specified vehicle
	*/
	ASL_Get_Active_Ropes = {
		params ["_vehicle"];
		private _activeRopes = [];
		private _existingRopes = _vehicle getVariable ["ASL_Ropes", []];
		private _ropeLabelSets = [["Center"], ["Front", "Rear"], ["Front", "Center", "Rear"]];
		private _ropeIndex = 0;
		private _totalExistingRopes = count _existingRopes;
		private ["_ropeLabels"];
		{
			if (count _x > 0) then {
				_ropeLabels = _ropeLabelSets select (_totalExistingRopes - 1);
				_activeRopes pushBack [_ropeIndex, _ropeLabels select _ropeIndex];
			};
			_ropeIndex = _ropeIndex + 1;
		} forEach _existingRopes;
		_activeRopes;
	};
	
	/*
	 Constructs an array of all inactive rope indexes and position labels (e.g. [[rope index,"Front"],[rope index,"Rear"]])
	 for a specified vehicle
	*/
	ASL_Get_Inactive_Ropes = {
		params ["_vehicle"];
		private _inactiveRopes = [];
		private _existingRopes = _vehicle getVariable ["ASL_Ropes", []];
		private _ropeLabelSets = [["Center"], ["Front", "Rear"], ["Front", "Center", "Rear"]];
		private _ropeIndex = 0;
		private _totalExistingRopes = count _existingRopes;
		private ["_ropeLabels"];
		{
			if (count _x == 0) then {
				_ropeLabels = _ropeLabelSets select (_totalExistingRopes - 1);
				_inactiveRopes pushBack [_ropeIndex, _ropeLabels select _ropeIndex];
			};
			_ropeIndex = _ropeIndex + 1;
		} forEach _existingRopes;
		_inactiveRopes;
	};
	
	ASL_Get_Active_Ropes_With_Cargo = {
		params ["_vehicle"];
		private _activeRopesWithCargo = [];
		private _existingCargo = _vehicle getVariable ["ASL_Cargo", []];
		private _activeRopes = _this call ASL_Get_Active_Ropes;
		private ["_cargo"];
		{
			_cargo = _existingCargo select (_x select 0);
			if (!isNull _cargo) then {
				_activeRopesWithCargo pushBack _x;
			};
		} forEach _activeRopes;
		_activeRopesWithCargo;
	};
	
	ASL_Get_Active_Ropes_Without_Cargo = {
		params ["_vehicle"];
		private _activeRopesWithoutCargo = [];
		private _existingCargo = _vehicle getVariable ["ASL_Cargo", []];
		private _activeRopes = _this call ASL_Get_Active_Ropes;
		private ["_cargo"];
		{
			_cargo = _existingCargo select (_x select 0);
			if (isNull _cargo) then {
				_activeRopesWithoutCargo pushBack _x;
			};
		} forEach _activeRopes;
		_activeRopesWithoutCargo;
	};
	
	ASL_Get_Ropes = {
		params ["_vehicle", "_ropeIndex"];
		private _selectedRopes = [];
		private _allRopes = _vehicle getVariable ["ASL_Ropes", []];
		if (count _allRopes > _ropeIndex) then {
			_selectedRopes = _allRopes select _ropeIndex;
		};
		_selectedRopes;
	};
	
	ASL_Get_Ropes_Count = {
		params ["_vehicle"];
		count (_vehicle getVariable ["ASL_Ropes", []]);
	};
	
	ASL_Get_Cargo = {
		params ["_vehicle", "_ropeIndex"];
		private _selectedCargo = objNull;
		private _allCargo = _vehicle getVariable ["ASL_Cargo", []];
		if (count _allCargo > _ropeIndex) then {
			_selectedCargo = _allCargo select _ropeIndex;
		};
		_selectedCargo;
	};
	
	ASL_Get_Ropes_And_Cargo = {
		params ["_vehicle", "_ropeIndex"];
		private _selectedCargo = (_this call ASL_Get_Cargo);
		private _selectedRopes = (_this call ASL_Get_Ropes);
		[_selectedRopes, _selectedCargo];
	};
	
	ASL_Show_Select_Ropes_Menu = {
		params ["_title", "_functionName", "_ropesIndexAndLabelArray", ["_ropesLabel", "Ropes"]];
		ASL_Show_Select_Ropes_Menu_Array = [[_title, false]];
		{
			ASL_Show_Select_Ropes_Menu_Array pushBack [(_x select 1) + " " + _ropesLabel, [0], "", -5, [["expression", "["+(str (_x select 0))+"] call " + _functionName]], "1", "1"];
		} forEach _ropesIndexAndLabelArray;
		ASL_Show_Select_Ropes_Menu_Array pushBack ["All " + _ropesLabel, [0], "", -5, [["expression", "{ [_x] call " + _functionName + " } forEach [0,1,2];"]], "1", "1"];
		showCommandingMenu "";
		showCommandingMenu "#USER:ASL_Show_Select_Ropes_Menu_Array";
	};
	
	ASL_Extend_Ropes_Index_Action = {
		params ["_ropeIndex"];
		private _vehicle = player getVariable ["ASL_Extend_Index_Vehicle", objNull];
		if (_ropeIndex >= 0 && !isNull _vehicle && [_vehicle] call ASL_Can_Extend_Ropes) then {
			[_vehicle, player, _ropeIndex] call ASL_Extend_Ropes;
		};
	};

	ASL_Extend_Ropes_Action_Check = {
		params ["_vehicle", "_unit"];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Extend_Ropes_Action_Check) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if ([getConnectedUAV _unit, _unit] call ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Extend_Ropes_Action_Check) EXIT 1, can release: ", [getConnectedUAV _unit, _unit] call ASL_Can_Release_Cargo];
			[getConnectedUAV _unit] call ASL_Can_Extend_Ropes
		};
		if (vehicle _unit == _vehicle && [_vehicle, _unit] call ASL_Is_Unit_Authorized) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Extend_Ropes_Action_Check) EXIT 2, can release: ", [_vehicle, _unit] call ASL_Can_Release_Cargo];
			[_vehicle] call ASL_Can_Extend_Ropes
		};
		false
	};
	
	ASL_Is_Unit_Authorized = {
		params ["_vehicle", "_unit"];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Is_Unit_Authorized) _vehicle: ", _vehicle, "    _unit: ", _unit];
		// if (driver _vehicle == _unit || gunner _vehicle == _unit || commander _vehicle == _unit) exitWith {true};
		if (driver _vehicle == _unit && ASL_PilotsAuthorized || 
		gunner _vehicle == _unit && ASL_GunnersAuthorized || 
		commander _vehicle == _unit && ASL_CommandersAuthorized) exitWith {true};
		if !(ASL_CopilotsAuthorized) exitWith {false};
		private _cfg = configFile >> "CfgVehicles" >> typeOf(_vehicle);
		private _trts = _cfg >> "turrets";
		private _isCopilot = false;
		for "_i" from 0 to (count _trts - 1) do {
			private _trt = _trts select _i;
			if (getNumber(_trt >> "iscopilot") == 1) exitWith {
				_isCopilot = ((_vehicle turretUnit [_i]) == _unit);				// check, if unit is copilot
			};
		};
		_isCopilot
	};
	
	ASL_Can_Extend_Ropes = {
		params ["_vehicle"];
		if !([_vehicle] call ASL_Is_Supported_Vehicle) exitWith {false};
		private _existingRopes = _vehicle getVariable ["ASL_Ropes", []];
		if (count _existingRopes == 0) exitWith {false};
		private _activeRopes = [_vehicle] call ASL_Get_Active_Ropes;
		if (count _activeRopes == 0) exitWith {false};
		true;
	};
	
	ASL_Extend_Ropes_Action = {
		params [["_vehicle", objNull], "_unit"];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Extend_Ropes_Action) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if (isNull _vehicle) exitWith {false};
		if !([_vehicle] call ASL_Can_Extend_Ropes) exitWith {false};
		private _activeRopes = [_vehicle] call ASL_Get_Active_Ropes;
		if (count _activeRopes == 1) then {
			[_vehicle, _unit, (_activeRopes select 0) select 0] call ASL_Extend_Ropes;
		};
		if (count _activeRopes > 1) then {
			_unit setVariable ["ASL_Extend_Index_Vehicle", _vehicle];
			["Extend Cargo Ropes", "ASL_Extend_Ropes_Index_Action", _activeRopes] call ASL_Show_Select_Ropes_Menu;
		}; 
	};
	
	ASL_Extend_Ropes = {
		params ["_vehicle", "_player", ["_ropeIndex", 0]];
		if (local _vehicle) exitWith {
			private _existingRopes = [_vehicle, _ropeIndex] call ASL_Get_Ropes;
			if (count _existingRopes > 0) then {
				private _ropeLength = ropeLength (_existingRopes select 0);
				if (_ropeLength <= ASL_MaxRopeLength) then {
					{
						ropeUnwind [_x, 3, 5, true];
					} forEach _existingRopes;
				};
			};
		};
		[_this, "ASL_Extend_Ropes", _vehicle, true] call ASL_RemoteExec;
	};
	
	ASL_Shorten_Ropes_Index_Action = {
		params ["_ropeIndex"];
		private _vehicle = player getVariable ["ASL_Shorten_Index_Vehicle", objNull];
		if (_ropeIndex >= 0 && !isNull _vehicle && [_vehicle] call ASL_Can_Shorten_Ropes) then {
			[_vehicle, player, _ropeIndex] call ASL_Shorten_Ropes;
		};
	};
	
	ASL_Shorten_Ropes_Action_Check = {
		params ["_vehicle", "_unit"];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Shorten_Ropes_Action_Check) _vehicle: ", _vehicle, "    _unit: ", _unit];
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
		if !([_vehicle] call ASL_Is_Supported_Vehicle) exitWith {false};
		private _existingRopes = _vehicle getVariable ["ASL_Ropes", []];
		if (count _existingRopes == 0) exitWith {false};
		private _activeRopes = [_vehicle] call ASL_Get_Active_Ropes;
		if (count _activeRopes == 0) exitWith {false};
		true
	};

	ASL_Shorten_Ropes_Action = {
		params [["_vehicle", objNull], "_unit"];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Extend_Ropes_Action) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if (isNull _vehicle) exitWith {false};
		if !([_vehicle] call ASL_Can_Shorten_Ropes) exitWith {false};
		private _activeRopes = [_vehicle] call ASL_Get_Active_Ropes;
		if (count _activeRopes == 1) then {
			[_vehicle, _unit, (_activeRopes select 0) select 0] call ASL_Shorten_Ropes;
		};
		if (count _activeRopes > 1) then {
			_unit setVariable ["ASL_Shorten_Index_Vehicle", _vehicle];
			["Shorten Cargo Ropes", "ASL_Shorten_Ropes_Index_Action", _activeRopes] call ASL_Show_Select_Ropes_Menu;
		}; 
	};

	ASL_Shorten_Ropes = {
		params ["_vehicle", "_player", ["_ropeIndex", 0]];
		if (local _vehicle) exitWith {
			private _existingRopes = [_vehicle, _ropeIndex] call ASL_Get_Ropes;
			if (count _existingRopes > 0) then {
				private _ropeLength = ropeLength (_existingRopes select 0);
				if (_ropeLength <= 2) exitWith {
					_this call ASL_Release_Cargo;
				}; 
				{
					if (_ropeLength >= 10) then {
						ropeUnwind [_x, 3, -5, true];
					} else {
						ropeUnwind [_x, 3, -1, true];
					};
				} forEach _existingRopes;
			};
		};
		[_this,"ASL_Shorten_Ropes", _vehicle, true] call ASL_RemoteExec;
	};
	
	ASL_Release_Cargo_Index_Action = {
		params ["_ropesIndex"];
		private _vehicle = player getVariable ["ASL_Release_Cargo_Index_Vehicle", objNull];
		if (_ropesIndex >= 0 && !isNull _vehicle && [_vehicle] call ASL_Can_Release_Cargo) then {
			[_vehicle, player, _ropesIndex] call ASL_Release_Cargo;
		};
	};
	
	ASL_Release_Cargo_Action_Check = {
		params ["_vehicle", "_unit"];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Release_Cargo_Action_Check) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if ([getConnectedUAV _unit, _unit] call ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Release_Cargo_Action_Check) EXIT 1, can release: ", [getConnectedUAV _unit, _unit] call ASL_Can_Release_Cargo];
			[getConnectedUAV _unit] call ASL_Can_Release_Cargo
		};
		if (vehicle _unit == _vehicle && [_vehicle, _unit] call ASL_Is_Unit_Authorized) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Release_Cargo_Action_Check) EXIT 2, can release: ", [_vehicle, _unit] call ASL_Can_Release_Cargo];
			[_vehicle] call ASL_Can_Release_Cargo
		};
		false
	};
	
	ASL_Can_Release_Cargo = {
		params ["_vehicle"];
		if !([_vehicle] call ASL_Is_Supported_Vehicle) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Release_Cargo) EXIT 1"];
			false
		};
		_existingRopes = _vehicle getVariable ["ASL_Ropes", []];
		if (count _existingRopes == 0) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Release_Cargo) EXIT 2"];
			false
		};
		private _activeRopes = [_vehicle] call ASL_Get_Active_Ropes_With_Cargo;
		if (count _activeRopes == 0) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Release_Cargo) EXIT 3"];
			false
		};
		
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Release_Cargo) _existingRopes: ", _existingRopes];
		true
	};
	
	ASL_Release_Cargo_Action = {
		params [["_vehicle", objNull], "_unit"];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Release_Cargo_Action) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if (isNull _vehicle) exitWith {false};
		if !([_vehicle] call ASL_Can_Release_Cargo) exitWith {false};
		private _activeRopes = [_vehicle] call ASL_Get_Active_Ropes_With_Cargo;
		if (count _activeRopes == 1) then {
			[_vehicle, _unit, (_activeRopes select 0) select 0] call ASL_Release_Cargo;
			// [_vehicle, (_activeRopes select 0) select 0] call ASL_Release_Cargo;
		};
		if (count _activeRopes > 1) then {
			_unit setVariable ["ASL_Release_Cargo_Index_Vehicle", _vehicle];
			["Release Cargo", "ASL_Release_Cargo_Index_Action", _activeRopes, "Cargo"] call ASL_Show_Select_Ropes_Menu;
		}; 
	};
	
	ASL_Release_Cargo = {
		params ["_vehicle", "_player", ["_ropeIndex", 0]];
		// params ["_vehicle", ["_ropeIndex", 0]];
		if (local _vehicle) exitWith {
			private _existingRopesAndCargo = [_vehicle,_ropeIndex] call ASL_Get_Ropes_And_Cargo;
			private _existingRopes = _existingRopesAndCargo select 0;
			private _existingCargo = _existingRopesAndCargo select 1; 
			{
				_existingCargo ropeDetach _x;
			} forEach _existingRopes;
			private _allCargo = _vehicle getVariable ["ASL_Cargo", []];
			_allCargo set [_ropeIndex, objNull];
			_vehicle setVariable ["ASL_Cargo", _allCargo, true];
			_this call ASL_Retract_Ropes;
		};
		[_this, "ASL_Release_Cargo", _vehicle, true] call ASL_RemoteExec;
	};
	
	ASL_Retract_Ropes_Action_Check = {
		params ["_vehicle", "_unit"];
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
		params ["_vehicle", "_unit", ["_distanceCheck", false]];
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
		params [["_vehicle", objNull], "_unit"];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Retract_Ropes_Action) _vehicle: ", _vehicle, "    _unit: ", _unit];
		if (isNull _vehicle) exitWith {false};
		if !([_vehicle] call ASL_Can_Retract_Ropes) exitWith {false};
		private _activeRopes = [_vehicle] call ASL_Get_Active_Ropes_Without_Cargo;
		if (count _activeRopes == 1) then {
			[_vehicle, _unit, (_activeRopes select 0) select 0] call ASL_Retract_Ropes;
			// [_vehicle, (_activeRopes select 0) select 0] call ASL_Retract_Ropes;
		};
		if (count _activeRopes > 1) then {
			_unit setVariable ["ASL_Retract_Ropes_Index_Vehicle", _vehicle];
			["Retract Cargo Ropes", "ASL_Retract_Ropes_Index_Action", _activeRopes] call ASL_Show_Select_Ropes_Menu;
		}; 
	};
	
	ASL_Retract_Ropes = {
		params ["_vehicle", "_player", ["_ropeIndex", 0]];
		// params ["_vehicle", ["_ropeIndex", 0]];
		if (local _vehicle) exitWith {
			private _existingRopesAndCargo = [_vehicle, _ropeIndex] call ASL_Get_Ropes_And_Cargo;
			private _existingRopes = _existingRopesAndCargo select 0;
			private _existingCargo = _existingRopesAndCargo select 1; 
			if (isNull _existingCargo) then {
				_this call ASL_Drop_Ropes;
				{
					[_x] spawn {
						params ["_rope"];
						private _count = 0;
						ropeUnwind [_rope, 3, 0];
						while {(!ropeUnwound _rope) && _count < 20} do {
							sleep 1;
							_count = _count + 1;
						};
						ropeDestroy _rope;
					};
				} forEach _existingRopes;
				private _allRopes = _vehicle getVariable ["ASL_Ropes", []];
				_allRopes set [_ropeIndex, []];
				_vehicle setVariable ["ASL_Ropes", _allRopes, true];
			};
			private _activeRopes = [_vehicle] call ASL_Get_Active_Ropes;
			if (count _activeRopes == 0) then {
				_vehicle setVariable ["ASL_Ropes", nil, true];
			};
		};
		[_this, "ASL_Retract_Ropes", _vehicle, true] call ASL_RemoteExec;
	};
	
	ASL_Retract_Ropes_Index_Action = {
		params ["_ropesIndex"];
		private _vehicle = player getVariable ["ASL_Retract_Ropes_Index_Vehicle", objNull];
		if (_ropesIndex >= 0 && !isNull _vehicle && [_vehicle] call ASL_Can_Retract_Ropes) then {
			[_vehicle, player, _ropesIndex] call ASL_Retract_Ropes;
			// [_vehicle, _ropesIndex] call ASL_Retract_Ropes;
		};
	};
	
	ASL_Deploy_Ropes = {
		params ["_vehicle", "_player", ["_cargoCount", 1]];
		if (local _vehicle) then {
			private _slingLoadPoints = [_vehicle] call ASL_Get_Sling_Load_Points;
			private _existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
			if (count _existingRopes == 0) then {
				if (count _slingLoadPoints == 0) exitWith {
					[["Vehicle doesn't support cargo ropes", false], "ASL_Hint", _player] call ASL_RemoteExec;
				};
				if (count _slingLoadPoints < _cargoCount) exitWith {
					[["Vehicle doesn't support " + _cargoCount + " cargo ropes", false], "ASL_Hint", _player] call ASL_RemoteExec;
				};
				private _cargoRopes = [];
				private _cargo = [];
				for "_i" from 0 to (_cargoCount-1) do {
					_cargoRopes pushBack [];
					_cargo pushBack objNull;
				};
				_vehicle setVariable ["ASL_Ropes", _cargoRopes, true];
				_vehicle setVariable ["ASL_Cargo", _cargo, true];
				for "_i" from 0 to (_cargoCount-1) do
				{
					[_vehicle, _player, _i] call ASL_Deploy_Ropes_Index;
				};
			} else {
				[["Vehicle already has cargo ropes deployed", false], "ASL_Hint", _player] call ASL_RemoteExec;
			};
		} else {
			[_this, "ASL_Deploy_Ropes", _vehicle, true] call ASL_RemoteExec;
		};
	};
	
	ASL_Deploy_Ropes_Index = {
		params ["_vehicle", "_player", ["_ropesIndex", 0], ["_ropeLength", 15]];
		if (local _vehicle) then {
			private _existingRopes = [_vehicle,_ropesIndex] call ASL_Get_Ropes;
			private _existingRopesCount = [_vehicle] call ASL_Get_Ropes_Count;
			if (count _existingRopes == 0) then {
				private _slingLoadPoints = [_vehicle] call ASL_Get_Sling_Load_Points;
				private _cargoRopes = [];
				_cargoRopes pushBack ropeCreate [_vehicle, (_slingLoadPoints select (_existingRopesCount - 1)) select _ropesIndex, 0]; 
				_cargoRopes pushBack ropeCreate [_vehicle, (_slingLoadPoints select (_existingRopesCount - 1)) select _ropesIndex, 0]; 
				_cargoRopes pushBack ropeCreate [_vehicle, (_slingLoadPoints select (_existingRopesCount - 1)) select _ropesIndex, 0]; 
				_cargoRopes pushBack ropeCreate [_vehicle, (_slingLoadPoints select (_existingRopesCount - 1)) select _ropesIndex, 0]; 
				{
					ropeUnwind [_x, 5, _ropeLength];
				} forEach _cargoRopes;
				private _allRopes = _vehicle getVariable ["ASL_Ropes", []];
				_allRopes set [_ropesIndex, _cargoRopes];
				_vehicle setVariable ["ASL_Ropes", _allRopes, true];
			};
		} else {
			[_this, "ASL_Deploy_Ropes_Index", _vehicle, true] call ASL_RemoteExec;
		};
	};
	
	ASL_Deploy_Ropes_Index_Action = {
		params ["_ropesIndex"];
		private _vehicle = player getVariable ["ASL_Deploy_Ropes_Index_Vehicle", objNull];
		// if (_ropesIndex >= 0 && !isNull _vehicle && [_vehicle] call ASL_Can_Deploy_Ropes) then {
		if (_ropesIndex >= 0 && !isNull _vehicle && [_vehicle, player] call ASL_Can_Deploy_Ropes) then {
			[_vehicle, player, _ropesIndex] call ASL_Deploy_Ropes_Index;
		};
	};
	
	ASL_Deploy_Ropes_Count_Action = {
		params ["_count"];
		private _vehicle = player getVariable ["ASL_Deploy_Count_Vehicle", objNull];
		// if (_count > 0 && !isNull _vehicle && [_vehicle] call ASL_Can_Deploy_Ropes) then {
		if (_count > 0 && !isNull _vehicle && [_vehicle, player] call ASL_Can_Deploy_Ropes) then {
			[_vehicle, player, _count] call ASL_Deploy_Ropes;
		};
	};
	
	ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit = {
		params ["_UAV", "_unit"];
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit) _UAV: ", _UAV, "    _unit: ", _unit];
		if (isNull _UAV) exitWith {false};
		if (UAVControl _UAV select 0 == _unit && (UAVControl _UAV select 1 == "GUNNER" || UAVControl _UAV select 1 == "DRIVER")) exitWith {
			// diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (ASL_Vehicle_Is_UAV_And_Currently_Operatied_By_Unit) EXIT 1: unit is UAV gunner or driver"];
			true
		};
		false
	};
	
	ASL_Deploy_Ropes_Action_Check = {
		params ["_vehicle", "_unit"];
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
		params ["_vehicle", "_unit", ["_distanceCheck", false]];
		_unit setVariable ["ASL_TargetDeployVehicle", nil];
		// if (_distanceCheck && player distance _vehicle > ASL_MaxDeployRetractDistance) exitWith {
		if (_distanceCheck && _unit distance _vehicle > ASL_MaxDeployRetractDistance) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Deploy_Ropes) EXIT 1"];
			false
		};
		if !([_vehicle] call ASL_Is_Supported_Vehicle) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Deploy_Ropes) EXIT 2"];
			false
		};
		// private _existingVehicle = player getVariable ["ASL_Ropes_Vehicle", []];
		private _existingVehicle = _unit getVariable ["ASL_Ropes_Vehicle", []];
		if (count _existingVehicle > 0) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Deploy_Ropes) EXIT 3"];
			false
		};
		_existingRopes = _vehicle getVariable ["ASL_Ropes", []];
		if (count _existingRopes == 0) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Deploy_Ropes) EXIT 4"];
			_unit setVariable ["ASL_TargetDeployVehicle", _vehicle];
			true
		};
		private _activeRopes = [_vehicle] call ASL_Get_Active_Ropes;
		if (count _existingRopes > 0 && (count _existingRopes) == (count _activeRopes)) exitWith {
			// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Can_Deploy_Ropes) EXIT 5"];
			false
		};
		_unit setVariable ["ASL_TargetDeployVehicle", _vehicle];
		true
	};
	
	ASL_Deploy_Ropes_Action = {
		params [["_vehicle", objNull]];
		
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Deploy_Ropes_Action) _this: ", _this];
		if (isNull _vehicle) exitWith {false};
		
		private _canDeployRopes = true;
		if !(missionNamespace getVariable ["ASL_LOCKED_VEHICLES_ENABLED", false]) then {
			if (locked _vehicle > 1) then {
				["Cannot deploy cargo ropes from locked vehicle", false] call ASL_Hint;
				_canDeployRopes = false;
			};
		};
		if (!_canDeployRopes) exitWith {};
		
		// diag_log formatText ["%1%2%3%4%5", time, "s  (ASL_Deploy_Ropes_Action) _canDeployRopes: ", _canDeployRopes];
		
		private _inactiveRopes = [_vehicle] call ASL_Get_Inactive_Ropes;
		if (count _inactiveRopes > 0) then {
			if (count _inactiveRopes > 1) then {
				player setVariable ["ASL_Deploy_Ropes_Index_Vehicle", _vehicle];	
				["Deploy Cargo Ropes", "ASL_Deploy_Ropes_Index_Action", _inactiveRopes] call ASL_Show_Select_Ropes_Menu;
			} else {
				[_vehicle, player, (_inactiveRopes select 0) select 0] call ASL_Deploy_Ropes_Index;
			};
		} else {
			private _slingLoadPoints = [_vehicle] call ASL_Get_Sling_Load_Points;
			if (count _slingLoadPoints > 1) then {
				player setVariable ["ASL_Deploy_Count_Vehicle", _vehicle];
				ASL_Deploy_Ropes_Count_Menu = [
					["Deploy Ropes", false]
				];
				ASL_Deploy_Ropes_Count_Menu pushBack ["For Single Cargo", [0], "", -5, [["expression", "[1] call ASL_Deploy_Ropes_Count_Action"]], "1", "1"];
				if ((count _slingLoadPoints) > 1) then {
					ASL_Deploy_Ropes_Count_Menu pushBack ["For Double Cargo", [0], "", -5, [["expression", "[2] call ASL_Deploy_Ropes_Count_Action"]], "1", "1"];
				};
				if ((count _slingLoadPoints) > 2) then {
					ASL_Deploy_Ropes_Count_Menu pushBack ["For Triple Cargo", [0], "", -5, [["expression", "[3] call ASL_Deploy_Ropes_Count_Action"]], "1", "1"];
				};
				showCommandingMenu "";
				showCommandingMenu "#USER:ASL_Deploy_Ropes_Count_Menu";
			} else {			
				[_vehicle, player] call ASL_Deploy_Ropes;
			};
		};
	};
	
	ASL_Get_Corner_Points = {
		params ["_vehicle"];
		
		// Correct width and length factor for air
		private _widthFactor = 0.5;
		private _lengthFactor = 0.5;
		if (_vehicle isKindOf "Air") then {
			_widthFactor = 0.3;
		};
		if (_vehicle isKindOf "Helicopter") then {
			_widthFactor = 0.2;
			_lengthFactor = 0.45;
		};
		
		private _centerOfMass = getCenterOfMass _vehicle;
		private _bbr = boundingBoxReal _vehicle;
		private _p1 = _bbr select 0;
		private _p2 = _bbr select 1;
		private _maxWidth = abs ((_p2 select 0) - (_p1 select 0));
		private _widthOffset = ((_maxWidth / 2) - abs (_centerOfMass select 0)) * _widthFactor;
		private _maxLength = abs ((_p2 select 1) - (_p1 select 1));
		private _lengthOffset = ((_maxLength / 2) - abs (_centerOfMass select 1)) * _lengthFactor;
		private _maxHeight = abs ((_p2 select 2) - (_p1 select 2));
		private _heightOffset = _maxHeight/6;
		
		private _rearCorner = [(_centerOfMass select 0) + _widthOffset, (_centerOfMass select 1) - _lengthOffset, (_centerOfMass select 2)+_heightOffset];
		private _rearCorner2 = [(_centerOfMass select 0) - _widthOffset, (_centerOfMass select 1) - _lengthOffset, (_centerOfMass select 2)+_heightOffset];
		private _frontCorner = [(_centerOfMass select 0) + _widthOffset, (_centerOfMass select 1) + _lengthOffset, (_centerOfMass select 2)+_heightOffset];
		private _frontCorner2 = [(_centerOfMass select 0) - _widthOffset, (_centerOfMass select 1) + _lengthOffset, (_centerOfMass select 2)+_heightOffset];
		
		[_rearCorner, _rearCorner2, _frontCorner, _frontCorner2];
	};
	
	ASL_Attach_Ropes = {
		params ["_cargo", "_player"];
		private _vehicleWithIndex = _player getVariable ["ASL_Ropes_Vehicle", [objNull, 0]];
		private _vehicle = _vehicleWithIndex select 0;
		if (!isNull _vehicle) then {
			if (local _vehicle) then {
				private _ropes = [_vehicle,(_vehicleWithIndex select 1)] call ASL_Get_Ropes;
				if (count _ropes == 4) then {
					private _attachmentPoints = [_cargo] call ASL_Get_Corner_Points;
					private _ropeLength = (ropeLength (_ropes select 0));
					private _objDistance = (_cargo distance _vehicle) + 2;
					if (_objDistance > _ropeLength) then {
						[["The cargo ropes are too short. Move vehicle closer.", false],"ASL_Hint",_player] call ASL_RemoteExec;
					} else {		
						[_vehicle, _player] call ASL_Drop_Ropes;
						[_cargo, _attachmentPoints select 0, [0, 0, -1]] ropeAttachTo (_ropes select 0);
						[_cargo, _attachmentPoints select 1, [0, 0, -1]] ropeAttachTo (_ropes select 1);
						[_cargo, _attachmentPoints select 2, [0, 0, -1]] ropeAttachTo (_ropes select 2);
						[_cargo, _attachmentPoints select 3, [0, 0, -1]] ropeAttachTo (_ropes select 3);
						private _allCargo = _vehicle getVariable ["ASL_Cargo", []];
						_allCargo set [(_vehicleWithIndex select 1),_cargo];
						_vehicle setVariable ["ASL_Cargo",_allCargo, true];
						if (missionNamespace getVariable ["ASL_HEAVY_LIFTING_ENABLED",true]) then {
							[_cargo, _vehicle, _ropes] spawn ASL_Rope_Adjust_Mass;		
						};				
					};
				};
			} else {
				[_this, "ASL_Attach_Ropes", _vehicle, true] call ASL_RemoteExec;
			};
		};
	};
	
	ASL_Attach_Ropes_Action = {
		private _cargo = cursorTarget;
		private _vehicle = (player getVariable ["ASL_Ropes_Vehicle", [objNull, 0]]) select 0;
		if ([_vehicle, _cargo] call ASL_Can_Attach_Ropes) then {
			private _canBeAttached = true;
			if !(missionNamespace getVariable ["ASL_LOCKED_VEHICLES_ENABLED", false]) then {
				if (locked _cargo > 1) then {
					["Cannot attach cargo ropes to locked vehicle", false] call ASL_Hint;
					_canBeAttached = false;
				};
			};
			if !(missionNamespace getVariable ["ASL_EXILE_SAFEZONE_ENABLED", false]) then {
				if (!isNil "ExilePlayerInSafezone") then {
					if (ExilePlayerInSafezone) then {
						["Cannot attach cargo ropes in safe zone", false] call ASL_Hint;
						_canBeAttached = false;
					};
				};
			};
			if (_canBeAttached) then {
				[_cargo, player] call ASL_Attach_Ropes;
			};
		};
	};
	
	ASL_Attach_Ropes_Action_Check = {
		private _vehicleWithIndex = player getVariable ["ASL_Ropes_Vehicle", [objNull,0]];
		private _cargo = cursorTarget;
		[_vehicleWithIndex select 0,_cargo] call ASL_Can_Attach_Ropes;
	};
	
	ASL_Can_Attach_Ropes = {
		params ["_vehicle", "_cargo"];
		if (!isNull _vehicle && !isNull _cargo) then {
			[_vehicle, _cargo] call ASL_Is_Supported_Cargo && vehicle player == player && player distance _cargo < 10 && _vehicle != _cargo;
		} else {
			false;
		};
	};
	
	ASL_Drop_Ropes = {
		params ["_vehicle", "_player", ["_ropesIndex", 0]];
		if (local _vehicle) then {
			private _helper = (_player getVariable ["ASL_Ropes_Pick_Up_Helper", objNull]);
			if (!isNull _helper) then {
				private _existingRopes = [_vehicle, _ropesIndex] call ASL_Get_Ropes;		
				{
					_helper ropeDetach _x;
				} forEach _existingRopes;
				detach _helper;
				deleteVehicle _helper;		
			};
			_player setVariable ["ASL_Ropes_Vehicle", nil,true];
			_player setVariable ["ASL_Ropes_Pick_Up_Helper", nil,true];
		} else {
			[_this, "ASL_Drop_Ropes", _vehicle, true] call ASL_RemoteExec;
		};
	};
	
	ASL_Drop_Ropes_Action = {
		if ([] call ASL_Can_Drop_Ropes) then {	
			private _vehicleAndIndex = player getVariable ["ASL_Ropes_Vehicle", []];
			if (count _vehicleAndIndex == 2) then {
				[_vehicleAndIndex select 0, player, _vehicleAndIndex select 1] call ASL_Drop_Ropes;
			};
		};
	};
	
	ASL_Drop_Ropes_Action_Check = {
		[] call ASL_Can_Drop_Ropes;
	};
	
	ASL_Can_Drop_Ropes = {
		count (player getVariable ["ASL_Ropes_Vehicle", []]) > 0 && vehicle player == player;
	};
	
	ASL_Get_Closest_Rope = {
		private _nearbyVehicles = missionNamespace getVariable ["ASL_Nearby_Vehicles", []];
		private _closestVehicle = objNull;
		private _closestRopeIndex = 0;
		private _closestDistance = -1;
		private ["_vehicle", "_activeRope", "_ropes", "_ends", "_end1", "_end2", "_minEndDistance"];
		{
			_vehicle = _x;
			{
				_activeRope = _x;
				_ropes = [_vehicle, (_activeRope select 0)] call ASL_Get_Ropes;
				{
					_ends = ropeEndPosition _x;
					if (count _ends == 2) then {
						_end1 = _ends select 0;
						_end2 = _ends select 1;
						_minEndDistance = ((position player) distance _end1) min ((position player) distance _end2);
						if (_closestDistance == -1 || _closestDistance > _minEndDistance) then {
							_closestDistance = _minEndDistance;
							_closestRopeIndex = (_activeRope select 0);
							_closestVehicle = _vehicle;
						};
					};
				} forEach _ropes;
			} forEach ([_vehicle] call ASL_Get_Active_Ropes);
		} forEach _nearbyVehicles;
		[_closestVehicle, _closestRopeIndex];
	};
	
	ASL_Pickup_Ropes = {
		params ["_vehicle", "_player", ["_ropesIndex", 0]];
		if (local _vehicle) then {
			private _existingRopesAndCargo = [_vehicle,_ropesIndex] call ASL_Get_Ropes_And_Cargo;
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
			private _helper = "Land_Can_V2_F" createVehicle position _player;
			{
				[_helper, [0, 0, 0], [0, 0, -1]] ropeAttachTo _x;
				_helper attachTo [_player, [-0.1, 0.1, 0.15], "Pelvis"];
			} forEach _existingRopes;
			hideObject _helper;
			[[_helper], "ASL_Hide_Object_Global"] call ASL_RemoteExecServer;
			_player setVariable ["ASL_Ropes_Vehicle", [_vehicle, _ropesIndex], true];
			_player setVariable ["ASL_Ropes_Pick_Up_Helper", _helper, true];
		} else {
			[_this, "ASL_Pickup_Ropes", _vehicle, true] call ASL_RemoteExec;
		};
	};
	
	ASL_Pickup_Ropes_Action = {
		private _nearbyVehicles = missionNamespace getVariable ["ASL_Nearby_Vehicles", []];
		if ([] call ASL_Can_Pickup_Ropes) then {
			private _closestRope = [] call ASL_Get_Closest_Rope;
			if (!isNull (_closestRope select 0)) then {
				private _canPickupRopes = true;
				if !(missionNamespace getVariable ["ASL_LOCKED_VEHICLES_ENABLED", false]) then {
					if (locked (_closestRope select 0) > 1) then {
						["Cannot pick up cargo ropes from locked vehicle", false] call ASL_Hint;
						_canPickupRopes = false;
					};
				};
				if (_canPickupRopes) then {
					[(_closestRope select 0), player, (_closestRope select 1)] call ASL_Pickup_Ropes;
				};	
			};
		};
	};
	
	ASL_Pickup_Ropes_Action_Check = {
		[] call ASL_Can_Pickup_Ropes;
	};
	
	ASL_Can_Pickup_Ropes = {
		count (player getVariable ["ASL_Ropes_Vehicle", []]) == 0 && count (missionNamespace getVariable ["ASL_Nearby_Vehicles",[]]) > 0 && vehicle player == player;
	};
	
	ASL_SUPPORTED_VEHICLES = [
		"Helicopter",
		"VTOL_Base_F"
	];
	
	ASL_Is_Supported_Vehicle = {
		params ["_vehicle"];
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
		params ["_vehicle", "_cargo"];
		private _canSling = false;
		if (not isNull _vehicle && not isNull _cargo) then {
			{
				if (_vehicle isKindOf (_x select 0)) then {
					if (_cargo isKindOf (_x select 2)) then {
						if ((toUpper (_x select 1)) == "CAN_SLING") then {
							_canSling = true;
						} else {
							_canSling = false;
						};
					};
				};
			} forEach (missionNamespace getVariable ["ASL_SLING_RULES_OVERRIDE", ASL_SLING_RULES]);
		};
		_canSling;
	};
	
	ASL_Hint = {
		params ["_msg", ["_isSuccess", true]];
		if (!isNil "ExileClient_gui_notification_event_addNotification") then {
			if (_isSuccess) then {
				["Success", [_msg]] call ExileClient_gui_notification_event_addNotification; 
			} else {
				["Whoops", [_msg]] call ExileClient_gui_notification_event_addNotification; 
			};
		} else {
			hint _msg;
		};
	};
	
	ASL_Hide_Object_Global = {
		params ["_obj"];
		if (_obj isKindOf "Land_Can_V2_F") then {
			hideObjectGlobal _obj;
		};
	};
	
	ASL_Find_Nearby_Vehicles = {
		private _nearVehicles = [];
		{
			_nearVehicles append  (player nearObjects [_x, 30]);
		} forEach (missionNamespace getVariable ["ASL_SUPPORTED_VEHICLES_OVERRIDE", ASL_SUPPORTED_VEHICLES]);
		private _nearVehiclesWithRopes = [];
		private ["_vehicle", "_ropes", "_ends", "_end1", "_end2", "_playerPosAGL"];
		{
			_vehicle = _x;
			{
				_ropes = _vehicle getVariable ["ASL_Ropes",[]];
				if (count _ropes > (_x select 0)) then {
					_ropes = _ropes select (_x select 0);
					{
						_ends = ropeEndPosition _x;
						if (count _ends == 2) then {
							_end1 = _ends select 0;
							_end2 = _ends select 1;
							_playerPosAGL = ASLtoAGL getPosASL player;
							if ((_playerPosAGL distance _end1) < 5 || (_playerPosAGL distance _end2) < 5) then {
								_nearVehiclesWithRopes =  _nearVehiclesWithRopes + [_vehicle];
							}
						};
					} forEach _ropes;
				};
			} forEach ([_vehicle] call ASL_Get_Active_Ropes);
		} forEach _nearVehicles;
		_nearVehiclesWithRopes;
	};
	
	ASL_Add_Vehicle_Actions = {
		params ["_vehicle"];
		private _exit = true;
		{
			if (_vehicle isKindOf _x) exitWith {_exit = false};
		} foreach ASL_SUPPORTED_VEHICLES;
		if (_exit) exitWith {};

		if (isNil{_vehicle getVariable "ASL_ActionID_Deploy"}) then {
			private _actionID = _vehicle addAction [
				"Deploy Cargo Ropes",									// Title
				{[_this select 0] call ASL_Deploy_Ropes_Action;},		// Script
				nil,													// Arguments
				0,														// Priority
				false,													// showWindow
				true,													// hideOnUse
				"",														// Shortcut
				"[_target, _this] call ASL_Deploy_Ropes_Action_Check"	// Condition
			];
			_vehicle setVariable ["ASL_ActionID_Deploy", _actionID];
		};
		
		if (isNil{_vehicle getVariable "ASL_ActionID_Retract"}) then {
			private _actionID = _vehicle addAction [
				"Retract Cargo Ropes",												// Title
				{[_this select 0, _this select 1] call ASL_Retract_Ropes_Action;},	// Script
				nil,																// Arguments
				0,																	// Priority
				false,																// showWindow
				true,																// hideOnUse
				"",																	// Shortcut
				"[_target, _this] call ASL_Retract_Ropes_Action_Check"				// Condition
			];
			_vehicle setVariable ["ASL_ActionID_Retract", _actionID];
		};

		if (isNil{_vehicle getVariable "ASL_ActionID_Extend"}) then {
			private _actionID = _vehicle addAction [
				"Extend Cargo Ropes",												// Title
				{[_this select 0, _this select 1] call ASL_Extend_Ropes_Action;},	// Script
				nil,																// Arguments
				0,																	// Priority
				false,																// showWindow
				true,																// hideOnUse
				"",																	// Shortcut
				"[_target, _this] call ASL_Extend_Ropes_Action_Check"				// Condition
			];
			_vehicle setVariable ["ASL_ActionID_Extend", _actionID];
		};
		
		if (isNil{_vehicle getVariable "ASL_ActionID_Shorten"}) then {
			private _actionID = _vehicle addAction [
				"Shorten Cargo Ropes",												// Title
				{[_this select 0, _this select 1] call ASL_Shorten_Ropes_Action;},	// Script
				nil,																// Arguments
				0,																	// Priority
				false,																// showWindow
				true,																// hideOnUse
				"",																	// Shortcut
				"[_target, _this] call ASL_Shorten_Ropes_Action_Check"				// Condition
			];
			_vehicle setVariable ["ASL_ActionID_Shorten", _actionID];
		};
		
		if (isNil{_vehicle getVariable "ASL_ActionID_Release"}) then {
			private _actionID = _vehicle addAction [
				"Release Cargo",													// Title
				{[_this select 0, _this select 1] call ASL_Release_Cargo_Action;},	// Script
				nil,																// Arguments
				0,																	// Priority
				false,																// showWindow
				true,																// hideOnUse
				"",																	// Shortcut
				"[_target, _this] call ASL_Release_Cargo_Action_Check"				// Condition
			];
			_vehicle setVariable ["ASL_ActionID_Release", _actionID];
		};
	};
	
	ASL_Add_Player_Actions = {
		player addAction ["Pickup Cargo Ropes", { 
			[] call ASL_Pickup_Ropes_Action;
		}, nil, 0, false, true, "", "call ASL_Pickup_Ropes_Action_Check"];
		
		player addAction ["Drop Cargo Ropes", { 
			[] call ASL_Drop_Ropes_Action;
		}, nil, 0, false, true, "", "call ASL_Drop_Ropes_Action_Check"];
		
		player addAction ["Attach To Cargo Ropes", { 
			[] call ASL_Attach_Ropes_Action;
		}, nil, 0, false, true, "", "call ASL_Attach_Ropes_Action_Check"];
		
		player addEventHandler ["Respawn", {
			player setVariable ["ASL_Actions_Loaded", false];
		}];
	};
	
	if (!isDedicated) then {
		["Air", "init", {_this call ASL_Add_Vehicle_Actions}, true] call CBA_fnc_addClassEventHandler; // adds init event to all air vehicles; has to be run preinit!
		[] spawn {
			while {true} do {
				if (!isNull player && isPlayer player) then {
					if !(player getVariable ["ASL_Actions_Loaded", false]) then {
						[] call ASL_Add_Player_Actions;
						player setVariable ["ASL_Actions_Loaded", true];
					};
				};
				missionNamespace setVariable ["ASL_Nearby_Vehicles", (call ASL_Find_Nearby_Vehicles)];
				sleep 2;
			};
		};
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
		
		// Adds support for exile network calls (Only used when running exile)
		ASL_SUPPORTED_REMOTEEXECSERVER_FUNCTIONS = ["ASL_Hide_Object_Global"];
		
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
		
		ASL_SUPPORTED_REMOTEEXECCLIENT_FUNCTIONS = ["ASL_Pickup_Ropes", "ASL_Deploy_Ropes_Index", "ASL_Rope_Set_Mass", "ASL_Extend_Ropes", "ASL_Shorten_Ropes", "ASL_Release_Cargo", "ASL_Retract_Ropes", "ASL_Deploy_Ropes", "ASL_Hint", "ASL_Attach_Ropes", "ASL_Drop_Ropes"];
		
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
	if (isNil "ASL_MaxRopeLength") then {ASL_MaxRopeLength 							= 100};		// max rope length in meter
	if (isNil "ASL_MaxDeployRetractDistance") then {ASL_MaxDeployRetractDistance 	= 10};		// max rope deploy, retract distance in meter (when player is on foot)
	if (isNil "ASL_PilotsAuthorized") then {ASL_PilotsAuthorized 					= true};	// Pilots authorized to manipulate ropes
	if (isNil "ASL_CommandersAuthorized") then {ASL_CommandersAuthorized 			= true};	// Pilots authorized to manipulate ropes
	if (isNil "ASL_CopilotsAuthorized") then {ASL_CopilotsAuthorized 				= true};	// Copilots authorized to manipulate ropes
	if (isNil "ASL_GunnersAuthorized") then {ASL_GunnersAuthorized 					= true};	// Gunners authorized to manipulate ropes
	[] call ASL_Advanced_Sling_Loading_Install;
};
