/ - system eodtime configuraion
/ - loaded into and used in the tp and pdb processes
\d .eodtime

// default settings
rolltimeoffset:@[value;`rolltimeoffset;0D00:00:00.000];     // offset from standard midnight rollover
datatimezone:@[value;`datatimezone;`$"GMT"];                // timezone for stamping data
rolltimezone:@[value;`rolltimezone;`$"GMT"];                // timezone for EOD roll

// function to determine offset from UTC for timestamping data
getdailyadjustment:{exec adjustment from .tz.t asof `timezoneID`gmtDateTime!(.eodtime.datatimezone;.z.p)};

dailyadj:getdailyadjustment[];                              // get offset when loading process and store it in dailyadj

// function to determine offset from UTC for EOD roll
adjtime:{[p]
     :exec adjustment from .tz.t asof `timezoneID`gmtDateTime!(.eodtime.rolltimezone;.z.p);
     };

// function to get time (in UTC) of next roll after UTC timestamp, p
getroll:{[p]
     z:rolltimeoffset-adjtime[p];                           // convert rolltimeoffset from rolltimezone to UTC
     z:`timespan$(mod) . "j"$z, 1D;                         // force time adjust to be between 0D and 1D
     ("d"$p) + $[z <= p;z+1D;z]                             // if past time already today, make it tomorrow
     };

// function to determine the date (in rolltimezone) from UTC timestamp, p
getday:{[p]
     p+:adjtime[p];                                         // convert date from UTC to rolltimezone
     "d"$p-rolltimeoffset                                   // adjust day according to rolltimeoffset
     };

d:getday[.z.p];                                             // get current date when loading process, store in d
nextroll:getroll[.z.p];                                     // get next roll when loading process, store in nextroll
