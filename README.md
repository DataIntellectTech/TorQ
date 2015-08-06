![TorQ Logo](../master/html/img/AquaQ-TorQ-symbol-small.png)

The framework forms the basis of a production kdb+ system by implementing some core functionality and utilities on top of kdb+, allowing developers to concentrate on the application business logic. It incorporates as many best practices as possible, with particular focus on performance, process management, diagnostic information, maintainability and extensibility. Wherever possible, we have tried to avoid re-inventing the wheel and instead have used contributed code from code.kx.com (either directly or modified). This framework will be suitable for those looking to create a new kdb+ system from scratch or those looking to add additional functionality to their existing kdb+ systems.

[Have a skim through our brochure](../master/aquaq-torq-brochure.pdf?raw=true) for a bit more information.  The easiest way to get a production capture started is to download and install one of the [Starter Packs](https://github.com/AquaQAnalytics), or [read the manual](../master/AquaQTorQ.pdf?raw=true)

## Quick Start

To launch a process wrapped in the framework, you need to set the environment variables and give the process a type and name.  The type and name can be explicitly passed on the command line.  setenv.sh is an example of how to set the environment variables on a unix type system.  For a windows system, see http://www.computerhope.com/issues/ch000549.htm.  kdb+ expects all paths to be / (forward-slash) separated so all paths on all OSs should be forward-slash separated. 

To avoid standard out/err being redirected, used the -debug flag
``` 
./setenv.sh         /- Assuming unix type OS
q torq.q -proctype test -procname mytest -debug
```

To load a file, use -load
```
q torq.q -load mytest.q -proctype test -procname mytest -debug
```
This will launch the a process running within the framework with all the default values.  For the rest, read the document!

## Release Notes

- **1.0.0, Feb 2014**: 
  * Initial public release of TorQ
- **1.1.0, Apr 2014**: 
  * Added compression utilities, HTML5 utilities, housekeeping process, file alerter process, kdb+tick quick start
- **1.2.0, Sep 2014**:	
  * Tested on kdb+ 3.2
  * Added connections to external (non TorQ) processes using nonprocess.csv
  * Modified file alerter with optional switch to move or not move a file if any function fails to process the file
  * Discovery service(s) host:port(s) can be passed on the command line (.servers.DISCOVERY) to a process (this should enable complete bypassing of process.csv if required)
  * Add custom hook (.servers.connectcustom) which is invoked whenever a new connection is made (allows, for example, subscription to a new process)
  * Add optional application detail file ($KDBCONFIG/application.txt) to allow customisation of the start up banner (application version etc.)
  * If required env. variables (KDBCODE, KDBCONFIG, KDBLOG) are not set they will default to $QHOME/code, $QHOME/config, $QHOME/logs respectively (previously the process failed and exited)
- **2.0.1, May 2015**:  
  * Added RDB process which extends r.q from kdb+ tick.
  * Added WDB to write down data periodically throughout the day.  Extends w.q.
  * RDB and WDB allow seamless end-of-day event (no data outage, no tickerplant back pressure)
  * Added Reporting Process to run reports periodically and process the results
  * Added environment variable resolution to process.csv to allow greater portability.  If a process is started without a port specified it will look it up from process.csv based on the proctype and procname.
  * Added -localtime flag to allow process to run in localtime rather than GMT (log message, timer calls etc.).  The change is backwardly compatible - without -localtime flag the process will print logs etc. in GMT but can also have a different .z.P
  * Added Subscription code to manage multiple subscriptions to different data sources
  * Added email library which uses libcurl.  Used to send emails from TorQ processes
  * Added standard monitoring checks to the database code
  * Added data loader script.  Utility functions to load a directory of data into a database in chunks, sort and part at the end
  * Added tickerplant log recovery utilities to recover as many messages as possible from a log file rather than just stopping at the first bad message
  * Added compression process to run and compress a given database
  * Modified compression code to handle par.txt databases
  * Modified compression code and housekeeping process to run with kdb+ 2.*
  * Modified std out/err logging and usage logging to include process name and process type (the logmsg table had changed along with some of the functions in the .lg namespace so you might need to check in case you have overridden any of them)
  * Removed launchtick scripts and some default configuration: to create a test system, install a starter pack
- **2.1.0, July 2015**:
  * Added a chained tickerplant process
  * Updated housekeeping.csv to take in an extra column agemin which represents whether to use minutes or days in find function
  * Updated email libraries
