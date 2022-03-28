//functionality loaded in by gateway
//functions include: getserverids, getserveridstype, getserverscross, buildcross, getservers

\d .gw

getserverids:{[att]
  if[99h<>type att;
   // its a list of servertypes e.g. `rdb`hdb
   // check if user attributes are a symbol list
   if[not 11h=abs type att;
     '" Servertype should be given as either a dictionary(type 99h) or a symbol list (11h)"
   ];
   servertype:distinct att,();
   //list of active servers
   activeservers:exec distinct servertype from .gw.servers where active;
   //list of all servers
   allservers:exec distinct servertype from .gw.servers;
   activeserversmsg:". Available servers include: ",", " sv string activeservers;
   //check if a null argument is passed
   if[any null att;'"A null server cannot be passed as an argument",activeserversmsg];
   //if any requested servers are missing then:
   //if requested server does not exist, return error with list of available servers
   //if requested server exists but is currently inactive, return error with list of available servers
   if[count servertype except activeservers;
    '"the following ",$[max not servertype in allservers;
     "are not valid servers: ",", " sv string servertype except allservers;
     "requested servers are currently inactive: ",", " sv string servertype except activeservers
    ],activeserversmsg;
   ];
   :(exec serverid by servertype from .gw.servers where active)[servertype];
  ];

  serverids:$[`servertype in key att;
    raze getserveridstype[delete servertype from att] each (),att`servertype;
    getserveridstype[att;`all]];

  if[all 0=count each serverids;'"no servers match requested attributes"];
  :serverids;
 }

getserveridstype:{[att;typ]
  // default values
  besteffort:1b;
  attype:`cross;

  servers:$[typ=`all;
    exec serverid!attributes from .gw.servers where active;
    exec serverid!attributes from .gw.servers where active,servertype=typ];

  if[`besteffort in key att;
    if[-1h=type att`besteffort;besteffort:att`besteffort];
    att:delete besteffort from att;
  ];
  if[`attributetype in key att;
    if[-11h=type att`attributetype;attype:att`attributetype];
    att:delete attributetype from att;
  ];

  res:$[attype=`independent;getserversindependent[att;servers;besteffort];
  getserverscross[att;servers;besteffort]];

  serverids:first value flip $[99h=type res; key res; res];
  if[all 0=count each serverids;'"no servers match ",string[typ]," requested attributes"];
  :serverids;
 }

/- build a cross product from a nested dictionary
buildcross:{(cross/){flip (enlist y)#x}[x] each key x}

/- given a dictionary of requirements and a list of attribute dictionaries
/- work out which servers we need to hit to satisfy each requirement
/- we want to satisfy the cross product of requirements - so each attribute has to be available with each other attribute
/- e.g. each symbol has to be availble within each specified date
getserverscross:{[req;att;besteffort]

 if[0=count req; :([]serverid:enlist key att)];

 s:getserversinitial[req;att];

 /- build the cross product of requirements
 reqcross:buildcross[req];

 /- calculate the cross product of data contributed by each source
 /- and drop it from the list of stuff that is required
 util:flip `remaining`found!flip ({[x;y;z] (y[0] except found; y[0] inter found:$[0=count y[0];y[0];buildcross x@'where each z])}[req]\)[(reqcross;());value s];

 /- check if everything is done
 if[(count last util`remaining) and not besteffort;
   '"getserverscross: cannot satisfy query as the cross product of all attributes can't be matched"];
 /- remove any rows which don't add value
 s:1!(0!s) w:where not 0=count each util`found;
 /- return the parameters which should be queried for
 (key s)!distinct each' flip each util[w]`found
 }

// Input a table of ([]tablename;starttime;endtime;instruments;procs)
// Or dict of `tablename`starttime`endtime`instruments`procs!(tablename;starttime;endtime;instruments;procs)
// Returns a dict of serverid(s) that should be queried to cover all that data
getservers:{[dict]
    // Check if input is a table, get the dict
    if[98h~type dict;
        if[1<count dict;.z.s each dict]; /use recursive calls for each dict(row)
        if[1=count dict;dict:first dict]]; 

    // Check required keys
    req:`tablename`starttime`endtime;
    if[not all req in k:key dict;
        '"Provide a dictionary with required keys: `tablename`starttime`endtime"];

    // Check if correct keys
    if[not all k in`tablename`starttime`endtime`instruments`procs;
        '"Provide a dictionary with keys of only: `tablename`starttime`endtime`instruments`procs"];

    // Checktype
    validtypes:`tablename`starttime`endtime`instruments`procs!(enlist -11h;t;t:-12 -14 -15h;s;s:-11 11h);
    {if[not(t:type y z)in x;
        'string[z]," input type incorrect - valid type(s):",(" "sv string x)," - input type:",string t]}[;dict]'[validtypes k;k];

    // Get the Procs in a (nested) list of serverid(s)
    dict[`procs]:attributesrouting[dict;part:partdict dict];

    // Adjust queries based on relevant data and stripe
    d:adjustqueriesoverlap[dict;part];
    servers:adjustqueriesstripe[dict;d];
	:key[servers]!(`serverid`attributes)_value servers;
    };

// Dynamic routing finds all processes with relevant data 
attributesrouting:{[options;procdict]
    // Get the tablename and timespan
    timespan:`date$options[`starttime`endtime];
    // See if any of the provided partitions are with the requested ones
    procdict:{[x;timespan] (all x within timespan)or any timespan within x}[;timespan]each procdict;
    // Only return appropriate dates
    types:(key procdict)where value procdict;
    // If the dates are out of scope of processes then error
    if[0=count types;
        '`$"gateway error - no info found for that table name and time range. Either table does not exist; attributes are incorect in .gw.servers on gateway, or the date range is outside the ones present"
       ];
    :types;
    };

// Generates a dictionary of `tablename!mindate;maxdate
partdict:{[input]
    // Get the servers
    servers:update striped:{`dataaccess in key x}each attributes from .gw.servers where not servertype=`hdb;
    // Filter the servers by servertype input
    if[`procs in key input;servers:delete from servers where not servertype in input`procs];
	// Servertypes that are all striped
    allstriped:select from servers where(all;striped)fby servertype;
    // Servertypes that has any but not all striped
    // Sort it by serverid
    anyandnotallstriped:select by serverid from servers 
        where((striped=0)&({any[x]&not all x};striped)fby servertype)|not(any;striped)fby servertype;
    servers:allstriped,
        // Get the first unstriped server by type
        select from anyandnotallstriped where i=(first;i)fby servertype;
    // Get the (nested) list of serverids by servertype
    serverids:(exec serverid from allstriped),value exec serverid by servertype from anyandnotallstriped;
    // Create a dictionary of the attributes against serverids
    procdict:serverids!(servers'[first each serverids]`attributes)@\:`date;
    // Dictionary as min date/ max date
    @[procdict;key procdict;{:(min x; max x)}]
    };

adjustqueriesoverlap:{[options;part]
	// Get the overlapping part(itions) from options`procs found by attributesrouting
	// e.g. if `procs is not specified in the querydict but starttime and endtime specified is .z.d
	//      attributesrouting will set options`procs to only rdb servers but part may still contain hdb servers
	overlap:max{x~/:key y}[;part]each options`procs;
	part:key[part][where overlap]!value[part]where overlap;
	// get the date casting where relevant
	st:$[a:-14h~tp:type start:options`starttime;start;`date$start];
	et:$[a;options`endtime;`date$options`endtime];
	// get the dates that are required by each process
	dates:key[part]!{y(min;max)@\:x}[;l]each where each flip{within[y;]each value x}[part]'[l:st+til 1+et-st];
	// if start/end time not a date, then adjust dates parameter for the
	// correct types
	if[not a;
		// converts dates dictionary to timestamps/datetimes
		dates:$[-15h~tp;{"z"$x};::]{(0D+x 0;x[1]+1D-1)}'[dates];
		// convert first and last timestamp to start and end time
		dates:key[dates]!?[value[dates][;0]<start;start;value[dates][;0]],'?[value[dates][;1]>end;end:options`endtime;value[dates][;1]];
		];
    :`part`isdate`dates!(part;a;dates);
    }

// Modify queries based on striped processes
adjustqueriesstripe:{[options;dict]
    // create a dictionary of procs and different queries
	query:{@[@[x;`starttime;:;y 0];`endtime;:;y 1]}[options]'[dict`dates];
    // modify query based on `instrumentsfilter`timecolumns
    modquery:select serverid,inftc:attributes[;`dataaccess;`tablename;options`tablename;`instrumentsfilter`timecolumns],segid:attributes[;`dataaccess;`segid]from
        (select from .gw.servers where({`dataaccess in key x}each attributes)&serverid in first each options`procs)
            where{(y in key x[`dataaccess;`tablename])&`dataaccess in key x}[;options`tablename]each attributes;
    timecolumn:$[`timecolumn in key options;options`timecolumn;`time];
    // get time segment based on timecolumn specified
    modquery:update inftc:.[inftc;(::;1);:;.[inftc;(::;1;timecolumn)]]from modquery;
    // union join based on serverid
    querytable:0!(`serverid xkey update serverid:(first each key query)from value query)uj`serverid xkey modquery;
    // convert times to timestamps
    querytable:update starttime:`timestamp$starttime,endtime:(`timestamp$endtime)+?[-14h=type each endtime;0D23:59:59.999999999;0]from querytable;
    // modify starttime and endtime based on stripe
    querytable:update 
        // if no overlap return empty list
        timeoverlaps:{[st;et;tc] $[(et<tc 0)|st>tc 1;`timestamp$();($[st<tc 0;tc 0;st];$[et>tc 1;tc 1;et])]}'[starttime;endtime;inftc[;1]]
            from querytable where serverid in modquery`serverid;
    querytable:update starttime:timeoverlaps[;0],endtime:timeoverlaps[;1] from querytable where serverid in modquery`serverid; 
    querytable:enlist[`timeoverlaps]_querytable;
    
	if[i:`instruments in key options;
		// modify instruments based on stripe
        querytable:update 
            // query instruments needs to be an atom if only 1sym is queried, if not it will throw a type error
			adjinstruments:
                // check if instrumentsfilter exists
                {$[""~x 0;
                    $[1=count y;y 0;y];
                    [inf:get"`",x 0;$[1=count s:y where inf y,();s 0;s]]
                    ]}'[inftc;instruments]
                from querytable where serverid in modquery`serverid;
		querytable:update adjinstruments:instruments from querytable where not serverid in modquery`serverid;
		querytable:(enlist[`adjinstruments]!enlist `instruments)xcol enlist[`instruments]_querytable;
		];

    // filter queries not required
    querytable:$[i;
        select from querytable where(0=count each inftc)|(0<count each inftc[;1])&(not null each starttime)&0<count each instruments;
        select from querytable where(0=count each inftc)|(0<count each inftc[;1])&not null each starttime];
    // if no results
    if[0=count querytable;'`$"gateway error - no info found for that table name and time range."];
    // convert serverid atoms into their respective serverid lists
    querytable:update serverid:{x where{any x in y}[;y]each x}[options`procs;serverid],
        // get servertype
        servertype:`${string .gw.servers'[x]`servertype}serverid,
        // convert procs into procname if striped
        procs:.gw.servers[;`attributes;`procname]@/:serverid from querytable;
    querytable:update procs:servertype from querytable where not(last each serverid)in modquery`serverid;

    // filter overlap timings between rdb and wdb (tailer) process
    segids:exec distinct[segid]except 0N from querytable;
    if[count segids;
        querytable:{y;if[exec all`rdb`wdb in servertype from x where segid=y;
            rdbtimes:exec(starttime,endtime)from x where(segid=y)&servertype=`rdb;
            wdbtimes:exec(starttime,endtime)from x where(segid=y)&servertype=`wdb;
            if[rdbtimes[0]<wdbtimes 1;wdbtimes[1]:rdbtimes[0]-1;
                :update starttime:wdbtimes 0,endtime:wdbtimes 1 from x where(segid=y)&servertype=`wdb]];x}/[querytable;segids];
        querytable:delete from querytable where starttime>endtime];

    querytable:`inftc`segid _ querytable;
    // optimize hdb query
    if[(not`timecolumn in key options)&(14h~type options`starttime`endtime)&exec`hdb in servertype from querytable;
        querytable:update optimhdb:1b from querytable where servertype=`hdb];
    // Input dictionary must have keys of type 11h
    // return query as a dict of table
    :(exec serverid from querytable)!querytable;
    }