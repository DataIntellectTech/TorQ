// minor customisation of controlaccess.q from code.kx
// http://code.kx.com/wsvn/code/contrib/simon/dotz/
// main change is that the set up (users, hosts and functions) are loaded from csv files
// also want to throw an error and have it as an error in the io log rather than a separate log file

/ control external (.z.p*) access to  a kdb+ session, log access errors to file
/ use <loadinvalidaccess.q> to load and display table INVALIDACCESS
/ setting .access.HOSTPATTERNS - list of allowed hoststring patterns (";"vs ...)
/ setting .access.USERTOKENS/POWERUSERTOKENS - list of allowed k tokens (use -5!)
/ adding rows to .access.USERS for .z.u matches
/ ordinary user would normally only be able to run canned queries
/ poweruser can run canned queries and some sql commands
/ superuser can do anything

\d .access

// Check if the process has been initialised correctly
if[not @[value;`.proc.loaded;0b]; '"environment is not initialised correctly to load this script"]

MAXSIZE:@[value;`MAXSIZE;200000000]	// the maximum size of any returned result set
enabled:@[value;`enabled;0b]		// whether permissions are enabled
openonly:@[value;`openonly;0b]		// only check permissions when the connection is made, not on every call

USERS:([u:`symbol$()]poweruser:`boolean$();superuser:`boolean$())
adduser:{[u;pu;su]USERS,:(u;pu;su);}
addsuperuser:adduser[;0b;1b];addpoweruser:adduser[;1b;0b];adddefaultuser:adduser[;0b;0b]
deleteusers:{delete from`.access.USERS where u in x;}

// Read in the various files
readhostfile:{
	.lg.o[`access;"reading host file ",x];
	1!("*B";enlist",")0:hsym `$x
	}

// Read in the default users file
readuserfile:{
        .lg.o[`access;"reading user file ",x];
        1!("SBBB";enlist",")0:hsym `$x
	}

// Read in the default functions file
readfunctionfile:{
        .lg.o[`access;"reading function file ",x];
        res:("*BB*";enlist",")0:hsym `$x;
	res:update func:{@[value;x;{.lg.e[`access;"failed to parse ",x," : ",y];`}[x]]} each func from res;
	// parse out the user list
	1!update userlist:`$";"vs'userlist from res
	}

// Read in each of the files and set up the permissions
// if {procname}_*.csv is found, we will use that
// otherwise {proctype}_*.csv
// otherwise default_*.csv
readpermissions:{[dir]
	.lg.o[`access;"reading permissions from ",dir];
	// Check the directory exists
	if[()~f:key hsym `$dir; .lg.e[`access;"permissions directory ",dir," doesn't exist"]];

	// Read in the permissions
	files:{poss:`$(string (`default;.proc.proctype;.proc.procname)),\:y;
	 poss:poss where poss in x;
	 if[0=count poss; .lg.e[`access;"failed to find appropriate ",y," file. At least default",y," should be supplied"]];
	 poss}[key hsym `$dir] each ("_hosts.csv";"_users.csv";"_functions.csv");

	// only need to clear out the users - everything else is reset
	.lg.o[`access;"clearing out old permissions"];
        delete from `.access.USERS;

	// Load up each one
	hosts::raze readhostfile each (dir,"/"),/:string files 0;
	users::raze readuserfile each (dir,"/"),/:string files 1;
	funcs::raze readfunctionfile each (dir,"/"),/: string files 2;

	HOSTPATTERNS::exec host from hosts where allowed;
	addsuperuser each exec distinct user from users where superuser;
	addpoweruser each exec distinct user from users where not superuser,poweruser;
	adddefaultuser each exec distinct user from users where not superuser,not poweruser,defaultuser;
	USERTOKENS::asc distinct exec func from funcs where default;
        POWERUSERTOKENS::asc distinct exec func from funcs where default or power;
        // build a dictionary of specific functions for specific users
        BESPOKETOKENS::exec asc distinct func by userlist from ungroup select func,userlist from funcs where not userlist~\:enlist`;
	}

likeany:{0b{$[x;x;y like z]}[;x;]/y}

loginvalid:{[ok;zcmd;cmd] if[not ok;H enlist(`LOADINVALIDACCESS;`INVALIDACCESS;(.z.i;.proc.cp[];zcmd;.z.a;.z.w;.z.u;.dotz.txtC[zcmd;cmd]))];ok}
validuser:{[zu;pu;su]$[su;exec any(`,zu)in u from USERS where superuser;$[pu;exec any(`,zu)in u from USERS where poweruser or superuser;exec any(`,zu)in u from USERS]]}
superuser:validuser[;0b;1b];poweruser:validuser[;1b;0b];defaultuser:validuser[;0b;0b]
validhost:{[za] $[likeany[.dotz.ipa za;HOSTPATTERNS];1b;likeany["."sv string"i"$0x0 vs za;HOSTPATTERNS]]}
validsize:{[x;y;z] $[superuser .z.u;x;MAXSIZE>s:-22!x;x;'"result size of ",(string s)," exceeds MAXSIZE value of ",string MAXSIZE]}

cmdpt:{$[10h=type x;.q.parse x;x]}
cmdtokens:{
	// return a list from nested lists
	raze(raze each)over{
		// check if the argument is a list or mixed list
		$[(0h<=type x) & 1<count x;
			// check if the first element of the argument is a string or
			// has one element but is not a mixed list
			$[(10h = type fx) | (not 0h=type fx) & 1=count fx:first x;
				// return the first element and convert any character types to sym type
				{[x] $[(type x) in -10 10h;`$x;x]} fx;
				// apply this function interatively into nested lists where the type is a mixed list or list of symbols
				],.z.s each x where (type each x) in 0 11h;
			]
		}x
	}
	
usertokens:{$[superuser x;0#`;$[poweruser x;POWERUSERTOKENS;$[defaultuser x;USERTOKENS;'`access]]],BESPOKETOKENS[x]}
validpt:{all(cmdtokens x)in y}
validcmd:{[u;cmd] $[superuser u;1b;validpt[cmdpt cmd;usertokens u]]}

invalidpt:{'"invalid parse token(s):",raze" ",'string distinct(cmdtokens cmdpt x)except usertokens .z.u}

vpw:{[x;y] $[defaultuser x;validhost .z.a;0b]}
vpg:{validcmd[.z.u;x]}
/ vps:{$[0=.z.w;1b;poweruser .z.u;validcmd[.z.u;x];0b]}
vps:{$[0=.z.w;1b;validcmd[.z.u;x]]}
vpi:{$[0=.z.w;1b;superuser .z.u]}
vph:{superuser .z.u}
vpp:{superuser .z.u}
vws:{defaultuser .z.u} / not clear what/how to restrict yet

\d .

.lg.o[`access;"access controls are ",("disabled";"enabled").access.enabled]
if[.access.enabled;
	// Read in the permissions
	.access.readpermissions each string reverse .proc.getconfig["permissions";1];
	.z.pw:{$[.access.vpw[y;z];x[y;z];0b]}.z.pw;
	/ .z.po - untouched, .z.pw does the checking
	/ .z.pc - untouched, close is always allowed
	/ .z.pg:{$[.access.vpg[y];x y;.access.invalidpt y]}.z.pg;
	if[not .access.openonly;
		.z.pg:{$[.access.vpg[y];.access.validsize[;`pg.size;y]x y;.access.invalidpt y]}.z.pg;
		.z.ps:{$[.access.vps[y];x y;.access.invalidpt y]}.z.ps;
		.z.ws:{$[.access.vws[y];x y;.access.invalidpt y]}.z.ws;
		.z.pi:{$[.access.vpi[y];x y;.access.invalidpt y]}.z.pi;
		.z.ph:{$[.access.vph[y];x y;.h.hn["403 Forbidden";`txt;"Forbidden"]]}.z.ph;
		.z.pp:{$[.access.vpp[y];x y;.h.hn["403 Forbidden";`txt;"Forbidden"]]}.z.pp]];
\
note that you can put global restrictions on the amount of memory used, and
the maximum time a single interaction can take by setting command line parameters:
-T NNN (where NNN seconds is the maximum duration) - q will signal 'stop
-w NNN (where NNN MB is the maximum memory) - q will *EXIT* with wsfull
could use .z.po+.z.pc to track clients (.z.a+u+w, .z.z + active) - simplest is to use trackclients.q directly
