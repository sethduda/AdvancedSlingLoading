class CfgPatches {
	class SA_AdvancedSlingLoading {
		units[]				= {
			"SA_AdvancedSlingLoading"
		};
		requiredVersion		= 1;
		requiredAddons[]	= {
			"A3_Modules_F"
		};
	};
};
class CfgNetworkMessages {
	class AdvancedSlingLoadingRemoteExecClient {
		module			= "AdvancedSlingLoading";
		parameters[]	= {
			"ARRAY",
			"STRING",
			"OBJECT",
			"BOOL"
		};
	};
	class AdvancedSlingLoadingRemoteExecServer {
		module			= "AdvancedSlingLoading";
		parameters[]	= {
			"ARRAY",
			"STRING",
			"BOOL"
		};
	};
};
class CfgFunctions {
	class SA {
		class AdvancedSlingLoading {
			file = "\SA_AdvancedSlingLoading\functions";
			class advancedSlingLoadingInit {
				preInit = 1;
			};
		};
	};
};
class Extended_PreInit_EventHandlers {
	class SA {
		init = "call compile preprocessFileLineNumbers '\SA_AdvancedSlingLoading\scripts\XEH_preInit.sqf'";		// CBA_a3 integration
	};
};
class Extended_PostInit_EventHandlers {
	class SA {
		init = "call compile preprocessFileLineNumbers '\SA_AdvancedSlingLoading\scripts\XEH_postInit.sqf'";	// CBA key binding integration
	};
};
class CfgSounds {
	sounds[] = {};
	class SA_SlingLoadDownExt {
		sound[]		= {"A3\Sounds_F\vehicles\air\noises\SL_engineDownEXT", 1.2589254, 1, 500};					// filename, volume, pitch, distance (optional)
		titles[] 	= {};
		frequency	= 1;
		volume		= "camPos * (slingLoadActive factor [0, -1])";
	};
	class SA_SlingLoadUpExt {
		sound[]		= {"A3\Sounds_F\vehicles\air\noises\SL_engineUpEXT", 1.2589254, 1, 500};
		titles[] 	= {};
		frequency	= 1;
		volume		= "camPos * (slingLoadActive factor [0, 1])";
	};
	class SA_SlingLoadDownInt {
		sound[]		= {"A3\Sounds_F\vehicles\air\noises\SL_engineDownINT", 1, 1, 500};
		titles[] 	= {};
		frequency	= 1;
		volume		= "(1 - camPos) * (slingLoadActive factor [0, -1])";
	};
	class SA_SlingLoadUpInt {
		sound[]		= {"A3\Sounds_F\vehicles\air\noises\SL_engineUpINT", 1, 1, 500};
		titles[] 	= {};
		frequency	= 1;
		volume		= "(1 - camPos) * (slingLoadActive factor [0, 1])";
	};
};
