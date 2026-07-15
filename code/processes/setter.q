// Setter process to set cache to disk

\d .anycache.setter

// Save cache down to disk
savecachedowntodisk:{[data;filePath] (hsym filePath) set data };

// Get location of cache config and load it in.
cacheconfiglocation:.proc.getconfigfile["cacheconfig.json"];
cacheconfig:.j.k raze read0 hsym first cacheconfiglocation;

\d .
