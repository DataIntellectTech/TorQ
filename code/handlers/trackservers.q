// modified version of trackservers.q
// http://code.kx.com/wsvn/code/contrib/simon/dotz/
/ track active servers of a kdb+ session in session table SERVERS

// Check if the process has been initialised correctly
if[not @[value;`.proc.loaded;0b]; '"environment is not initialised correctly to load this script"]

\d .servers

SERVERS:@[value;`.servers.SERVERS;([]procname:`symbol$();proctype:`symbol$();hpup:`symbol$();w:`int$();hits:`int$();startp:`timestamp$();lastp:`timestamp$();endp:`timestamp$();attributes:())]

enabled:@[value;`enabled;1b]                                                                    // whether server tracking is enabled
CONNECTIONS:@[value;`CONNECTIONS;`]                                                             // the list of connections to make at start up
DISCOVERYREGISTER:@[value;`DISCOVERYREGISTER;1b]                                                // whether to register with the discovery service
CONNECTIONSFROMDISCOVERY:@[value;`CONNECTIONSFROMDISCOVERY;1b]                                  // whether to get connection details from the discovery service (as opposed to the static file)
SUBSCRIBETODISCOVERY:@[value;`SUBSCRIBETODISCOVERY;1b]                                          // whether to subscribe to the discovery service for new processes becoming available
DISCOVERYRETRY:@[value;`DISCOVERYRETRY;0D00:05]                                                 // how often to retry the connection to the discovery service.  If 0, no connection is made
TRACKNONTORQPROCESS:@[value;`TRACKNONTORQPROCESS;0b]                                            // whether to track and register non torQ processes
NONTORQPROCESSFILE:@[value;`NONTORQPROCESSFILE;hsym .proc.getconfigfile["nontorqprocess.csv"]]  // non torQ processes file
HOPENTIMEOUT:@[value;`HOPENTIMEOUT;2000]                                                        // new connection time out value in milliseconds
RETRY:@[value;`RETRY;0D00:05]                                                                   // period on which to retry dead connections. If 0 no connection is made
RETAIN:@[value;`RETAIN;`long$0D00:30]                                                           // length of time to retain server records
AUTOCLEAN:@[value;`AUTOCLEAN;0b]                                                                // clean out old records when handling a close
DEBUG:@[value;`DEBUG;1b]                                                                        // whether to print debug output
LOADPASSWORD:@[value;`LOADPASSWORD;1b]                                                          // load the external username:password from ${KDBCONFIG}/passwords
USERPASS:`                                                                                      // the username and password used to make connections
STARTUP:@[value;`STARTUP;0b]                                                                    // whether to automatically make connections on startup
DISCOVERY:@[value;`DISCOVERY;enlist`]                                                           // list of discovery services to connect to (if not using process.csv)
SOCKETTYPE:@[value;`SOCKETTYPE;enlist[`]!enlist `]                                              // dict of proctype!sockettype. sockettype options : `tcp`tcps`unix. e.g. `rdb`tickerplant!`tcp`unix
PASSWORDS:@[value;`PASSWORDS;enlist[`]!enlist `]                                                // dict of host:port!user:pass e.g. `:host:1234!`user:pass


// If required, change this method to something more secure!
// Otherwise just load the usernames and passwords from the passwords directory
// using the usual hierarchic approach
loadpassword:{
    .lg.o[`conn;"attempting to load external connection username:password from file"];
    // load a password file
    loadpassfile:{[file]
         $[()~key hsym file;
           .lg.o[`conn;"password file ",(string file)," not found"];
           [.lg.o[`conn;"password file ",(string file)," found"];
            .servers.USERPASS:first`$read0 hsym file]]};
    files:{.proc.getconfig["passwords/",(string x),".txt";2]} each `default,.proc.parentproctype,.proc.proctype,.proc.procname;
    loadpassfile each distinct[raze flip files[;1 0]]except`;
    }
loadpassword[]

// open a connection
opencon:{
    if[DEBUG;.lg.o[`conn;"attempting to open handle to ",string x]];
    // If the supplied connection string has no more than 2 colons (or 3 if using a tcps connection) append user:pass from passwords dictionary
    // else return connection string passed in
    tcps:string[x] like ":tcps:*";
    connection:hsym $[(2+tcps) >= sum ":"=string x; `$(string x),":",string USERPASS^PASSWORDS[x];x];
    h:@[{(hopen x;"")};(connection;.servers.HOPENTIMEOUT);{(0Ni;x)}];
    // just log this as standard out.  Depending on the scenario, failing to open a connection isn't necessarily an error
    if[DEBUG;.lg.o[`conn;"connection to ",(string x),$[null first h;" failed: ",last h;" successful"]]];
    first h}

