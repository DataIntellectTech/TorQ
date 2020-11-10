# Unit Testing in TorQ

### Introduction

Unit testing is a software validation methodology where individual modules or 'units' of source code are tested to determine whether they work as intended. TorQ makes use of the [k4unit](https://code.kx.com/q/kb/unit-tests/) framework from Kx, where tests are written in CSV files and loaded into a Q process along with the testing code and are run line by line, with the results being stored in a table. This framework, when combined with the functionality of TorQ processes, yields a flexible and user-friendly testing framework.

### Test Basics

**My First Test**

In order to write and run a basic test, in a new folder create a CSV file with some basic tests in it, like the following:

```
action,ms,bytes,lang,code,repeat,minver,comment
comment,0,0,,this will be ignored,1,,""
before,0,0,q,aa:22,1,,"This sets a variable before the tests begin"
true,0,0,q,2=sum 1 1,1,,"A basic arithmetic check"
fail,0,0,q,2=`aa,1,,"This ought to fail"
after,0,0,q,bb:33,1,,"This code executes after the tests have run"
```

Then use the `torq.q` script to start up a TorQ process with the test flag pointing to the directory where the CSV is written and a debug flag so that the process outputs its logs into the prompt and stays alive:

```shell
$ q ${TORQHOME}/torq.q -proctype test -procname test1 -test /path/to/my/tests -debug
```

This will automatically load in the test code and all CSVs in that directory into a test TorQ process and run the tests in those files, then output the results to the screen.

**Simple RDB Test**

A similar scenario is when the test code is loaded into a 'production' TorQ process, ie. an RDB or a tickerplant, in order to test the functioning of that process. A simple RDB example can be seen here:

```
action,ms,bytes,lang,code,repeat,minver,comment
true,0,0,q,`segmentedtickerplant~.rdb.tickerplanttypes,1,,"Check the TP type"
true,0,0,q,all (null;{-11h=type x}) @' .rdb.subscribeto,1,,"Check RDB is subscribed to null symbol (all tables)"
true,0,0,q,1~count key .rdb.subcsv,1,,"Check that the subcsv exists"
```

These tests simply check that certain process variables have been set properly, and these are triggered similarly to the previous set, except that an RDB process is used to load in the tests rather than a 'blank' test process:

```shell
$ q ${TORQHOME}/torq.q -proctype rdb -procname rdb1 -test /path/to/my/tests -debug
```

### Integration Testing: WDB Subscription Tests

Once the basic concepts from before have been understood it is possible to generate much more complex testing scenarios. Often it will be necessary to test interactions between different processes, in which case you will need more than just the one testing process. In this example test we are examining the interaction between a Segmented Tickerplant (STP) and three WDBs, one of which is subscribed to everything, one to a subset of syms and the other to a subset of tables. In order to facilitate this, we need to make some additions to our test directory. As well as the CSVs containing the tests themselves we now add three more files: `process.csv`, `run.sh` and `settings.q`, and we shall examine these in more detail.

**process.csv**

An easy way to spin up multiple custom processes is to pass a custom version of `process.csv` into the TorQ start script. Our file will contain a discovery process, three WDBs and an STP and can be seen here:

```
host,port,proctype,procname,U,localtime,g,T,w,load,startwithall,extras,qcmd
localhost,{KDBBASEPORT}+100,discovery,discovery1,${TORQHOME}/appconfig/passwords/accesslist.txt,1,0,,,${KDBCODE}/processes/discovery.q,1,,q
localhost,{KDBBASEPORT}+101,wdb,wdball,${TORQHOME}/appconfig/passwords/accesslist.txt,1,1,,,${KDBCODE}/processes/wdb.q,1,-.wdb.tickerplanttypes segmentedtickerplant,q
localhost,{KDBBASEPORT}+102,wdb,wdbsymfilt,${TORQHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/wdb.q,1,-.wdb.tickerplanttypes segmentedtickerplant -.wdb.subsyms GOOG,q
localhost,{KDBBASEPORT}+103,wdb,wdbtabfilt,${TORQHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/wdb.q,1,-.wdb.tickerplanttypes segmentedtickerplant -.wdb.subtabs quote,q
localhost,{KDBBASEPORT}+104,segmentedtickerplant,stp1,${TORQHOME}/appconfig/passwords/accesslist.txt,1,0,,,${KDBCODE}/processes/segmentedtickerplant.q,1,-schemafile ${TORQHOME}/database.q,q
```

As we can see here, three WDBs are being started up but with different parameters in the 'extras' column, meaning they will have different subscription behaviour. 

**run.sh**

Since we need to run multiple shell commands to bring up all the processes and run the tests, it makes sense to move them to a file:

```sh
#!/bin/bash

# Path to test directory
testpath=${KDBTESTS}/demo

# Start procs
${TORQHOME}/torq.sh start all -csv ${testpath}/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -procfile ${testpath}/process.csv -debug

# Shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/process.csv
```

The first piece of code in this script simply sets a variable with the path for the test directory. Then the discovery, STP and WDB processes are started, with the custom CSV flag pointing to the file we just created above. If only a subset of the processes in that file are needed then they can be called by name instead of using 'all'. Next, our test process is started up with some extra flags. The `-load` flag allows other q files to be loaded, in this case we are loading a file of helper functions defined in the `KDBTESTS` directory and the `settings.q` file which will be explored in greater depth shortly. There is also a `-procfile` flag in use which, again, points to our custom process CSV, and this more easily allows the use of TorQ connection management in tests. Finally, once all the tests have been run and the test process exited, all the other processes are brought down. The tests can now be run from the command line with a simple `/path/to/tests/run.sh`.

**settings.q**

This file, while not strictly speaking necessary, is a very handy place to store variables and functions that will be used in the tests rather than having to declare them in the CSV itself. In this example we are storing TorQ connection parameters and test updates for the trade and quote tables:

```q
// IPC connection parameters
.servers.CONNECTIONS:`wdb`segmentedtickerplant`tickerplant;
.servers.USERPASS:`admin:admin;

// Test updates
testtrade:((5#`GOOG),5?`4;10?100.0;10?100i;10#0b;10?.Q.A;10?.Q.A;10#`buy);
testquote:(10?`4;(5?50.0),50+5?50.0;10?100.0;10?100i;10?100i;10?.Q.A;10?.Q.A;10#`3);
```

**WDB Tests**

The following CSV shows a fairly straightforward use of this setup:

```
action,ms,bytes,lang,code,repeat,minver,comment
before,0,0,q,.servers.startup[],1,,"Start TorQ connection management"
before,0,0,q,.proc.sys "sleep 2",1,,"Wait for proc to start"
before,0,0,q,stpHandle:gethandle[`stp1],1,,"Open STP handle"
before,0,0,q,wdbHandles:`all`sym`tab!gethandle each `wdball`wdbsymfilt`wdbtabfilt,1,,"Open WDB handles"
before,0,0,q,t1:wdbHandles[`all`sym] @\: "count trade",1,,"Get initial trade table counts"
before,0,0,q,q1:(value wdbHandles) @\: "count quote",1,,"Get initial quote table counts"
run,0,0,q,"stpHandle @/: `.u.upd ,/: ((`trade;testtrade);(`quote;testquote))",1,,"Send trade and quote updates to STP"
run,0,0,q,.proc.sys "sleep 2",1,,"Wait for updates to publish"
true,0,0,q,(t1+10 5)~wdbHandles[`all`sym] @\: "count trade",1,,"Check trade update was correctly published"
true,0,0,q,(q1+10 0 10)~(value wdbHandles) @\: "count quote",1,,"Check quote update was correctly published"
```

The first thing that happens is that TorQ connection management is set up, then handles are opened to the STP and WDBs and some test updates are sent to the STP. Finally, the test process grabs the latest table counts from the WDBs and checks they have updated correctly. Note that functions and variables not defined in the test are brought in from the settings and helper function files.

Our test directory now looks like this:

```
wdbtests
|---- process.csv
|---- run.sh
|---- settings.q
|---- test.csv
```

### Adding functionality to the run script

In order to make our tests more dynamic and useful there are a few things we can do. In the `KDBTESTS` directory there is a `flagparse.sh` script which contains some basic code for parsing command line flags. If we add this line to the top of our run script:

```shell
source $KDBTESTS/flagparse.sh
```

We can now pass flags to our run script, and these are as follows:

| **Flag**       | **Description**                                              |
| -------------- | ------------------------------------------------------------ |
| `-d`           | Starts the test process in debug mode                        |
| `-s`           | Starts the test process in debug and stop mode (thrown out to q prompt on error or test failure) |
| `-w`           | Writes test results to CSVs on disk                          |
| `-q`           | Starts the test process in quiet mode                        |
| `-r timestamp` | Passes a timestamp into the tests for on-disk versioning     |

The other addition to be made is a `-testresults` flag to the TorQ start line in the run script. This passes in a folder where the test process will store its logs and test results in a date-partitioned folder structure. Our run script now looks like the following:

```shell
#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/demo

# Start procs
${TORQHOME}/torq.sh start discovery1 stp1 wdball wdbsymfilt wdbtabfilt -csv ${testpath}/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/demo/results/ \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  $debug $stop $write $quiet

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 stp1 wdball wdbsymfilt wdbtabfilt -csv ${testpath}/process.csv
```

Near the end we have four variables which are optional flags that will be added by the flag parser script. We now have plenty of options when it comes to running the script:

```shell
./run.sh -d  									                  # Run in debug mode
./run.sh -s										                  # Run in debug and stop mode
./run.sh -r 2020.10.12D16:34:44.261143000 -wq	  # Run in quiet mode, pass in a runtime and write results to disk
```

### Running Multiple Test Sets

When testing a large piece of functionality it is very likely that there will a large number of tests to run. It is advised in such a case that the tests are split up into different technical groupings, each with their own folder with test CSVs, process and settings files and run scripts. This is essentially creating an isolated environment for each group of tests. The issue though is that it becomes cumbersome to run all tests, and so a script has been created which executes all the run scripts in each of the directories, saves their results to disk and displays them at the end of the run. 

The `runall.q` script lives in the `KDBTESTS` directory and it takes two arguments, `-rundir` and `-resdir`, which are the top level directory where your test sub-folders live, and the folder where the test logs and results are kept respectively. This script runs each of the `run.sh` scripts in each of the sub-folders in the `-rundir` folder in write and quiet mode, passing in the current timestamp so that all will be saved to disk in an easily-versioned manner. An example run would look like the following:

```shell
q runall.q -rundir /path/to/top/test/folder/ -resdir /path/to/results/folder/
```

### Debugging Tests

In the scenario where there are a large number of tests spread across several folders, you can use the run-all mechanic to test them all. However, say there is an error in one of the test files. Normally, this would be fairly difficult to track down and deal with, but the features of this framework make it much easier. At the end of the run, three things will be shown on the console, a results table, a fails table and dictionary of error logs and any errors in them. Any tests that fail will be displayed in the fails table and any code errors that occur will be logged to disk and displayed in the dictionary, and both of these sources contain the file the test was in, the line number it is on and the code itself. This information may be enough to solve the issue, but if not, we can examine the tests themselves. 

Since we know what file the test errors/failures are coming from we can execute the run script in its folder with the `-d` flag, which will put all the logs for the process out onto the screen so we can see what is happening, and then the process remains alive at the end so we can debug in the process. The other option is to run the script with the `-s` flag, where you will be thrown out to the q prompt whenever the tests hit an error or a failed test, which will allow you to debug the code at the point where it appears in the testing order.

### Notes on Best Practice

Here are some recommendations on making test development more straightforward:

- Use TorQ connection management when dealing with multiple processes
- Run the tests from a 'blank' test process where possible, as this ensures that test code and process code don't get in each other's way
- Put any variable or function declarations in a settings file so as not to clutter the test code
- If there are a large number of tests, split into folders of related tests