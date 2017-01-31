
Message Handlers
================

There is a separate code directory containing message handler
customizations. This is found at $KDBCODE/handlers. Much of the code is
derived from Simon Garland’s contributions to
[code.kx](http://code.kx.com/wiki/Contrib/UsingDotz).

Every external interaction with a process goes through a message
handler, and these can be modified to, for example, log or restrict
access. Passing through a bespoke function defined in a message handler
will add extra processing time and therefore latency to the message. All
the customizations we have provided aim to minimise additional latency,
but if a bespoke process is latency sensitive then some or all of the
customizations could be switched off. We would argue though that
generally it is better to switch on all the message handler functions
which provide diagnostic information, as for most non-latency sensitive
processes (HDBs, Gateways, some RDBs etc.) the extra information upon
failure is worth the cost. The message handlers can be globally switched
off by setting .proc.loadhandlers to 0b in the configuration file.

|     Script      |     NS     | Diag |                 Function                 |                 Modifies                 |
| :-------------: | :--------: | :--: | :--------------------------------------: | :--------------------------------------: |
|   logusage.q    |   .usage   |  Y   | Log all client interaction to an ascii log file and/or in-memory table. Messages can be logged before and after they are processed. Timer calls are also logged. Exclusion function list can be applied to .z.ps to disable logging of asynchronous real time updates | pw, po, pg, ps, pc, ws, ph, pp, pi, exit, timer |
| controlaccess.q |  .access   |  N   | Restrict access for set of users/user groups to a list of functions, and from a defined set of servers |        pw, pg, ps, ws, ph, pp, pi        |
| trackclients.q  |  .clients  |  Y   | Track client process details including then number of requests and cumulative data size returned |            po, pg, ps, ws, pc            |
| trackservers.q  |  .servers  |  Y   | Discover and track server processes including name, type and attribute information. This also contains the core of the code which can be used in conjunction with the discovery service. |                pc, timer                 |
|   zpsignore.q   | .zpsignore |  N   | Override async message handler based on certain message patterns |                    ps                    |
|  writeaccess.q  | .readonly  |  N   | Restrict client write access to prevent any modification to data in place. Also disables all HTTP access. |            pg, ps, ws, ph, pp            |
|     ldap.q      |   .ldap    |  N   | Restrict client access to process using ldap authentication. | pw |


Each customization can be turned on or off individually from the
configuration file(s). Each script can be extensively customised using
the configuration file. Example customization for logusage.q, taken from
$KDBCONFIG/settings/default.q is below. Please see default.q for the
remaining configuration of the other message handler files.

    /- Configuration used by the usage functions - logging of client interaction
    \d .usage
    enabled:1b		/- whether the usage logging is enabled
    logtodisk:1b		/- whether to log to disk or not
    logtomemory:1b		/- write query logs to memory
    ignore:1b		/- check the ignore list for functions to ignore
    ignorelist:(`upd;"upd")	/- the list of functions to ignore in async calls
    flushtime:1D00		/- default value for how long to persist the
    			/- in-memory logs. Set to 0D for no flushing
    suppressalias:0b	/- whether to suppress the log file alias creation
    logtimestamp:{[].z.d}	/- function to generate the log file timestamp suffix
    LEVEL:3			/- log level. 0=none;1=errors;2=errors+complete
    			/- queries;3=errors+before a query+after
    logroll:1b		/- Whether or not to roll the log file
    			/- automatically (on a daily schedule)


dotz.q
---------

Stores all the default values for the message handlers and can be used to revert back to the default if necessary.

<a name="logu"></a>

logusage.q
----------

logusage.q is probably the most important of the scripts from a
diagnostic perspective. It is a modified version of the logusage.q
script on code.kx.

In its most verbose mode it will log information to an in-memory table
(.usage.usage) and an on-disk ASCII file, both before and after every
client interaction and function executed on the timer. These choices
were made because:

-   logging to memory enables easy interrogation of client interaction;

-   logging to disk allows persistence if the process fails or locks up.
      ASCII text files allow interrogation using OS tools such as vi, grep
      or tail;

-   logging before a query ensures any query that adversely effects the
      process is definitely captured, as well as capturing some state
      information before the query execution;

-   logging after a query captures the time taken, result set size and
      resulting state;

-   logging timer calls ensures a full history of what the process is
      actually doing. Also, timer call performance degradation over time
      is a common source of problems in kdb+ systems.

The following fields are logged in .usage.usage:

| Field  |               Description                |
| :----: | :--------------------------------------: |
|  time  |   Time the row was added to the table    |
|   id   | ID of the query. Normally before and complete rows will be consecutive but it might not be the case if the incoming call invokes further external communication |
| timer  | Execution time. Null for rows with status=b (before) |
|  zcmd  |   .z handler the query arrived through   |
| status | Query status. One of b, c or e (before, complete, error) |
|   a    | Address of sender. .dotz.ipa can be used to convert from the integer format to a hostname |
|   u    |            Username of sender            |
|   w    |             Handle of sender             |
|  cmd   |               Command sent               |
|  mem   |            Memory statistics             |
|   sz   | Size of result. Null for rows with status of b or e |
| error  |              Error message               |



<a name="control"></a>

controlaccess.q
---------------

controlaccess.q is used to restrict client access to the process. It is
modified version of controlaccess.q from code.kx. The script allows
control of several aspects:

-   the host/ip address of the servers which are allowed to access the
    process;

-   definition of three user groups (default, poweruser and superuser)
      and the actions each group is allowed to do;

-   the group(s) each user is a member of, and any additional actions an
      individual user is allowed/disallowed outside of the group
      permissions;

-   the maximum size of the result set returned to a client.

The access restrictions are loaded from csv files. The permissions files
are stored in $KDBCONFIG/permissions.

|       File        |               Description                |
| :---------------: | :--------------------------------------: |
|   \*\_hosts.csv   | Contains hostname and ip address (patterns) for servers which are allowed or disallowed access. If a server is not found in the list, it is disallowed |
|   \*\_users.csv   | Contains individual users and the user groups they are are a member of |
| \*\_functions.csv | Contains individual functions and whether each user group is allowed to execute them. ; separated user list enables functions to be allowed by individual users |



The permissions files are loaded using a similar hierarchical approach
as for the configuration and code loading. Three files can be provided-
default\_.csv, \[proctype\]\_.csv, and \[procname\]\_.csv. All of the
files will be loaded, but permissions for the same entity (hostpattern,
user, or function) defined in \[procname\]\_.csv will override those in
\[proctype\]\_.csv which will in turn override \[procname\]\_.csv.

When a client makes a query which is refused by the permissioning layer,
an error will be raised and logged in .usuage.usage if it is enabled.

<a name="track"></a>

trackclients.q
--------------

trackclients.q is used to track client interaction. It is a slightly
modified version of trackclients.q from code.kx, and extends the
functionality to handle interaction with the discovery service.

Whenever a client opens a connection to the q process, it will be
registered in the .clients.clients table. Various details are logged,
but from a diagnostic perspective the most important information are the
client details, the number of queries it has run, the last time it ran a
query, the number of failed queries and the cumulative size of results
returned to it.

<a name="tracks"></a>

trackservers.q
--------------

trackservers.q is used to register and maintain handles to external
servers. It is a heavily modified version of trackservers.q from
code.kx. It is explained more in section connectionmanagement.

<a name="zps"></a>

zpsignore.q
-----------

zpsignore.q is used to check incoming async calls for certain patterns
and to bypass all further message handler checks for messages matching
the pattern. This is useful for handling update messages published to a
process from a data source.

<a name="write"></a>

writeaccess.q
-------------

writeaccess.q is used to restrict client write access to data within a
process. The script uses the reval function, released in KDB+ 3.3, to
prevent client queries from modifying any data in place. At present only
queries in the form of strings are passed through the reval function.
Additonally the script disables any form of HTTP access. If using
versions of KDB+ prior to 3.3, this feature must be disabled. An attempt
to use this feature on previous KDB+ versions will result in an error
and the relevant process exiting.

permissions.q
-------------

permissions.q is used to control client access to a server process. It
allows:

-   Access control via username/password access, either in combination
    with the -u/U process flags or in place of them.

-   Definition of user groups, which control variable access.

-   Definition of user roles, which allow control over function
    execution.

-   Deeper control over table subsetting through the use of “virtual
    tables”, using enforced where clauses.

Access restriction in TorQ can be enabled on all processes, each of
which can then load the default.q in $KDBCONFIG/permissions/, which
adds users, groups and roles allowing standard operation of TorQ. The
admin user and role by default can access all functions, and each of the
system processes has access only to the required system functions.

Permissions are enabled or disabled on a per-process basis through
setting .pm.enabled as 1b or 0b at process load (set to 0b by default).
A permissioned process can safely interact with a non-permissioned
process while still controlling access to itself.

The access schema consists of 7 control tables:


  |**Name**       | **Descriptions**|
  |---------------| ------------------------------------------------------------------------------------------------------------|
  |User           |Username, locality, encryption type and password hash|
  |Usergroup      |User and their group.|
  |Userrole       |User and role.|
  |Functiongroup  |Functions and their group|
  |Function       |Function names, the roles which can access them, and a lambda checking the parameters those roles can use.|
  |Access         |Variable names, the groups which can access them, and the read or write access level.|
  |Virtualtable   |Virtual table name, main table name, and the where clause it enforces on access to that table.|

  
In addition to groupinfo and roleinfo tables, which contain the
group/role name and a string describing each group and role. A user can
belong to multiple groups, and have multiple roles. In particular the
schema supports group hierarchy, where a user group can be listed as a
user in the group table, and inherit all the permissions from another
other group, effectively inheriting the second group itself.

A user belonging to a group listed in the access table will have the
specified level of access (read or write) to that group’s variables,
e.g.


  |Table       |Group      |Level|
  |-------| -------------- |-------|
  |quote |    headtrader   |write|
  |trade|    juniortrader | read|

  
Here, users in headtrader will have write access to the quote table,
while juniortrader group has read access to the trade table. If
headtraders have been set to inherit the juniortrader group, they will
also have read access to trade. Note that read access is distinct from
write access. Headtraders in this circumstance do not have implicit read
access to the quote table. This control is for direct name access only.
Selects, execs and updates are controlled via the function table, as
below.

The permissions script can be set to have permissive mode enabled with
permissivemode:1b (disabled by default). When enabled at script loading,
this bypasses access checks on variables which are not listed in the
access table, effectively auto-whitelisting any variables not listed in
the access table for all users, which may be useful in partly restricted
development environments.

Function access is controlled through non-hierarchical roles. A user
attempting to run a named function will have their access checked
against the function table through their role, for example, trying to
run a function timedata\[syms;bkttype\], which selects from a table by a
time bucket type bkttype on xbar:


|**Function** | **Role** | **Param. Check** |
|------|------|------|
|timedata | quant | {1b}|
|timedata| normal user | {x[\`bkttype] in \`hh}|
|select| quant |{1b}|

The parameter check in the third column must be a lambda accepting a
dictionary of parameters and their values, which can then return a
boolean if some parameter condition is met. Here, any normal user must
have their bucket type as an hour. If they try anything else, the
function is not permitted. This could be extended to restriction to
certain syms as well, in this example, the quant can run this function
with any parameters. Anything passed to the param. check function
returns 1b. A quant having general select access is listed as having
1b in the param. check.

Further restriction of data can be achieved with virtual tables, via
which users can be restricted to having a certain subset of data from a
main table available. To avoid the need to replicate a potentially large
subset of a table into a separately-controlled variable, this is done
through pointing to the table under a different name via a where clause,
e.g.


  |**Virtual Table**  |  **Table**|  **Where Clause**|
  |------------------- |----------- |---------------------------------|
  |trade\_lse      |       trade   | ,(in;\`src;“L”)|
  |quote\_new     |        quote   | ,(&gt;;\`time;(-;\`.z.p;01:00))|

 
When a select from trade\_lse is performed, a select on trade is
modified to contain the where clause above. Access to virtual tables can
be controlled identically to access to real tables through the access
table.

If the process is given the flag “-public 1”, it will run in public
access mode. This allows a user to log in without a password and be
given the publicuser role and membership of the public group, which can
be configured as any other group or role.

The permissions control has a default size restriction of 2GB, set (as
bytes) on .pm.maxsize. This is a global restriction and is not affected
by user permissions.

Adding to the groups and roles is handled by the functions:

    adduser[`user;`locality;`hash type; md5"password"]
    removeuser[`user]
    addgroup[`groupname; "description"]
    removegroup[`groupname]
    addrole[`rolename; "description"]
    removerole[`rolename]
    addtogroup[`user;`groupname]
    removefromgroup[`user; `groupname]
    assignrole[`user; `rolename]
    unassignrole[`user; `rolename]
    addfunction[`function; `functiongroup]
    removefunction[`function; `functiongroup]
    grantaccess[`variable; `groupname; `level]
    revokeaccess[`variable; `groupname; `level]
    grantfunction[`function; `rolename; {paramCheckFn}]
    revokefunction[`function; `rolename]
    createvirtualtable[`vtablename; `table; ,(whereclause)]
    removevirtualtable[`vtablename]
    cloneuser[`user;`newuser;"password"]

which are further explained in the script API.

Permission control operates identically on the gateway. A user connected
to the gateway must have access to the gateway, and their roles must
have access to the .gw.syncexec or .gw.asyncexec functions.

### Usage Example

To connect to a permissioned RDB in the TorQ system, a group and role
for the user must be established. If the RDB contains the tables trade,
quote, and depth, and the process contains the functions getdata\[syms,
bkttype,bktsize\] and hloc\[table\], restricted access would be
configured like so:

    .pm.adduser[`adam;`local;`md5;md5"pass"]
    .pm.adduser[`bob;`local;`md5;md5"pass"]

    .pm.addtogroup[`adam;`fulluser]
    .pm.addtogroup[`bob;`partuser]
    .pm.addtogroup[`fulluser;`partuser]
    .pm.grantaccess[`quote;`fulluser;`read]
    .pm.grantaccess[`trade;`partuser;`read]

    .pm.createvirtualtable[`quotenew;`quote;enlist(>;`time;(-;`.z.p;01:00))]
    .pm.grantaccess[`quotenew;`partuser;`read]

    .pm.assignrole[`adam;`toplevel]
    .pm.assignrole[`bob;`lowlevel]
    .pm.grantfunction[`getdata;`toplevel;{1b}]
    .pm.grantfunction[`getdata;`lowlevel;{x[`syms] in `GOOG}]
    .pm.grantfunction[`hloc;`toplevel;{1b}]
    .pm.grantfunction[`hloc;`lowlevel;{x[`table] in `trade}]

This provides a system in which Bob can access only the trade table,
while Adam has access to the trade table and quote table (through
inheritance from Bob’s group). Through a virtual table, if Bob runs
“select from quotenew”, he is able to get a table of the last hour of
quotes. When the system is started in normal mode, there is no IPC
access to the depth table, however if the system was started in
permissive mode, in this case any user who could log in could access
depth.

Adam can run the getdata function however he wants, and Bob can only run
it against sym GOOG. Similarly Adam can run hloc against any table, but
Bob can only look at trade with it.

Additionally, any system calls would need to be actively permissioned in
the same way, after defining a systemuser role (or expanding the default
role in TorQ). The superuser is given global function access by
assigning them .pm.ALL in the function table, for example a tickerplant
pushing to the RDB would need to have a user and role defined:

    .pm.adduser[`ticker;`local;`md5;md5"plant"]
    .pm.assignrole[`ticker;`tp]

