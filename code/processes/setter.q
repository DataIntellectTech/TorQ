// Setter process to set cache to disk

\d .anycache

// Save cache down to disk
setter.savecachedowntodisk:{[data;filepath] (hsym filepath) set data };

// Get location of cache config and load it in.
setter.cacheconfiglocation: .proc.getconfigfile "cacheconfig.json";
setter.cacheconfig:.j.k raze read0 hsym first setter.cacheconfiglocation;

// Mode of cache
setter.isrequest: "request" ~ setter.cacheconfig.setter.mode;

// Number of main cache builds (and cache requests) to keep on disk in request mode
setter.cachestokeep:$[`cachestokeep in key setter.cacheconfig`setter; "j"$setter.cacheconfig.setter.cachestokeep; 3];

// Max size in MB of the data a component cache query can return
setter.maxresultmb:$[`maxresultmb in key setter.cacheconfig`setter; setter.cacheconfig.setter.maxresultmb; 1024];

// Max number of rows a component cache query can return from each server
setter.maxrows:$[`maxrows in key setter.cacheconfig`setter; "j"$setter.cacheconfig.setter.maxrows; 10000000];

// Longest a component cache query can take before the gateway times it out
setter.querytimeout:$[`querytimeout in key setter.cacheconfig`setter; "N"$setter.cacheconfig.setter.querytimeout; 0D00:01];

// Run on the rdb or hdb around each query, so a result over maxrows or maxresultmb errors there and is never sent back through the gateway
// Kept as a string so the server evaluates it in its own root namespace
setter.limitquery:"{[query;maxrows;maxmb] result:value query; if[maxrows<count result; '\"result has \",(string count result),\" rows, over the maxrows of \",string maxrows]; if[maxmb<sizemb:(-22!result)%1024*1024; '\"result is \",(string sizemb),\" MB, over the maxresultmb of \",string maxmb]; result}";

// Max number of days a request query can cover, counting both ends of its date range
setter.maxdatespan:$[`maxdatespan in key setter.cacheconfig`setter; "j"$setter.cacheconfig.setter.maxdatespan; 7];

// Hours a main cache build or cache request is kept before the flush deletes it
setter.flushhours:$[`flushhours in key setter.cacheconfig`setter; setter.cacheconfig.setter.flushhours; 24];

//Setter's main function
//Builds the caches, and completes the main cache build once every component cache is built
//Static mode's timer runs it every interval, and in request mode it builds the request when triggered
//If a component cache fails, the run's component caches are removed and the build isn't completed
//e.g. setter.detectandwritecache[]
setter.detectandwritecache:{ 
    cacheinfo:setter.detectcachetobuild[];
    setter.writetoken[;`start] each cachepath:cacheinfo`cachepath;
    //Included some basic error trapping here
    success:{.[setter.generateandwritecache; (x;y); {[cachepath;err] .lg.e[`anycache; "cache build failed for component cache ",(string last ` vs cachepath),": ",err];0b}[x]]}'[cachepath; cacheinfo`args];
    if[not all success;
        .lg.e[`anycache; "main cache build failed, not completing ",1_string first ` vs first cachepath];
        setter.cleanupcache each cachepath;
        :(::)
    ];
    setter.writetoken[;`end] each cachepath;
    //Can eject now if there are still caches to be built in the main cache - skipped when this run had nothing to build
    if[count cachepath;
        build:first ` vs first cachepath;
        componentcaches:` sv' build,/:key setter.cacheconfig.componentcaches;
        remainingcaches:key[d] where not `end in/: value d:componentcaches!key each componentcaches;
        if[count remainingcaches;
            .lg.o[`anycache; "main cache build ",(1_string build)," still has component caches to build: ",(", " sv string last each ` vs' remainingcaches),", not completing yet"];
            :(::)
        ]
    ];
    setter.completecache cacheinfo`maincachepath
 };

//accepts start or end and saves the current time as a timestamp to a flat file 
//in dir as `:startTime or `:endTime
setter.writetoken:{[dir;stage] 
    (` sv (dir;stage)) set .z.P
 };

