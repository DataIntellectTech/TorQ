//data quality engine config

\d .dqe

configcsv:first .proc.getconfigfile["dqcconfig.csv"]
dqcdbdir:hsym`$getenv[`KDBDQCDB]  // location to save dqc data
hdbdir:hsym`$getenv[`KDBHDB]      // for locating the sym file
utctime:1b                        // define whether this process is on UTC time or not
partitiontype:`date               // default partition type to date
writedownperiod:0D00:05:00        // period for writedown
getpartition:{@[value;`.dqe.currentpartition;(`date^partitiontype)$(.z.D,.z.d)utctime]}

\d .proc
loadprocesscode:1b                // whether to load the process specific code defined at ${KDBCODE}/{process type}
