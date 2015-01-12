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
add[`.proc.loadf;1b;"Load the specified file";"[string: filename]";"null"]
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

