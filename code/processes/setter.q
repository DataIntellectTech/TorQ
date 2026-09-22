// Setter process to set cache to disk

\d .anycache

// Save cache down to disk
setter.savecachedowntodisk:{[data;filepath] (hsym filepath) set data };

// Get location of cache config and load it in.
setter.cacheconfiglocation:.proc.getconfigfile["cacheconfig.json"];
setter.cacheconfig:.j.k raze read0 hsym first setter.cacheconfiglocation;

// Mode of cache
setter.isrequest: "request" ~ setter.cacheconfig.setter.mode;

setter.detectandwritecache:{ 
    cacheinfo:setter.detectcachetobuild[];
    if[not count cacheinfo;
        :(::)
    ];
    setter.writetoken[;`start] each cachepath:cacheinfo`cachepath;
    //Included some basic error trapping here
    success:{.[setter.generateandwritecache; (x;y); { .lg.e[`anycache; "cache build failed: ",x];0b}]}'[cachepath; cacheinfo`args];
    if[not all success;
        setter.cleanupcache each cachepath;
        :(::)
    ];
    setter.writetoken[;`end] each cachepath;
    //Can eject now if there are still caches to be built in the main cache
    if[not count remainingcaches:cacheinfo`maincachepath;
        :(::)
    ];
    setter.completecache cacheinfo`maincachepath
 };

setter.writetoken:{[dir;stage] 
    //accepts start or end and saves the current time as a timestamp to a flat file 
    //in dir as `:startTime or `:endTime
    (` sv (dir;stage)) set .z.P
 };

setter.detectcachetobuild:{
    cachename: setter.cacheconfig`cachename;
    asyncprocessname: setter.cacheconfig`asyncprocessname;
    maincachepath:` sv (hsym `$setter.cacheconfig.cacherootdir),`$cachename;
    caches:` sv' maincachepath,'(key maincachepath) where (key maincachepath) like cachename,"_*";
    if[not 0 = count caches; cachewithmaxstarttime:starts ? max starts:cands!{get ` sv x,`start} each cands:key[d1] where not `end in/: value d1:caches!key each caches];

    latestcache:{[caches;cachename;cachewithmaxstarttime]
    if[0 = count caches; :`cachename`newcache!(cachename,"_",string .z.P;1b)];
    if[(not setter.isrequest) and ("N"$setter.cacheconfig.setter.interval) < .z.P - "P"$@[last "_" vs string cachewithmaxstarttime;13 16 19;:;"::."];:`cachename`newcache!(cachename,"_",string .z.P;1b)];
    :`cachename`newcache!(cachewithmaxstarttime;0b)}[caches;cachename;cachewithmaxstarttime];

    if[latestcache[`newcache]; setter.writetoken[` sv maincachepath,`$latestcache[`cachename];`start]];
    if[latestcache[`newcache]; cachewithmaxstarttime:` sv maincachepath,`$latestcache[`cachename]];

    componentcaches:` sv' cachewithmaxstarttime,/:key setter.cacheconfig.componentcaches;
    incompletecomponentcaches:key[d2] where not `end in/: value d2:componentcaches!key each componentcaches;
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

setter.generateandwritecache:{[cachepath; args] 
    cachename:last ` vs cachepath;
    connectiondetails: setter.cacheconfig.componentcaches[cachename].datasource;
    cache: connectiondetails".anycache.sampleanalytic[(::)]";
    // Mock data
    // cache:`a`b`c!(1 2 3; (`d`e!4 5); 6);
    .anymap.writetoanymap[` sv cachepath,`data;cache];
    :1b
 };

setter.cleanupcache:{[cachepath] 
    //Want to just remove the component cache (cachename) from the main cache directory in event of a failure
    hdel cachepath
 };

setter.completecache:{[maincachepath]
    cachename: string last ` vs maincachepath;
    latestcache:first system"ls -lt ",(1_string maincachepath), " | grep ", cachename, " | grep -vE '(^l|total)' | head -n 1 | awk '{print $NF}'";
    latestcachefilepath: ` sv maincachepath,`$latestcache;
    setter.writetoken[latestcachefilepath;`end];
    if[not setter.isrequest; system"ln -sfn ", latestcache, " ", (1_string maincachepath), "/", cachename];
    if[not setter.isrequest; dir:{$[11h=type d:key x;raze x,.z.s each` sv/:x,/:d;d]}; nuke: hdel each desc dir@; nuke each ` sv' maincachepath,'(key maincachepath) except (`$cachename;`$latestcache)]
 };

\d .