//Returns a new build's name and 1b, or the newest build's path and 0b
setter.getlatestcache:{[caches;cachename;cachewithmaxstarttime]
    if[setter.isrequest or 0 = count caches; :`cachename`newcache!(cachename,"_",string .z.P;1b)];
    if[(("N"$setter.cacheconfig.setter.interval) - 0D00:00:03) < .z.P - "P"$@[last "_" vs string cachewithmaxstarttime;13 16 19;:;"::."];:`cachename`newcache!(cachename,"_",string .z.P;1b)];
    :`cachename`newcache!(cachewithmaxstarttime;0b)
 };

//Picks the main cache build to write to: either a new one, or the newest one to resume - and lists its unfinished component caches
//Returns the main cache path, the component cache paths and each one's args
//e.g. static mode, with no builds yet
//  setter.detectcachetobuild[]
//  maincachepath| `:/path/to/anycachedemodata/myfirstcache
//  cachepath    | `:/path/to/anycachedemodata/myfirstcache/myfirstcache_2026.10.28D09:42:28.548395000/cache1`:/path/to/anycachedemodata/myfirstcache/myfirstcache_2026.10.28D09:42:28.548395000/cache2
//  args         | ``
setter.detectcachetobuild:{
    cachename: setter.cacheconfig`cachename;
    asyncprocessname: setter.cacheconfig`asyncprocessname;
    maincachepath:hsym `$setter.cacheconfig.cacherootdir,"/",cachename;
    caches:` sv' maincachepath,'(key maincachepath) where (key maincachepath) like cachename,"_*";
    cachewithmaxstarttime:`;
    if[not 0 = count caches; cachewithmaxstarttime:starts ? max starts:caches!{get ` sv x,`start} each caches];

    latestcache:setter.getlatestcache[caches;cachename;cachewithmaxstarttime];

    if[latestcache`newcache;
        cachewithmaxstarttime:` sv maincachepath,`$latestcache`cachename;
        setter.writetoken[cachewithmaxstarttime;`start]
        ];
    .lg.o[`anycache; $[latestcache`newcache; "starting new main cache build "; "resuming main cache build "],1_string cachewithmaxstarttime];

    componentcaches:` sv' cachewithmaxstarttime,/:key setter.cacheconfig.componentcaches;
    incompletecomponentcaches:key[d2] where not `end in/: value d2:componentcaches!key each componentcaches;
    .lg.o[`anycache; "component caches to build: ",$[count incompletecomponentcaches; ", " sv string last each ` vs' incompletecomponentcaches; "none"]];
    setter.writetoken[;.proc.procname] each incompletecomponentcaches;
    args:(count incompletecomponentcaches)#enlist`;
    if[setter.isrequest;
        argpaths:` sv' maincachepath,'(key maincachepath) where (key maincachepath) like asyncprocessname,"*";
        maxstarttime:string first max "P"$-1#' "_" vs' string argpaths;
        argwithmaxstarttime:first argpaths where argpaths like "*",maxstarttime;
        args: get ` sv argwithmaxstarttime,`args
        ];
    `maincachepath`cachepath`args!(maincachepath;incompletecomponentcaches;args)
 };

//Queries the data for a component cache through the gateway and saves it as an anymap in the component cache's directory
//Static mode gets the query and datasources set for the component cache from the cache config
//e.g. static mode
//  setter.generateandwritecache[`:/path/to/anycachedemodata/myfirstcache/myfirstcache_2026.10.28D09:42:28.548395000/cache1;`]
//e.g. request mode
//  setter.generateandwritecache[`:/path/to/anycachedemodata/myfirstcache/myfirstcache_2026.10.28D09:42:28.548395000/cache1;enlist[`query]!enlist "select by sym from trade where date = 2026.10.28"]
setter.generateandwritecache:{[cachepath; args] 
    cachename:last ` vs cachepath;
    connectiondetails: `$trim each "," vs (setter.cacheconfig.componentcaches cachename)`datasource;
    if[`rdb`hdb ~ connectiondetails; connectiondetails: `hdb`rdb];
    $[setter.isrequest; querydetails: args`query; querydetails: (setter.cacheconfig.componentcaches cachename)`staticmode];
    // Request queries must have a date or date span
    if[not $[setter.isrequest; setter.checkdates[cachename;querydetails]; 1b]; :0b];
    if[setter.isrequest; connectiondetails:setter.requestservertypes querydetails];
    gateway:.servers.gethandlebytype[`gateway;`any];
    .lg.o[`anycache; "requesting data for component cache ",(string cachename)," from ",(", " sv string connectiondetails)];
    cache: setter.querygateway[gateway;querydetails;connectiondetails];
    //The gateway sends errors back as strings
    if[10h=type cache;
        .lg.e[`anycache; "query for component cache ",(string cachename)," failed on the gateway: ",cache];:0b];
    //Each server's result is under the size limit - return an error if they are over it once joined
    if[setter.maxresultmb < sizemb:(-22!cache)%1024*1024;
        .lg.e[`anycache; "result for component cache ",(string cachename)," is ",(string sizemb)," MB, over the maxresultmb of ",(string setter.maxresultmb),", not saving"];:0b];
    .lg.o[`anycache; "saving data for component cache ",(string cachename)," to ",1_string datapath:` sv cachepath,`data];
    .anymap.writetoanymap[datapath;cache];
    .lg.o[`anycache; "data save completed for component cache ",string cachename];
    :1b
 };

