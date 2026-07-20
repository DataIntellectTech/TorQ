// Setter process to set cache to disk

\d .anycache.setter

// Save cache down to disk
savecachedowntodisk:{[data;filePath] (hsym filePath) set data };

// Get location of cache config and load it in.
cacheconfiglocation:.proc.getconfigfile["cacheconfig.json"];
cacheconfig:.j.k raze read0 hsym first cacheconfiglocation;

\d .

\d .anycache.setter

getcachefromdisk:{ .proc.loadf }

detectAndWriteCache:{ 
    cacheInfo:detectCacheToBuild[];
    if[not count cacheInfo;
        :(::)
    ];
    writeToken[cachePath:cacheInfo`cachePath;`start]; 
    //Included some basic error trapping here 
    success:@[`generateAndWriteCache[cachePath];cacheInfo`args;0b]; 
    if[not success; 
        cleanupCache cachePath; 
        :(::) 
    ];
    writeToken[cachePath;`end]; 
    //Can eject now if there are still caches to be built in the main cache 
    If[not count remainingCaches:cacheInfo`mainCachePath; 
        :(::) 
    ];
    completeCache cacheInfo`mainCachePath 
};

 writeToken:{[dir;stage] 
    //accepts start or end and saves the current time as a timestamp to a flat file 
    //in dir as `:startTime or `:endTime
    (` sv (dir;stage)) set .z.P
}

detectCacheToBuild:{ 
    latestCache:{cacheName:"MyFirstCache";
    mainCachePath:` sv (hsym `$.setter.cacheconfig.cacheRootDir),`$cacheName; 
    caches:` sv' mainCachePath,'(key mainCachePath) except `$cacheName;
    if[0 = count caches; :`cacheName`newCache!(cacheName,"_",string .z.P;1b)];
    cacheWithMaxStartTime:starts ? max starts:cands!{get ` sv x,`start} each cands:key[d] where not `end in/: value d:caches!key each caches;
    if[("N"$.setter.cacheconfig.setter.interval) < .z.P - "P"$@[last "_" vs string cacheWithMaxStartTime;13 16 19;:;"::."];:`cacheName`newCache!(cacheName,"_",string .z.P;1b)];
    :`cacheName`newCache!(cacheWithMaxStartTime;0b)}[]

    if[latestCache[`newCache];writeToken[latestCache[`cacheName];`start]]
    if[latestCache[`newCache]; cacheWithMaxStartTime:` sv mainCachePath,`$latestCache[`newCache]]

    componentCaches:` sv' cacheWithMaxStartTime,/:key .setter.cacheconfig.componentCaches
    incompleteComponentCaches:key[d2] where not `end in/: value d2:componentCaches!key each componentCaches
    writeToken[;`start] each incompleteComponentCaches;
    writeToken[;`setter1] each incompleteComponentCaches;
    `mainCachePath`cachePath`args!(mainCachePath;incompleteComponentCaches;enlist`)
}

generateAndWriteCache:{[cachePath; args] 
cachename:last ` vs cachePath;
connectiondetails: .anycache.config.componentCaches[cachename].dataSource;
cache: connectiondetails".anycache.sampleanalytic[(::)]";
.anymap.writeToAnyMap[cache;cachePath]
}

cleanupCache:{[cachePath] 
 //Want to just remove the component cache (cacheName) from the main cache directory in event of a failure
 hdel cachePath
}

completeCache:{[mainCachePath] 
    cacheName: string last ` vs mainCachePath;
    latestCache:first system"ls -lt ",(1_string mainCachePath), " | grep -vE '(^l|total)' | head -n 1 | awk '{print $NF}'";
    latestCacheFilePath: ` sv mainCachePath,`$latestCache
    writeToken[latestCacheFilePath;`end];
    system"ln -sfn ", latestCache, " ", (1_string mainCachePath), "/", cacheName
    hdel each ` sv' mainCachePath,'(key mainCachePath) except (`$cacheName;`$latestCache)
}

\d .