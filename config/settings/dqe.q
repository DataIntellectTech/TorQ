//data quality engine config

\d .dqe

configcsv:first .proc.getconfigfile["dqeconfig.csv"]

\d .proc
loadprocesscode:1b              // whether to load the process specific code defined at ${KDBCODE}/{process type}
