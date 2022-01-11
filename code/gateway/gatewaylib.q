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

    // Extract the procs which have the table defined
    tabname:dict`tablename;
    servers:select from .gw.servers where{[x;tabname]tabname in @[x;`tables]}[;tabname]each attributes;
    // Extract the procs which have the daterange defined
    daterange:`date$timerange:dict`starttime`endtime;
    servers:select from servers where{[x;daterange]any@[x;`date]within daterange}[;daterange]each attributes;
    // Extract the procs which have the servertype defined
    if[`procs in k;servers:select from servers where servertype in dict`procs];

    procdict:()!();
    if[count servers;
        // Check if any serverid by servertype is striped
        $[striped:any anystriped:any each stripedbyservertype:exec{all`skeysym`skeytime in key x}each attributes by servertype from servers;
            [allstriped:all each stripedbyservertype;
            allstripedservertypes:select from servers where servertype in where allstriped;
            anystripedandnotallstriped:select from servers where(not{all`skeysym`skeytime in key x}each attributes)&
                servertype in where anystriped&not allstriped;
            unstripedservertypes:select from servers where servertype in where not anystriped;
            servers:allstripedservertypes,select from(anyandunstriped:anystripedandnotallstriped,unstripedservertypes)where i=(first;i)fby servertype;
            // Create a dictionary of the attributes against serverids, asc sorts it by serverid
            procdict:((exec serverid from allstripedservertypes),
                asc value exec serverid by servertype from anyandunstriped)!(exec attributes from servers)@\:`date;
                ];
            [
            // Remove duplicate servertypes from the gw.servers
            servers:select from servers where i=(first;i)fby servertype;
            // Create a dictionary of the attributes against servertypes
            procdict:(exec servertype from servers)!(exec attributes from servers)@'(key each exec attributes from servers)[;0];
                ]
            ];

        // Returns the dictionary as min & max date
        procdict:@[procdict;key procdict;{:(min x; max x)}];
        // Prevents overlap if all unstriped and more than one process contains a specified date
        if[not[striped]&1<count procdict;procdict:{:$[y~`date$();x;$[within[x 0;(min y;max y)];(1+max[y];x 1);x]]}':[procdict]];
        ];

    // If the dates are out of scope of processes then error
    if[0=count procdict;
        '`$"gateway error - no info found for that table name and time range. Either table does not exist; attributes are incorect in .gw.servers on gateway, or the date range is outside the ones present"
       ];

    // Get the date casting where relevant
    st:$[datetype:-14h~tp:type start:timerange 0;start;`date$start];
    et:$[datetype;timerange 1;`date$timerange 1];
    // Get the dates that are required by each process
    dates:$[inttype:6h~type raze key procdict;
        {key[y]!where each flip x};
        {group key[y]where each x}][;procdict]{within[y;]each value x}[procdict]'[l:st+til 1+et-st];
    // Drop additional null entry
    if[any key[dates]in enlist`symbol$();dates:(enlist`symbol$())_dates];
    dates:l{(min x;max x)}'[dates];

    // If start/end time not a date, then adjust dates parameter for the correct type
    if[not datetype;
        // Converts dates dictionary to timestamps/datetimes
        dates:$[-15h~tp;{"z"$x};::]{(0D+x 0;x[1]+1D-1)}'[dates];
        // Convert first and last timestamp to start and end time
        $[inttype;
            dates:key[dates]!?[value[dates][;0]<start;start;value[dates][;0]],'?[value[dates][;1]>end;end:timerange 1;value[dates][;1]];
            [dates:@[dates;f;:;(start;dates[f:first key dates;1])];
            dates:@[dates;l;:;(dates[l:last key dates;0];timerange 1)];
                ]
                ];
            ];

    // Modify query based on stripe
    // Create a dictionary of procs and different queries
    query:{@[@[x;`starttime;:;y 0];`endtime;:;y 1]}[dict]'[dates];
    if[inttype&`instruments in key dict;
        modquery:select serverid,{x`skeysym`skeytime}each attributes from .gw.servers where({all`skeysym`skeytime in key x}each attributes)&serverid in raze key procdict;
        querytable:0!(`serverid xkey update serverid:(first each key query)from value query)uj`serverid xkey modquery;
        // Modify starttime, endtime and instruments based on stripe
        querytable:update
            {$[z;y;$[(stripest:x[1]0)<`time$y;y;stripest+`date$y]]}[;;datetype]'[attributes;starttime],
            {$[z;y;$[(stripeet:x[1]1)<`time$y;stripeet+`date$y;y]]}[;;datetype]'[attributes;endtime],
            // Query instruments needs to be an atom if only 1sym is queried, if not it will throw a type error
            adjinstruments:{$[1=count s:skeysym where(skeysym:.ds.stripe[(),y;x 0])in y;s 0;s]}'[attributes;instruments]
                from querytable where serverid in modquery`serverid;
        querytable:update adjinstruments:instruments from querytable where not serverid in modquery`serverid;
        querytable:(enlist[`adjinstruments]!enlist `instruments)xcol enlist[`instruments]_querytable;
        // filter queries not required
        drops:exec serverid from querytable where 0=count each instruments;
        // Input dictionary must have keys of type 11h
        querytable:(`serverid`attributes)_update procs:{.gw.servers[x]`servertype}each serverid from 
            select from querytable where not serverid in drops;
        // return query as a dict of table
        :query:k[where not(first each k:key query)in drops]!querytable;
        ];
    // If instruments not specified
    if[inttype;:query:key[query]!update procs:.gw.servers'[first each key query]`servertype from value query];
    
    fk:first each k:key query;
    :query:((exec serverid by servertype from .gw.servers where servertype in fk)fk)!update procs:k from value query;
    };