And then grant that role access to the .u.upd function:

    .pm.grantfunction[`.u.upd;`tp;{1b}]

Although the .u.upd function updates to a table, there is no need to
grant direct access to that table.

### Gateway Example

The gateway user will have superuser role by default. The execution of a
function passed through the gateway is checked against the user who sent
the call. This should not be modified.

Within the gateway itself, access to target processes can be controlled
via the function table. For example, if Adam in the previous example was
allowed to access only the RDB with .gw.syncexec, you could use:

    .pm.grantfunction[`.gw.syncexec;`toplevel;{x[`1] in `rdb}]

Since .gw.syncexec is a projection, the arguments supplied are checked
in order, with dictionary keys \`0\`1\`2... etc. This could be further
extended to restrict access to queries with the
.pm.allowed[user;query] function, which checks permissions of the
current user as listed on the gateway permission tables:

    .pm.grantfunction[`.gw.syncexec;`toplevel;
        {.pm.allowed[.z.u;x[`0]] and x[`1] in `rdb}]


<a name="ldap"></a>

ldap.q
------

Authentication with an ldap server is managed with ldap.q. It allows:

- A user to authenticate against an ldap server;

- Caching of user attempts to allow reauthentication without server if within checktime period;

- Users to be blocked if too many failed authentication attempts are made.

