\d .dqe
dqedbdir:hsym`$getenv[`KDBDQEDB]  // location to save dqc data
hdbdir:hsym`$getenv[`KDBHDB]      // for locating the sym file
gmttime:1b                        // define whether this process is on gmt time or not
partitiontype:`date               // default partition type to date
getpartition:{@[value;`.dqe.currentpartition;(`date^partitiontype)$(.z.D,.z.d)gmttime]}
writedownperiodengine:0D00:05:00  // period for writedown

\d .proc
loadprocesscode:1b                // whether to load the process specific code defined at ${KDBCODE}/{process type}
