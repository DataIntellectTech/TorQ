# Cheat Sheet

The purpose of this cheatsheet is to provide a very condensed guide to the bits you need to know about TorQ to either debug a running process, or to extend a TorQ stack. It does not replace the main body of documentation, and ordering is presumed order-of-relevance. The below uses the default configuration of TorQ and TorQ Finance Starter Pack, though a lot of it is configurable. It's probably a good idea to read the [About](http://aquaqanalytics.github.io/TorQ/Overview/) section at least. 
## Debugging Running Processes
Each TorQ process has several internal tables which are useful. Connect to these using standard tools (qcon, an IDE etc.). Default user:pass of admin:admin will usually work. 

### .usage.usage
.usage.usage is used to track the queries that are executed against the process and is usually the first place to look for problems. Data is stored in memory for 24 hours and also persisted to disk in a usage_ file which is rolled daily. Every query and timer function call is logged, except for `` `.u.upd`` or `` `upd`` messages as this would bloat the log file considerably. Queries are logged before they are executed (status="b") and after (status="c" (complete) or status="e" (error)). 

If a query blocks a process and makes it unresponsive, it will have an entry (status="b") in the log file on disk.  

.usage.usage can be queried like any other kdb+ table to diagnose problems e.g. 

```
100 sublist `timer xdesc .usage.usage
select from .usage.usage where time within ... 
```

Note that this table is not especially helpful for gateway queries which are executed in an async call back manner. The gateway part of the request will (should) usually have a very short run time so the back end services should be interrogated to see what the slow parts are. 

[More info on usage logs.](http://aquaqanalytics.github.io/TorQ/handlers/#logusageq)

### .timer.timer
.timer.timer shows information about the timer calls which are scheduled / have been run. Pay attention to the "active" field- if a timer call fails it will be removed from the timer (active=0b). To avoid this if required, wrap the function being executed by the timer in an error trap in the standard way. Use .timer.timer in combination with .usage.usage to work out if there are slow running/too frequent timers which are causing problems. [More info.](http://aquaqanalytics.github.io/TorQ/utilities/#timerq)

### Log Files 
Log files are stored in the log directory specified by the environment variable KDBLOG. Each process creates 3 log files: 

- an out log (out_ ) with standard log messages
- an error log file (err_ ) with errors
- a usage log file (usage_ ) with a log of every request that hits the process. 

The error log file should be empty. Don't ignore the out_ log file, there is a lot of information in there which can be used to debug. One thing that is a bit awkward is that if there is an error then the error log message timestamp has to be matched off against the out message log messages. You can force a process to write to a single log file if the process is started with the -onelog command line parameter, or use system commands similar to below to sync them up when required.

```
# format the out and err logs into a single output sorted on time
sort -nk1 out_log err_log 

# combine into a single output, show the last n rows of output before an error 
sort -nk1 out_log err_log | grep -B n ERR 
``` 

### .clients.clients
This shows inbound connections (connections created into this process). It may have interesting information about connection open/close. If it has a lot of rows it means some clients are connecting and disconnecting frequently. [More info.](http://aquaqanalytics.github.io/TorQ/handlers/#trackclientsq)

### .servers.SERVERS
This shows outbound connections (connections created by this process to other processes). It's useful for tracking connections which have died. 

## Starting, Stopping and Debugging Processes
95% of TorQ installations in production run on Linux, and the below applies to Linux only. Use the torq.sh script to start/stop/debug processes. [Become familiar with torq.sh, it has some very handy utilities.](http://aquaqanalytics.github.io/TorQ/gettingstarted/#using-torqsh)

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

**It is very, very difficult to try to debug a running kdb+ process remotely. Do not do this.** Use torq.sh to stop the process and run it in the foreground in a test environment. 

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
... snip ...
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

## Deploying

Deployments should be very simple on Linux [using the installation script](http://aquaqanalytics.github.io/TorQ/InstallGuide/). 

```bash
# pull in latest TorQ FSP install script 
wget https://raw.githubusercontent.com/AquaQAnalytics/TorQ-Finance-Starter-Pack/master/installlatest.sh
# execute it
bash installlatest.sh 
# It will finish with a message like below:
=============================================================
INSTALLATION COMPLETE
=============================================================
Installation is finished. For a regular installation, run it as follows in the working directory: ./deploy/bin/torq.sh start all
# you may need to change the value of KDBBASEPORT held in deploy/bin/setenv.sh to avoid conflicts with other TorQ stacks if running on a shared host
# once done execute start line and check it:
torquser@homer:/home/torquser/newdeploy$ ./deploy/bin/torq.sh start all
08:28:02 | Starting discovery1...
08:28:02 | Starting tickerplant1...
... snip ...
08:28:06 | Starting dqe1...
08:28:06 | Starting dqedb1...
torquser@homer:/home/torquser/newdeploy$ ./deploy/bin/torq.sh summary
TIME      |  PROCESS        |  STATUS  |  PID    |  PORT
08:28:30  |  discovery1     |  up      |  23221  |  43101
08:28:30  |  tickerplant1   |  up      |  23333  |  43100
08:28:30  |  rdb1           |  up      |  23443  |  43102
08:28:30  |  hdb1           |  up      |  23553  |  43103
... snip ...
```

## Modifying Existing Installations
We always try to esnure new versions of TorQ are backwardly compatible. Try to avoid modifying TorQ itself and instead make application specific modifications. The installation script deploys TorQ in a structure which keeps TorQ and the application separate, and this should be adhered to whenever possible. 

To modify the config for a process, do it either in the [config directory](http://aquaqanalytics.github.io/TorQ/gettingstarted/#configuration-loading) or as a command line start up parameter as- almost all config variables that are defined in a config file and exists in a non-root namespace can be overridden from the command line. 

To make a process load additional files, you can:

- append the additional files to the -load parameter on the start line
- append a set of directories of files using -loaddir on the start line
- place the files in one of the directories that is [loaded by default on start up](http://aquaqanalytics.github.io/TorQ/gettingstarted/#code-loading)

Start line modifications can be made in process.csv and will be picked up by torq.sh. Of these approaches, the latter is probably preferable. 

## Adding Custom Processes

When adding custom processes to TorQ it is important to [understand the significance of proctype](http://aquaqanalytics.github.io/TorQ/gettingstarted/#process-identification). In a nutshell, only processes which do exactly the same thing should have the same proctype. If two processes do roughly the same thing then -parentproctype can be used to share common functionality. Also there isn't any formal association between proctype and code name file name e.g. a process that loads code/processes/rdb.q can have any proctype we like. 

How TorQ [manages connections](http://aquaqanalytics.github.io/TorQ/conn/) is important. Avoid using hopen, use TorQ connection management.

TorQ uses the fail fast principle (if you are going to fail, may as well do it as quickly as possible). This helps avoid processes starting up in inconsistent or unexpected states. If running a process with the -debug option, add the -stop or -trap options to stop at, or trap and continue through, start up errors. 

Code is loaded in a specific order, which can be overridden. To determine the order, inspect the bottom of the torq.q script (the last 100 lines or so). Everything after the switch into the root namespace is relevant. 
