/*
The MIT License (MIT)

Copyright (c) 2016 Seth Duda

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

ASL_Advanced_Sling_Loading_Install = {

// Prevent advanced sling loading from installing twice
if(!isNil "ASL_ROPE_INIT") exitWith {};
ASL_ROPE_INIT = true;

diag_log "Advanced Sling Loading Loading...";

ASL_Rope_Get_Lift_Capability = {
	private ["_heli","_heliType"];
	_heli = [_this,0] call BIS_fnc_param;
	_heliType = toLower(typeOf _heli);
	_returnVal = [500,0];
	if(
		//(_heliType) == toLower("B_Heli_Transport_01_F") ||
		//(_heliType) == toLower("B_Heli_Transport_01_camo_F") ||
		(_heliType) == toLower("I_Heli_Transport_02_F")
	) then {
		_returnVal = [4000,100000];
	};
	if(
		(_heliType) == toLower("B_Heli_Transport_03_F") ||
		(_heliType) == toLower("B_Heli_Transport_03_unarmed_F")
	) then {
		_returnVal = [10000,100000];
	};
	if(
		(_heliType) == toLower("O_Heli_Transport_04_F") ||
		(_heliType) == toLower("O_Heli_Transport_04_ammo_F")
	) then {
		_returnVal = [12000,100000];
	};
	_returnVal;
};

ASL_Rope_Set_Mass = {
	private ["_obj","_mass"];
	_obj = [_this,0] call BIS_fnc_param;
	_mass = [_this,1] call BIS_fnc_param;
	_obj setMass _mass;
};

ASL_Rope_Adjust_Mass = {
	private ["_obj","_mass","_lift","_heli","_originalMass","_ropes"];
	_obj = [_this,0] call BIS_fnc_param;
	_heli = [_this,1] call BIS_fnc_param;
	_ropes = [_this,2,[]] call BIS_fnc_param;
	_lift = [_heli] call ASL_Rope_Get_Lift_Capability;
	_originalMass = _obj getVariable ["asl_rope_original_mass", getMass _obj];
	// Is mass adjustment needed?
	if( _originalMass >= ((_lift select 0)*0.8) && _originalMass <= _lift select 1 ) then {
		private ["_originalMassSet","_ends","_endDistance","_ropeLength"];
		_originalMassSet = (getMass _obj) == _originalMass;
		while { _obj in (ropeAttachedObjects _heli) && _originalMassSet } do {
			{
				_ends = ropeEndPosition _x;
				_endDistance = (_ends select 0) distance (_ends select 1);
				_ropeLength = ropeLength _x;
				if((_ropeLength - 2) <= _endDistance && ((position _heli) select 2) > 0 ) then {
					[[_obj, ((_lift select 0)*0.8)],"ASL_Rope_Set_Mass",_obj,false,true] spawn BIS_fnc_MP;
					_originalMassSet = false;
				};
			} forEach _ropes;
			sleep 0.1;
		};
		while { _obj in (ropeAttachedObjects _heli) } do {
			sleep 0.5;
		};
		[[_obj, _originalMass],"ASL_Rope_Set_Mass",_obj,false,true] spawn BIS_fnc_MP;
	};	
};
	
ASL_Extend_Ropes = {
	params ["_vehicle","_player"];
	if(local _vehicle) then {
		private ["_existingRopes"];
		_existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
		if(count _existingRopes > 0) then {
			_ropeLength = ropeLength (_existingRopes select 0);
			if(_ropeLength <= 100 ) then {
				{
					ropeUnwind [_x, 3, 5, true];
				} forEach _existingRopes;
			};
		};
	} else {
		[_this,"ASL_Extend_Ropes",_vehicle,true] call ASL_RemoteExec;
	};
};

ASL_Extend_Ropes_Action = {
	private ["_vehicle"];
	_vehicle = vehicle player;
	if([_vehicle] call ASL_Can_Extend_Ropes) then {
		[_vehicle,player] call ASL_Extend_Ropes;
	};
};

ASL_Extend_Ropes_Action_Check = {
	[vehicle player] call ASL_Can_Extend_Ropes;
};

ASL_Can_Extend_Ropes = {
	params ["_vehicle"];
	private ["_existingRopes"];
	if([_vehicle] call ASL_Is_Supported_Vehicle) then {
		_existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
		player distance _vehicle < 10 && (count _existingRopes) > 0;
	} else {
		false;
	};
};
	
ASL_Shorten_Ropes = {
	params ["_vehicle","_player"];
	if(local _vehicle) then {
		private ["_existingRopes"];
		_existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
		if(count _existingRopes > 0) then {
			_ropeLength = ropeLength (_existingRopes select 0);
			if(_ropeLength <= 2 ) then {
				_this call ASL_Release_Cargo;
			} else {
				{
					if(_ropeLength >= 10) then {
						ropeUnwind [_x, 3, -5, true];
					} else {
						ropeUnwind [_x, 3, -1, true];
					};
				} forEach _existingRopes;
			};
		};
	} else {
		[_this,"ASL_Shorten_Ropes",_vehicle,true] call ASL_RemoteExec;
	};
};

ASL_Shorten_Ropes_Action = {
	private ["_vehicle"];
	_vehicle = vehicle player;
	if([_vehicle] call ASL_Can_Shorten_Ropes) then {
		[_vehicle,player] call ASL_Shorten_Ropes;
	};
};

ASL_Shorten_Ropes_Action_Check = {
	[vehicle player] call ASL_Can_Shorten_Ropes;
};

ASL_Can_Shorten_Ropes = {
	params ["_vehicle"];
	private ["_existingRopes"];
	if([_vehicle] call ASL_Is_Supported_Vehicle) then {
		_existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
		player distance _vehicle < 10 && (count _existingRopes) > 0;
	} else {
		false;
	};
};
	
ASL_Release_Cargo = {
	params ["_vehicle","_player"];
	if(local _vehicle) then {
		private ["_existingRopes","_attachedCargo","_attachedObj"];
		_existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
		_attachedCargo = ropeAttachedObjects _vehicle;
		if(count _existingRopes > 0 && count _attachedCargo > 0) then {
			{
				_attachedObj = _x;
				{
					_attachedObj ropeDetach _x;
				} forEach _existingRopes;
			} forEach ropeAttachedObjects _vehicle;
			_this call ASL_Retract_Ropes;
		};
	} else {
		[_this,"ASL_Release_Cargo",_vehicle,true] call ASL_RemoteExec;
	};
};
	
ASL_Release_Cargo_Action = {
	private ["_vehicle"];
	_vehicle = vehicle player;
	if([_vehicle] call ASL_Can_Release_Cargo) then {
		[_vehicle,player] call ASL_Release_Cargo;
	};
};

ASL_Release_Cargo_Action_Check = {
	[vehicle player] call ASL_Can_Release_Cargo;
};

ASL_Can_Release_Cargo = {
	params ["_vehicle"];
	private ["_existingRopes"];
	if([_vehicle] call ASL_Is_Supported_Vehicle) then {
		_existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
		player distance _vehicle < 10 && (count _existingRopes) > 0 && count (ropeAttachedObjects _vehicle) > 0;
	} else {
		false;
	};
};

ASL_Retract_Ropes = {
	params ["_vehicle","_player"];
	if(local _vehicle) then {
		private ["_existingRopes","_attachedCargo"];
		_existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
		_attachedCargo = ropeAttachedObjects _vehicle;
		if(count _existingRopes > 0 && count _attachedCargo == 0) then {
			_this call ASL_Drop_Ropes;
			{
				[_x,_vehicle] spawn {
					params ["_rope","_vehicle"];
					private ["_count"];
					_count = 0;
					ropeUnwind [_rope, 3, 0];
					while {(!ropeUnwound _rope) && _count < 20} do {
						sleep 1;
						_count = _count + 1;
					};
					ropeDestroy _rope;
				};
			} forEach _existingRopes;
			_vehicle setVariable ["ASL_Ropes",nil,true];
		};
	} else {
		[_this,"ASL_Retract_Ropes",_vehicle,true] call ASL_RemoteExec;
	};
};

ASL_Retract_Ropes_Action = {
	private ["_vehicle","_canRetractRopes"];
	if(vehicle player == player) then {
		_vehicle = cursorTarget;
	} else {
		_vehicle = vehicle player;
	};
	if([_vehicle] call ASL_Can_Retract_Ropes) then {
	
		_canRetractRopes = true;
		
		if!(missionNamespace getVariable ["ASL_LOCKED_VEHICLES_ENABLED",false]) then {
			if( locked _vehicle > 1 ) then {
				["Cannot retract cargo ropes to locked vehicle",false] call ASL_Hint;
				_canRetractRopes = false;
			};
		};
		
		if!(missionNamespace getVariable ["ASL_EXILE_SAFEZONE_ENABLED",false]) then {
			if(!isNil "ExilePlayerInSafezone") then {
				if( ExilePlayerInSafezone ) then {
					["Cannot retract cargo ropes in safe zone",false] call ASL_Hint;
					_canRetractRopes = false;
				};
			};
		};
	
		if(_canRetractRopes) then {
			[_vehicle,player] call ASL_Retract_Ropes;
		};
	
	};
};

ASL_Retract_Ropes_Action_Check = {
	[vehicle player] call ASL_Can_Retract_Ropes;
};

ASL_Can_Retract_Ropes = {
	params ["_vehicle"];
	private ["_existingRopes"];
	if([_vehicle] call ASL_Is_Supported_Vehicle) then {
		_existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
		player distance _vehicle < 10 && (count _existingRopes) > 0 && count (ropeAttachedObjects _vehicle) == 0;
	} else {
		false;
	};
};

ASL_Deploy_Ropes = {
	params ["_vehicle","_player",["_ropeLength",15]];
	if(local _vehicle) then {
		private ["_existingRopes","_cargoRopes","_startLength"];
		_existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
		if(count _existingRopes == 0) then {
			_startLength = 0;
			if(vehicle _player == _player) then {
				_startLength = _ropeLength;
			};
			_cargoRopes = [];
			_cargoRopes = _cargoRopes + [ropeCreate [_vehicle, "slingload0", _startLength]]; 
			_cargoRopes = _cargoRopes + [ropeCreate [_vehicle, "slingload0", _startLength]]; 
			_cargoRopes = _cargoRopes + [ropeCreate [_vehicle, "slingload0", _startLength]]; 
			_cargoRopes = _cargoRopes + [ropeCreate [_vehicle, "slingload0", _startLength]]; 
			_vehicle setVariable ["ASL_Ropes",_cargoRopes,true];
			{
				ropeUnwind [_x, 5, _ropeLength];
			} forEach _cargoRopes;
			if(vehicle _player == _player) then {
				// Pick up the ropes if player outside of vehicle
				_this call ASL_Pickup_Ropes;
			};
		};
	} else {
		[_this,"ASL_Deploy_Ropes",_vehicle,true] call ASL_RemoteExec;
	};
};

ASL_Deploy_Ropes_Action = {
	private ["_vehicle","_canDeployRopes"];
	if(vehicle player == player) then {
		_vehicle = cursorTarget;
	} else {
		_vehicle = vehicle player;
	};
	if([_vehicle] call ASL_Can_Deploy_Ropes) then {
	
		_canDeployRopes = true;
		
		if!(missionNamespace getVariable ["ASL_LOCKED_VEHICLES_ENABLED",false]) then {
			if( locked _vehicle > 1 ) then {
				["Cannot deploy cargo ropes from locked vehicle",false] call ASL_Hint;
				_canDeployRopes = false;
			};
		};
		
		if!(missionNamespace getVariable ["ASL_EXILE_SAFEZONE_ENABLED",false]) then {
			if(!isNil "ExilePlayerInSafezone") then {
				if( ExilePlayerInSafezone ) then {
					["Cannot deploy cargo ropes in safe zone",false] call ASL_Hint;
					_canDeployRopes = false;
				};
			};
		};
	
		if(_canDeployRopes) then {
			[_vehicle,player] call ASL_Deploy_Ropes;
		};
	
	};
};

ASL_Deploy_Ropes_Action_Check = {
	if(vehicle player == player) then {
		[cursorTarget] call ASL_Can_Deploy_Ropes;
	} else {
		[vehicle player] call ASL_Can_Deploy_Ropes;
	};
};

ASL_Can_Deploy_Ropes = {
	params ["_vehicle"];
	if([_vehicle] call ASL_Is_Supported_Vehicle) then {
		private ["_existingVehicle","_existingRopes"];
		_existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
		_existingVehicle = player getVariable ["ASL_Ropes_Vehicle", objNull];
		player distance _vehicle < 10 && (count _existingRopes) == 0 && isNull _existingVehicle;
	} else {
		false;
	};
};

ASL_Put_Away_Ropes = {
	params ["_vehicle","_player"];
	if(local _vehicle) then {
		private ["_existingRopes"];
		_existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
		if(count _existingRopes > 0) then {
			_this call ASL_Pickup_Ropes;
			_this call ASL_Drop_Ropes;
			{
				ropeDestroy _x;
			} forEach _existingRopes;
			_vehicle setVariable ["ASL_Ropes",nil,true];
		};
	} else {
		[_this,"ASL_Put_Away_Ropes",_vehicle,true] call ASL_RemoteExec;
	};
};

ASL_Put_Away_Ropes_Action = {
	private ["_vehicle","_canPutAwayRopes"];
	_vehicle = cursorTarget;
	if([_vehicle] call ASL_Can_Put_Away_Ropes) then {
	
		_canPutAwayRopes = true;
		
		if!(missionNamespace getVariable ["ASL_LOCKED_VEHICLES_ENABLED",false]) then {
			if( locked _vehicle > 1 ) then {
				["Cannot put away cargo ropes in locked vehicle",false] call ASL_Hint;
				_canPutAwayRopes = false;
			};
		};
		
		if!(missionNamespace getVariable ["ASL_EXILE_SAFEZONE_ENABLED",false]) then {
			if(!isNil "ExilePlayerInSafezone") then {
				if( ExilePlayerInSafezone ) then {
					["Cannot put away cargo ropes in safe zone",false] call ASL_Hint;
					_canPutAwayRopes = false;
				};
			};
		};
	
		if(_canPutAwayRopes) then {
			[_vehicle,player] call ASL_Put_Away_Ropes;
		};
		
	};
};

ASL_Put_Away_Ropes_Action_Check = {
	[cursorTarget] call ASL_Can_Put_Away_Ropes;
};

ASL_Can_Put_Away_Ropes = {
	params ["_vehicle"];
	private ["_existingRopes"];
	if([_vehicle] call ASL_Is_Supported_Vehicle) then {
		_existingRopes = _vehicle getVariable ["ASL_Ropes",[]];
		vehicle player == player && player distance _vehicle < 10 && (count _existingRopes) > 0;
	} else {
		false;
	};
};

ASL_Get_Corner_Points = {
	params ["_vehicle"];
	private ["_centerOfMass","_bbr","_p1","_p2","_rearCorner","_rearCorner2","_frontCorner","_frontCorner2"];
	private ["_maxWidth","_widthOffset","_maxLength","_lengthOffset","_widthFactor","_lengthFactor","_maxHeight","_heightOffset"];
	
	// Correct width and length factor for air
	_widthFactor = 0.5;
	_lengthFactor = 0.5;
	if(_vehicle isKindOf "Air") then {
		_widthFactor = 0.3;
	};
	if(_vehicle isKindOf "Helicopter") then {
		_widthFactor = 0.2;
		_lengthFactor = 0.45;
	};
	
	_centerOfMass = getCenterOfMass _vehicle;
	_bbr = boundingBoxReal _vehicle;
	_p1 = _bbr select 0;
	_p2 = _bbr select 1;
	_maxWidth = abs ((_p2 select 0) - (_p1 select 0));
	_widthOffset = ((_maxWidth / 2) - abs ( _centerOfMass select 0 )) * _widthFactor;
	_maxLength = abs ((_p2 select 1) - (_p1 select 1));
	_lengthOffset = ((_maxLength / 2) - abs (_centerOfMass select 1 )) * _lengthFactor;
	_maxHeight = abs ((_p2 select 2) - (_p1 select 2));
	_heightOffset = _maxHeight/6;
	
	_rearCorner = [(_centerOfMass select 0) + _widthOffset, (_centerOfMass select 1) - _lengthOffset, (_centerOfMass select 2)+_heightOffset];
	_rearCorner2 = [(_centerOfMass select 0) - _widthOffset, (_centerOfMass select 1) - _lengthOffset, (_centerOfMass select 2)+_heightOffset];
	_frontCorner = [(_centerOfMass select 0) + _widthOffset, (_centerOfMass select 1) + _lengthOffset, (_centerOfMass select 2)+_heightOffset];
	_frontCorner2 = [(_centerOfMass select 0) - _widthOffset, (_centerOfMass select 1) + _lengthOffset, (_centerOfMass select 2)+_heightOffset];
	
	[_rearCorner,_rearCorner2,_frontCorner,_frontCorner2];
};


ASL_Attach_Ropes = {
	params ["_cargo","_player"];
	_vehicle = _player getVariable ["ASL_Ropes_Vehicle", objNull];
	if(!isNull _vehicle) then {
		if(local _vehicle) then {
			private ["_ropes","_attachmentPoints","_objDistance","_ropeLength"];
			_ropes = _vehicle getVariable ["ASL_Ropes",[]];
			if(count _ropes == 4) then {
				_attachmentPoints = [_cargo] call ASL_Get_Corner_Points;
				_ropeLength = (ropeLength (_ropes select 0));
				_objDistance = (_cargo distance _vehicle) + 2;
				if( _objDistance > _ropeLength ) then {
					[["The cargo ropes are too short. Move vehicle closer.", false],"ASL_Hint",_player] call ASL_RemoteExec;
				} else {		
					[_vehicle,_player] call ASL_Drop_Ropes;
					[_cargo, _attachmentPoints select 0, [0,0,-1]] ropeAttachTo (_ropes select 0);
					[_cargo, _attachmentPoints select 1, [0,0,-1]] ropeAttachTo (_ropes select 1);
					[_cargo, _attachmentPoints select 2, [0,0,-1]] ropeAttachTo (_ropes select 2);
					[_cargo, _attachmentPoints select 3, [0,0,-1]] ropeAttachTo (_ropes select 3);
					if(missionNamespace getVariable ["ASL_HEAVY_LIFTING_ENABLED",true]) then {
						[_cargo, _vehicle, _ropes] spawn ASL_Rope_Adjust_Mass;		
					};				
				};
			};
		} else {
			[_this,"ASL_Attach_Ropes",_vehicle,true] call ASL_RemoteExec;
		};
	};
};

ASL_Attach_Ropes_Action = {
	private ["_vehicle","_cargo","_canBeAttached"];
	_cargo = cursorTarget;
	_vehicle = player getVariable ["ASL_Ropes_Vehicle", objNull];
	if([_vehicle,_cargo] call ASL_Can_Attach_Ropes) then {
		
		_canBeAttached = true;
		
		if!(missionNamespace getVariable ["ASL_LOCKED_VEHICLES_ENABLED",false]) then {
			if( locked _cargo > 1 ) then {
				["Cannot attach cargo ropes to locked vehicle",false] call ASL_Hint;
				_canBeAttached = false;
			};
		};
		
		if!(missionNamespace getVariable ["ASL_EXILE_SAFEZONE_ENABLED",false]) then {
			if(!isNil "ExilePlayerInSafezone") then {
				if( ExilePlayerInSafezone ) then {
					["Cannot attach cargo ropes in safe zone",false] call ASL_Hint;
					_canBeAttached = false;
				};
			};
		};
	
		if(_canBeAttached) then {
			[_cargo,player] call ASL_Attach_Ropes;
		};
		
	};
};

ASL_Attach_Ropes_Action_Check = {
	private ["_vehicle","_cargo"];
	_vehicle = player getVariable ["ASL_Ropes_Vehicle", objNull];
	_cargo = cursorTarget;
	[_vehicle,_cargo] call ASL_Can_Attach_Ropes;
};

ASL_Can_Attach_Ropes = {
	params ["_vehicle","_cargo"];
	if(!isNull _vehicle && !isNull _cargo) then {
		[_vehicle,_cargo] call ASL_Is_Supported_Cargo && vehicle player == player && player distance _cargo < 10 && _vehicle != _cargo;
	} else {
		false;
	};
};


ASL_Drop_Ropes = {
	params ["_vehicle","_player"];
	if(local _vehicle) then {
		private ["_helper"];
		_helper = (_player getVariable ["ASL_Ropes_Pick_Up_Helper", objNull]);
		if(!isNull _helper) then {
			{
				_helper ropeDetach _x;
			} forEach (_vehicle getVariable ["ASL_Ropes",[]]);
			detach _helper;
			deleteVehicle _helper;
		};
		_player setVariable ["ASL_Ropes_Vehicle", nil,true];
		_player setVariable ["ASL_Ropes_Pick_Up_Helper", nil,true];
	} else {
		[_this,"ASL_Drop_Ropes",_vehicle,true] call ASL_RemoteExec;
	};
};

ASL_Drop_Ropes_Action = {
	private ["_vehicle"];
	_vehicle = player getVariable ["ASL_Ropes_Vehicle", objNull];
	if([] call ASL_Can_Drop_Ropes) then {
		[_vehicle, player] call ASL_Drop_Ropes;
	};
};

ASL_Drop_Ropes_Action_Check = {
	[] call ASL_Can_Drop_Ropes;
};

ASL_Can_Drop_Ropes = {
	!isNull (player getVariable ["ASL_Ropes_Vehicle", objNull]) && vehicle player == player;
};

ASL_Pickup_Ropes = {
	params ["_vehicle","_player"];
	if(local _vehicle) then {
		private ["_attachedObj","_helper"];
		{
			_attachedObj = _x;
			{
				_attachedObj ropeDetach _x;
			} forEach (_vehicle getVariable ["ASL_Ropes",[]]);
		} forEach ropeAttachedObjects _vehicle;
		_helper = "Land_Can_V2_F" createVehicle position _player;
		{
			[_helper, [0, 0, 0], [0,0,-1]] ropeAttachTo _x;
			_helper attachTo [_player, [-0.1, 0.1, 0.15], "Pelvis"];
		} forEach (_vehicle getVariable ["ASL_Ropes",[]]);
		hideObject _helper;
		[[_helper],"ASL_Hide_Object_Global"] call ASL_RemoteExecServer;
		_player setVariable ["ASL_Ropes_Vehicle", _vehicle,true];
		_player setVariable ["ASL_Ropes_Pick_Up_Helper", _helper,true];
	} else {
		[_this,"ASL_Pickup_Ropes",_vehicle,true] call ASL_RemoteExec;
	};
};

ASL_Pickup_Ropes_Action = {
	private ["_nearbyVehicles","_canPickupRopes","_vehicle"];
	_nearbyVehicles = missionNamespace getVariable ["ASL_Nearby_Vehicles",[]];
	if([] call ASL_Can_Pickup_Ropes) then {
	
		_vehicle = _nearbyVehicles select 0;
		_canPickupRopes = true;
		
		if!(missionNamespace getVariable ["ASL_LOCKED_VEHICLES_ENABLED",false]) then {
			if( locked _vehicle > 1 ) then {
				["Cannot pick up cargo ropes from locked vehicle",false] call ASL_Hint;
				_canPickupRopes = false;
			};
		};
		
		if!(missionNamespace getVariable ["ASL_EXILE_SAFEZONE_ENABLED",false]) then {
			if(!isNil "ExilePlayerInSafezone") then {
				if( ExilePlayerInSafezone ) then {
					["Cannot pick up cargo ropes in safe zone",false] call ASL_Hint;
					_canPickupRopes = false;
				};
			};
		};
	
		if(_canPickupRopes) then {
			[_nearbyVehicles select 0, player] call ASL_Pickup_Ropes;
		};
	
	};
};

ASL_Pickup_Ropes_Action_Check = {
	[] call ASL_Can_Pickup_Ropes;
};

ASL_Can_Pickup_Ropes = {
	isNull (player getVariable ["ASL_Ropes_Vehicle", objNull]) && count (missionNamespace getVariable ["ASL_Nearby_Vehicles",[]]) > 0 && vehicle player == player;
};

ASL_SUPPORTED_VEHICLES = [
	"Helicopter"
];

ASL_Is_Supported_Vehicle = {
	params ["_vehicle","_isSupported"];
	_isSupported = false;
	if(not isNull _vehicle) then {
		{
			if(_vehicle isKindOf _x) then {
				_isSupported = true;
			};
		} forEach (missionNamespace getVariable ["ASL_SUPPORTED_VEHICLES_OVERRIDE",ASL_SUPPORTED_VEHICLES]);
	};
	_isSupported;
};

ASL_SLING_RULES = [
	["Helicopter","CAN_SLING","All"]
];

ASL_Is_Supported_Cargo = {
	params ["_vehicle","_cargo"];
	private ["_canSling"];
	_canSling = false;
	if(not isNull _vehicle && not isNull _cargo) then {
		{
			if(_vehicle isKindOf (_x select 0)) then {
				if(_cargo isKindOf (_x select 2)) then {
					if( (toUpper (_x select 1)) == "CAN_SLING" ) then {
						_canSling = true;
					} else {
						_canSling = false;
					};
				};
			};
		} forEach (missionNamespace getVariable ["ASL_SLING_RULES_OVERRIDE",ASL_SLING_RULES]);
	};
	_canSling;
};

ASL_Hint = {
    params ["_msg",["_isSuccess",true]];
    if(!isNil "ExileClient_gui_notification_event_addNotification") then {
		if(_isSuccess) then {
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
	if( _obj isKindOf "Land_Can_V2_F" ) then {
		hideObjectGlobal _obj;
	};
};

ASL_Find_Nearby_Vehicles = {
	private ["_nearVehicles","_nearVehiclesWithRopes","_vehicle","_ends","_end1","_end2"];
	_nearVehicles = [];
	{
		_nearVehicles append  (position player nearObjects [_x, 30]);
	} forEach (missionNamespace getVariable ["ASL_SUPPORTED_VEHICLES_OVERRIDE",ASL_SUPPORTED_VEHICLES]);
	_nearVehiclesWithRopes = [];
	{
		_vehicle = _x;
		{
			_ends = ropeEndPosition _x;
			if(count _ends == 2) then {
				_end1 = _ends select 0;
				_end2 = _ends select 1;
				if(((position player) distance _end1) < 5 || ((position player) distance _end2) < 5 ) then {
					_nearVehiclesWithRopes pushBack _vehicle;
				}
			};
		} forEach (_vehicle getVariable ["ASL_Ropes",[]]);
	} forEach _nearVehicles;
	_nearVehiclesWithRopes;
};

ASL_Add_Player_Actions = {

	player addAction ["Extend Cargo Ropes", { 
		[] call ASL_Extend_Ropes_Action;
	}, nil, 0, false, true, "", "call ASL_Extend_Ropes_Action_Check"];
	
	player addAction ["Shorten Cargo Ropes", { 
		[] call ASL_Shorten_Ropes_Action;
	}, nil, 0, false, true, "", "call ASL_Shorten_Ropes_Action_Check"];
		
	player addAction ["Release Cargo", { 
		[] call ASL_Release_Cargo_Action;
	}, nil, 0, false, true, "", "call ASL_Release_Cargo_Action_Check"];
		
	player addAction ["Retract Cargo Ropes", { 
		[] call ASL_Retract_Ropes_Action;
	}, nil, 0, false, true, "", "call ASL_Retract_Ropes_Action_Check"];
	
	player addAction ["Deploy Cargo Ropes", { 
		[] call ASL_Deploy_Ropes_Action;
	}, nil, 0, false, true, "", "call ASL_Deploy_Ropes_Action_Check"];

	player addAction ["Put Away Cargo Ropes", { 
		[] call ASL_Put_Away_Ropes_Action;
	}, nil, 0, false, true, "", "call ASL_Put_Away_Ropes_Action_Check"];

	player addAction ["Attach To Cargo Ropes", { 
		[] call ASL_Attach_Ropes_Action;
	}, nil, 0, false, true, "", "call ASL_Attach_Ropes_Action_Check"];

	player addAction ["Drop Cargo Ropes", { 
		[] call ASL_Drop_Ropes_Action;
	}, nil, 0, false, true, "", "call ASL_Drop_Ropes_Action_Check"];

	player addAction ["Pickup Cargo Ropes", { 
		[] call ASL_Pickup_Ropes_Action;
	}, nil, 0, false, true, "", "call ASL_Pickup_Ropes_Action_Check"];

	player addEventHandler ["Respawn", {
		player setVariable ["ASL_Actions_Loaded",false];
	}];
	
};

if(!isDedicated) then {
	[] spawn {
		while {true} do {
			if(!isNull player && isPlayer player) then {
				if!( player getVariable ["ASL_Actions_Loaded",false] ) then {
					[] call ASL_Add_Player_Actions;
					player setVariable ["ASL_Actions_Loaded",true];
				};
			};
			missionNamespace setVariable ["ASL_Nearby_Vehicles", (call ASL_Find_Nearby_Vehicles)];
			sleep 2;
		};
	};
};

ASL_RemoteExec = {
	params ["_params","_functionName","_target",["_isCall",false]];
	if(!isNil "ExileClient_system_network_send") then {
		["AdvancedSlingLoadingRemoteExecClient",[_params,_functionName,_target,_isCall]] call ExileClient_system_network_send;
	} else {
		if(_isCall) then {
			_params remoteExecCall [_functionName, _target];
		} else {
			_params remoteExec [_functionName, _target];
		};
	};
};

ASL_RemoteExecServer = {
	params ["_params","_functionName",["_isCall",false]];
	if(!isNil "ExileClient_system_network_send") then {
		["AdvancedSlingLoadingRemoteExecServer",[_params,_functionName,_isCall]] call ExileClient_system_network_send;
	} else {
		if(_isCall) then {
			_params remoteExecCall [_functionName, 2];
		} else {
			_params remoteExec [_functionName, 2];
		};
	};
};

if(isServer) then {
	
	// Adds support for exile network calls (Only used when running exile) //
	
	ASL_SUPPORTED_REMOTEEXECSERVER_FUNCTIONS = ["ASL_Hide_Object_Global"];

	ExileServer_AdvancedSlingLoading_network_AdvancedSlingLoadingRemoteExecServer = {
		params ["_sessionId", "_messageParameters",["_isCall",false]];
		_messageParameters params ["_params","_functionName"];
		if(_functionName in ASL_SUPPORTED_REMOTEEXECSERVER_FUNCTIONS) then {
			if(_isCall) then {
				_params call (missionNamespace getVariable [_functionName,{}]);
			} else {
				_params spawn (missionNamespace getVariable [_functionName,{}]);
			};
		};
	};
	
	ASL_SUPPORTED_REMOTEEXECCLIENT_FUNCTIONS = ["ASL_Extend_Ropes","ASL_Shorten_Ropes","ASL_Release_Cargo","ASL_Retract_Ropes","ASL_Deploy_Ropes","ASL_Put_Away_Ropes","ASL_Hint","ASL_Attach_Ropes","ASL_Drop_Ropes"];
	
	ExileServer_AdvancedSlingLoading_network_AdvancedSlingLoadingRemoteExecClient = {
		params ["_sessionId", "_messageParameters"];
		_messageParameters params ["_params","_functionName","_target",["_isCall",false]];
		if(_functionName in ASL_SUPPORTED_REMOTEEXECCLIENT_FUNCTIONS) then {
			if(_isCall) then {
				_params remoteExecCall [_functionName, _target];
			} else {
				_params remoteExec [_functionName, _target];
			};
		};
	};

	// Install Advanced Sling Loading on all clients (plus JIP) //
	
	publicVariable "ASL_Advanced_Sling_Loading_Install";
	remoteExecCall ["ASL_Advanced_Sling_Loading_Install", -2,true];
	
};

diag_log "Advanced Sling Loading Loaded";

};

if(isServer) then {
	[] call ASL_Advanced_Sling_Loading_Install;
};

