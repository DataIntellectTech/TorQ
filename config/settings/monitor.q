// Default configuration for the monitor process

\d .monitor 
configcsv: first .proc.getconfigfile["monitorconfig.csv"];                               //filepath to checkmonitor config csv file 
configstored:first .proc.getconfigfile["monitorconfig"];                                 //filepath to checkmonitor flat table file
runcheckinterval:0D00:00:05;                                                             //interval to run checks 
checkinginterval:0D00:00:07;                                                             //interval to identify that checks are not lagging 
cleartrackinterval:0D01:00:00;                                                           //interval to check tracks are under certain age in checktracker 
agecheck:0D12:00:00;                                                                     //if check over agecheck, delete from tracker
lagtime:0D00:01:00;                                                                      //if check has been running over this time, set to neg


//Enable loading
\d .proc
loadprocesscode:1b;                                                                     //whether to load process specific code defined at ${KDBCODE}/{process type} 

// Server connection details
\d .servers
CONNECTIONS:`ALL		                                                        // list of connections to make at start up