//Runs a query on one server type through the gateway and waits for the result
//e.g. setter.queryservertype[gateway;"select by sym from trade";`rdb]
setter.queryservertype:{[gateway;query;servertype]
    if[setter.isrequest and `rdb~servertype; query:setter.dropdatefilter query];
    //Send the query to the gateway asynchronously and flush it, then wait for the gateway's reply
    //The server checks the result against maxrows and maxresultmb, and the gateway gives up after querytimeout
    neg[gateway](`.gw.asyncexecjpt;(setter.limitquery;query;setter.maxrows;setter.maxresultmb);enlist servertype;raze;();setter.querytimeout);
    neg[gateway][];
    gateway[]
 };

//Runs a query on each server type through the gateway and joins the results
//e.g. setter.querygateway[gateway;"select by sym from trade";`rdb]
setter.querygateway:{[gateway;query;servertypes]
    results:setter.queryservertype[gateway;query] each servertypes;
    if[any errors:10h=type each results; :first results where errors];
    raze {$[(`date in cols x) and not `date in keys x; delete date from x; x]} each results
 };

//Whether a where clause constraint from parse filters on date, e.g. (within;`date;(enlist;2026.11.03;2026.11.04))
setter.isdatefilter:{[constraint] $[1<count constraint; `date~constraint 1; 0b]};

//Server types a request query needs: the hdb if it asks for before today, and the rdb if it asks for today
setter.requestservertypes:{[query]
    datefilter:c where setter.isdatefilter each c:raze (parse query) 2;
    dates:raze {$[enlist~first x; 1_x; x]} each last each datefilter;
    today:.eodtime.getday .z.p;
    `hdb`rdb where (today > min dates;0 < count ?[([] date:enlist today);datefilter;0b;()])
 };

//A request query with its date filter dropped, returned as a functional select for the rdb
setter.dropdatefilter:{[query]
    parsed:parse query;
    @[parsed;2;:;c where not setter.isdatefilter each c:raze parsed 2]
 };

//Checks a request query is a select that filters on date first, on a date, list of dates or date range of at most maxdatespan days.
//Returns 1b if the query can be built, otherwise logs why and returns 0b
//e.g. setter.checkdates[`cache1;"select by sym from trade where date within 2026.10.27 2026.10.28, sym in `AAPL`GOOG"]
//  1b
//e.g. setter.checkdates[`cache1;"select by sym from trade where sym = `AAPL"]
//  0b
setter.checkdates:{[cachename;query]
    //Request queries must be a select, filtering on a date or a date range of at most maxdatespan days
    if[(not query like "* where date in *") and (not query like "* where date = *") and (not query like "* where date within *");
        .lg.e[`anycache; "query for component cache ",(string cachename)," does not filter on a date first, not building"];
        :0b
    ];
    parsed:parse query;
    if[not ((?) ~ first parsed) and type[parsed 3] in -1 99h;
        .lg.e[`anycache; "query for component cache ",(string cachename)," is not a select, not building"];
         :0b
         ];
    constraints:raze parsed 2;
    constraints:constraints where (first each constraints) in (=;within;in);
    d:raze {$[enlist~first x; 1_x; x]} each last each constraints where `date~/:constraints[;1];
    dates:d where -14h=type each d;
    if[(not count dates) or count[d]>count dates;
        .lg.e[`anycache; "query for component cache ",(string cachename)," has no date, or an invalid value, not building"];
         :0b
         ];
    if[.eodtime.getday[.z.p] < min dates;
        .lg.e[`anycache; "query for component cache ",(string cachename)," only asks for days after today, not building"];
        :0b
        ];
    if[(setter.maxdatespan < span:1+(max dates)-min dates) or setter.maxdatespan < count dates;
        .lg.e[`anycache; "query for component cache ",(string cachename)," spans ",(string span)," days, over the maxdatespan of ",(string setter.maxdatespan),", not building"];
        :0b
        ];
    :1b
 };

