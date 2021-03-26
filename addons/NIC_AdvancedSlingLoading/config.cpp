class CfgPatches {
	class SA_AdvancedSlingLoading {
		units[]				= {
			"SA_AdvancedSlingLoading",
			"ASL_RopeSmallWeight"
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
			// class ASLaddActions {
				// preInit = 1;
			// };
			class advancedSlingLoadingInit {
				// postInit = 1;
				preInit = 1;
			};
		};
	};
};
class Extended_PreInit_EventHandlers {
	class SA {
		init = "call compile preprocessFileLineNumbers '\SA_AdvancedSlingLoading\scripts\XEH_preInit.sqf'"; // CBA_a3 integration
	};
};
class CfgVehicles {
	class Land_Camping_Light_F;
	class ASL_RopeSmallWeight : Land_Camping_Light_F {
		scope		= 2;
		displayname = "Rope weight";
		model		= "\SA_AdvancedSlingLoading\ASL_weightSmall";
	};
};
class cfgMods {
	author		= "76561198131707990";
	timepacked	= "1473204282";
};
