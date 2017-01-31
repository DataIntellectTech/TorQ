
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

  

In addition any process variable in a namespace (.\*.\*) can be
overridden from the command line. Any value supplied on the command line
will take priority over any other predefined value (.e.g. in a
configuration or wrapper). Variable names should be supplied with full
qualification e.g. -.servers.HOPENTIMEOUT 5000.

<a name="env"></a>

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
defined by two variables - .proc.proctype and .proc.procname which are
the type and name of the process respectively. These two values
determine the code base and configuration loaded, and how they are
connected to by other processes. If both of these are not defined, the
TorQ will attempt to use the port number a process was started on to
determine the code base and configuration loaded.

The most important of these is the proctype. It is up to the user to
define at what level to specify a process type. For example, in a
production environment it would be valid to specify processes of type
“hdb” (historic database) and “rdb” (real time database). It would also
be valid to segregate a little more granularly based on approximate
functionality, for example “hdbEMEA” and “hdbAmericas”. The actual
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
    host,port,proctype,procname
    aquaq,9997,rdb,rdb_europe_1
    aquaq,9998,hdb,hdb_europe_1
    aquaq,9999,hdb,hdb_europa_2

The process will read the file and try to identify itself based on the
host and port it is started on. The host can either be the value
returned by .z.h, or the ip address of the server. If the process can
not automatically identify itself it will exit, unless proctype and
procname were both passed in as command line parameters. If both of
these parameters are passed in then default configuration settings will
be used.

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
    customisable configuration, including comments;

-   [proctype].q: configuration for a specific process type;

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

-   [\[proctype\]]{}.q: Application specific configuration for a
    specific process type.

-   [\[procname\]]{}.q: Appliction specific configuration for a specific
    named process.

All loaded configuration will override anything loaded previously. None
of the above scripts are required to be present and can contain a subset
of the default configuration variables from the default configuration
directory.

All configuration is loaded before code.

<a name="code"></a>

Code Loading
------------

Code is loaded from the $KDBCODE directory. There is also a common
codebase, a codebase for each process type, and a code base for each
process name, contained in the following directories and loaded in this
order:

-   $KDBCODE/common: shared codebase loaded by all processes;

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

