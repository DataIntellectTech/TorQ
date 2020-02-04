// Add to the api functions

\d .api

if[not`add in key `.api;add:{[name;public;descrip;params;return]}]

// Add each of the api calls to the detail table
add[`.api.f;1b;"Find a function/variable/table/view in the current process";"[string:search string]";"table of matching elements"]
add[`.api.p;1b;"Find a public function/variable/table/view in the current process";"[string:search string]";"table of matching public elements"]
add[`.api.u;1b;"Find a non-standard q public function/variable/table/view in the current process.  This excludes the .q, .Q, .h, .o namespaces";"[string:search string]";"table of matching public elements"]
add[`.api.s;1b;"Search all function definitions for a specific string";"[string: search string]";"table of matching functions and definitions"]
add[`.api.find;1b;"Generic method for finding functions/variables/tables/views. f,p and u are based on this";"[string: search string; boolean (list): public flags to include; boolean: whether the search is context senstive";"table of matching elements"]
add[`.api.search;1b;"Generic method for searching all function definitions for a specific string. s is based on this";"[string: search string; boolean: whether the search is context senstive";"table of matching functions and definitions"]
add[`.api.add;1b;"Add a function to the api description table";"[symbol:the name of the function; boolean:whether it should be called externally; string:the description; dict or string:the parameters for the function;string: what the function returns]";"null"]
add[`.api.fullapi;1b;"Return the full function api table";"[]";"api table"]
add[`.api.exportconfig;1b;"Return value table of requested torq variables and descriptions";"[symbol:torq namespace(s) as in namespace column in .api.f table]";"keyed table of name, value, description"]
add[`.api.exportallconfig;1b;"Return value table of all current torq variables and descriptions";"[]";"keyed table of name, value, description"]
add[`.api.m;1b;"Return the ordered approximate memory usage of each variable and view in the process. Views will be re-evaluated if required";"[]";"memory usage table"]
add[`.api.mem;1b;"Return the ordered approximate memory usage of each variable and view in the process. Views are only returned if view flag is set to true. Views will be re-evaluated if required";"[boolean:return views]";"memory usage table"]
add[`.api.whereami;1b;"Get the name of a supplied function definition. Can be used in the debugger e.g. .api.whereami[.z.s]";"function definition";"symbol: the name of the current function"]

// Process api
add[`.lg.o;1b;"Log to standard out";"[symbol: id of log message; string: message]";"null"]
add[`.lg.e;1b;"Log to standard err";"[symbol: id of log message; string: message]";"null"]
add[`.lg.l;1b;"Log to either standard error or standard out, depending on the log level";"[symbol: log level; symbol: name of process; symbol: id of log message; string: message; dict: extra parameters, used in the logging extension function]";"null"]
add[`.lg.err;1b;"Log to standard err";"[symbol: log level; symbol: name of process; symbol: id of log message; string: message; dict: extra parameters, used in the logging extension function]";"null"]
add[`.lg.ext;1b;"Extra function invoked in standard logging function .lg.l.  Can be used to do more with the log message, e.g. publish externally";"[symbol: log level; symbol: name of process; symbol: id of log message; string: message; dict: extra parameters]";"null"]
add[`.err.ex;1b;"Log to standard err, exit";"[symbol: id of log message; string: message; int: exit code]";"null"]
add[`.err.usage;1b;"Throw a usage error and exit";"[]";"null"]
add[`.err.param;1b;"Check a dictionary for a set of required parameters. Print an error and exit if not all required are supplied";"[dict: parameters; symbol list: the required param values]";"null"]
add[`.err.env;1b;"Check if a list of required environment variables are set.  If not, print an error and exit";"[symbol list: list of required environment variables]";"null"]
add[`.proc.createlog;1b;"Create the standard out and standard err log files. Redirect to them";"[string: log directory; string: name of the log file;mixed: timestamp suffix for the file (can be null); boolean: suppress the generation of an alias link]";"null"]
add[`.proc.rolllogauto;1b;"Roll the standard out/err log files";"[]";"null"]
add[`.proc.loadf;1b;"Load the specified file if not already loaded";"[string: filename]";"null"]
add[`.proc.reloadf;1b;"Load the specified file even if already laoded";"[string: filename]";"null"]
add[`.proc.loaddir;1b;"Load all the .q and .k files in the specified directory. If order.txt is found in the directory, use the ordering found in that file";"[string: name of directory]";"null"]
add[`.proc.getattributes;1b;"Called by external processes to retrieve the attributes (advertised functionality) of this process";"[]";"dictionary of attributes"]
add[`.proc.override;1b;"Override configuration varibles with command line parameters.  For example, if you set -.servers.HOPENTIMEOUT 5000 on the command line and call this function, then the command line value will be used";"[]";"null"]
add[`.proc.overrideconfig;1b;"Override configuration varibles with values in supplied parameter dictionary. Generic version of .proc.override";"[dictionary: command line parameters.  .proc.params should be used]";"null"]


