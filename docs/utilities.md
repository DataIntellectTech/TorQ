
<a name="ut"></a>

Utilities
=========

We have provided several utility scripts, which either implement
developer aids or standard operations which are useful across processes.

<a name="api.q"></a>

api.q
-----

This provides a mechanism for documenting and publishing
function/variable/table or view definitions within the kdb+ process. It
provides a search facility both by name and definition (in the case of
functions). There is also a function for returning the approximate
memory usage of each variable in the process in descending order.

Definitions are added using the .api.add function. A variable can be
marked as public or private, and given a description, parameter list and
return type. The search functions will return all the values found which
match the pattern irrespective of them having a pre-defined definition.

Whether a value is public or private is defined in the definitions
table. If not found then by default all values are private, except those
which live in the .q or top level namespace.

.api.f is used to find a function, variable, table or view based on a
case-insensitive pattern search. If a symbol parameter is supplied, a
wildcard search of \*\[suppliedvalue\]\* is done. If a string is
supplied, the value is used as is, meaning other non-wildcard regex
pattern matching can be done.

```no-highlight

    q).api.f`max                                                                                                                                                                                                                    
    name                | vartype   namespace public descrip             ..
    --------------------| -----------------------------------------------..
    maxs                | function  .q        1      ""                  ..
    mmax                | function  .q        1      ""                  ..
    .clients.MAXIDLE    | variable  .clients  0      ""                  ..
    .access.MAXSIZE     | variable  .access   0      ""                  ..
    .cache.maxsize      | variable  .cache    1      "The maximum size in..
    .cache.maxindividual| variable  .cache    1      "The maximum size in..
    max                 | primitive           1      ""                  ..
    q).api.f"max*"                                                                                                                                                                                                                  
    name| vartype   namespace public descrip params return
    ----| ------------------------------------------------
    maxs| function  .q        1      ""      ""     ""    
    max | primitive           1      ""      ""     ""    

```

.api.p is the same as .api.f, but only returns public functions. .api.u
is as .api.p, but only includes user defined values i.e. it excludes q
primitives and values found in the .q, .Q, .h and .o namespaces.
.api.find is a more general version of .api.f which can be used to do
case sensitive searches.

.api.s is used to search function definitions for specific values.

    q).api.s"*max*"                                                                                                                                                                                                                 
    function            definition                                       ..
    ---------------------------------------------------------------------..
    .Q.w                "k){`used`heap`peak`wmax`mmap`mphy`syms`symw!(.\"..
    .clients.cleanup    "{if[count w0:exec w from`.clients.clients where ..
    .access.validsize   "{[x;y;z] $[superuser .z.u;x;MAXSIZE>s:-22!x;x;'\..
    .servers.getservers "{[nameortype;lookups;req;autoopen;onlyone]\n r:$..
    .cache.add          "{[function;id;status]\n \n res:value function;\n..

.api.m is used to return the approximate memory usage of variables and
views in the process, retrieved using -22!. Views will be re-evaluated
if required. Use .api.mem\[0b\] if you do not want to evaluate and
return views.

    q).api.m[]                                                                                                                                                                                                                      
    variable          size    sizeMB
    --------------------------------
    .tz.t             1587359 2     
    .help.TXT         15409   0     
    .api.detail       10678   0     
    .proc.usage       3610    0     
    .proc.configusage 1029    0     
    ..

