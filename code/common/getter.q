// Bootstrap script that will enable an existing process to load in cache getter functionalities.

\d .anycache

// Get cache from disk
getter.getcachefromdisk:{[filepath] get hsym filepath};

// Get location of cache config and load it in.
getter.cacheconfiglocation:.proc.getconfigfile["cacheconfig.json"];
getter.cacheconfig:.j.k raze read0 hsym first getter.cacheconfiglocation;
getter.cachename: `$getter.cacheconfig`cachename;
getter.asyncprocessname: getter.cacheconfig`asyncprocessname;
getter.cacherootdir: `$getter.cacheconfig`cacherootdir;

// `.anycache.getter.loadcaches[]` loads the newest static build into `.anycache.cache.<name>`, one variable per component cache.
// Static mode only, as it reads through the `<cachename>` symlink.
//
// ```q
// q).anycache.getter.loadcaches[]
// q).anycache.cache.cache2
// sym  time                          bid   ask   bsize asize mode ex src  
// ------------------------------------------------------------------------
// AAPL 2026.10.28D11:31:43.521507000 78.28 79.37 131   99    B    N  DB   
// AIG  2026.10.28D11:31:43.521507000 33.24 34.85 41    77    A    O  GETGO
// AMD  2026.10.28D11:31:40.321631000 33.84 35.02 100   72    Z    N  GETGO
// ```
getter.loadcaches:{
    caches:key getter.cacheconfig`componentcaches;
    cachefilepaths: ` sv' ((hsym getter.cacherootdir),2#getter.cachename),/:`$(string caches),\:"/data";
    cachesdata:getter.getcachefromdisk each cachefilepaths;
    cachevarnames:` sv' `.anycache.cache,/:caches;
    cachevarnames set' cachesdata;
 };

// From any TorQ process, write a request with one query per component cache. It is saved as an args file in an `<asyncprocessname>_<timestamp>` folder:
//
// ```q
// q)q1:"select from trade where date = 2026.10.28, sym=`AAPL"
// q)q2:"select from quote where date = 2026.10.28, sym=`AAPL"
// q).anycache.getter.requestnewcache `cache1`cache2!{enlist[`query]!enlist x} each (q1;q2)
// `:<cacherootdir>/myfirstcache/asynccache_2026.10.28D09:35:57.161384000/args
// ```
getter.requestnewcache:{[args]
    maincache:` sv (hsym getter.cacherootdir),(getter.cachename),`$getter.asyncprocessname, "_", string .z.P;
    (` sv maincache,`args) set args
 };

\d .