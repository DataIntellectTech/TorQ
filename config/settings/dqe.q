//data quality engine config

\d .dqe

configcsv:first .proc.getconfigfile["dqeconfig.csv"]
dqedbdir:hsym`$getenv[`KDBDQEDB]  // location to save dqe data
gmttime:1b                        // define whether this process is on gmt time or not
getpartition:{@[value;`.dqe.currentpartition;(`date^partitiontype)$(.z.D,.z.d)gmttime]}

\d .proc
loadprocesscode:1b                // whether to load the process specific code defined at ${KDBCODE}/{process type}
