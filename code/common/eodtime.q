/ - system eodtime configuartion
/ - loaded into and used in the tp and pdb processes
\d .eodtime
rolltime:0D17:00:00.000000000;
datatimezone:`$"America/Chicago";
rolltimezone:`$"Europe/London";
dayoffset:1;
getdailyadjustment:{first exec adjustment from aj[`timezoneID`gmtDateTime;([]timezoneID:enlist .eodtime.datatimezone;gmtDateTime:enlist .z.p); .tz.t]};
dailyadj:getdailyadjustment[];
getroll:{[d] 
     z:rolltime - first exec adjustment from aj[`timezoneID`gmtDateTime;([]timezoneID:enlist .eodtime.rolltimezone;gmtDateTime:enlist .z.p); .tz.t];
     z:$[z >= 1D;z - 1D;z];		
     d + $[z <= .z.p;z+1D;z]			// if past time already today, make it tomorros
     }
nextroll:getroll[.z.D];
