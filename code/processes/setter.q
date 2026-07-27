// Setter process to set cache to disk

\d .anycache.setter

// Save cache down to disk
savecachedowntodisk:{[data;filepath] (hsym filepath) set data };

// Get location of cache config and load it in.
cacheconfiglocation:.proc.getconfigfile["cacheconfig.json"];
cacheconfig:.j.k raze read0 hsym first cacheconfiglocation;

detectandwritecache:{ 
    cacheinfo:detectcachetobuild[];
    if[not count cacheinfo;
        :(::)
    ];
    writetoken[cachepath:cacheinfo`cachepath;`start]; 
    //Included some basic error trapping here 
    success:@[`generateandwritecache[cachepath];cacheinfo`args;0b]; 
    if[not success; 
        cleanupcache cachepath; 
        :(::) 
    ];
    writetoken[cachepath;`end]; 
    //Can eject now if there are still caches to be built in the main cache 
    if[not count remainingcaches:cacheinfo`maincachepath; 
        :(::) 
    ];
    completecache cacheinfo`maincachepath 
};

 writetoken:{[dir;stage] 
    //accepts start or end and saves the current time as a timestamp to a flat file 
    //in dir as `:startTime or `:endTime
    (` sv (dir;stage)) set .z.P
}

detectcachetobuild:{ 
    latestcache:{cachename:"MyFirstCache";
    maincachepath:` sv (hsym `$.setter.cacheconfig.cacheRootDir),`$cachename; 
    caches:` sv' maincachepath,'(key maincachepath) except `$cachename;
    if[0 = count caches; :`cachename`newcache!(cachename,"_",string .z.P;1b)];
    cachewithmaxstarttime:starts ? max starts:cands!{get ` sv x,`start} each cands:key[d] where not `end in/: value d:caches!key each caches;
    if[("N"$.setter.cacheconfig.setter.interval) < .z.P - "P"$@[last "_" vs string cachewithmaxstarttime;13 16 19;:;"::."];:`cachename`newcache!(cachename,"_",string .z.P;1b)];
    :`cachename`newcache!(cachewithmaxstarttime;0b)}[]

    if[latestcache[`newcache];writetoken[latestcache[`cachename];`start]]
    if[latestcache[`newcache]; cachewithmaxstarttime:` sv maincachepath,`$latestcache[`newcache]]

    componentcaches:` sv' cachewithmaxstarttime,/:key .setter.cacheconfig.componentCaches
    incompletecomponentcaches:key[d2] where not `end in/: value d2:componentcaches!key each componentcaches
    writetoken[;`start] each incompletecomponentcaches;
    writetoken[;`setter1] each incompletecomponentcaches;
    `maincachepath`cachepath`args!(maincachepath;incompletecomponentcaches;enlist`)
}

generateandwritecache:{[cachepath; args] 
    cachename:last ` vs cachepath;
    connectiondetails: .anycache.config.componentCaches[cachename].dataSource;
    cache: connectiondetails".anycache.sampleanalytic[(::)]";
    .anymap.writetoanymap[cache;cachepath]
}

cleanupcache:{[cachepath] 
    //Want to just remove the component cache (cacheName) from the main cache directory in event of a failure
    hdel cachepath
}

completecache:{[maincachepath]
    cachename: string last ` vs maincachepath;
    latestcache:first system"ls -lt ",(1_string maincachepath), " | grep -vE '(^l|total)' | head -n 1 | awk '{print $NF}'";
    latestcachefilepath: ` sv maincachepath,`$latestcache
    writetoken[latestcachefilepath;`end];
    system"ln -sfn ", latestcache, " ", (1_string maincachepath), "/", cachename
    hdel each ` sv' maincachepath,'(key maincachepath) except (`$cachename;`$latestcache)
}

\d .