.api.whereami\[lambda\] can be used to retrieve the name of a function
given its definition. This can be useful in debugging.

    q)g:{x+y}                                                                                                                                                                                                                                                                     
    q)f:{20 + g[x;10]}                                                                                                                                                                                                                                                            
    q)f[10]                                                                                                                                                                                                                                                                       
    40
    q)f[`a]                                                                                                                                                                                                                                                                       
    {x+y}
    `type
    +
    `a
    10
    q)).api.whereami[.z.s]                                                                                                                                                                                                                                                        
    `..g

<a name="tim"></a>

timer.q
-------

kdb+ provides a single timer function, .z.ts which is triggered with the
frequency specified by -t. We have provided an extension to allow
multiple functions to be added to the timer and fired when required. The
basic concept is that timer functions are registered in a table, with
.z.ts periodically checking the table and running whichever functions
are required. This is not a suitable mechanism where very high frequency
timers are required (e.g. sub 500ms).

There are two ways a function can be added to a timer- either as a
repeating timer, or to fire at a specific time. When a repeating timer
is specified, there are three options as to how the timer can be
rescheduled. Assuming that a timer function with period P is scheduled
to fire at time T0, actually fires at time T1 and finishes at time T2,
then

-   mode 0 will reschedule for T0+P;

-   mode 1 will reschedule for T1+P;

-   mode 2 will reschedule for T2+P.

Both mode 0 and mode 1 have the potential for causing the timer to back
up if the finish time T2 is after the next schedule time. See
.api.p“.timer.\*”for more details.

<a name="async"></a>

async.q
-------

kdb+ processes can communicate with each using either synchronous or
asynchronous calls. Synchronous calls expect a response and so the
server must process the request when it is received to generate the
result and return it to the waiting client. Asynchronous calls do not
expect a response so allow for greater flexibility. The effect of
synchronous calls can be replicated with asynchronous calls in one of
two ways (further details in section gateway):

-   deferred synchronous: the client sends an async request, then blocks
    on the handle waiting for the result. This allows the server more
    flexibility as to how and when the query is processed;

-   asynchronous postback: the client sends an async request which is
      wrapped in a function to be posted back to the client when the
      result is ready. This allows the server flexibility as to how and
      when the query is processed, and allows the client to continue
      processing while the server is generating the result.

The code for both of these can get a little tricky, largely due to the
amount of error trapping required. We have provided two functions to
allow these methods to be used more easily. .async.deferred takes a list
of handles and a query, and will return a two item list of
(success;results).

    q).async.deferred[3 5;({system"sleep 1";system"p"};())]                                                                                                                                                                                     
    1    1   
    9995 9996
    q).async.deferred[3 5;({x+y};1;2)]                                                                                                                                                                                                          
    1 1
    3 3
    q).async.deferred[3 5;({x+y};1;`a)]                                                                                                                                                                                                         
    0                         0                        
    "error: server fail:type" "error: server fail:type"
    q).async.deferred[3 5 87;({system"sleep 1";system"p"};())]                                                                                                                                                                                  
    1     1     0                                       
    9995i 9996i "error: comm fail: failed to send query"

.async.postback takes a list of handles, a query, and the name or lambda
of the postback function to return the result to. It will immediately
return a success vector, and the results will be posted back to the
client when ready.

    q).async.postback[3 5;({system"sleep 1";system"p"};());`showresult]                                                                                                                                                                         
    11b
    q)                                                                                                                                                                                                                                          
    q)9995i
    9996i
                                                                                                                                                                                                                                                
    q).async.postback[3 5;({x+y};1;2);`showresult]                                                                                                                                                                                              
    11b
    q)3
    3
                                                                                                                                                                                                                                                
    q).async.postback[3 5;({x+y};1;`a);`showresult]                                                                                                                                                                                             
    11b
    q)"error: server fail:type"
    "error: server fail:type"
                                                                                                                                                                                                                                                
    q).async.postback[3 5;({x+y};1;`a);showresult]                                                                                                                                                                                              
    11b
    q)"error: server fail:type"
    "error: server fail:type"
                                                                                                                                                                                                                                                
    q).async.postback[3 5 87;({x+y};1;2);showresult]                                                                                                                                                                                            
    110b
    q)3
    3

For more details, see .api.p“.async.\*”.

<a name="cache"></a>

cache.q
-------

cache.q provides a mechanism for storing function results in a cache and
returning them from the cache if they are available and non stale. This
can greatly boost performance for frequently run queries.

The result set cache resides in memory and as such takes up space. It is
up to the programmer to determine which functions are suitable for
caching. Likely candidates are those where some or all of the following
conditions hold:

-   the function is run multiple times with the same parameters (perhaps
    different clients all want the same result set);

-   the result set changes infrequently or the clients can accept
      slightly out-of-date values;

-   the result set is not too large and/or is relatively expensive to
      produce. For example, it does not make sense to cache raw data
      extracts.

The cache has a maximum size and a minimum size for any individual
result set, both of which are defined in the configuration file. Size
checks are done with -22! which will give an approximation (but
underestimate) of the result set size. In the worst case the estimate
could be half the size of the actual size.

If a new result set is to be cached, the size is checked. Assuming it
does not exceed the maximum individual size then it is placed in the
cache. If the new cache size would exceed the maximum allowed space,
other result sets are evicted from the cache. The current eviction
policy is to remove the least recently accessed result sets until the
required space is freed. The cache performance is tracked in a table.
Cache adds, hits, fails, reruns and evictions are monitored.