// req = required set of attribute
// avail = the attributes which the server process is advertising
// return a dict of (complete match boolean; partial match values)
attributematch:{[req;avail]
    // the dictionary is mixed type - so have to handle non values in the avialable dictionary separately
    vals:key[req] inter key avail;
    notpresent:noval!(count noval:key[req] except key avail)#enlist(0b;());
    notpresent,vals!{($[0>type y;x~y;all x in y];(x,()) inter y,())}'[req vals;avail vals]}

// Get the list of servers which match specific types or names
// attributes is used to return an attribute dictionary with the matches to the required attributes
// autoopen is used to attempt to automatically open a connection if it is registered but not available
// if onlyone is true, and at least one server per name/type is found, then autoopen is ignored (as we only need one server, which we have)
// name or type can be `procname`proctype
getservers:{[nameortype;lookups;req;autoopen;onlyone]
    r:$[`~lookups; select procname,proctype,lastp,w,hpup,attributes,index:i from .servers.SERVERS;
        nameortype~`proctype; select procname,proctype,lastp,w,hpup,attributes,index:i from .servers.SERVERS where proctype in lookups;
        select procname,proctype,lastp,w,hpup,attributes,index:i from .servers.SERVERS where procname in lookups];
    // no servers found matching the criteria - so throw them back
    if[0=count r;:update attributematch:attributes from r];
    r:update alive:.dotz.liveh w from r;
    // try to automatically reopen handles if there are closed ones, and we need more than one connection
    if[autoopen;
        if[(count r) > alivecount:sum r`alive;
            // we don't have any servers, or we have to try to return them all, or there is a specified name/type where we don't have an open handle
            if[(alivecount=0) or (not onlyone) or (any not exec max alive by agg:?[nameortype~`proctype;proctype;procname] from r);
                retryrows exec index from r where not alive;
                r:select procname,proctype,lastp,w,hpup,attributes,alive:.dotz.liveh w from .servers.SERVERS where i in r`index]]];
    select procname,proctype,lastp,w,hpup,attributes,attribmatch:.servers.attributematch[req]each attributes from r where alive}

selector:{[servertable;selection]
    $[selection=`roundrobin;first `lastp xasc servertable;
      selection=`any;rand servertable;
      selection=`last;last `lastp xasc servertable;
     '"unknown selection type : ",string selection]}

// short cut function to get a server by type
// Only require one server of the given type
getserverbytype:{[ptype;serverval;selection]
    r:getservers[`proctype;ptype;()!();1b;1b];
    if[count r;
        r:selector[r;selection];
        updatestats[r`w]];
    r[serverval]}

gethandlebytype:getserverbytype[;`w;]
gethpbytype:getserverbytype[;`hpup;]

// Update the server stats
updatestats:{[W] update lastp:.proc.cp[],hits:1+hits from`.servers.SERVERS where w=W}

names:{asc distinct exec procname from`.servers.SERVERS where .dotz.liveh w}
types:{asc distinct exec proctypes from`.servers.SERVERS where .dotz.liveh w}
unregistered:{except[key .z.W;exec w from`.servers.SERVERS]}