//Want to just remove the component cache (cachename) from the main cache directory in event of a failure
//Directory contains token files so use deldir rather than hdel, which only removes empty directories
//e.g. setter.cleanupcache each cachepath
setter.cleanupcache:{[cachepath]
    .lg.o[`anycache; "removing failed component cache ",1_string cachepath];
    .os.deldir cachepath
 };

//Deletes an old cache
//e.g. setter.deleteoldcache `:/path/to/anycachedemodata/myfirstcache/myfirstcache_2026.10.28D09:42:28.548395000
setter.deleteoldcache:{[cachepath]
    .lg.o[`anycache; "deleting old cache ",1_string cachepath];
    .os.deldir cachepath
 };

//In request mode keep the most recent cachestokeep main cache builds and cache requests, delete the rest
//Directory names end in their start timestamp so sorting by name sorts by age
//e.g. setter.removeoldrequestcaches maincachepath
setter.removeoldrequestcaches:{[maincachepath]
    names:key maincachepath;
    old:raze {neg[setter.cachestokeep] _ asc x where x like y}[names] each setter.cacheconfig[`cachename`asyncprocessname],\:"_*";
    setter.deleteoldcache each ` sv' maincachepath,'old;
 };

//Completes the newest main cache build once all its component caches are built by writing its end token
//Static mode points the cachename symlink at the newest build and deletes the older builds
//Request mode deletes all but the newest cachestokeep builds and requests
//e.g. setter.completecache `:/path/to/anycachedemodata/myfirstcache
setter.completecache:{[maincachepath]
    cachename: string last ` vs maincachepath;
    caches:` sv' maincachepath,'(key maincachepath) where (key maincachepath) like cachename,"_*";
    latestcache:string last ` vs starts ? max starts:caches!{get ` sv x,`start} each caches;
    latestcachefilepath: ` sv maincachepath,`$latestcache;
    setter.writetoken[latestcachefilepath;`end];
    .lg.o[`anycache; "main cache build completed ",1_string latestcachefilepath];
    if[setter.isrequest; setter.removeoldrequestcaches maincachepath];
    if[not setter.isrequest or .os.NT; system"ln -sfn ", latestcache, " ", (1_string maincachepath), "/", cachename];
    if[(not setter.isrequest) and .os.NT;
        target: .os.pth latestcachefilepath;
        link: .os.pth ` sv maincachepath,`$cachename;
        system"cmd /c if exist \"", link, "\" rmdir \"", link, "\"";
        system"cmd /c mklink /J \"", link, "\" \"", target, "\"";
    ];
    if[not setter.isrequest; setter.deleteoldcache each ` sv' maincachepath,'{x where not x like (setter.cacheconfig`asyncprocessname),"_*"} (key maincachepath) except (`$cachename;`$latestcache)]
 };

//Windows has no find, so this works out the age of each entry in the main cache folder in q instead
//e.g. setter.oldcaches `:/path/to/anycachedemodata/myfirstcache
setter.oldcaches:{[maincachepath]
    paths:` sv' maincachepath,'key maincachepath;
    times:{$[`end in k:key x; get ` sv x,`end; `start in k; get ` sv x,`start; "P"$last "_" vs string last ` vs x]} each paths;
    paths where times < .z.P-"n"$0D01*setter.flushhours
 };

//Delete caches more than flushhours old - 24 hours unless the cache config sets it
//e.g. setter.flushcaches[]
setter.flushcaches:{
    maincachepath:hsym `$setter.cacheconfig.cacherootdir,"/",setter.cacheconfig`cachename;
    if[() ~ key maincachepath; :(::)];
    old:$[.os.NT; setter.oldcaches maincachepath; hsym `$system "find \"",(1_string maincachepath),"\" -mindepth 1 -maxdepth 1 -mmin +",string "j"$60*setter.flushhours];
    setter.deleteoldcache each old
 };

// Read API for KX Dashboards - reads the newest completed build from disk

//Get time saved in a build's start or end token - null if that token hasn't been written yet
// e.g. setter.readtoken[`:/path/to/anycachedemodata/myfirstcache/myfirstcache_2026.10.28D09:42:28.548395000;`end]
//  2026.10.28D09:42:28.578025000
setter.readtoken:{[dir;stage] $[stage in key dir; get ` sv (dir;stage); 0Np]};

//Get cache builds on disk, return newest first, with their start and end times and component caches
//e.g. setter.cachebuilds[]
//  build                                      start                         end                           componentcaches
//  ---------------------------------------------------------------------------------------------------------------------
//  myfirstcache_2026.10.28D09:42:28.548395000 2026.10.28D09:42:28.548419000 2026.10.28D09:42:28.578025000 "cache1, cache2"
setter.cachebuilds:{
    maincachepath:hsym `$setter.cacheconfig.cacherootdir,"/",setter.cacheconfig`cachename;
    builds:(key maincachepath) where (key maincachepath) like setter.cacheconfig[`cachename],"_*";
    paths:` sv' maincachepath,'builds;
    `start xdesc ([]
        build:builds;
        start:setter.readtoken[;`start] each paths;
        end:setter.readtoken[;`end] each paths;
        componentcaches:{", " sv string key[x] except `start`end} each paths)
 };

//Path of the newest completed main cache build - null if there isn't one yet
//e.g. setter.latestcache[]
//  `:/path/to/anycachedemodata/myfirstcache/myfirstcache_2026.10.28D09:42:28.548395000
setter.latestcache:{
    completed:exec build from setter.cachebuilds[] where not null end;
    maincachepath:hsym `$setter.cacheconfig.cacherootdir,"/",setter.cacheconfig`cachename;
    $[count completed; ` sv maincachepath,first completed; `]
 };

//Data of a component cache from the newest completed build
//e.g. setter.getcache `cache2
//  sym  time                          bid   ask   bsize asize mode ex src
//  ----------------------------------------------------------------------
//  AAPL 2026.10.28D09:42:28.496662000 72.65 73.42 48    80    B    N  GETGO
setter.getcache:{[cachename]
    if[null latest:setter.latestcache[]; '"no completed cache build on disk"];
    data:get ` sv latest,cachename,`data;
    $[.Q.qt data; 0!data; data]
 };

setter.registertimers:{
    .timer.repeat[0D00:00:01 + .proc.cp[];0Wp;"N"$setter.cacheconfig.setter.interval;(`.anycache.setter.detectandwritecache; `);"Running static cachebuilder on a timer"];
 };

setter.registerflushtimer:{
    .timer.repeat[0D01 + .proc.cp[];0Wp;0D01;(`.anycache.setter.flushcaches; `);"Delete caches older than flushhours, checked every hour"];
 };

setter.registerconnections:{
    .servers.startupdepcycles[`gateway;3;1];
 };

.api.add[`.anycache.setter.getcache;1b;"Data of a component cache from the newest completed build";"[symbol: component cache name, e.g. `cache1]";"table (or whatever the component cache query returned)"];
.api.add[`.anycache.setter.cachebuilds;1b;"Main cache builds on disk, newest first, with their start and end times and component caches";"[]";"table"];
.api.add[`.anycache.setter.latestcache;1b;"Path of the newest completed main cache build";"[]";"symbol - null if no build has completed"];

//Starts setter when setter.q loads: the build timer in static mode, the flush timer, and the gateway connection
setter.init:{
    // Register timers
    if[not setter.isrequest; setter.registertimers[]];
    setter.registerflushtimer[];
    setter.registerconnections[];
 };

setter.init[];

\d .