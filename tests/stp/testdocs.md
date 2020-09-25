## Repeatable Test Guide

This is a quick guide to setting up k4 unit tests for TorQ in a repeatable folder structure for all your testing needs!

**Test Directory Structure**

Under this system all the tests for a larger piece of TorQ functionality, eg. the Segmented Tickerplant, all sits in `tests/stp` and within this folder are several sub-folders for the specific pieces of sub-functionality being tested, for instance end-of-day behaviour. Each of these folders must contain *at least* the following elements:

- `run.sh` - a shell script for kicking off the tests
- `settings.q` - a file where constants/functions for these tests can be stored
- CSV files containing the tests

These shall be further explained below. One other file which may commonly be needed is `process.csv`, for cases where custom processes are needed to run the tests on. This is not necessary but will often be useful.

**Shell Script**

The script `run.sh` is used to start all the processes needed for the subset of tests in the folder, as well as starting the test process and bringing down any processes left over at the end. An example script can be seen here:

```shell
#!/bin/bash

# Start procs
${TORQHOME}/torq.sh start discovery1 rdball rdbsymfilt rdbonetab stp1 -csv ${KDBTESTS}/stp/periodend/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${KDBTESTS}/stp/periodend \
  -load ${KDBTESTS}/helperfunctions.q ${KDBTESTS}/stp/periodend/settings.q \
  -results ${KDBTESTS}/stp/results/ \
  -procfile ${KDBTESTS}/stp/periodend/process.csv \
  -debug

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 rdball rdbsymfilt rdbonetab stp1 -csv ${KDBTESTS}/stp/periodend/process.csv
```

The first line calls the `torq.sh` script on the TorQ home level and is using it to bring up several processes. In this particular instance it is starting these using a custom `process.csv` file, though if this isn't being used the `-csv` flag can be omitted. The second line uses the `torq.q` script to start the test process. In this case this is just a test process being linked into the TorQ framework, but this process can be an RDB or a Tickerplant. The `-test` flag tells it where to get test CSVs from, the `-load` flag tells it what auxiliary q files to load, in this case some helper functions and the local settings file. Process code can also be loaded in here. The `-results` flag tells it where to write test results to if they are being written to disk (more on this later), `-procfile` specifies a custom `process.csv` and `-debug` allows the process to stay up when tests are finished running.

The final line shuts down any processes that need shutting down.

**Settings File**

The file `settings.q` can be used to store anything that may be useful in the tests, which saves functions/constants having to be defined in the tests themselves. But there is only one thing that *needs* to be in this file and that is the boolean variable `.k4.savetodisk`. If this is set to true, the test results will be saved to disk and the test process will be exited as part of the run all tests mechanic, which will be explored later.

**Writing Tests**

The basics of writing k4 unit tests can be found [here](https://code.kx.com/q/kb/unit-tests/), so this is just some guidelines to writing tests under this framework. The file `helperfunctions.q` contains some useful functions for bringing processes up and down as well as getting handles for processes using TorQ's built-in connection management, and so for neatness' sake it is advised to use the functions in this file along with TorQ's connection management, and to store frequently used variables, such as a test trade table update, in the `settings.q` file.

**Run All Tests**

Since in this case we have our tests dispersed across various folders with separate run scripts it would be convenient firstly, to run them all in one go and secondly, to be able to store the results on disk. To address this, the `runtests.q` file in the root test folder has been modified to contain the function `.k4.writeres` which, when called, will save the current batch of test results and errors to CSV files on disk. This is called when the aforementioned settings variable `.k4.savetodisk` is true. in order to run all the tests on that level, a `runall.q` script has been created on the level above all the sub-functionality tests, for example, `tests/stp`. This function calls all the `run.sh` scripts in all the directories below it, where they exist, and then reads and displays the test results from disk.