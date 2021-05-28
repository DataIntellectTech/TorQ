
Getting Started
===============

kdb+ is very customisable. Customisations are contained in q scripts (.q
files), which define functions and variables which modify the behaviour
of a process. Every q process can load a single q script, or a directory
containing q scripts and/or q data files. Hooks are provided to enable
the programmer to apply a custom function to each entry point of the
process (.z.p\*), to be invoked on the timer (.z.ts) or when a variable
in the top level namespace is amended (.z.vs). By default none of these
hooks are implemented.

We provide a codebase and a single main script, torq.q. torq.q is
essentially a wrapper for bespoke functionality which can load other
scripts/directories, or can be sourced from other scripts. Whenever
possible, torq.q should be invoked directly and used to load other
scripts as required. torq.q will:

-   ensure the environment is set up correctly;

-   define some common utility functions (such as logging);

-   execute process management tasks, such as discovering the name and
    type of the process, and re-directing output to log files;

-   load configuration;

-   load the shared code based;

-   set up the message handlers;

-   load any required bespoke scripts.

The behavior of torq.q is modified by both command line parameters and
configuration. We have tried to keep as much as possible in
configuration files, but if the parameter either has a global effect on
the process or if it is required to be known before the configuration is
read, then it is a command line parameter.

<a name="torq"></a>

Installing TorQ
------------

A guide on how to install TorQ using installation script [here](/TorQ/InstallGuide/).

Using torq.q
------------

torq.q can be invoked directly from the command line and be set to
source a specified file or directory. torq.q requires the 5 environment
variables to be set (see section envvar). If using a unix
environment, this can be done with the setenv.sh script. To start a
process in the foreground without having to modify any other files (e.g.
process.csv) you need to specify the type and name of the process as
parameters. An example is below.

    $ . setenv.sh
    $ q torq.q -debug -proctype testproc -procname test1 

To specify the parent process type, do:

    $ q torq.q -debug -parentproctype testparentproc -proctype testproc -procname test1

To load a file, do:

    $ q torq.q -load myfile.q -debug -proctype testproc -procname test1