cleanup:{if[count w0:exec w from`.servers.SERVERS where not .dotz.livehn w;
        update endp:.proc.cp[],lastp:.proc.cp[],w:0Ni from`.servers.SERVERS where w in w0];
    if[AUTOCLEAN;delete from`.servers.SERVERS where not .dotz.liveh w,(.proc.cp[]^endp)<.proc.cp[]-.servers.RETAIN];}

/ add a new server for current session 
addnthawc:{[name;proctype;hpup;attributes;W;checkhandle]
    if[checkhandle and not isalive:.dotz.liveh W;'"invalid handle"];
    cleanup[];
    $[not hpup in (exec hpup from .servers.SERVERS) inter (exec hpup from .servers.nontorqprocesstab);
        `.servers.SERVERS insert(name;proctype;lower hpup;W;0i;$[isalive;.proc.cp[];0Np];.proc.cp[];0Np;attributes); 
        .lg.o[`conn;"Removed double entries: name->", string[name],", proctype->",string[proctype],", hpup->\"",string[hpup],"\""]];
    W
    }

addh:{[hpuP]
    W:opencon hpuP;
    $[null W;
    '"failed to open handle to ",string hpuP;
    addhw[hpuP;W]]}

// return the details of the current process
getdetails:{(.z.f;.z.h;system"p";@[value;`.proc.procname;`];@[value;`.proc.proctype;`];@[value;(`.proc.getattributes;`);()!()])}
/ add session behind a handle
addhw:{[hpuP;W]
    // Get the information around a process
    info:`f`h`port`procname`proctype`attributes!(@[W;({$[`getdetails in key`.servers;.servers.getdetails[];(.z.f;.z.h;system"p";`;`;$[`getattributes in key`.proc;.proc.getattributes[];()!()])]};`);(`;`;0Ni;`;`;()!())]);
    if[0Ni~info`port;'"remote call failed on handle ",string W];
    if[null name:info`procname;name:`$last("/"vs string info`f)except enlist""];
    if[0=count name;name:`default];
    if[null hpuP;hpuP:.servers.formathp[info`h;info`port;`tcp^.servers.SOCKETTYPE info`proctype]];
    // If this handle already has an entry, delete the old entry
    delete from `.servers.SERVERS where w=W;
    addnthawc[name;info`proctype;hpuP;info`attributes;W;0b]}

addw:addhw[`]

reset:init:{delete from`.servers.SERVERS}

