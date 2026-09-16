// Bootstrap script that will enable an existing process to load in cache getter functionalities.

\d .anycache

// Get cache from disk
getter.getcachefromdisk:{[filepath] get hsym filepath};

// Get location of cache config and load it in.
getter.cacheconfiglocation:.proc.getconfigfile["cacheconfig.json"];
getter.cacheconfig:.j.k raze read0 hsym first getter.cacheconfiglocation;
getter.cachename: getter.cacheconfig`cachename;
getter.asyncprocessname: getter.cacheconfig`asyncprocessname;

getter.loadcaches:{
    caches:key getter.cacheconfig`componentcaches;
    cachefilepaths: ` sv' ((hsym `$getter.cacheconfig`cacherootdir),2#`$getter.cachename),/:`$(string caches),\:"/data";
    cachesdata:getter.getcachefromdisk each cachefilepaths;
    cachevarnames:` sv' `.anycache.cache,/:caches;
    cachevarnames set' cachesdata;
 };

// Example of args: `cache1`cache2!(`a`b`c! 1 2 3;`d`e`f!4 5 6)
getter.requestnewcache:{[args]
    maincache:` sv (hsym `$getter.cacheconfig`cacherootdir),(`$getter.cachename),`$getter.asyncprocessname, "_", string .z.P;
    (` sv maincache,`args) set args
 };

\d .