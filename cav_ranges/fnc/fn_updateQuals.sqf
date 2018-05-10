/* ----------------------------------------------------------------------------
Function: CAV_Ranges_fnc_stopRange

Description:
	Stops the sequence for a popup target range.
	Used for both normal and premature end of the sequence.
	
	Not used for spawn ranges.

Parameters:
	Args - Array of standard range data:
		Type - Sets mode of operation for the range [String, ["targets","spawn"]]
		Title - String representation of the range [String]
		Tag - Internal prefix used for the range, so it can find range objects [String]
		Lane Count - How many lanes there are [Integer]
		Target Count - Number of targets per range [Integer]
		Sequence - List of events when the range is started [Array of Arrays of [event, delay]]
		Grouping - target groupings [Array of Arrays of Numbers]
		Qualitification Tiers - number of targets to attain each qual [Array of Integers]
	Show No Go - Whether to set the flag to -1 if below no go threshold
		(So that AT range doesn't just show no go all the time)

Returns: 
	Nothing

Locality:
	Server

Examples:
    [
		"targets", 	//	"targets" : pop up targets, terc animation is used
					//	"spawn"   : spawned units, targets being alive/dead is used
		"Pistol Range",	// Title
		"r1",			// Tag
		1,				// Lane count
		10,				// Targets per lane
		[				
										// Range sequence
											// First element defines the type of event:
											//		ARRAY: target(s)/group(s) to raise. Multiple elements for multiple targets/groups
											//		STRING: Message to show on the lane UI. Third element is not used in this case
											// Second element: seconds length/delay for that event
											// Third element (optional): delay between end of this event and start of the next, default 2 if not present
			["Load a magazine.",5], 	//show message for 5 seconds
			["Range is hot!",3],
			[[1],5], 					// raise first target for 5 seconds
			[[3],5],
			[[7],2],
			[[4],2],
			[[9],5],
			["Reload.",5],
			["Range is hot!",3],
			[[2,7],8], 					// raise targets 2 and 7 for 5 seconds
			[[1,10],8],
			[[7,4],5],
			[[6,2],5],
			[[7,10],5],
			["Safe your weapon.",3],
			["Range complete.",0]
		],
		nil,							// target grouping, nil to disable grouping, otherwise group as define nested arrays: [[0,1],[2,3]] etc
										//     a particular target can be in multiple groups
		[13,11,9]						// qualification tiers, [expert, sharpshooter, marksman], nil to disable qualifications altogether
										//     values below the last element will show no go
										//     Not all three are required, [35] would simply return expert above 35, and no go below that
	] spawn CAV_Ranges_fnc_stopRange;

Author:
	=7Cav=WO1.Raynor.D

---------------------------------------------------------------------------- */

#include "..\script_macros.hpp"

_this params ["_args",["_showNoGo",true]];

_args DEF_RANGE_PARAMS;

LOG_1("GetQual: %1",_this);

_objectCtrl = GET_ROBJ(_rangeTag,"ctrl");
if(isNull _objectCtrl) exitWith {ERROR_2("Range control object (%1) is null: %2", format ["%1_ctrl",_rangeTag], _this)};

_rangeTargets = GET_VAR(_objectCtrl,GVAR(rangeTargets));
if(isNil "_rangeTargets") exitWith {NIL_ERROR(_rangeTargets)};

_rangeScores = GET_VAR(_objectCtrl,GVAR(rangeScores));
if(isNil "_rangeScores") exitWith {NIL_ERROR(_rangeScores)};

// return qualification tier, need to make this scalable
_rangeScoreQuals = [];
{
	if((count _rangeScores) > _forEachIndex) then {
		_score = _rangeScores select _forEachIndex;
		if(!isNil "_score") then {	
			_qual = -1;
			if(count _qualTiers >= 1) then {
				if(_score >= _qualTiers select 0) then {
					_qual = 0;
				} else {
					if(count _qualTiers >= 2) then {
						if(_score >= _qualTiers select 1) then {
							_qual = 1;
						} else {
							if(count _qualTiers >= 3) then {
								if(_score >= _qualTiers select 2) then {
									_qual = 2;
								};
							};
						};
					};
				};
			};
			
			if(!(_qual == -1 && !_showNoGo)) then {
				_rangeScoreQuals set [_forEachIndex, _qual];
			};

		};
	};
} foreach _rangeTargets;

SET_VAR_G(_objectCtrl,GVAR(rangeScoreQuals),_rangeScoreQuals);
[_rangeTag, "qual"] remoteExec [QFUNC(updateUI),0];