checkw:{{x!@[;"1b";0b]each x}exec w from`.servers.SERVERS where .dotz.liveh w,w in x}

/ after getting new servers run retry to open connections
retry:{retryrows exec i from `.servers.SERVERS where not .dotz.liveh0 w,not proctype=`discovery}
retrydiscovery:{
    if[count d:exec i from `.servers.SERVERS where proctype=`discovery,not ({any .dotz.liveh0 x};w) fby hpup, i=(first;i) fby hpup;
        .lg.o[`conn;"attempting to connect to discovery services"];
        retryrows d;
        // register with the newly opened discovery services
        if[DISCOVERYREGISTER and count h:exec w from .servers.SERVERS[d] where .dotz.liveh w;
            .lg.o[`conn;"registering with discovery services"];
            @[;(`..register;`);()] each neg h];
        if[CONNECTIONSFROMDISCOVERY and count h;
            registerfromdiscovery[$[`discovery in CONNECTIONS;(CONNECTIONS,()) except `discovery;CONNECTIONS];0b]];
        ]}

// Called by the discovery service when it restarts
autodiscovery:{if[DISCOVERYRETRY>0; .servers.retrydiscovery[]]}

// Attempt to make a connection for specified row ids
retryrows:{[rows]
    //function a checks if the handle passed is empty and also invokes checknontorqattr function 
    //which checks if .proc.getattributes is defined on the nontorqprocess and executes it 
    //only if it is defined
    a:{$[not null x;@[x;({.proc.getattributes[]};::);()!()];()!()]};
 
    // opencon, amends global tables, cannot be used inside of a select statement
    handles:.servers.opencon each exec hpup from`.servers.SERVERS where i in rows;
    update lastp:.proc.cp[],w:handles from`.servers.SERVERS where i in rows;
    update attributes:a each w,startp:?[null w;0Np;.proc.cp[]] from`.servers.SERVERS where i in rows;
    if[count connectedrows:select from`.servers.SERVERS where i in rows,.dotz.liveh0 w;
    connectcustom[connectedrows]]}

// user definable function to be executed when a service is reconnected. Also performed on first connection of that service.
// Input is the line(s) from .servers.SERVERS corresponding to the newly (re)connected service
connectcustom:@[value;`.servers.connectcustom;{[connectedrows]}]

// close handles and remove rows from the table
removerows:{[rows]
    @[hclose;;()] each .servers.SERVERS[rows][`w] except 0 0Ni;
    delete from `.servers.SERVERS where i in rows}

// Create some connections and optionally connect to them
register:{[connectiontab;proc;connect]
    {addnthawc[x`procname;x`proctype;x`hpup;()!();0Ni;0b]}each distinct select from connectiontab where proctype=proc;
    // automatically connect
    if[connect;
        $[`discovery=proc;retrydiscovery[];retry[]]]};

// Query a discovery service, and get the list of available services
// Does not attempt to re-open any discovery services
querydiscovery:{[procs]
    if[0=count procs;:()];
    .lg.o[`conn;"querying discovery services for processes of types "," " sv string procs,()];
    h:exec w from getservers[`proctype;`discovery;()!();0b;0b];
    $[0=count h;
        [.lg.o[`conn;"no discovery services available"];()];
         raze @[;(`getservices;procs;SUBSCRIBETODISCOVERY);()] each h]}

// register processes from the discovery service
// if connect is true, will try to
registerfromdiscovery:{[procs;connect]
    if[`discovery in procs; '"cannot use registerfromdiscovery to locate discovery services"];
    .lg.o[`conn;"requesting processes from discovery service"];
    res:querydiscovery[procs];
    if[0=count res; .lg.o[`conn;"no processes found"]; :()];
    // add the processes
    addprocs[res;procs;connect];}

addprocs:{[connectiontab;procs;connect]
    connectiontab:formatprocs[delete split from update host:`$last each -1 _' split, port:"I"$last each split from update split:{":" vs string x}each hpup from connectiontab];
    // filter out any we already have - same name,type and hpup
    res:select from connectiontab where not ([]procname;proctype;hpup) in select procname,proctype,hpup from .servers.SERVERS;
    // we've dropped some items - maybe there are updated attributes
    if[not count[res]=count connectiontab;
        if[`attributes in cols connectiontab;
            .servers.SERVERS:.servers.SERVERS lj 3!select procname,proctype,hpup,attributes from connectiontab where not ([]procname;proctype;hpup) in select procname,proctype,hpup from .servers.SERVERS]] 
    // if we have a match where the hpup is the same, but different name/type, then remove the old details
    removerows exec i from `.servers.SERVERS where hpup in exec hpup from res;
    register[res;;connect] each $[procs~`ALL;exec distinct proctype from res;procs,()];
    addprocscustom[res;procs]}

// addprocscustom is to allow bespoke extensions when adding processes
addprocscustom:@[value;`.servers.addprocscustom;{{[connectiontab;procs]}}]

// used to handle updates from the discovery service
// procupdatecustom is used to extend the functionality - do something when the service has been updated
procupdate:{[procs] addprocs[procs;exec distinct proctype from procs;0b];}

// refresh the attribute registration with each of the discovery servers
// useful for things like HDBs where the attributes may periodically change
refreshattributes:{
    retrydiscovery[];
    (neg exec w from .servers.getservers[`proctype;`discovery;()!();0b;0b])@\:(`..register;`);
    }

// return true if unix domain sockets can be used
domainsocketsenabled:{[]
        // unix domain sockets only works on unix and not windows
        notwin:not .z.o like "w*";
    // v3.4 brought in the first version of unix domain sockets ipc
        iskdbv:3.4<=.z.K;
        :notwin and iskdbv;
    }

// format hpup from procs table, take into account ipc type
// IPCTYPE [-11h] (`tcp;`tcps;`unix);
formathp:{[HOST;PORT;IPCTYPE]
    ipctype:IPCTYPE;
    isunixsocket:ipctype = `unix;
    notsamebox:not any HOST in `localhost,.z.h;

    host:string $[HOST=`localhost;.z.h;HOST];
    port:string PORT;

    /// Determine whether socket connection is valid
    // revert socket to tcp;
    if[isunixsocket and notsamebox;
        .lg.w[`formathp;"Expects to connect via domain sockets, but host is not on the same machine. Reverting IPC mechanism to TCP"];
        ipctype:`tcp;
    ];
    if[isunixsocket and not domainsocketsenabled[];
        .lg.w[`formathp;"Domain sockets are not enabled for this system. Reverting IPC mechanism from to TCP"];
        ipctype:`tcp;
    ];

    /// Format hpup file handle
    if[ipctype = `tcp;
        hpup:lower `$":",host,":",port;
    ];
    if[ipctype = `tcps;
        hpup:lower `$":tcps://",host,":",port;
    ];
    if[ipctype = `unix;
        hpup:lower `$":unix://",port;
    ];

    :hpup;
    }

// do full formatting of proc table
formatprocs:{[PROCS]
    procs:update ipctype:`tcp^.servers.SOCKETTYPE[proctype] from PROCS;
    procs:update hpup:.servers.formathp'[host;port;ipctype] from procs;
    :procs;
    }