The main function to use the cache is .cache.execute\[function;
staletime\]. If the function has been executed within the last
staletime, then the result is returned from the cache. Otherwise the
function is executed and placed in the cache.

The function is run and the result placed in the cache:

    q)\t r:.cache.execute[({system"sleep 2"; x+y};1;2);0D00:01]                                                                                                                                                                     
    2023
    q)r                                                                                                                                                                                                                             
    3

The second time round, the result set is returned immediately from the
cache as we are within the staletime value:

    q)\t r1:.cache.execute[({system"sleep 2"; x+y};1;2);0D00:01]                                                                                                                                                                    
    0
    q)r1                                                                                                                                                                                                                            
    3

If the time since the last execution is greater than the required stale
time, the function is re-run, the cached result is updated, and the
result returned:

    q)\t r2:.cache.execute[({system"sleep 2"; x+y};1;2);0D00:00]                                                                                                                                                                    
    2008
    q)r2                                                                                                                                                                                                                            
    3

The cache performance is tracked:

    q).cache.getperf[]                                                                                                                                                                                                              
    time                          id status function                  
    ------------------------------------------------------------------
    2013.11.06D12:41:53.103508000 2  add    {system"sleep 2"; x+y} 1 2
    2013.11.06D12:42:01.647731000 2  hit    {system"sleep 2"; x+y} 1 2
    2013.11.06D12:42:53.930404000 2  rerun  {system"sleep 2"; x+y} 1 2

See .api.p.cache.\*for more details.

<a name="email"></a>

email.q
-------

A library file is provided to allow TorQ processes to send emails using
an SMTP server. This is a wrapper around the standard libcurl library.
The library file is currently available for Windows (32 bit), Linux (32
and 64 bit) and OSX (32 and 64 bit). The associated q script contains
two main methods for creating a connection and sending emails. The email
library requires a modification to the path to find the required libs -
see the top of email.q for details.

The main connection method .email.connect takes a single dictionary
parameter and returns 0i for success and -1i for failure.

| Parameter | Req  |  Type   |               Description                |
| :-------: | :--: | :-----: | :--------------------------------------: |
|    url    |  Y   | symbol  | URL of mail server e.g. smtp://mail.example.com |
|   user    |  Y   | symbol  |       Username of user to login as       |
| password  |  Y   | symbol  |            Password for user             |
|  usessl   |  N   | boolean | Connect using SSL/TLS, defaults to false |
|   from    |  N   | symbol  | Email from field, defaults to torq@aquaq.co.uk |
|   debug   |  N   | integer | Debug level. 0=no output, 1=normal output, 2=verbose output. Default is 1 |


An example is:

    q).email.connect[`url`user`password`from`usessl`debug!(`$"smtp://mail.example.com:80";`$"torquser@aquaq.co.uk";`hello;`$"torquser@aquaq.co.uk";0b;1i)]
    02 Jan 2015 11:45:19   emailConnect: url is set to smtp://mail.example.com:80
    02 Jan 2015 11:45:19   emailConnect: user is set to torquser@aquaq.co.uk
    02 Jan 2015 11:45:19   emailConnect: password is set
    02 Jan 2015 11:45:19   emailConnect: from is set torquser@aquaq.co.uk
    02 Jan 2015 11:45:19   emailConnect: trying to connect
    02 Jan 2015 11:45:19   emailConnect: connected, socket is 5
    0i

The email sending function .email.send takes a single dictionary
parameter containing the details of the email to send. A connection must
be established before an email can be sent. The send function returns an
integer of the email length on success, or -1 on failure.


| Parameter | Req  |        Type        |               Description                |
| :-------: | :--: | :----------------: | :--------------------------------------: |
|    to     |  Y   |   symbol (list)    |           addresses to send to           |
|  subject  |  Y   |     char list      |              email subject               |
|   body    |  Y   | list of char lists |                email body                |
|    cc     |  N   |   symbol (list)    |                 cc list                  |
| bodyType  |  N   |       symbol       | type of email body. Can be \`text or \`html. Default is \`text |
|   debug   |  N   |      integer       | Debug level. 0=no output, 1=normal output,2=verbose output. Default is 1 |

An example is:

    q).email.send[`to`subject`body`debug!(`$"test@aquaq.co.uk";"test email";("hi";"this is an email from torq");1i)]
    02 Jan 2015 12:39:29   sending email with subject: test email
    02 Jan 2015 12:39:29   email size in bytes is 16682
    02 Jan 2015 12:39:30   emailSend: email sent
    16682i

