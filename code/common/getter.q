// Bootstrap script that will enable an existing process to load in cache getter functionalities.

\d .getter

// Get cache from disk
getcachefromdisk:{[filepath] get hsym filepath}

// Get location of cache config and load it in.
cacheconfiglocation:.proc.getconfigfile["cacheconfig.json"];
cacheconfig:.j.k raze read0 hsym first cacheconfiglocation;
cachename: cacheconfig`cachename;
asyncprocessname: cacheconfig`asyncprocessname;

loadcaches:{
    caches:key cacheconfig`componentcaches;
    cachefilepaths: ` sv' ((hsym `$cacheconfig`cacherootdir),2#`$cachename),/:`$(string caches),\:"/data";
    cachesdata:getcachefromdisk each cachefilepaths;
    cachevarnames:` sv' `.anycache.cache,/:caches;
    cachevarnames set' cachesdata;
}

// Example of args: `cache1`cache2!(`a`b`c! 1 2 3;`d`e`f!4 5 6)
requestnewcache:{[args]
    maincache:` sv (hsym `$cacheconfig`cacherootdir),(`$cachename),`$asyncprocessname, "_", string .z.P;
    (` sv maincache,`args) set args
}

\d .