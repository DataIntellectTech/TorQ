/ - system eodtime configuartion
/ - loaded into and used in the tp and pdb processes
\d .eodtime
rolltime:@[value;`rolltime;0D18:00:00.000];
datatimezone:@[value;`datatimezone;`$"America/New_York"];
rolltimezone:@[value;`rolltimezone;`$"Europe/London"];
dayoffset:@[value;`dayoffset;1];
getdailyadjustment:{first exec adjustment from aj[`timezoneID`gmtDateTime;([]timezoneID:enlist .eodtime.datatimezone;gmtDateTime:enlist .z.p); .tz.t]};
dailyadj:getdailyadjustment[];
adjrolltime:{[p] 
     z:rolltime - first exec adjustment from aj[`timezoneID`gmtDateTime;([]timezoneID:enlist .eodtime.rolltimezone;gmtDateTime:enlist p); .tz.t];  
     z:$[z >= 1D;z - 1D;z]			// don't let it go past one day
     }
getroll:{[p;d] 
     z:adjrolltime[p];
     d + $[z <= p;z+1D;z]			// if past time already today, make it tomorrow
     }
getday:{[p;d] 
     z:adjrolltime[p];
     d+dayoffset+$[z > p;-1;0]			// if not past roll time, subtract one day
     }
d:getday[.z.p;.z.d];
nextroll:getroll[.z.p;.z.d];
