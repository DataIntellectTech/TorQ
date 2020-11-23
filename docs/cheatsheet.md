#Cheat Sheet

The purpose of this cheatsheet is to provide a very condensed guide to the bits you need to know about TorQ to either debug a running process, or to extend a TorQ stack. It does not replace the main body of documentation, and ordering is presumed order-of-relevance. The below uses the default configuration of TorQ and TorQ Finance Starter Pack, though a lot of it is configurable. 

##Debugging Running Processes

Each TorQ process has several internal tables which are useful. Connect to these using standard tools (qcon, an IDE etc.). Default user:pass of admin:admin will usually work. 

###.usage.usage
.usage.usage is used to track the queries that are executed against the process and is usually the first place to look for problems. Data is stored in memory for 24 hours and also persisted to disk in a usage_* file which is rolled daily. Every query and timer function call is logged, except for `.u.upd or `upd messages as this would bloat the log file considerably. Queries are logged before they are executed (status="b") and after (status="c" (complete) or status="e" (error)). 

If a query blocks a process and makes it unresponsive, it will have an entry (status="b") in the log file on disk.  

.usage.usage can be queried like any other kdb+ table to diagnose problems e.g. 

```
100 sublist `timer xdesc .usage.usage
select from .usage.usage where time within ... 
```

Note that this table is not especially helpful for gateway queries which are executed in an async call back manner. The gateway part of the the request will (should) usually have a very short run time so the back end services should be interrogated to see what slow parts are. 

[More info.](http://aquaqanalytics.github.io/TorQ/handlers/#logusageq)

##.timer.timer
.timer.timer shows information about the timer calls which are scheduled / have been run. Pay attention to the "active" field- if a timer call fails it will be removed from the timer (active=0b). To avoid this if required, wrap the function being executed by the timer in an error trap in the standard way. Use .timer.timer in combination with .usage.usage to work out if there are slow running/too frequent timers which are causing problems. 

[More info.](http://aquaqanalytics.github.io/TorQ/utilities/#timerq)

###Log Files 
Log files are stored in the log directory specified by KDBLOG. Each process creates 3 log files: 
 - an out log (out_*) with standard log messages
 - an error log file (err_*) with errors
 - a usage log file (usage_*) with a log of every request that hits the process. 

The error log file should be empty. Don't ignore the out_ log file, there is a lot of information in there which can be used to debug. One thing that is a bit awkward is that if there is an error then the error log message timestamp has to be matched off against the out message log messages. You can force a process to write to a single log file if the process is started with the -onelog command line parameter. 

###.clients.clients
This shows inbound connections (connections created into this process). It may have interesting information about connection open/close. If it has a lot of rows it means some clients are connecting and disconnecting frequently. [More info.](http://aquaqanalytics.github.io/TorQ/handlers/#trackclientsq)

###.servers.SERVERS
This shows outbound connections (connections created by this process to other processes). It's useful for tracking connections which have died. 

##Starting/Stopping and Debugging Processes
95% of clients run TorQ in production on Linux, the below applies to Linux only. Use the torq.sh script to start/stop/debug processes. [Become familiar with torq.sh, it has some very handy utilities.](http://aquaqanalytics.github.io/TorQ/gettingstarted/#using-torqsh)

```
newdeploy$ ./deploy/bin/torq.sh 
Arguments:
  start all|<processname(s)>               to start all|process(es)
  stop all|<processname(s)>                to stop all|process(es)
  print all|<processname(s)>               to view default startup lines
  debug <processname(s)>                   to debug a single process
  qcon <processname> <username>:<password> to qcon process
  procs                                    to list all processes
  summary                                  to view summary table
  top <processname>                        to show top.q statistics for a single process
Optional flags:
  -csv <fullcsvpath>                       to run a different csv file
  -extras <args>                           to add/overwrite extras to the start line
  -csv <fullcsvpath> -extras <args>        to run both
  -force                                   to force stop process(es) using kill -9
