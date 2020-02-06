
Connection Management 
=====================

trackservers.q is used to register and maintain handles to external
servers. It is a heavily modified version of trackservers.q from
code.kx. All the options are described in the default config file. All
connections are tracked in the .servers.SERVERS table. When the handle
is used the count and last query time are updated.

    q).servers.SERVERS 
    procname     proctype  hpup                            w  hits startp                        lastp                         endp                          attributes                   
    ---------------------------------------------------------------------------------
    discovery1   discovery :aquaq:9996    0                                  2014.01.08D11:13:10.583056000                               ()!()                        
    discovery2   discovery :aquaq:9995 6  0    2014.01.07D16:44:47.175757000 2014.01.07D16:44:47.174408000                               ()!()                        
    rdb_europe_1 rdb       :aquaq:9998 12 0    2014.01.07D16:46:47.897910000 2014.01.07D16:46:47.892901000 2014.01.07D16:46:44.626293000 `datacentre`country!`essex`uk
    rdb1         rdb       :aquaq:5011 7  0    2014.01.07D16:44:47.180684000 2014.01.07D16:44:47.176994000                               `datacentre`country!`essex`uk
    rdb_europe_1 hdb       :aquaq:9997    0                                  2014.01.08D11:13:10.757801000                               ()!()                        
    hdb1         hdb       :aquaq:9999    0                                  2014.01.08D11:13:10.757801000                               ()!()                        
    hdb2         hdb       :aquaq:5013 8  0    2014.01.07D16:44:47.180684000 2014.01.07D16:44:47.176994000                               `datacentre`country!`essex`uk
    hdb1         hdb       :aquaq:5012 9  0    2014.01.07D16:44:47.180684000 2014.01.07D16:44:47.176994000                               `datacentre`country!`essex`uk
    
    q)last .servers.SERVERS 
    procname  | `hdb2
    proctype  | `hdb
    hpup      | `:aquaq:5013
    w         | 8i
    hits      | 0i
    startp    | 2014.01.08D11:51:01.928045000
    lastp     | 2014.01.08D11:51:01.925078000
    endp      | 0Np
    attributes| `datacentre`country!`essex`uk


Connections
-----------

Processes locate other processes based on their process type. The
location is done either statically using the process.csv file or
dynamically using a discovery service. It is recommended to use the
discovery service as it allows the process to be notified as new
processes become available.

The main configuration variable is .servers.CONNECTIONS, which dictates
which process type(s) to create connections to. .servers.startup\[\]
must be called to initialise the connections. When connections are
closed, the connection table is automatically updated. The process can
be set to periodically retry connections.


Process Attributes
------------------

Each process can report a set of attributes. When process A connects to
process B, process A will try to retrieve the attributes of process B.
The attributes are defined by the result of the .proc.getattributes
function, which is by default an empty dictionary. Attributes are used
to retrieve more detail about the capabilities of each process, rather
than relying on the broad brush process type and process name
categorization. Attributes can be used for intelligent query routing.
Potential fields for attributes include:

-   range of data contained in the process;

-   available tables;

-   instrument universe;

-   physical location;

-   any other fields of relevance.


Connection Passwords
--------------------

The password used by a process to connect to external processes is
retrieved using the .servers.loadpassword function call. By default,
this will read the password from a txt file contained in
$KDBCONFIG/passwords. A default password can be used, which is
overridden by one for the process type, which is itself overridden by
one for the process name. For greater security, the
.servers.loadpassword function should be modified.

Some non-torq processes require a username and password to allow connection. 
These will be stored in a passwords dictionary. 
Passing the host and port of a process into this dictionary will return the full connection string 
if it is present within the dictionary. 
If however it is not present in the dictionary then the default username and password will be returned.


Retrieving and Using Handles
----------------------------

A function .servers.getservers is supplied to return a table of handle
information. .servers.getservers takes five parameters:

-   type-or-name: whether the lookup is to be done by type or name (can
    be either proctype or procname);

-   types-or-names: the types or names to retrieve e.g. hdb;

-   required-attributes: the dictionary of attributes to match on;

-   open-dead-connections: whether to re-open dead connections;

-   only-one: whether we only require one handle. So for example if 3
      services of the supplied type are registered, and we have an open
      handle to 1 of them, the open handle will be returned and the others
      left closed irrespective of the open-dead-connections parameter.

.servers.getservers will compare the required parameters with the
available parameters for each handle. The resulting table will have an
extra column called attribmatch which can be used to determine how good
a match the service is with the required attributes. attribmatch is a
dictionary of (required attribute key) ! (Boolean full match;
intersection of attributes).

    q).servers.SERVERS 
    procname     proctype  hpup                            w hits startp                        lastp                         endp attributes                   
    ---------------------------------------------------------------------------------
    discovery1   discovery :aquaq:9996   0                                  2014.01.08D11:51:01.922390000      ()!()                        
    discovery2   discovery :aquaq:9995 6 0    2014.01.08D11:51:01.923812000 2014.01.08D11:51:01.922390000      ()!()                        
    rdb_europe_1 rdb       :aquaq:9998   0                                  2014.01.08D11:51:38.347598000      ()!()                        
    rdb_europe_2 rdb       :aquaq:9997   0                                  2014.01.08D11:51:38.347598000      ()!()                        
    rdb1         rdb       :aquaq:5011 7 0    2014.01.08D11:51:01.928045000 2014.01.08D11:51:01.925078000      `datacentre`country!`essex`uk
    hdb3         hdb       :aquaq:5012 9 0    2014.01.08D11:51:38.349472000 2014.01.08D11:51:38.347598000      `datacentre`country!`essex`uk
    hdb2         hdb       :aquaq:5013 8 0    2014.01.08D11:51:01.928045000 2014.01.08D11:51:01.925078000      `datacentre`country!`essex`uk
    
    /- pull back hdbs.  Leave the attributes empty
    q).servers.getservers[`proctype;`hdb;()!();1b;0b] 
    procname proctype lastp                         w hpup        attributes                    attribmatch
    -------------------------------------------------------------------------------
    hdb3     hdb      2014.01.08D11:51:38.347598000 9 :aquaq:5012 `datacentre`country!`essex`uk ()!()      
    hdb2     hdb      2014.01.08D11:51:01.925078000 8 :aquaq:5013 `datacentre`country!`essex`uk ()!()      
    
    /- supply some attributes
    q).servers.getservers[`proctype;`hdb;(enlist`country)!enlist`uk;1b;0b] 
    procname proctype lastp                         w hpup        attributes                    attribmatch           
    -------------------------------------------------------------------------------
    hdb3     hdb      2014.01.08D11:51:38.347598000 9 :aquaq:5012 `datacentre`country!`essex`uk (,`country)!,(1b;,`uk)
    hdb2     hdb      2014.01.08D11:51:01.925078000 8 :aquaq:5013 `datacentre`country!`essex`uk (,`country)!,(1b;,`uk)
    q).servers.getservers[`proctype;`hdb;`country`datacentre!`uk`slough;1b;0b]                                                                                                                                                                                                    
    procname proctype lastp                         w hpup        attributes                    attribmatch                                    
    -------------------------------------------------------------------------------
    hdb3     hdb      2014.01.08D11:51:38.347598000 9 :aquaq:5012 `datacentre`country!`essex`uk `country`datacentre!((1b;,`uk);(0b;`symbol$()))
    hdb2     hdb      2014.01.08D11:51:01.925078000 8 :aquaq:5013 `datacentre`country!`essex`uk `country`datacentre!((1b;,`uk);(0b;`symbol$()))

.servers.getservers will try to automatically re-open connections if
required.

    q).servers.getservers[`proctype;`rdb;()!();1b;0b] 
    2014.01.08D12:01:06.023146000|aquaq|gateway1|INF|conn|attempting to open handle to :aquaq:9998
    2014.01.08D12:01:06.023581000|aquaq|gateway1|INF|conn|connection to :aquaq:9998 failed: hop: Connection refused
    2014.01.08D12:01:06.023597000|aquaq|gateway1|INF|conn|attempting to open handle to :aquaq:9997
    2014.01.08D12:01:06.023872000|aquaq|gateway1|INF|conn|connection to :aquaq:9997 failed: hop: Connection refused
    procname proctype lastp                         w hpup         attributes                    attribmatch
    -------------------------------------------------------------------------------
    rdb1     rdb      2014.01.08D11:51:01.925078000 7 :aquaq:5011 `datacentre`country!`essex`uk ()!()      
    
    /- If we only require one connection, and we have one open,then it doesn't retry connections
    q).servers.getservers[`proctype;`rdb;()!();1b;1b] 
    procname proctype lastp                         w hpup        attributes                    attribmatch
    -------------------------------------------------------------------------------
    rdb1     rdb      2014.01.08D11:51:01.925078000 7 :aquaq:5011 `datacentre`country!`essex`uk ()!()      

There are two other functions supplied for retrieving server details,
both of which are based on .servers.getservers. .servers.gethandlebytype
returns a single handle value, .servers.gethpupbytype returns a single
host:port value. Both will re-open connections if there are not any
valid connections. Both take two parameters:

-   types: the type to retrieve e.g. hdb;

-   selection-algorithm: can be one of any, last or roundrobin.


Connecting To Non-TorQ Processes
--------------------------------

Connections to non-torq (external) processes can also be established.
This is useful if you wish to integrate TorQ with an existing
infrastructure. Any process can connect to external processes, or it can
be managed by the discovery service only. Every external process should
have a type and name in the same way as TorQ processes, to enable them
to be located and used as required.

Non-TorQ processes need to be listed by default in
$KDBCONFIG/settings/nontorqprocess.csv. This file has the same format
as the standard process.csv file. The location of the non-TorQ process
file can be adjusted using the .servers.NONTORQPROCESSFILE variable. To
enable connections, set .servers.TRACKNONTORQPROCESS to 1b.

Example of nontorqprocess.csv file:

    host,port,proctype,procname
    aquaq,5533,hdb,extproc01
    aquaq,5577,hdb,extproc02


Manually Adding And Using Connections
-------------------------------------

Connections can also be manually added and used. See .api.p“.servers.\*”
for details.


IPC types
---------

In version kdb+ v3.4, two new IPC connection types were added. These new
types are unix domain sockets and SSL/TLS (tcps). The incoming
connections to a proctype can be set by updating .servers.SOCKETTYPE.

In the settings example below, everything that connects to the
tickerplant will use unix domain sockets.

    \d .servers 
    SOCKETTYPE:enlist[`tickerplant]!enlist `unix 

Attempting to open a unix domain socket connection to a process which
has an older kdb+ version will fail. We allow for processes to fallback
to tcp if this happens by setting .servers.SOCKETFALLBACK to true. It
will not fallback if the connection error message returned is one of the
following : timeout, access. It will also not fallback for SSL/TLS
(tcps) due to security concerns.

At the time of writing, using unix domain sockets syntax on windows will
appear to work whilst it’s actually falling back to tcp in the
background. This can be misleading so we disabled using them on windows.
