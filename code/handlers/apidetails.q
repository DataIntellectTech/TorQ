// Add to the api functions

\d .api

if[not`add in key `.api;add:{[name;public;descrip;params;return]}]

// Message handlers
add[`.usage.usage;1b;"log of messages through the message handlers";"";""]
add[`.usage.logtodisk;1b;"whether to log to disk";"";""]
add[`.usage.logtomemory;1b;"whether to log to .usage.usage";"";""]
add[`.usage.ignore;1b;"whether to check the ignore list for functions to ignore";"";""]
add[`.usage.ignorelist;1b;"the list of functions to ignore";"";""]
add[`.usage.logroll;1b;"whether to automatically roll the log file";"";""]
add[`.usage.rolllogauto;1b;"Roll the .usage txt files";"[]";"null"]
add[`.usage.readlog;1b;"Read and return a usage log file as a table";"[string: name of log file]";"null"]
add[`.access.USERS;1b;"Table of users and their types";"";""]
add[`.access.HOSTPATTERNS;1b;"List of host patterns allowed to access this process";"";""]
add[`.access.POWERUSERTOKENS;1b;"List of tokens allowed by power users";"";""]
add[`.access.USERTOKENS;1b;"List of tokens allowed by default users";"";""]
add[`.access.BESPOKETOKENS;1b;"Dictionary of tokens on a per-user basis (outside of their standard allowance)";"";""]
add[`.access.addsuperuser;1b;"Add a super user";"[symbol: user]";"null"]
add[`.access.addpoweruser;1b;"Add a power user";"[symbol: user]";"null"]
add[`.access.adddefaultuser;1b;"Add a default user";"[symbol: user]";"null"]
add[`.access.readpermissions;1b;"Read the permissions from a directory";"[string: directory containing the permissions files]";"null"]
add[`.clients.clients;1b;"table containing client handles and session values";"";""]
add[`.servers.SERVERS;1b;"table containing server handles and session values";"";""]
add[`.servers.opencon;1b;"open a connection to a process using the default timeout. If no user:pass supplied, the default one will be added if set";"[symbol: the host:port[:user:pass]]";"int: the process handle, null if the connection failed"]
add[`.servers.addh;1b;"open a connection to a server, store the connection details";"[symbol: the host:port:user:pass connection symbol]";"int: the server handle"]
add[`.servers.addw;1b;"add the connection details of a process behind the handle";"[int: server handle]";"null"]
add[`.servers.addnthawc;1b;"add the details of a connection to the table";"[symbol: process name; symbol: process type; hpup: host:port:user:pass connection symbol; dict: attributes of the process; int: handle to the process;boolean: whether to check the handle is valid on insert";"int: the handle of the process"]
add[`.servers.getservers;1b;"get a table of servers which match the given criteria";"[symbol: pick the server based on the name value or the type value.  Can be either `procname`proctype; symbol(list): lookup values. ` for any; dict: requirements dictionary; boolean: whether to automatically open dead connections for the specified lookup values; boolean: if only one of each of the specified lookup values is required (means dead connections aren't opened if there is one available)]";"table: processes details and requirements matches"]
add[`.servers.gethandlebytype;1b;"get a server handle for the supplied type";"[symbol: process type; symbol: selection criteria. One of `roundrobin`any`last]";"int: handle of server"]
add[`.servers.gethpbytype;1b;"get a server hpup connection symbol for the supplied type";"[symbol: process type; symbol: selection criteria. One of `roundrobin`any`last]";"symbol: h:p:u:p connection symbol of server"]
add[`.servers.startup;1b;"initialise all the connections.  Must processes should call this during initialisation";"[]";"null"]
add[`.servers.refreshattributes;1b;"refresh the attributes registered with the discovery service.  Should be called whenever they change e.g. end of day for an HDB";"[]";"null"]