// Timer related functions
add[`.timer.timer;1b;"The table containing the timer information";"";""];
add[`.timer.repeat;1b;"Add a repeating timer with default next schedule";"[timestamp: start time; timestamp: end time; timespan: period; mixedlist: (function and argument list); string: description string]";"null"];
add[`.timer.once;1b;"Add a one-off timer to fire at a specific time";"[timestamp: execute time; mixedlist: (function and argument list); string: description string]";"null"];
add[`.timer.remove;1b;"Delete a row from the timer schedule";"[int: timer id to delete]";"null"];
add[`.timer.removefunc;1b;"Delete a specific function from the timer schedule";"[mixedlist: (function and argument list)]";"null"];
add[`.timer.rep;1b;"Add a repeating timer - more flexibility than .timer.repeat";"[timestamp: execute time; mixedlist: (function and argument list); short: scheduling algorithm for next timer; string: description string; boolean: whether to check if this new function is already present on the schedule]";"null"];
add[`.timer.one;1b;"Add a one-off timer to fire at a specific time - more flexibility than .timer.once";"[timestamp: execute time; mixedlist: (function and argument list); string: description string; boolean: whether to check if this new function is already present on the schedule]";"null"];

// Caching functions
add[`.cache.execute;1b;"Check the cache for a valid result set, return the results if found, execute the function, cache it and return if not";"[mixed: function or string to execute;timespan: maximum allowable age of cache item if found in cache]";"mixed: result of function"]
add[`.cache.getperf;1b;"Return the performance statistics of the cache";"[]";"table: cache performance"]
add[`.cache.maxsize;1b;"The maximum size in MB of the cache. This is evaluated using -22!, so may be incorrect due to power of 2 memory allocation.  To be conservative and ensure it isn't exceeded, set max size to half of the actual max size that you want";"";""]
add[`.cache.maxindividual;1b;"The maximum size in MB of an individual item in the cache. This is evaluated using -22!, so may be incorrect due to power of 2 memory allocation.  To be conservative and ensure it isn't exceeded, set max size to half of the actual max size that you want";"";""]

// timezone
add[`.tz.default;1b;"Default timezone";"";""]
add[`.tz.t;1b;"Table of timestamp information";"";""]
add[`.tz.dg;1b;"default from GMT. Convert a timestamp from GMT to the default timezone";"[timestamp (list): timestamps to convert]";"timestamp atom or list"]
add[`.tz.lg;1b;"local from GMT. Convert a timestamp from GMT to the specified local timezone";"[symbol (list): timezone ids;timestamp (list): timestamps to convert]";"timestamp atom or list"]
add[`.tz.gd;1b;"GMT from default. Convert a timestamp from the default timezone to GMT";"[timestamp (list): timestamps to convert]";"timestamp atom or list"]
add[`.tz.gl;1b;"GMT from local. Convert a timestamp from the specified local timezone to GMT";"[symbol (list): timezone ids; timestamp (list): timestamps to convert]";"timestamp atom or list"]
add[`.tz.ttz;1b;"Convert a timestamp from a specified timezone to a specified destination timezone";"[symbol (list): destination timezone ids; symbol (list): source timezone ids; timestamp (list): timestamps to convert]";"timestamp atom or list"]

// subscriptions
add[`.sub.getsubscriptionhandles;1b;"Connect to a list of processes of a specified type";"[symbol: process type to match; symbol: process name to match; dictionary:attributes of process]";"table of process names, types and the handle connected on"]
add[`.sub.subscribe;1b;"Subscribe to a table or list of tables and specified instruments";"[symbol (list):table names; symbol (list): instruments; boolean: whether to set the schema from the server; boolean: wether to replay the logfile; dictionary: procname,proctype,handle";""]

// pubsub
add[`.ps.publish;1b;"Publish a table of data";"[symbol: name of table; table: table of data]";""]
add[`.ps.subscribe;1b;"Subscribe to a table and list of instruments";"[symbol(list): table name. ` for all; symbol(list): symbols to subscribe to. ` for all]";"mixed type list of table names and schemas"]
add[`.ps.initialise;1b;"Initialise the pubsub routines.  Any tables that exist in the top level can be published";"[]";""]

// heartbeating
add[`.hb.addprocs;1b;"Add a set of process types and names to the heartbeat table to actively monitor for heartbeats.  Processes will be automatically added and monitored when the heartbeats are subscribed to, but this is to allow for the case where a process might already be dead and so can't be subscribed to";"[symbol(list): process types; symbol(list): process names]";""]
add[`.hb.processwarning;1b;"Callback invoked if any process goes into a warning state.  Default implementation is to do nothing - modify as required";"[table: processes currently in warning state]";""]
add[`.hb.processerror;1b;"Callback invoked if any process goes into an error state. Default implementation is to do nothing - modify as required";"[table: processes currently in error state]";""]
add[`.hb.storeheartbeat;1b;"Store a heartbeat update.  This function should be added to you update callback when a heartbeat is received";"[table: the heartbeat table data to store]";""]
add[`.hb.warningperiod;1b;"Return the warning period for a particular process type.  Default is to return warningtolerance * publishinterval. Can be overridden as required"; "[symbollist: the process types to return the warning period for]";"timespan list of warning period"]
add[`.hb.errorperiod;1b;"Return the error period for a particular process type.  Default is to return errortolerance * publishinterval. Can be overridden as required"; "[symbollist: the process types to return the error period for]";"timespan list of error period"]

// async messaging
add[`.async.deferred;1b;"Use async messaging to simulate sync communication";"[int(list): handles to query; query]";"(boolean list:success status; result list)"]
add[`.async.postback;1b;"Send an async message to a process and the results will be posted back within the postback function call";"[int(list): handles to query; query; postback function]";"boolean list: successful send status"]

// compression
add[`.cmp.showcomp;1b;"Show which files will be compressed and how; driven from csv file";"[`:/path/to/database; `:/path/to/configcsv; maxagefilestocompress]";"table of files to be compressed"]
add[`.cmp.compressmaxage;1b;"Run compression on files using parameters specified in configuration csv file, and specifying the maximum age of files to compress";"[`:/path/to/database; `:/path/to/configcsv; maxagefilestocompress]";""]
add[`.cmp.docompression;1b;"Run compression on files using parameters specified in configuration csv file";"[`:/path/to/database; `:/path/to/configcsv]";""]