```

It is very, very difficult to try to debug a running process remotely. Do not do this. Use torq.sh to stop the process and run it in the foreground in a test environment. 

```
torquser@homer:/home/torquser/newdeploy$ ./deploy/bin/torq.sh stop rdb1
09:45:40 | Shutting down rdb1...
torquser@homer:/home/torquser/newdeploy$ ./deploy/bin/torq.sh debug rdb1
09:45:45 | Executing...
q /home/torquser/newdeploy/deploy/TorQ/latest/torq.q -stackid 43100 -proctype rdb -procname rdb1 -U /home/torquser/newdeploy/deploy/TorQApp/latest/appconfig/passwords/accesslist.txt -localtime 1 -g 1 -T 180 -load /home/torquser/newdeploy/deploy/TorQ/latest/code/processes/rdb.q  -procfile /home/torquser/newdeploy/deploy/TorQApp/latest/appconfig/process.csv  -debug

KDB+ 4.0 2020.06.18 Copyright (C) 1993-2020 Kx Systems
l64/ 24()core 128387MB torquser homer 127.0.1.1 EXPIRE 2021.06.30 AquaQ #59946

(::;::)
################################################################################
#                                                                              #
#                                 TorQ v3.8.0                                  #
#                               AquaQ Analytics                                #
#                    kdb+ consultancy, training and support                    #
#                                                                              #
#      For questions, comments, requests or bug reports please contact us      #
#                           w :     www.aquaq.co.uk                            #
#                           e : support@aquaq.co.uk                            #
#                                                                              #
#                         Running on kdb+ 4 2020.06.18                         #
#                                                                              #
#                      TorQ Finance Starter Pack v 1.9.1                       #
#                                                                              #
################################################################################
2020.11.23D09:45:45.294308000|homer|torq|/home/torquser/newdeploy/deploy/TorQ/latest/torq.q_3407_0|INF|init|trap mode (initialisation errors will be caught and thrown, rather than causing an exit) is set to 0
2020.11.23D09:45:45.294327000|homer|torq|/home/torquser/newdeploy/deploy/TorQ/latest/torq.q_3407_0|INF|init|stop mode (initialisation errors cause the process loading to stop) is set to 0
2020.11.23D09:45:45.294815000|homer|torq|/home/torquser/newdeploy/deploy/TorQ/latest/torq.q_3407_0|INF|init|attempting to read required process parameters proctype,procname from file /home/torquser/newdeploy/deploy/TorQApp/latest/appconfig/process.csv
2020.11.23D09:45:45.295076000|homer|torq|/home/torquser/newdeploy/deploy/TorQ/latest/torq.q_3407_0|INF|readprocfile|port set to 43102
2020.11.23D09:45:45.295109000|homer|torq|/home/torquser/newdeploy/deploy/TorQ/latest/torq.q_3407_0|INF|init|read in process parameters of proctype=rdb; procname=rdb1
2020.11.23D09:45:45.295616000|homer|rdb|rdb1|INF|fileload|config file /home/torquser/newdeploy/deploy/TorQ/latest/config/settings/default.q found
2020.11.23D09:45:45.295627000|homer|rdb|rdb1|INF|fileload|loading /home/torquser/newdeploy/deploy/TorQ/latest/config/settings/default.q
2020.11.23D09:45:45.296164000|homer|rdb|rdb1|INF|fileload|successfully loaded /home/torquser/newdeploy/deploy/TorQ/latest/config/settings/default.q

... SNIP ...

