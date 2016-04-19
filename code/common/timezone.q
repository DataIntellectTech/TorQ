// taken from http://code.kx.com/wiki/Cookbook/Timezones

\d .tz

default:@[value;`default;`$"Europe/London"]

// Load the timezone info from the config directory
t:@[get;hsym`$tzfile;{.lg.e[`init;"failed to load timezone table from ",x," ",y]}[tzfile:string first .proc.getconfigfile["tzinfo"]]]

// local from GMT
lg:{[tz;z] $[0>type z;first;(::)]@exec gmtDateTime+adjustment from aj[`timezoneID`gmtDateTime;([]timezoneID:tz;gmtDateTime:z,());select timezoneID,gmtDateTime,adjustment from t]};

// GMT from local
gl:{[tz;z] $[0>type z;first;(::)]@exec localDateTime-adjustment from aj[`timezoneID`localDateTime;([]timezoneID:tz;localDateTime:z,());select timezoneID,localDateTime,adjustment from t]};

// timezone switch
// d = destination time zone
// s = source timezone
// z = time
ttz:{[d;s;z]lg[d;gl[s;z]]}

// default from GMT
dg:lg[default]
// GMT from default
gd:gl[default]

\
\d .
/ To recreate tzinfo from tzinfo.csv
t:("SPJJ";enlist ",")0:`:tzinfo.csv;
update gmtOffset:`timespan$1000000000*gmtOffset,dstOffset:`timespan$1000000000*dstOffset from `t;
update adjustment:gmtOffset+dstOffset from `t;
update localDateTime:gmtDateTime+adjustment from `t;
`gmtDateTime xasc `t;
update `g#timezoneID from `t;
`:tzinfo set t; / save file for easy distribution