// data loader
add[`.loader.loadallfiles;1b;"Generic loader function to read a directory of files in chunks and write them out to disk";"[dictionary of load parameters. Should have keys of headers (symbol list), types (character list), separator (character), tablename (symbol), dbdir (symbol).  Optional params of dataprocessfunc (diadic function), datecol (name of column to extract date from: symbol), chunksize (amount of data to read at once:int), compression (compression parameters to use e.g. 16 1 0:int list), gc (boolean flag of whether to run garbage collection:boolean); directory containing files to load (symbol)]";""]


// sort and set attributes
add[`.sort.sorttab;1b;"Sort and set the attributes for a table and set of partitions based on a configuration file (default is $KDBCONFIG/sort.csv)";"[2 item list of (tablename e.g. `trade; partitions to sort and apply attributes to e.g. `:/hdb/2000.01.01/trade`:hdb/2000.01.02/trade)]";""]
add[`.sort.getsortcsv;1b;"Read in the sort csv from the specified location";"[symbol: the location of the file e.g. `:config/sort.csv]";""]

// garbage collection
add[`.gc.run;1b;"Run garbage collection, print debug info before and after"; "";""]

// email
add[`.email.connectdefault;1b;"connect to the default mail server specified in configuration";"[]";""]
add[`.email.senddefault;1b;"connect to email server if not connected. Send email using default settings";"[dictionary of email parameters. Required dictionary keys are to (symbol (list) of email address to send to), subject (character list), body (list of character arrays).  Optional parameters are cc (symbol(list) of addresses to cc), bodyType (can be `html, default is `text), attachment (symbol (list) of files to attach), image (symbol of image to append to bottom of email. `none is no image), debug (int flag for debug level of connection library. 0i=no info, 1i=normal. 2i=verbose)]";"size in bytes of sent email. -1 if failure"]  
add[`.email.test;1b;"send a test email";"[symbol(list):email address to send test email to]";"size in bytes of sent email. -1 if failure"]
add[`.email.connect;1b;"connect to specified email server";"[dictionary of connection settings.  Required dictionary keys are url (symbol url of mail server host:port), user (symbol of user to sign in as) and password (symbol of password to use).  Optional parameters are from (return address on emails, default is torq@aquaq.co.uk), usessl (boolean flag of whether to use ssl/tls, default is 0b), debug (int flag for debug level of connection library. 0i=no info, 1i=normal. 2i=verbose)]";"0 if successful, -1 if failure"]
add[`.email.send;1b;"Send email using supplied parameters.  Requires connection to already be established";"[dictionary of email parameters. Required dictionary keys are to (symbol (list) of email address to send to), subject (character list), body (list of character arrays).  Optional parameters are cc (symbol(list) of addresses to cc), bodyType (can be `html, default is `text), attachment (symbol (list) of files to attach), image (symbol of image to append to bottom of email. `none is no image), debug (int flag for debug level of connection library. 0i=no info, 1i=normal. 2i=verbose)]";"size in bytes of sent email. -1 if failure"]
add[`.email.disconnect;1b;"disconnect from email server";"[]";"0"]

// tplog
add[`.tplog.check;1b;"Checks if tickerplant log can be replayed.  If it can or can replay the first X messages, then returns the log handle, else it will read log as byte stream and create a good log and then return the good log handle ";"[logfile (symbol), handle to the log file to check; lastmsgtoreplay (long), the index of the last message to be replayed from log ]";"handle to log file, will be either the input log handle or handle to repaired log, depends on whether the log was corrupt"]

// memory usage
add[`.mem.objsize;1b;"Returns the calculated memory size in bytes used by an object.  It may take a little bit of time for objects with lots of nested structures (e.g. lots of nested columns)";"[q object]";"size of the object in bytes"]