// given a hpup, return its ipc type (`tcp;`tcps;`unix)
getipctype:{[HPUP]
        tokens:`unix`tcps!(":unix://*";":tcps://*");
        :`tcp^first where string[HPUP] like/: tokens;
    }

// called at start up
startup:{
    // correctly format procs and hpup
    procstab::procs:formatprocs .proc.readprocs .proc.file;
    nontorqprocesstab::formatprocs $[count key NONTORQPROCESSFILE;.proc.readprocs NONTORQPROCESSFILE;0#procs];

    // If DISCOVERY servers have been explicity defined
    if[count .servers.DISCOVERY;
                if[not null first .servers.DISCOVERY;
                        if[count select from procs where hpup in .servers.DISCOVERY; .lg.e[`startup; "host:port in .servers.DISCOVERY list is already present in data read from ",string .proc.file]];
                        procs,:([]host:`;port:0Ni;proctype:`discovery;procname:`;hpup:.servers.DISCOVERY)]];
    // Remove any processes that have an active connection
    connectedprocs: select procname, proctype, hpup from SERVERS;
    procs: delete from procs where ([] procname; proctype; hpup) in connectedprocs;
    nontorqprocs: delete from nontorqprocesstab where ([] procname; proctype; hpup) in connectedprocs;
    // if there aren't any processes left to connect to, then escape
    if[not any count each (procs;nontorqprocs); .lg.o[`conn;"No new processes to connect to.  Escaping..."];:()];
    if[CONNECTIONSFROMDISCOVERY or DISCOVERYREGISTER;
        register[procs;`discovery;0b];
        retrydiscovery[]];
    if[not CONNECTIONSFROMDISCOVERY; register[procs;;0b] each $[CONNECTIONS~`ALL;exec distinct proctype from procs;CONNECTIONS]];
    if[TRACKNONTORQPROCESS;register[nontorqprocs;;0b] each $[CONNECTIONS~`ALL;exec distinct proctype from nontorqprocs;CONNECTIONS]];
    // try and open dead connections
    retry[]}

// Check if required processes all connected
reqprocsnotconn:{[requiredprocs] 
    not all requiredprocs in exec proctype from .servers.SERVERS where .dotz.liveh[w]
  };

// Block process until all required processes are connected
startupdepcycles:{[requiredprocs;timeintv;cycles]
  n:1;                                                                                                                  //variable used to check how many cycles have passed
  .servers.startup[];
  while[.servers.reqprocsnotconn requiredprocs;                                                                         //check if requiredprocs are running
    if[n>cycles;
      b:((),requiredprocs)except(),exec proctype from .servers.SERVERS where .dotz.liveh w;
      .lg.e[`connectionreport;string[.proc.procname]," cannot connect to ",","sv string'[b]];                           //after "cycles" times output error and exit process.
     ];
    .os.sleep[timeintv];
    n+:1;
    .servers.startup[];
   ];
 };

startupdependent:startupdepcycles[;;0W];

pc:{[result;W] update w:0Ni,endp:.proc.cp[] from`.servers.SERVERS where w=W;cleanup[];result}

.z.pc:{.servers.pc[x y;y]}.z.pc;

if[enabled;
    if[DISCOVERYRETRY > 0; .timer.repeat[.proc.cp[];0Wp;DISCOVERYRETRY;(`.servers.retrydiscovery;`);"Attempt reconnections to the discovery service"]];
    if[RETRY > 0; .timer.repeat[.proc.cp[];0Wp;RETRY;(`.servers.retry;`);"Attempt reconnections to closed server handles"]]];