Note that if emails are sent infrequently the library must re-establish
the connection to the mail server (this will be done automatically after
the initial connection). In some circumstances it may be better to batch
emails together to send, or to offload email sending to separate
processes as communication with the SMTP server can take a little time.

Two further functions are available, .email.connectdefault and
.email.senddefault. These are as above but will use the default
configuration defined within the configuration files as the relevant
parameters passed to the methods. In addition, .email.senddefault will
automatically establish a connection.

    q).email.senddefault[`to`subject`body!(`$"test@aquaq.co.uk";"test email";("hi";"this is an email from torq"))]
    2015.01.02D12:43:34.646336000|aquaq||discovery1|INF|email|sending email
    2015.01.02D12:43:35.743887000|aquaq||discovery1|INF|email|connection to mail server successful
    2015.01.02D12:43:37.250427000|aquaq|discovery1|INF|email|email sent
    16673i
    q).email.senddefault[`to`subject`body!(`$"test@aquaq.co.uk";"test email 2";("hi";"this is an email from torq"))]
    2015.01.02D12:43:48.115403000|aquaq|discovery1|INF|email|sending email
    2015.01.02D12:43:49.385807000|aquaq|discovery1|INF|email|email sent
    16675i
    q).email.senddefault[`to`subject`body!(`$"test@aquaq.co.uk";"test email 2";("hi";"this is an email from torq");`"$/home/ashortt/example.txt")]
    2015.01.02D12:43:48.115403000|aquaq|discovery1|INF|email|sending email
    2015.01.02D12:43:49.385807000|aquaq|discovery1|INF|email|email sent
    47338i

.email.test will attempt to establish a connection to the default
configured email server and send a test email to the specified address.
debug should be set to 2i (verbose) to extract the full information.

    q).email.debug:2i
    q).email.test `$"test@aquaq.co.uk"
    ...

Additionally functions are available within the email library. See
.api.p.email.\*for more details.

### Emails with SSL certificates from Windows

If you wish to send emails via an account which requires authentication
from Windows (e.g. Hotmail, Gmail) then you have to do a few extra steps
as usessl must be true and Windows does not usually find the correct
certificate. The steps are:

-   download
    [this](https://raw.githubusercontent.com/bagder/ca-bundle/master/ca-bundle.crt)
    and save it to your PC

-   set

          CURLOPT_CAINFO=c:/path/to/cabundle_file/ca-bundle.crt 

More information is available
[here](http://richardwarrender.com/2007/05/the-secret-to-curl-in-php-on-windows/)
and [here](http://curl.haxx.se/docs/caextract.html)

<a name="tz"></a>

timezone.q
----------

A slightly customised version of the timezone conversion functionality
from code.kx. It loads a table of timezone information from
$KDBCONFIG. See .api.p.tz.\*for more details.

<a name="com"></a>

compress.q
----------

compress.q applies compression to any kdb+ database, handles all
partition types including date, month, year, int, and can deal with top
level splayed tables. It will also decompress files as required. Once
the compression/decompression is complete, summary statistics are
returned, with detailed statistics for each compressed or decompressed
file held in a table.

The utility is driven by the configuration specified within a csv file.
Default parameters can be given, and these can be used to compress all
files within the database. However, the compress.q utility also provides
the flexibility to compress different tables with different compression
parameters, and different columns within tables using different
parameters. A function is provided which will return a table showing
each file in the database to be compressed, and how, before the
compression is performed.

Compression is performed using the -19! operator, which takes 3
parameters; the compression algorithm to use (0 - none, 1 - kdb+ IPC, 2
- gzip), the compression blocksize as a power of 2 (between 12 and 19),
  and the level of compression to apply (from 0 - 9, applicable only for
  gzip). (For further information on -19! and the parameters used, see
  code.kx.com.)

The compressionconfig.csv file should have the following format:

    table,minage,column,calgo,cblocksize,clevel
    default,20,default,2,17,6
    trades,20,default,1,17,0
    quotes,20,asize,2,17,7
    quotes,20,bsize,2,17,7

This file can be placed in the config folder, or a path to the file
given at run time.

The compression utility compresses all tables and columns present in the
HDB but not specified in the driver file according the default
parameters. In effect, to compress an entire HDB using the same
compression parameters, a single row with name default would suffice. To
specify that a particular table should be compressed in a certain
different manner, it should be listed in the table. If default is given
as the column for this table, then all of the columns of that table will
be compressed accordingly. To specify the compression parameters for
particular columns, these should be listed individually. For example,
the file above will compress trades tables 20 days old or more with an
algorithm of 1, and a blocksize of 17. The asize and bsize columns of
any quotes tables older than 20 days old will be compressed using
algorithm 2, blocksize 17 and level 7. All other files present will be
compressed according to the default, using an algorithm 2, blocksize 17
and compression level 6. To leave files uncompressed, you must specify
them explicitly in the table with a calgo of 0. If the file is already
compressed, note that an algorithm of 0 will decompress the file.

This utility should be used with caution. Before running the compression
it is recommended to run the function .cmp.showcomp, which takes three
parameters - the path to the database, the path to the csv file, and the
maximum age of the files to be compressed:

    .cmp.showcomp[`:/full/path/to/HDB;.cmp.inputcsv;maxage]   
    		/- for using the csv file in the config folder
    .cmp.showcomp[`:/full/path/to/HDB;`:/full/path/to/csvfile;maxage]    
    		/- to specify a file

This function produces a table of the files to be compressed, the
parameters with which they will be compressed, and the current size of
the file. Note that the current size column is calculated using hcount;
on a file which is already compressed this returns the uncompressed
length, i.e. this cannot be used as a signal as to whether the file is
compressed already.

    fullpath                        column table  partition  age calgo cblocksize clevel compressage currentsize
    -------------------------------------------------------------------------------------
    :/home/hdb/2013.11.05/depth/asize1 asize1 depth  2013.11.05 146 0     17         8      1           787960
    :/home/hdb/2013.11.05/depth/asize2 asize2 depth  2013.11.05 146 0     17         8      1           787960
    :/home/hdb/2013.11.05/depth/asize3 asize3 depth  2013.11.05 146 0     17         8      1           787960
    :/home/hdb/2013.11.05/depth/ask1   ask1   depth  2013.11.05 146 0     17         8      1           1575904
    ....

To then run the compression function, use .cmp.compressmaxage with the
same parameters as .cmp.showcomp (hdb path, csv path, maximum age of
files):

    .cmp.compressmaxage[`:/full/path/to/HDB;.cmp.inputcsv;maxage]   
    		/- for using the csv file in the config folder
    .cmp.compressmaxage[`:/full/path/to/HDB;`:/full/path/to/csvfile;maxage]    
    		/- to specify a file

To run compression on all files in the database disregarding the maximum
age of the files (i.e. from minage as specified in the configuration
file to infinitely old), then use:

    .cmp.docompression[`:/full/path/to/HDB;.cmp.inputcsv]   
    		/- for using the csv file in the config folder
    .cmp.docompression[`:/full/path/to/HDB;`:/full/path/to/csvfile]    
    		/- to specify a file

Logs are produced for each file which is compressed or decompressed.
Once the utility is complete, the statistics of the compression are also
logged. This includes the memory savings in MB from compression, the
additional memory usage in MB for decompression, the total compression
ratio, and the total decompression ratio:

    |comp1|INF|compression|Memory savings from compression: 34.48MB. Total compression ratio: 2.51.
    |comp1|INF|compression|Additional memory used from de-compression: 0.00MB. Total de-compression ratio: .
    |comp1|INF|compression|Check .cmp.statstab for info on each file.

A table with the compressed and decompressed length for each individual
file, in descending order of compression ratio, is also produced. This
can be found in .cmp.statstab:

    file                    algo compressedLength uncompressedLength compressionratio
    -----------------------------------------------------------------------------------
    :/hdb/2014.03.05/depth/asize1 2    89057            772600             8.675343
    :/hdb/2014.01.06/depth/asize1 2    114930           995532             8.662073
    :/hdb/2014.03.05/depth/bsize1 2    89210            772600             8.660464
    :/hdb/2014.03.12/depth/bsize1 2    84416            730928             8.658643
    :/hdb/2014.01.06/depth/bsize1 2    115067           995532             8.651759
    .....

A note for windows users - windows supports compression only with a
compression blocksize of 16 or more.

<a name="data"></a>

dataloader.q 
------------

This script contains some utility functions to assist in loading data
from delimited files (e.g. comma separated, tab delimited). It is a more
generic version of [the data loader example on
code.kx](http://code.kx.com/wiki/Cookbook/LoadingFromLargeFiles).
The supplied functions allow data to be read in configurable size chunks
and written out to the database. When all the data is written, the
on-disk data is re-sorted and the attributes are applied. The main
function is .loader.loadalldata which takes two parameters- a dictionary
of loading parameters and a directory containing the files to read. The
dictionary should/can have the following fields:


|    Parameter    | Req  |     Type     |               Description                |
| :-------------: | :--: | :----------: | :--------------------------------------: |
|     headers     |  Y   | symbol list  | Names of the header columns in the file  |
|      types      |  Y   |  char list   |     Data types to read from the file     |
|    separator    |  Y   | char\[list\] | Delimiting character. Enlist it if first line of file is header data |
|    tablename    |  Y   |    symbol    |      Name of table to write data to      |
|      dbdir      |  Y   |    symbol    |        Directory to write data to        |
|  partitiontype  |  N   |    symbol    | Partitioning to use. Must be one of 
\`date\`month\`year\`int. Default is \`date |
|  partitioncol   |  N   |    symbol    | Column to use to extract partition information.Default is `time |
| dataprocessfunc |  N   |   function   | Diadic function to process data after it has been read in. First argument is load parameters dictionary, second argument is data which has been read in. Default is {[x;y] y} |
|    chunksize    |  N   |     int      | Data size in bytes to read in one chunk. Default is 100 MB |
|   compression   |  N   |   int list   | Compression parameters to use e.g. 17 2 6. Default is empty list for no compression |
|       gc        |  N   |   boolean    | Whether to run garbage collection at appropriate points. Default is 0b (false) |

Example usage:

    .loader.loadallfiles[`headers`types`separator`tablename`dbdir!(`sym`time`price`volume;"SP  FI";",";`trade;`:hdb); `:TDC/toload]
    .loader.loadallfiles[`headers`types`separator`tablename`dbdir`dataprocessfunc`chunksize`partitiontype`partitioncol`compression`gc!(`sym`time`price`volume;"SP  FI";enlist",";`tradesummary;`:hdb;{[p;t] select sum size, max price by date:time.date from t};`int$500*2 xexp 20;`month;`date;16 1 0;1b); `:TDC/toload]

<a name="sub"></a>

subscriptions.q
---------------

The subscription utilities allow multiple subscriptions to different
data sources to be managed and maintained. Automatic resubscriptions in
the event of failure are possible, along as specifying whether the
process will get the schema and replay the log file from the remote
source (e.g. in the case of tickerplant subscriptions).

.sub.getsubscriptionhandles is used to get a table of processes to
subscribe to. The following can be used to return a table of all
connected processes of type tickerplant:

    .sub.getsubscriptionhandles[`tickerplant;`;()!()]

.sub.subscribe is used to subscribe to a process for the supplied list
of tables and instruments. For example, to subscribe to instruments A, B
and C for the quote table from all tickerplants:

    .sub.subscribe[`trthquote;`A`B;0b;0b] each .sub.getsubscriptionhandles[`tickerplant;`;()!()]

The subscription method uses backtick for “all” (which is the same as
kdb+tick). To subscribe to all tables, all instruments, from all
tickerplants:

    .sub.subscribe[`;`;0b;0b] each .sub.getsubscriptionhandles[`tickerplant;`;()!()]

See .api.p“.sub.\*” for more details.

<a name="ps"></a>

pubsub.q
--------

pubsub.q is essentially a placeholder script to allow publish and
subscribe functionality to be implemented. Licenced kdb+tick users can
use the publish and subscribe functionality implemented in u.\[k|q\]. If
u.\[k|q\] is placed in the common code directory and loaded before
pubsub.q (make sure u.\[k|q\] is listed before pubsub.q in order.txt)
then publish and subscribe will be implemented. You can also build out
this file to add your own publish and subscribe routines as required.

<a name="tp"></a>

tplogutils.q
------------

tplogutils.q contains functions for recovering tickerplant log files.
Under certain circumstances the tickerplant log file can become corrupt
by having an invalid sequence of bytes written to it. A log file can be
recovered using a simple recovery method. However, this will only
recover messages up to the first invalid message. The recovery functions
defined in tplogutils.q allow all valid messages to be recovered from
the tickerplant log file.

<a name="mon"></a>

monitoringchecks.q
------------------

monitoringchecks.q implements a set of standard, basic monitoring
checks. They include checks to ensure:

-   table sizes are increasing during live capture

-   the HDB data saves down correctly

-   the allocated memory of a process does not increase past a certain
      size

-   the size of the symbol list in memory doesn’t grow to big

-   the process does not have too much on its pending subscriber queue

These checks are intended to be run by the reporter process on a
schedule, and any alerts emailed to an appropriate recipient list.

<a name="hb"></a>

heartbeat.q
-----------

heartbeat.q implements heartbeating, and relies on both timer.q and
pubsub.q. A table called heartbeat will be published periodically,
allowing downstream processes to detect the availability of upstream
components. The heartbeat table contains a heartbeat time and counter.
The heartbeat script contains functions to handle and process heartbeats
and manage upstream process failures. See .api.p.hb.\*for details.

<a name="wu"></a>

dbwriteutils.q
--------------

This contains a set of utility functions for writing data to historic
databases.

### Sorting and Attributes

The sort utilities allow the sort order and attributes of tables to be
globally defined. This helps to manage the code base when the data can
potentially be written from multiple locations (e.g. written from the
RDB, loaded from flat file, replayed from the tickerplant log). The
configuration is defined in a csv which defaults to $KDBCONFG/sort.csv.
The default setup is that every table is sorted by sym and time, with a
p attribute on sym (this is the standard kdb+ tick configuration).

    aquaq$ tail config/sort.csv 
    tabname,att,column,sort
    default,p,sym,1
    default,,time,1

As an example, assume we have an optiontrade table which we want to be
different from the standard set up. We would like the table to be sorted
by optionticker and then time, with a p attribute on optionticker. We
also have a column called underlyingticker which we can put an attribute
on as it is derived from optionticker (so there is an element of
de-normalisation present in the table). We also have an exchange field
which we would like to put a g attribute on. All other tables we want to
be sorted and parted in the standard way. The configuration file would
look like this (sort order is derived from the order within the file
combined with the sort flag being set to true):

    aquaq$ tail config/sort.csv                
    tabname,att,column,sort
    default,p,sym,1
    default,,time,1
    optiontrade,p,optionticker,1
    optiontrade,,exchtime,1
    optiontrade,p,underlyingticker,0
    optiontrade,g,exchange,0

To invoke the sort utilities, supply a list of (tablename; partitions)
e.g.

    q).sort.sorttab(`trthtrade;`:hdb/2014.11.20/trthtrade`:hdb/2014.11.20/trthtrade)
    2014.12.03D09:56:19.214006000|aquaq|test|INF|sort|sorting the trthtrade table
    2014.12.03D09:56:19.214045000|aquaq|test|INF|sorttab|No sort parameters have been specified for : trthtrade. Using default parameters
    2014.12.03D09:56:19.214057000|aquaq|test|INF|sortfunction|sorting :hdb/2014.11.19/trthtrade/ by these columns : sym, time
    2014.12.03D09:56:19.219716000|aquaq|test|INF|applyattr|applying p attr to the sym column in :hdb/2014.11.19/trthtrade/
    2014.12.03D09:56:19.220846000|aquaq|test|INF|sortfunction|sorting :hdb/2014.11.20/trthtrade/ by these columns : sym, time
    2014.12.03D09:56:19.226008000|aquaq|test|INF|applyattr|applying p attr to the sym column in :hdb/2014.11.20/trthtrade/
    2014.12.03D09:56:19.226636000|aquaq|test|INF|sort|finished sorting the trthtrade table

A different sort configuration file can be loaded with

    .sort.getsortcsv[`:file]

### Garbage Collection

The garbage collection utility prints some debug information before and
after the garbage collection.

    q).gc.run[]                                                                                                                                                      
    2014.12.03D10:22:51.688435000|aquaq|test|INF|garbagecollect|Starting garbage collect. mem stats: used=2 MB; heap=1984 MB; peak=1984 MB; wmax=0 MB; mmap=0 MB; mphy=16384 MB; syms=0 MB; symw=0 MB
    2014.12.03D10:22:53.920656000|aquaq|test|INF|garbagecollect|Garbage collection returned 1472MB. mem stats: used=2 MB; heap=512 MB; peak=1984 MB; wmax=0 MB; mmap=0 MB; mphy=16384 MB; syms=0 MB; symw=0 MB

### Table Manipulation

The table manipulation utilities allow table manipulation routines to be
defined in a single place. This is useful when data can be written from
mutliple different processes e.g. RDB, WDB, or tickerplant log replay.
Instead of having to create a separate definition of customised
manipulation in each process, it can be done in a single location and
invokved in each process.

<a name="help"></a>

help.q
------

The standard help.q from code.kx provides help utilities in the console.
This should be kept up to date with
[[code.kx](http://code.kx.com/wsvn/code/kx/kdb+/d/help.q)].

    q)help`                                                                                                                                                                                                                         
    adverb    | adverbs/operators
    attributes| data attributes
    cmdline   | command line parameters
    data      | data types
    define    | assign, define, control and debug
    dotz      | .z locale contents
    errors    | error messages
    save      | save/load tables
    syscmd    | system commands
    temporal  | temporal - date & time casts
    verbs     | verbs/functions

<a name="html"></a>

html.q
------

An HTML utility has been added to accompany the HTML5 front end for the
Monitoring process. It includes functions to format dates, tables to csv
to configure the HTML file to work on the correct process. It is
accessible from the `.html` namespace.

<a name="eodtime"></a>

eodtime.q
---------

This script provides functionality for managing timezones. TorQ can be 
configured to timestamp data in a specific timezone, while also being
configured to perform the end of day rollover in another timezone, at a
configurable time.

These options are handled by three settings:

| Setting | Req  |  Type   |               Description                |
| :-----: | :--: | :-----: | :--------------------------------------: |
| .eodtime.rolltimeoffset |  Y   | timespan  | Offset from default midnight roll time |
| .eodtime.rolltimezone |  Y   | symbol  | Time zone in which to rollover |
| .eodtime.datatimezone |  Y   | symbol  | Time zone in which to timestamp data in TP |

The default configuration sets both timezones to GMT and has the rollover
performed at midnight.

An example configuration where data is stamped in GMT, but the rollover
occurs at 5PM New York time would be:

    .eodtime.rolltimeoffset:-0D07:00:00.000000000; // 5 PM i.e. 7 hours before midnight
    .eodtime.rolltimezone:`$"America/New_YorK";    // roll in NYC time
    .eodtime.datatimezone:`$"GMT";                 // timestamp in GMT

Note that the rolltimeoffset can be negative - this will cause the rollover to happen 
"yesterday", meaning that at the rolltime, the trading date will become the day *after*
the calendar date. Where this is positive, the rollover occurs "today" and so the trading
date will become the current calendar date.

<a name="addu"></a>

Additional Utilities
--------------------

There are some additional user contributed utility scripts available on
code.kx which are good candidates for inclusion. These could either be
dropped into the common code directory, or if not globally applicable
then in the code directory for either the process type or name. The full
set of user contributed code is documented
[here](http://code.kx.com/wiki/Contrib).

<a name="api"></a>

Full API
--------

The full public api can be found by running

    q).api.u`                                                                                                                                                                                                                       
    name             | vartype  namespace public descrip                 ..
    -----------------| --------------------------------------------------..
    .proc.createlog  | function .proc     1      "Create the standard out..
    .proc.rolllogauto| function .proc     1      "Roll the standard out/e..
    .proc.loadf      | function .proc     1      "Load the specified file..
    .proc.loaddir    | function .proc     1      "Load all the .q and .k ..
    .lg.o            | function .lg       1      "Log to standard out"   ..
    ..

Combined with the commented configuration file, this should give a good
overview of the functionality available. A description of the individual
namespaces is below- run .api.u namespace\*to list the functions.

| Namespace |              Description               |
| :-------: | :------------------------------------: |
|   .proc   |              Process API               |
|    .lg    |     Standard out/error logging API     |
|   .err    |           Error throwing API           |
|  .usage   |           Usage logging API            |
|  .access  |            Permissions API             |
| .clients  |          Client tracking API           |
| .servers  |          Server tracking API           |
|  .async   |        Async communication API         |
|  .timer   |               Timer API                |
|  .cache   |              Caching API               |
|    .tz    |        Timezone conversions API        |
|  .checks  |             Monitoring API             |
|   .cmp    |            Compression API             |
|    .ps    |       Publish and Subscribe API        |
|    .hb    |            Heartbeating API            |
|  .loader  |            Data Loader API             |
|   .sort   | Data sorting and attribute setting API |
|   .sub    |            Subscription API            |
|    .gc    |         Garbage Collection API         |
|  .tplog   |       Tickerplant Log Replay API       |
|   .api    |           API management API           |

  
<a name="u.q"></a>

Modified u.q
------------

Starting in kdb+ v3.4, the new broadcast feature has some performance
benefits. It works by serialising a message once before sending it
asynchronously to a list of subscribers whereas the previous method
would serialise it separately for each subscriber. To take advantage of
this, we’ve modified u.q. This can be turned off by setting .u.broadcast
to false. It is enabled by default, but will only override default
publishing if the kdb+ version being used is 3.4 or after.
