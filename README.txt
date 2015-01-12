Quick Start
-----------

To launch a process wrapped in the framework, you need to set the environment variables and give the process a type and name.  The type and name can be explicitly passed on the command line.  setenv.sh is an example of how to set the environment variables on a unix type system.  For a windows system, see http://www.computerhope.com/issues/ch000549.htm. 

To avoid standard out/err being redirected, used the -debug flag

./setenv.sh         /- Assuming unix type OS
q torq.q -proctype test -procname mytest -debug

To load a file, use -load

q torq.q -load mytest.q -proctype test -procname mytest -debug

This will launch the a process running within the framework with all the default values.  For the rest, read the document!


Tick Integration - Quick(ish) Start
-----------------------------------

launchtick.sh and launchtick.bat are provided to launch a simple version of kdb+tick on unix and windows operating systems respectively.  To launch on Windows, you will need to set the environment variables as above. 

1. kdb+tick can be downloaded from http://code.kx.com/wsvn/code/kx/kdb+tick.  Both tick.q and the tick directory should be placed in the same directory as torq.q.
2. Copy exampleschema.q into the tick folder
3. Copy tick/u.q to code/common.  This will allow the processes to have pub/sub functionality
4. Modify the hostname of every process in config/process.csv to the local machine name
5. On unix (linux/mac/solaris) modify the setenv.sh to contain absolute paths.  Some of the kdb+tick processes change directory, so the relative paths will become invalid
6. On unix, run

sh launchtick.sh

On windows,
Edit the bat file to provide full paths to the environment variables, eg:
setx KDBCODE "C:/path/to/code"
else C:/q/ is used as the directory holding code, config, html and log folders.

You can set the environment variables permanently by using setx (requires console restart) or by:
Right click my computer -> properties
Click advanced system settings
click environment variables -> add

run
launchtick.bat

7. Open the Monitor gui by navigating to http://hostname:20001/.non?monitorui
8. Kill the processes (or some of the processes) by using the kill process as detailed in launch.sh
9. For more details, read the manual!

Release Notes
-------------

1.0, Feb 2014: 	Initial public release of TorQ
1.1, Apr 2014:	Added compression utilities, HTML5 utilities, housekeeping process, file alerter process, kdb+tick quick start
1.2, Sep 2014:	Tested on kdb+ 3.2
		Added connections to external (non TorQ) processes using nonprocess.csv
		Modified file alerter with optional switch to move or not move a file if any function fails to process the file
		Discovery service(s) host:port(s) can be passed on the command line (.servers.DISCOVERY) to a process (this should enable complete bypassing of process.csv if required)
		Add custom hook (.servers.connectcustom) which is invoked whenever a new connection is made (allows, for example, subscription to a new process)
		Add optional application detail file ($KDBCONFIG/application.txt) to allow customisation of the start up banner (application version etc.)
		If required env. variables (KDBCODE, KDBCONFIG, KDBLOG) are not set they will default to $QHOME/code, $QHOME/config, $QHOME/logs respectively (previously the process failed and exited)