It can also be sourced from another script. If this is the case, some of
the variables can be overridden, and the usage information can be
modified or extended. Any variable that has a definition like below can
be overridden from the loading script.

    myvar:@[value;`myvar;1 2 3]

The available command line parameters are:

  |Cmd Line Param|            Description|
  |-------------------------| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
  |-procname x -proctype y   |The process name and process type|
  |-parentproctype x         |The parent process type. Specifying will load in any additional code or configuration that is associated with another process type|
  |-procfile x               |The name of the file to get the process information from|
  |-load x \[y..z\]          |The files or database directory to load|
  |-loaddir x \[y..z\]       |Load all .q, .k files in specified directories|
  |-localtime                |Sets processes running in local time rather than GMT for log messages, timer calls etc. The change is backwards compatible; without -localtime flag the process will print logs etc. in GMT but can also have a different .z.P|
  |-trap                     |Any errors encountered during initialization when loading external files will be caught and logged, processing will continue|
  |-stop                     |Stop loading the file if an error is encountered but do not exit|
  |-noredirect               |Do not redirect std out/std err to a file (useful for debugging)|
  |-noredirectalias          |Do not create an alias for the log files (aliases drop any suffix e.g. timestamp suffix)|
  |-noconfig                 |Do not load configuration|
  |-nopi                     |Reset the definition of .z.pi to the initial value (useful for debugging)|
  |-debug                    |Equivalent to \[-nopi -noredirect\]|
  |-usage                    |Print usage info and exit|
  |-onelog                   |Writes all messages to stdout log file, note non-trapped errors will still be written to stderr log file|
  |-test x                   |Use for unit testing. Pass the location of tests directory|
  |-dataaccess path/to/csv   |Initialise the Dataaccess API in the process with table properties|
  

In addition any process variable in a namespace (.\*.\*) can be
overridden from the command line. Any value supplied on the command line
will take priority over any other predefined value (.e.g. in a
configuration or wrapper). Variable names should be supplied with full
qualification e.g. -.servers.HOPENTIMEOUT 5000.

<a name="env"></a>

Using torq.sh
---------------------

torq.sh is a script that runs processes in torq with added functionality,
one key enhancement is all the process configuration is now in one place.
The default process file is located in $KDBCONFIG/process.csv. This 
script is only available on Linux. It requires environment variables to 
be set, similar to torq.q. A usage statement for the script can be seen 
by running the following in a unix environment: `./torq.sh`.


Environment Variables 
---------------------

Five environment variables are required:

  |Environment Variable|   Description|
  |----------------------| -----------------------------------------------------|
  |KDBCONFIG              |The base configuration directory|
  |KDBCODE                |The base code directory|
  |KDBLOGS                |Where standard out/error and usage logs are written|
  |KDBHTML                |Contains HTML files|
  |KDBLIB                 |Contains supporting library files|


torq.q will check for these and exit if they are not set. If torq.q is
being sourced from another script, the required environment variables
can be extended by setting .proc.envvars before loading torq.q.

<a name="procid"></a>

Process Identification
----------------------

At the crux of AquaQ TorQ is how processes identify themselves. This is
defined by two required variables - .proc.proctype and .proc.procname
which are the type and name of the process respectively. An optional
variable parentproctype allows an inital codebase and configuration to
be loaded. The two required  values determine the code base and
configuration loaded, and how they are connected to by other processes.
If both of the required variables are not defined, TorQ will attempt
to use the port number a process was started on to determine the code
base and configuration loaded.

The most important of these is the proctype. It is up to the user to
define at what level to specify a process type. For example, in a
production environment it would be valid to specify processes of type
“hdb” (historic database) and “rdb” (real time database). It would also
be valid to segregate a little more granularly based on approximate
functionality, for example “hdbEMEA” and “hdbAmericas”. In this example
it may be sensible to set the parentproctype as "hdb" and putting all
shared code in the "hdb" configuration to be loaded first with the
region-specific configuration being loaded after. The actual
functionality of a process can be defined more specifically, but this
will be discussed later. The procname value is used solely for
identification purposes. A process can determine its type and name in a
number of ways:

1.  From the process file in the default location of
    $KDBCONFIG/process.csv;

2.  From the process file defined using the command line parameter
    -procfile;

3.  From the port number it is started on, by referring to the process
    file for further process details;

4.  Using the command line parameters -proctype and -procname;

5.  By defining .proc.proctype and .proc.procname in a script which
    loads torq.q.

For options 4 and 5, both parameters must be defined using that method
or neither will be used (the values will be read from the process file).

For option 3, TorQ will check the process file for any entries where the
port matches the port number it has been started on, and deduce it’s
proctype and procname based on this port number and the corresponding
hostname entry.

The process file has format as below.

    aquaq$ cat config/process.csv 
    host,port,proctype,procname,U,localtime,g,T,w,load,startwithall,extras,qcmd
    aquaq,9997,rdb,rdb_europe_1,appconfig/passwords/accesslist.txt,1,1,3,,${KDBCODE}/processes/rdb.q,1,,q
    aquaq,9998,hdb,hdb_europe_1,appconfig/passwords/accesslist.txt,1,1,60,4000,${KDBHDB},1,,q
    aquaq,9999,hdb,hdb_europe_2,appconfig/passwords/accesslist.txt,1,1,60,4000,${KDBHDB},1,,q

The process will read the file and try to identify itself based on the
host and port it is started on. The host can either be the value
returned by .z.h, or the ip address of the server. If the process can
not automatically identify itself it will exit, unless proctype and
procname were both passed in as command line parameters. If both of
these parameters are passed in then default configuration settings will
be used.

The parameters following procname set the following:

  |Parameter                        |  Description|
  |---------------------------------| ----------------------------|
  |U                                |  Authentication requiring a usr:pwd file|
  |localtime                        |  Sets process running in local time rather than GMT|
  |g                                |  Garbage collection immediate (1) or deferred (0)|
  |T                                |  Timeout in seconds for client queries, 0 for no timeout|
  |w                                |  Workspace MB limit|
  |load                             |  Files or database directory to load|
  |startwithall                     |  Determine if process is started when all is specified| 
  |extras                           |  Specify any additional parameters|
  |qcmd                             |  Allows different versions of q to be used or different command line options - rlwap, numactl|

Where U/g/T/w are standard q command line arguments and localtime and 
load are TorQ command line parameters. 

Running processes using torq.sh
-------

torq.sh is able to start or stop processes seperately, in a batch or 
all at once. Before a process is started/stopped the script will 
check that the process is not already running before attempting to 
start/stop a process, a time of when this is executed is printed to screen.
```
$ ./torq.sh start rdb1 hdb1 tickerplant1
    15:42:00 | Starting rdb1...
    15:42:00 | hdb1 already running
    15:42:00 | Starting tickerplant1...
            
$ ./torq.sh stop all
    15:46:19 | Shutting down hdb1...
    15:46:19 | Shutting down hdb2...
```
A status summary table of all the processes can be printed to screen, 
the summary provides information on the time the process was checked, 
process name, status and the port number and PID of that process.
```
$ ./torq.sh summary
    TIME     | PROCESS        | STATUS | PORT   | PID
    11:33:59 | discovery1     | up     | 41001  | 14426
    11:33:59 | tickerplant1   | down   |
```
It is possible to view the underlying start code for all processes. 
This is useful if another available command line parameter was required 
for start up. 
```
$ ./torq.sh print discovery1 
    Start line for discovery1:
    nohup q deploy/torq.q -procname discovery1 -stackid 41000 -proctype discovery -U appconfig/passwords/accesslist.txt -localtime 1 -g 0 -load deploy/code/processes/discovery.q -procfile deploy/appconfig/process.csv </dev/null > deploy/logs/torqdiscovery1.txt 2>&1 &
```
The debug command line parameter can be appended to the start line 
straight from torq.sh to start a process in debug mode. Note it is only 
possible to start one process at a time in debug mode.
```
$ ./torq.sh debug tickerplant1 
```
If a process name not present in the process.csv is used, the input 
process name will return as an invalid input. To see a list of all the 
processes in the process.csv see below.
```
$ ./torq.sh procs
```
A different process file can be used with this script from the command 
line. The argument following the csv flag needs to be a full path to 
the process.csv.
```
$ ./torq.sh start all -csv ${KDBAPPCONFIG}/process.csv
```
To add/override the default values in the g, T, w, or extras column the 
extras flag can be used in this script. 
```
$ ./torq.sh start rdb1 -extras -T 60 -w 4000
$ ./torq.sh start sort1 -extras -s -3
```

Using the Code Profiler with torq.sh
------------------------------------

KDB 4.0 includes an experimental built-in call-stack snapshot primitive that allows
building a sampling profiler.  The profiler uses the new function [`.Q.prf0`](https://code.kx.com/q/ref/dotq/#qprf0-code-profiler). 

Requirements and documentation of the new code profiler by kx can be found [here](https://code.kx.com/q/kb/profiler/).

Assuming a process is running, you can run the code below as an example in the command line.
Note that this `top` function currently only allows a single process as an argument and
multiple processes is not currently supported.

```
$ ./torq.sh top rdb1
```

This uses the `top.q` script given by kx (description found [here](https://code.kx.com/q/kb/profiler/))
which will show an automatically updated display of functions most heavily 
contributing to the running time. The display has the following fields:

|Field                            |  Description|
|---------------------------------| ----------------------------|
|self                             |  the percentage of time spent in the function itself|
|total                            |  percentage of time spent in the function including all descendants|
|name                             |  the name of the function|
|file                             |  the file path where the function is located|


<a name="logging"></a>

Logging
-------

By default, each process will redirect output to a standard out log and
a standard error log, and create aliases for them. These will be rolled
at midnight on a daily basis. They are all written to the $KDBLOGS
directory. The log files created are:

  |Log File|                          Description|
  |---------------------------------| ----------------------------|
  |out\_\[procname\]\_\[date\].log   |Timestamped out log|
  |err\_\[procname\]\_\[date\].log   |Timestamped error log|
  |out\_\[procname\].log             |Alias to current log log|
  |err\_\[procname\].log             |Alias to current error log|

 
The date suffix can be overridden by modifying the .proc.logtimestamp
function and sourcing torq.q from another script. This could, for
example, change the suffixing to a full timestamp.

In the case where -onelog is flagged TorQ will attempt to redirect
all output to the out log file, unfortunately this is not perfect.

TorQ uses \1 and \2 to redirect stderr and stdout, onelog only
overrides handled errors to the \1 redirect. This is because
there are issuses with redirecting both to the same file, (the ordering
of messages will be incorrect) the issue is with KDB+ rather than
with TorQ.

Because of this errors that are raised by KDB+ and unhandled are still
directed to the err log file because \1 and \2 cannot be redirected to
the same file.

<a name="config"></a>

Configuration Loading
---------------------

### Default Configuration Loading

Default process configuration is contained in q scripts, and stored in
the $KDBCONFIG /settings directory. Each process tries to load all the
configuration it can find and will attempt to load three configuration
files in the below order:-

-   default.q: default configuration loaded by all processes. In a
    standard installation this should contain the superset of
    customisable configuration, including comments.

-   [parentproctype].q: configuration for a specific parent process
    type (only if parentproctype specified).

-   [proctype].q: configuration for a specific process type.

-   [procname].q: configuration for a specific named process.

The only one which should always be present is default.q. Each of the
other scripts can contain a subset of the configuration variables, which
will override anything loaded previously.

### Application Configuration Loading

Application specific configuration can be stored in a user defined
directory and made visible to TorQ by setting the $KDBAPPCONFIG
environment variable. If $KDBAPPCONFIG is set, then TorQ will search
the $KDBAPPCONFIG/settings directory and load all configuration it can
find. Application configuration will be loaded after all default
configuration in the following order:-

-   default.q: Application default configuration loaded by all
    processes.

-   [\[parentproctype\]]{}.q : Application specific configuration for a
    specific parent process type (only if parentproctype specified).

-   [\[proctype\]]{}.q: Application specific configuration for a
    specific process type.

-   [\[procname\]]{}.q: Appliction specific configuration for a specific
    named process.

All loaded configuration will override anything loaded previously. None
of the above scripts are required to be present and can contain a subset
of the default configuration variables from the default configuration
directory.

All configuration is loaded before code.

### Application Dependency

TorQ will automatically check application version and dependency
information. TorQ will check the $KDBAPPCONFIG directory for a dependency.csv
file. This file should contain information in the format:

|app  |version |dependency           |
|-----|--------|---------------------|
|app0 |1.0.0   |app1 1.1.1;app2 2.1.0|

TorQ will also search the $KDBCONFIG directory for the TorQ dependency.csv file.
If any of the dependency versions exceed application versions, TorQ will exit
and log the error. 

If no dependency files are supplied, TorQ will run as normal. However, if only an 
application dependency file is supplied, TorQ will exit and log the error.

Each version number can be up to 5 digits in length, separated by '.' and 
the current kdb+ version will be automatically added with the format
major.minor.yyyy.mm.dd

<a name="code"></a>

Code Loading
------------

Code is loaded from the $KDBCODE directory. There is also a common
codebase, a codebase for each process type, and a code base for each
process name, contained in the following directories and loaded in this
order:

-   $KDBCODE/common: shared codebase loaded by all processes;

-   $KDBCODE/\[parentproctype\]: code for a specific parent process type
    (only if parentproctype specified);

-   $KDBCODE/\[proctype\]: code for a specific process type;

-   $KDBCODE/\[procname\]: code for a specific process name;

For any directory loaded, the load order can be specified by adding
order.txt to the directory. order.txt dictates the order that files in
the directory are loaded. If a file is not in order.txt, it will still
be loaded but after all the files listed in order.txt have been loaded.

In addition to loading code form $KDBCODE, application specific code can be 
saved in a user defined directory with the same structure as above, and made
visible to TorQ by setting the $KDBAPPCODE environment variable.

If this environment variable is set, TorQ will load codebase in the following order.

-   $KDBCODE/common: shared codebase loaded by all processes;

-   $KDBAPPCODE/common: application specific code shared by all processes;

-   $KDBCODE/\[parentproctype\]: code for a specific parent process type (only if
    parentproctype specified);

-   $KDBAPPCODE/\[parentproctype\]: application specific code for a specific parent
    process type (only if parentproctype specified);

-   $KDBCODE/\[proctype\]: code for a specific process type;

-   $KDBAPPCODE/\[proctype\]: application specific code for a specific process type;

-   $KDBCODE/\[procname\]: code for a specific process name;

-   $KDBAPPCODE/\[procname\]: application specific code for a specific process name;



Additional directories can be loaded using the -loaddir command line
parameter.

<a name="init"></a>

Initialization Errors
---------------------

Initialization errors can be handled in different ways. The default
action is any initialization error causes the process to exit. This is
to enable fail-fast type conditions, where it is better for a process to
fail entirely and immediately than to start up in an indeterminate
state. This can be overridden with the -trap or -stop command line
parameters. With -trap, the process will catch the error, log it, and
continue. This is useful if, for example, the error is encountered
loading a file of stored procedures which may not be invoked and can be
reloaded later. With -stop the process will halt at the point of the
error but will not exit. Both -stop and -trap are useful for debugging.