Default parameters in the ldap namespace are set in {TORQHOME}/config/settings/default.q.

|      parameter     |     description     |
| :----------------: | :-----------------: |
|      enabled       |  Whether ldap authentication is enabled  |
|       debug        |  Whether logging message are written to console  |
|       server       |  Host for ldap server.   |
|        port        |  Port number for ldap server.  |
|      version       |  Ldap version number.    |
|     blocktime      |  Time that must elapse before a blocked user can attempt to authenticate. If set to 0Np then the user is permanently blocked until an admin unblocks them. |
|     checklimit     |  Login attempts before user is blocked.  |
|     checktime      |  Period of time that allows user to reauthenticate without confirming with ldap server. |
|     buildDNsuf     |  Suffix for building distinguished name. |
|      buildDN       |  Function to build distiniguished name.  |

To get started the following will need altered from their default values: enabled, port, server, buildDNsuf.

The value buildDNsuf is required to build a users bind_dn from the supplied username and is called by the function buildDN. An example definition is:

    .ldap.buildDNsuf:"ou=users,dc=website,dc=com";

Authentication is handled by .ldap.authenticate which is wrapped by .ldap.login, which is in turn wrapped by .z.pw when ldap authentication is enabled. When invoked .ldap.login retrieves the users latest authentication attempt from the cache, if it exists, and performs several checks before authenticating the user.

To authenticate the function first checks whether the user has been blocked by reaching the checklimit and blocktime has not passed, immediately returning false if this is the case. If the user has previously successfully authenticated within the period defined by checktime and is using the same credentials authentication will be permitted. For all other cases an authentication attempt will be made against the ldap server. 

Example authentication attempt:

    .ldap.login[`user;pass]
    0b

To manually unblock a user the function .ldap.unblock must be passed their userame as a symbol. The function checks the cache to see whether a user is blocked and will reset the blocked status if necessary. An example usage of this function is:

    .ldap.unblock[`user]


<a name="dia"></a>

Diagnostic Reporting
--------------------

The message handler modifications provide a wealth of diagnostic
information including:

-   the timings and memory usage for every query run on a process;

-   failed queries;

-   clients trying to do things they are not permissioned for;

-   the clients which are querying often and/or regularly extracting
      large datasets;

-   the number of clients currently connected;

-   timer calls and how long they take.

Although not currently implemented, it would be straightforward to use
this information to implement reports on the behaviour of each process
and the overall health of the system. Similarly it would be
straightforward to set up periodic publication to a central repository
to have a single point for system diagnostic statistics.
