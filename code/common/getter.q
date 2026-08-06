// Bootstrap script that will enable an existing process to load in cache getter functionalities.

\d .getter

// Get cache from disk
getcachefromdisk:{[filePath] get hsym filePath}

// Get location of cache config and load it in.
cacheconfiglocation:.proc.getconfigfile["cacheconfig.json"];
cacheconfig:.j.k raze read0 hsym first cacheconfiglocation;

loadcaches:{
    cachename:"MyFirstCache";
    caches:key cacheconfig`componentCaches;
    cachefilepaths: ` sv' ((hsym `$cacheconfig`cacheRootDir),2#`$cachename),/:`$(string caches),\:"/data";
    cachesdata:getcachefromdisk each cachefilepaths;
    cachevarnames:` sv' `.anycache.cache,/:caches;
    cachevarnames set' cachesdata;
}

requestnewcache:{[cachename; args]
    cachename:"MyFirstCache";
    args:`cache1`cache2!(`a`b`c! 1 2 3;`d`e`f!4 5 6);
    processname:"AsyncCache";
    maincache:` sv (hsym `$cacheconfig`cacheRootDir),(`$cachename),`$processname, "_", string .z.P;
    (` sv maincache,`args) set args
}

\d .