2020.11.23D09:45:47.432583000|homer|rdb|rdb1|INF|setpartition|rdbpartition contains - 2020.11.23
2020.11.23D09:45:47.432643000|homer|rdb|rdb1|INF|fileload|successfully loaded /home/torquser/newdeploy/deploy/TorQ/latest/code/processes/rdb.q
2020.11.23D09:45:47.432670000|homer|rdb|rdb1|INF|init|Resetting .z.pi to kdb+ default value
################################################################################
#                                                                              #
#                                 TorQ v3.8.0                                  #
#                               AquaQ Analytics                                #
#                    kdb+ consultancy, training and support                    #
#                                                                              #
#      For questions, comments, requests or bug reports please contact us      #
#                           w :     www.aquaq.co.uk                            #
#                           e : support@aquaq.co.uk                            #
#                                                                              #
#                         Running on kdb+ 4 2020.06.18                         #
#                                                                              #
#                      TorQ Finance Starter Pack v 1.9.1                       #
#                                                                              #
################################################################################
q)
```

Deploying

Deployments should be very simple on Linux [using the installation script](http://aquaqanalytics.github.io/TorQ/InstallGuide/). 

```
// pull in latest TorQ FSP install script 
wget https://raw.githubusercontent.com/AquaQAnalytics/TorQ-Finance-Starter-Pack/master/installlatest.sh

// execute it
bash installlatest.sh 

// It will finish with a message like below:
=============================================================
INSTALLATION COMPLETE
=============================================================
Installation is finished. For a regular installation, run it as follows in the working directory: ./deploy/bin/torq.sh start all

// you may need to change the value of KDBBASEPORT held in deploy/bin/setenv.sh to avoid conflicts with other TorQ stacks if running on a shared host
// once done execute start line and check it:

torquser@homer:/home/torquser/newdeploy$ ./deploy/bin/torq.sh start all
08:28:02 | Starting discovery1...
08:28:02 | Starting tickerplant1...
08:28:02 | Starting rdb1...
08:28:03 | Starting hdb1...
08:28:03 | Starting hdb2...
08:28:03 | Starting wdb1...
08:28:03 | Starting sort1...
08:28:03 | Starting gateway1...
08:28:04 | Starting monitor1...
08:28:04 | Starting housekeeping1...
08:28:04 | Starting reporter1...
08:28:04 | Starting filealerter1...
08:28:04 | Starting feed1...
08:28:05 | Starting chainedtp1...
08:28:05 | Starting sortworker1...
08:28:05 | Starting sortworker2...
08:28:05 | Starting metrics1...
08:28:06 | Starting iexfeed1...
08:28:06 | Starting dqc1...
08:28:06 | Starting dqcdb1...
08:28:06 | Starting dqe1...
08:28:06 | Starting dqedb1...

torquser@homer:/home/torquser/newdeploy$ ./deploy/bin/torq.sh summary
TIME      |  PROCESS        |  STATUS  |  PID    |  PORT
08:28:30  |  discovery1     |  up      |  23221  |  43101
08:28:30  |  tickerplant1   |  up      |  23333  |  43100
08:28:30  |  rdb1           |  up      |  23443  |  43102
08:28:30  |  hdb1           |  up      |  23553  |  43103
08:28:30  |  hdb2           |  up      |  23664  |  43104
08:28:31  |  wdb1           |  up      |  23770  |  43105
08:28:31  |  sort1          |  up      |  23883  |  43106
08:28:31  |  gateway1       |  up      |  23992  |  43107
08:28:31  |  killtick       |  down    |
08:28:31  |  monitor1       |  up      |  24122  |  43109
08:28:31  |  tpreplay1      |  down    |
08:28:32  |  housekeeping1  |  up      |  24231  |  43111
08:28:32  |  reporter1      |  up      |  24338  |  43112
08:28:32  |  filealerter1   |  up      |  24454  |  43113
08:28:32  |  feed1          |  up      |  24566  |  43114
08:28:32  |  chainedtp1     |  up      |  24675  |  43115
08:28:33  |  sortworker1    |  up      |  24782  |  43116
08:28:33  |  sortworker2    |  up      |  24889  |  43117
08:28:33  |  metrics1       |  up      |  24998  |  43118
08:28:33  |  iexfeed1       |  up      |  25107  |  43119
08:28:33  |  dqc1           |  up      |  25213  |  43120
08:28:34  |  dqcdb1         |  up      |  25592  |  43121
08:28:34  |  dqe1           |  up      |  25702  |  43122
08:28:34  |  dqedb1         |  up      |  25835  |  43123
```

Adding Custom Processes

