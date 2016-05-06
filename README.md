# Advanced Sling Loading

SP & MP Compatible. Full replacement for in-game sling loading. Supports Exile.

**Features:**

 - Ropes can no longer attach automatically! You need to either get out of your helicopter or have someone on the ground pick up your cargo ropes and attach them to an object. 
 - Helicopters support up to 3 sets of cargo ropes, depending on the size of the heli.
 - Once cargo ropes are deployed, any player can go to the end of the rope and pick it up. 
 - Once the ropes are picked up by a player, they can be attached to pretty much every object in the game. 
 - Players can drop ropes if they're carrying them
 - Players on the ground can detached ropes from an object 
 - Helicopters can lift heavy vehicles 

**Installation:**

1. Subscrive via steam: http://steamcommunity.com/sharedfiles/filedetails/?id=615007497 or dowload latest release from https://github.com/sethduda/AdvancedSlingLoading/releases
2. If installing this on a server, add the addon to the -serverMod command line option

**Default Sling Loading Rules:**

- Helicopters can sling load all objects
- You can't sling load locked vehicles (see settings below) 
- You can't sling load in an exile safe zone (see settings below) 

**Notes for Mission Makers:**

You can customize which classes of objects can "deploy" cargo ropes by overriding the ASL_SUPPORTED_VEHICLES_OVERRIDE variable in an init.sqf file. 

```ASL_SUPPORTED_VEHICLES_OVERRIDE = [ "Air" ]; ```

This will only allow objects of class Air deploy cargo ropes.

You can customize what can and can't be sling loaded by defining the ASL_SLING_RULES_OVERRIDE variable in the init.sqf file. 

```ASL_SLING_RULES_OVERRIDE = 
[ ["Air", "CAN_SLING", "Ship"], 
["Air", "CANT_SLING", "Air"]
]; ```

In this example, all objects of class Air can sling load Ships but not Air. 

You can allow sling loading of locked vehicles by defining ASL_LOCKED_VEHICLES_ENABLED in your init.sqf file. It defaults to false. 

```ASL_LOCKED_VEHICLES_ENABLED = true; ```

You can allow sling loading in an Exile safe zone by defining ASL_EXILE_SAFEZONE_ENABLED in your init.sqf file. It default to false. 

```ASL_EXILE_SAFEZONE_ENABLED = true; ```

**Not working on your server?**

Make sure you have the mod listed in the -mod or -serverMod command line option. Only -serverMod is required for this addon. If still not working, check your server log to make sure the addon is found. 

**FAQ**

*This addon is only required on the server - is it going to slow down my server?*

No - while this addon is server-side only, it installs itself on all clients without them downloading the addon. Most of the time, the towing code actually runs client-side, even though you installed the addon only on the server. Magic! 

*Battleye kicks me when I try to do xyz. What do I do?*

You need to configure Battleye rules on your server. Below are the files you need to configure: 

setvariable.txt 

Add the following exclusions to the end of all lines starting with 4, 5, 6, or 7 if they contain "" (meaning applies to all values): 

!="ASL_Ropes" !="ASL_Ropes_Vehicle" !="ASL_Ropes_Pick_Up_Helper" !="ASL_Cargo"

setvariableval.txt 

If you have any lines starting with 4, 5, 6, or 7 and they contain "" (meaning applies to all values) it's not going to work. Either remove the line or explicitly define the values you want to kick. Since the values of the variables above can vary, I don't know of a good way to define an exclusion rule. 

Also, it's possible there are other battleye filter files that can cause issues. If you check your battleye logs you can figure out which file is causing a problem.

*The sling actions appear when looking at a vehicle, but do nothing when I select them. How do I fix that?*

Most likely your server is setup with a white list for remote executions. In order to fix this, you need to modify your mission's description.ext file, adding the following CfgRemoteExec rules. If using InfiStar you should edit your cfgremoteexec.hpp instead of the description.ext file. See https://community.bistudio.com/wiki/Arma_3_Remote_Execution for more details on CfgRemoteExec.

```
class CfgRemoteExec
{
	class Functions
	{
		class ASL_Extend_Ropes	{ allowedTargets=0; }; 
		class ASL_Shorten_Ropes	{ allowedTargets=0; }; 
		class ASL_Release_Cargo		{ allowedTargets=0; }; 
		class ASL_Retract_Ropes	{ allowedTargets=0; }; 
		class ASL_Deploy_Ropes	{ allowedTargets=0; }; 
		class ASL_Attach_Ropes		{ allowedTargets=0; }; 
		class ASL_Drop_Ropes		{ allowedTargets=0; }; 
		class ASL_Hint			{ allowedTargets=1; }; 
		class ASL_Hide_Object_Global	{ allowedTargets=2; }; 
	};
};
```

**Issues & Feature Requests**

https://github.com/sethduda/AdvancedSlingLoading/issues 

If anyone wants to help fix any of these, please let me know. You can fork the repo and create a pull request. 

**Special Thanks for Testing & Support:**

- Stay Alive Tactical Team (http://sa.clanservers.com) 

---

The MIT License (MIT)

Copyright (c) 2016 Seth Duda

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
