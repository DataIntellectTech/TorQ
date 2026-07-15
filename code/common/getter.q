// Bootstrap script that will enable an existing process to load in cache getter functionalities.

\d .getter

// Get cache from disk
getcachefromdisk:{[filePath] load hsym filePath}

\d .
