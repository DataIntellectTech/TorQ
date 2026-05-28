\d .setter

saveCacheDowntoDisk:{[data;filePath] (hsym filePath) set data };
cacheConfigLocation:.proc.getconfigfile["cacheConfig.json"];		/ - location of the cache config configuration file
cacheConfig:.j.k raze read0 hsym first cacheConfigLocation;

\d .
