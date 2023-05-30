//functionality loaded in by gateway
//functions include: getserverids, getserveridstype, getserverscross, buildcross

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
