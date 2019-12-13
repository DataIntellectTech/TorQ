//data quality engine config

\d .dqe

configcsv:first .proc.getconfigfile["dqeconfig.csv"]
dqedbdir:hsym`$getenv[`KDBDQEDB]  // location to save dqe data

\d .proc
loadprocesscode:1b                // whether to load the process specific code defined at ${KDBCODE}/{process type}
