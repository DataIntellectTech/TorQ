/ - system eodtime configuartion
/ - loaded into and used in the tp and pdb processes
\d .eodtime
rolltime:@[value;`rolltime;0D00:00:00.000];
datatimezone:@[value;`datatimezone;`$"GMT"];
rolltimezone:@[value;`rolltimezone;`$"GMT"];
dayoffset:@[value;`dayoffset;0];
getdailyadjustment:{first exec adjustment from aj[`timezoneID`gmtDateTime;([]timezoneID:enlist .eodtime.datatimezone;gmtDateTime:enlist .z.p); .tz.t]};
dailyadj:getdailyadjustment[];
adjrolltime:{[p] 
     z:rolltime - first exec adjustment from aj[`timezoneID`gmtDateTime;([]timezoneID:enlist .eodtime.rolltimezone;gmtDateTime:enlist p); .tz.t];  
     z:$[z >= 1D;z - 1D;z]			// don't let it go past one day
     }
getroll:{[p] 
     z:adjrolltime[p];
     ("d"$p) + $[z <= p;z+1D;z]			// if past time already today, make it tomorrow
     }
getday:{[p] 
     z:adjrolltime[p];
     ("d"$p) + dayoffset+$[z > p;-1;0]		// if not past roll time, subtract one day
     }
d:getday[.z.p];
nextroll:getroll[.z.p];
