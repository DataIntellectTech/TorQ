
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

.api.torqnamespaces is a variable which returns a symbol list of torq 
namespaces.

.api.exportconfig uses the table returned by .api.f` to give a table
of the current values and descriptions of variables within the
inputted namespace. This can be used to quickly see what configurable
variables are currently set to.

.api.exportallconfig is .api.exportconfig evaluated with all the
available torqnamespaces and returns the same format as .api.exportconfig.

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

apidetails.q
----------------

This file in both the common and the handler directories is used to add to the api using the functions defined in api.q

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

Two additional functions are available, .email.connectdefault and
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

A further function .email.sendviaservice can be used to send an email using the default mail server on a separate specified process and can be used to allow latency sensitive processes to offload this piece of functionality. 

The function takes two parameters a process and a dictionary which should follow  the same format as .email.send. The function uses the .async.postback Utility to send the email by calling .email.servicesend on the specified process. The postback function immediately returns a success boolean indicating that the the async request has been sent and when the function has been run on the server the results are posted back to the client function  email.servicecallback which logs the email status.
 
```
q).email.sendviaservice[`emailservice;`to`subject`body!(`$"test@aquaq.co.uk";"test email";("hi";"this is an email from torq"))]
1b
q)2019.01.04D12:02:57.641940000|gateway|gateway1|INF|email|Email sent successfully

```

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
|     symdir      |  N   |    symbol    |      Directory to enumerate against      |
|  partitiontype  |  N   |    symbol    | Partitioning to use. Must be one of \`date\`month\`year\`int. Default is \`date |
|  partitioncol   |  N   |    symbol    | Column to use to extract partition information.Default is `time |
| dataprocessfunc |  N   |   function   | Diadic function to process data after it has been read in. First argument is load parameters dictionary, second argument is data which has been read in. Default is {[x;y] y} |
|    chunksize    |  N   |     int      | Data size in bytes to read in one chunk. Default is 100 MB |
|   compression   |  N   |   int list   | Compression parameters to use e.g. 17 2 6. Default is empty list for no compression |
|       gc        |  N   |   boolean    | Whether to run garbage collection at appropriate points. Default is 0b (false) |
|  filepattern    |  N   | char\[list\] | Pattern used to only load certain files e.g. "*.csv",("*.csv","*.txt")|

Example usage:

    .loader.loadallfiles[`headers`types`separator`tablename`dbdir!(`sym`time`price`volume;"SP  FI";",";`trade;`:hdb); `:TDC/toload]
    .loader.loadallfiles[`headers`types`separator`tablename`dbdir`dataprocessfunc`chunksize`partitiontype`partitioncol`compression`gc`filepattern!(`sym`time`price`volume;"SP  FI";enlist",";`tradesummary;`:hdb;{[p;t] select sum size, max price by date:time.date from t};`int$500*2 xexp 20;`month;`date;16 1 0;1b;("*.csv";"*.txt")); `:TDC/toload]

<a name="sub"></a>

subscriptions.q
---------------

The subscription utilities allow multiple subscriptions to different
data sources to be managed and maintained. Automatic resubscriptions in
the event of failure are possible, along as specifying whether the
process will get the schema and replay the log file from the remote
source (e.g. in the case of tickerplant subscriptions).

.sub.getsubscriptionhandles is used to get a table of processes to
subscribe to. It takes a process type and process name, where `()` or a null
symbol can be used for all:

    .sub.getsubscriptionhandles[`tickerplant;();()!()]      / all processes of type tickerplant
    .sub.getsubscriptionhandles[`;`rdb1;()!()]              / all processes called 'rdb1'
    .sub.getsubscriptionhandles[`;`;()!()]                  / all processes
    .sub.getsubscriptionhandles[();();()!()]                / nothing

.sub.subscribe is used to subscribe to a process for the supplied list
of tables and instruments. For example, to subscribe to instruments A, B
and C for the quote table from all tickerplants:

    .sub.subscribe[`trthquote;`A`B;0b;0b] each .sub.getsubscriptionhandles[`tickerplant;();()!()]

The subscription method uses backtick for “all” (which is the same as
kdb+tick). To subscribe to all tables, all instruments, from all
tickerplants:

    .sub.subscribe[`;`;0b;0b] each .sub.getsubscriptionhandles[`tickerplant;();()!()]

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

<a name="kafka"></a>

kafka.q
-------

kafka.q provides q language bindings for Apache Kafka, a 'distributed streaming
platform', a real time messaging system with persistent storage in message logs.

The core functionality of Kafka – pub/sub messaging with persisted logs, will be
familiar to most readers as the functionality offered by the kdb+ tick
tickerplant. The tickerplant log allows the real time database and other
consumers to replay a day’s events to recover state. An application architecture
built around Kafka could dispense with a tickerplant component, and have RDBs
and other real time clients query Kafka on startup for offsets, and play back
the data they need. While not suitable for very low latency access to streaming
data, it would carry some advantages for very high throughput applications,
particularly those in the cloud:

* Kafka’s distributed nature should allow it to scale more transparently than
splitting tickerplants by instrument universe or message type
* Replaying from offsets is the same interface as live pub/sub and doesn’t require
filesystem access to the tickerplant log, so RDB’s and other consumer could be
on a different server

By default, the Kafka bindings will be loaded into all TorQ processes running on
l64 systems (the only platform currently supported). An example of usage is
shown here (this assumes a local running instance of kafka - instructions for
this are available on the [kafkaq](https://github.com/AquaQAnalytics/kafkaq) github 
repo):

```
q).kafka.initconsumer[`localhost:9092;()]
q).kafka.initproducer[`localhost:9092;()]
q)kupd / print default definition for incoming data - ignore key, print message
as ascii
{[k;x] -1 `char$x;}
q).kafka.subscribe[`test;0] / subscribe to topic test, partition 0
q)pub:{.kafka.publish[`test;0;`;`byte$x]} / define pub to publish text input to topic
test on partition 0 with no key defined
q)pub"hello world"
q)hello world

```

Limitations of the current implementation:

* Only l64 supported
* Single consumer thread subscribed to one topic at a time

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

rmvr.q
-----------

This file contains a function which can be used to convert environment variable paths into a full path from the root directory.

os.q
-----------

A file with various q functions to perform system operations. This will detect your operating system and will perform the correct commands depending on what you are using.

This is a modification of a script developed by Simon Garland.

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

A table containing the valid timezones is loaded into TorQ processes as .tz.t

An example configuration where data is stamped in GMT, but the rollover
occurs at 5PM New York time would be:

    .eodtime.rolltimeoffset:-0D07:00:00.000000000; // 5 PM i.e. 7 hours before midnight
    .eodtime.rolltimezone:`$"America/New_YorK";    // roll in NYC time
    .eodtime.datatimezone:`$"GMT";                 // timestamp in GMT

Note that the rolltimeoffset can be negative - this will cause the rollover to happen 
"yesterday", meaning that at the rolltime, the trading date will become the day *after*
the calendar date. Where this is positive, the rollover occurs "today" and so the trading
date will become the current calendar date.

subscribercutoff.q
------------------

This script is used to provide functionality for cutting off any slow subscribers on any
TorQ processes. The script will periodically check (time between checks set in .subcut.checkfreq.
Default is 1 minute) the byte size of the queue for all the handles on the process to see if
they have exceeded a set cut-off point (set in the variable .subcut.maxsize) and will only
cut-off the handle if it exceeds this limit a set number of times in a row (default is 3
and set in the .subcut.breachlimit variable). This gives clients a chance to tidy up their
behavior and will avoid cutting off clients if they happened to have a spike just before the
check was performed. The .subcut.state variable is used to keep track of the handles and the 
number of times they have exceeded the size limit in a row. 

To enable this functionality the .subcut.enabled flag must be set to true and 
the timer.q script must be loaded on the desired processes. By default the chained 
tickerplant is the only processes with the functionality enabled. 

datareplay.q
------------

The datareplay utility provides functionality for generating tickerplant function calls from historcial
data which can be executed by subscriber functions. This can be used to test a known data-set against a 
subscriber for testing or debugging purposes.

It can load this data from the current TorQ session, or from a remote hdb if given its connection handle.

It can also chunk the data by time increments (as if the tickerplant was in batch mode), and can also generate
calls to a custom timer function for the same time increments (defaults to .z.ts).

The functions provided by this utility are made available in the .datareplay namespace.

The utility is mainly used via the tabesToDataStreamFunction, which accepts a dictionary parameter with the following
fields:

| Key     | Example Value           | Description                            | Required | Default  |
|:-------:|:-----------------------:|:--------------------------------------:|:--------:|:--------:|
|tabs     | `` `trade`quote or `trade ``  | List of tables to include              | Yes      | N/A      |
|sts      | 2014.04.04D07:00:00.000 | Start timestamp for data               | Yes      | N/A      |
|ets      | 2014.04.04D16:30:00.000 | End of timestamp for data              | Yes      | N/A      |
|syms     | `` `AAPL`IBM ``               | List of symbols to include             | No       | All syms |
|where    | `` ,(=;`src;,`L) ``           | Custom where clause in functional form | No       | none     |
|timer    | 1b                      | Generate timer function flag           | No       | 0b       |
|h        | 5i                      | Handle to hdb process                  | No       | 0i (self)|
|interval | 0D00:00:01.00           | Time interval used to chunk data, bucketed by timestamp if no time interval set       | No       | None     |
|tc       | `` `data_time ``              | Name of time column to cut on          | No       | `` `time ``    |
|timerfunc| .z.ts                   | Timer function to use if `timer parameter is set | No | .z.ts | 

When the timer flag is set, the utility will interleave timer function calls in the message column at intervals based on the interval parameter, or every 10 seconds if interval is not set. This is useful if testing requires a call to a function at a set time, to generate a VWAP every 10 minutes for example. The function the timer messages call is based on the timerfunc parameter, or .z.ts if this parameter is not set.

If the interval is set the messages will be aggregated into chunks based on the interval value, if no interval is specified, the data will be bucketed by timestamp (one message chunk per distinct timestamp per table).

If no connection handle is specified (h parameter), the utility will retrieve the data from the process the utility is running on, using handle 0.

The where parameter allows for the use of a custom where clause when extracting data, which can be useful when the dataset is large and only certain data is required, for example if only data where `` src=`L `` is required. The where clause(s) are required to be in functional form, for example `` enlist (=;`src;,`L) `` or `` ((=;`src;enlist `L);(>;`size;100)) `` (note, that if only one custom where clause is included it is required to be enlisted).

It is possible to get the functional form of a where clause by running parse on a mock select string like below:

    q)parse "select from t where src=`L,size>100"
    ?
    `t
    ,((=;`src;,`L);(>;`size;100))
    0b
    ()
    
The where clause is then the 3rd item returned in the parse tree.


## Examples:

Extract all data between sts and ets from the trades table in the current process.

    q)input
    tabs| `trades
    sts | 2014.04.21D07:00:00.000000000
    ets | 2014.05.02D17:00:00.000000000
    q).datareplay.tablesToDataStream input
    time                          msg                                            ..
    -----------------------------------------------------------------------------..
    2014.04.21D08:00:23.478000000 `upd `trades `sym`time`src`price`size!(`YHOO;20..
    2014.04.21D08:00:49.511000000 `upd `trades `sym`time`src`price`size!(`YHOO;20..
    2014.04.21D08:01:45.623000000 `upd `trades `sym`time`src`price`size!(`YHOO;20..
    2014.04.21D08:02:41.346000000 `upd `trades `sym`time`src`price`size!(`YHOO;20..
    ..
    q)first .datareplay.tablesToDataStream input
    time| 2014.04.21D08:00:23.478000000
    msg | (`upd;`trades;`sym`time`src`price`size!(`YHOO;2014.04.21D08:00:23.47800..

Extract all data between sts and ets from the trades table from a remote hdb handle=3i.

    q)input
    tabs| `trades
    sts | 2014.04.21D07:00:00.000000000
    ets | 2014.05.02D17:00:00.000000000
    h   | 3i
    q).datareplay.tablesToDataStream input
    time                          msg                                            ..
    -----------------------------------------------------------------------------..
    2014.04.21D08:00:07.769000000 `upd `trades `sym`time`src`price`size!(`IBM;201..
    2014.04.21D08:00:13.250000000 `upd `trades `sym`time`src`price`size!(`NOK;201..
    2014.04.21D08:00:19.070000000 `upd `trades `sym`time`src`price`size!(`MSFT;20..
    2014.04.21D08:00:23.678000000 `upd `trades `sym`time`src`price`size!(`YHOO;20..
    ..
    q)first .datareplay.tablesToDataStream input
    time| 2014.04.21D08:00:07.769000000
    msg | (`upd;`trades;`sym`time`src`price`size!(`IBM;2014.04.21D08:00:07.769000..


Same as above but including quote table and with interval of 10 minutes:


    q)input
    tabs    | `quotes`trades
    sts     | 2014.04.21D07:00:00.000000000
    ets     | 2014.05.02D17:00:00.000000000
    h       | 3i
    interval| 0D00:10:00.000000000
    q).datareplay.tablesToDataStream input
    time                          msg                                            ..
    -----------------------------------------------------------------------------..
    2014.04.21D08:09:47.600000000 `upd `trades +`sym`time`src`price`size!(`YHOO`A..
    2014.04.21D08:09:55.210000000 `upd `quotes +`sym`time`src`bid`ask`bsize`asize..
    2014.04.21D08:19:39.467000000 `upd `trades +`sym`time`src`price`size!(`CSCO`N..
    2014.04.21D08:19:49.068000000 `upd `quotes +`sym`time`src`bid`ask`bsize`asize..
    ..
    q)first .datareplay.tablesToDataStream input
    time| 2014.04.21D08:09:47.600000000
    msg | (`upd;`trades;+`sym`time`src`price`size!(`YHOO`AAPL`MSFT`NOK`DELL`YHOO`..
    
    
All messages from trades where `` src=`L `` bucketed in 10 minute intervals interleaved with calls to the function `` `vwap ``.

    q)input
    tabs     | `trades
    h        | 3i
    sts      | 2014.04.21D08:00:00.000000000
    ets      | 2014.05.02D17:00:00.000000000
    where    | ,(=;`src;,`L)
    timer    | 1b
    timerfunc| `vwap
    interval | 0D00:10:00.000000000
    q).datareplay.tablesToDataStream input
    time                          msg                                            ..
    -----------------------------------------------------------------------------..
    2014.04.21D08:00:00.000000000 (`vwap;2014.04.21D08:00:00.000000000)          ..
    2014.04.21D08:09:46.258000000 (`upd;`trades;+`sym`time`src`price`size!(`AAPL`..
    2014.04.21D08:10:00.000000000 (`vwap;2014.04.21D08:10:00.000000000)          ..
    2014.04.21D08:18:17.188000000 (`upd;`trades;+`sym`time`src`price`size!(`AAPL`..
    ..



Modified u.q
------------

Starting in kdb+ v3.4, the new broadcast feature has some performance
benefits. It works by serialising a message once before sending it
asynchronously to a list of subscribers whereas the previous method
would serialise it separately for each subscriber. To take advantage of
this, we’ve modified u.q. This can be turned off by setting .u.broadcast
to false. It is enabled by default, but will only override default
publishing if the kdb+ version being used is 3.4 or after.

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


API Table
--------------------

|name|vartype|namespace|descrip|params|return|
|-|-|-|-|-|-|
|.proc.createlog|function|.proc|Create the standard out and standard err log files. Redirect to them|[string: log directory; string: name of the log file;mixed: timestamp suffix for the file (can be null); boolean: suppress the generation of an alias link]|null|
|.proc.rolllogauto|function|.proc|Roll the standard out/err log files|[]|null|
|.proc.loadf|function|.proc|Load the specified file|[string: filename]|null|
|.proc.loaddir|function|.proc|Load all the .q and .k files in the specified directory. If order.txt is found in the directory, use the ordering found in that file|[string: name of directory]|null|
|.proc.getattributes|function|.proc|Called by external processes to retrieve the attributes (advertised functionality) of this process|[]|dictionary of attributes|
|.proc.override|function|.proc|Override configuration varibles with command line parameters.  For example, if you set -.servers.HOPENTIMEOUT 5000 on the command line and call this function, then the command line value will be used|[]|null|
|.proc.overrideconfig|function|.proc|Override configuration varibles with values in supplied parameter dictionary. Generic version of .proc.override|[dictionary: command line parameters.  .proc.params should be used]|null|
|.lg.o|function|.lg|Log to standard out|[symbol: id of log message; string: message]|null|
|.lg.e|function|.lg|Log to standard err|[symbol: id of log message; string: message]|null|
|.lg.l|function|.lg|Log to either standard error or standard out, depending on the log level|[symbol: log level; symbol: name of process; symbol: id of log message; string: message; dict: extra parameters, used in the logging extension function]|null|
|.lg.err|function|.lg|Log to standard err|[symbol: log level; symbol: name of process; symbol: id of log message; string: message; dict: extra parameters, used in the logging extension function]|null|
|.lg.ext|function|.lg|Extra function invoked in standard logging function .lg.l.  Can be used to do more with the log message, e.g. publish externally|[symbol: log level; symbol: name of process; symbol: id of log message; string: message; dict: extra parameters]|null|
|.err.ex|function|.err|Log to standard err, exit|[symbol: id of log message; string: message; int: exit code]|null|
|.err.usage|function|.err|Throw a usage error and exit|[]|null|
|.err.param|function|.err|Check a dictionary for a set of required parameters. Print an error and exit if not all required are supplied|[dict: parameters; symbol list: the required param values]|null|
|.err.env|function|.err|Check if a list of required environment variables are set.  If not, print an error and exit|[symbol list: list of required environment variables]|null|
|.usage.rolllogauto|function|.usage|Roll the .usage txt files|[]|null|
|.usage.readlog|function|.usage|Read and return a usage log file as a table|[string: name of log file]|null|
|.usage.logtodisk|variable|.usage|whether to log to disk|||
|.usage.logtomemory|variable|.usage|whether to log to .usage.usage|||
|.usage.ignore|variable|.usage|whether to check the ignore list for functions to ignore|||
|.usage.ignorelist|variable|.usage|the list of functions to ignore|||
|.usage.logroll|variable|.usage|whether to automatically roll the log file|||
|.usage.usage|table|.usage|log of messages through the message handlers|||
|.clients.clients|table|.clients|table containing client handles and session values|||
|.sub.getsubscriptionhandles|function|.sub|Connect to a list of processes of a specified type|[symbol: process type to match; symbol: process name to match; dictionary:attributes of process]|table of process names, types and the handle connected on|
|.sub.subscribe|function|.sub|Subscribe to a table or list of tables and specified instruments|[symbol (list):table names; symbol (list): instruments; boolean: whether to set the schema from the server; boolean: wether to replay the logfile; dictionary: procname,proctype,handle||
|.pm.adduser|function|.pm|Adds a user to be permissioned as well as setting their password and the method used to hash it.|[symbol: the username; symbol: method used to authenticate; symbol: method used to hash the password; string: password, hashed using the proper method]|null|
|.pm.addgroup|function|.pm|Add a group which will have access to certain tables and variables|[symbol: the name of the group; string: a description of the group]|null|
|.pm.addrole|function|.pm|Add a role which will have access to certain functions|[symbol: the name of the role; string: a description of the role]|null|
|.pm.addtogroup|function|.pm|Add a user to a group, giving them access to all of its variables|[symbol: the name of the user to add; symbol: group the user is to be added to]|null|
|.pm.assignrole|function|.pm|Assign a user a role, giving them access to all of its functions|[symbol: the name of the user to add; symbol: role the user is to be assigned to]|null|
|.pm.grantaccess|function|.pm|Give a group access to a variable|[symbol: the name of the variable the group should get access to; symbol: group that is to be given this access; symbol: the type of access that should be given, eg. read, write]|null|
|.pm.grantfunction|function|.pm|Give a role access to a function|symbol: name of the function to be added; symbol: role that is to be given this access; TO CLARIFY|null|
|.pm.createvirtualtable|function|.pm|Create a virtual table that a group might be able to access instead of the full table|[symbol: new name of the table; symbol: name of the actual table t add; TO CLARIFY]|null|
|.pm.cloneuser|function|.pm|Add a new user that is identical to another user|[symbol: name of the new user; symbol: name of the user to be cloned; string: password of the new user]|null|
|.access.addsuperuser|function|.access|Add a super user|[symbol: user]|null|
|.access.addpoweruser|function|.access|Add a power user|[symbol: user]|null|
|.access.adddefaultuser|function|.access|Add a default user|[symbol: user]|null|
|.access.readpermissions|function|.access|Read the permissions from a directory|[string: directory containing the permissions files]|null|
|.access.USERS|table|.access|Table of users and their types|||
|.servers.opencon|function|.servers|open a connection to a process using the default timeout. If no user:pass supplied, the default one will be added if set|[symbol: the host:port[:user:pass]]|int: the process handle, null if the connection failed|
|.servers.addh|function|.servers|open a connection to a server, store the connection details|[symbol: the host:port:user:pass connection symbol]|int: the server handle|
|.servers.addw|function|.servers|add the connection details of a process behind the handle|[int: server handle]|null|
|.servers.addnthawc|function|.servers|add the details of a connection to the table|[symbol: process name; symbol: process type; hpup: host:port:user:pass connection symbol; dict: attributes of the process; int: handle to the process;boolean: whether to check the handle is valid on insert|int: the handle of the process|
|.servers.getservers|function|.servers|get a table of servers which match the given criteria|[symbol: pick the server based on the name value or the type value.  Can be either \`procname\`proctype; symbol(list): lookup values. \` for any; dict: requirements dictionary; boolean: whether to automatically open dead connections for the specified lookup values; boolean: if only one of each of the specified lookup values is required (means dead connections aren't opened if there is one available)]|table: processes details and requirements matches|
|.servers.gethandlebytype|function|.servers|get a server handle for the supplied type|[symbol: process type; symbol: selection criteria. One of \`roundrobin\`any\`last]|int: handle of server|
|.servers.gethpbytype|function|.servers|get a server hpup connection symbol for the supplied type|[symbol: process type; symbol: selection criteria. One of \`roundrobin\`any\`last]|symbol: h:p:u:p connection symbol of server|
|.servers.startup|function|.servers|initialise all the connections.  Must processes should call this during initialisation|[]|null|
|.servers.refreshattributes|function|.servers|refresh the attributes registered with the discovery service.  Should be called whenever they change e.g. end of day for an HDB|[]|null|
|.servers.SERVERS|table|.servers|table containing server handles and session values|||
|.timer.repeat|function|.timer|Add a repeating timer with default next schedule|[timestamp: start time; timestamp: end time; timespan: period; mixedlist: (function and argument list); string: description string]|null|
|.timer.once|function|.timer|Add a one-off timer to fire at a specific time|[timestamp: execute time; mixedlist: (function and argument list); string: description string]|null|
|.timer.remove|function|.timer|Delete a row from the timer schedule|[int: timer id to delete]|null|
|.timer.removefunc|function|.timer|Delete a specific function from the timer schedule|[mixedlist: (function and argument list)]|null|
|.timer.rep|function|.timer|Add a repeating timer - more flexibility than .timer.repeat|[timestamp: execute time; mixedlist: (function and argument list); short: scheduling algorithm for next timer; string: description string; boolean: whether to check if this new function is already present on the schedule]|null|
|.timer.one|function|.timer|Add a one-off timer to fire at a specific time - more flexibility than .timer.once|[timestamp: execute time; mixedlist: (function and argument list); string: description string; boolean: whether to check if this new function is already present on the schedule]|null|
|.timer.timer|table|.timer|The table containing the timer information|||
|.cache.execute|function|.cache|Check the cache for a valid result set, return the results if found, execute the function, cache it and return if not|[mixed: function or string to execute;timespan: maximum allowable age of cache item if found in cache]|mixed: result of function|
|.cache.getperf|function|.cache|Return the performance statistics of the cache|[]|table: cache performance|
|.cache.maxsize|variable|.cache|The maximum size in MB of the cache. This is evaluated using -22!, so may be incorrect due to power of 2 memory allocation.  To be conservative and ensure it isn't exceeded, set max size to half of the actual max size that you want|||
|.cache.maxindividual|variable|.cache|The maximum size in MB of an individual item in the cache. This is evaluated using -22!, so may be incorrect due to power of 2 memory allocation.  To be conservative and ensure it isn't exceeded, set max size to half of the actual max size that you want|||
|.tz.dg|function|.tz|default from GMT. Convert a timestamp from GMT to the default timezone|[timestamp (list): timestamps to convert]|timestamp atom or list|
|.tz.lg|function|.tz|local from GMT. Convert a timestamp from GMT to the specified local timezone|[symbol (list): timezone ids;timestamp (list): timestamps to convert]|timestamp atom or list|
|.tz.gd|function|.tz|GMT from default. Convert a timestamp from the default timezone to GMT|[timestamp (list): timestamps to convert]|timestamp atom or list|
|.tz.gl|function|.tz|GMT from local. Convert a timestamp from the specified local timezone to GMT|[symbol (list): timezone ids; timestamp (list): timestamps to convert]|timestamp atom or list|
|.tz.ttz|function|.tz|Convert a timestamp from a specified timezone to a specified destination timezone|[symbol (list): destination timezone ids; symbol (list): source timezone ids; timestamp (list): timestamps to convert]|timestamp atom or list|
|.tz.default|variable|.tz|Default timezone|||
|.tz.t|table|.tz|Table of timestamp information|||
|.email.connectdefault|function|.email|connect to the default mail server specified in configuration|[]||
|.email.senddefault|function|.email|connect to email server if not connected. Send email using default settings|[dictionary of email parameters. Required dictionary keys are to (symbol (list) of email address to send to), subject (character list), body (list of character arrays).  Optional parameters are cc (symbol(list) of addresses to cc), bodyType (can be \`html, default is \`text), attachment (symbol (list) of files to attach), image (symbol of image to append to bottom of email. \`none is no image), debug (int flag for debug level of connection library. 0i=no info, 1i=normal. 2i=verbose)]|size in bytes of sent email. -1 if failure|
|.email.test|function|.email|send a test email|[symbol(list):email address to send test email to]|size in bytes of sent email. -1 if failure|
|.hb.addprocs|function|.hb|Add a set of process types and names to the heartbeat table to actively monitor for heartbeats.  Processes will be automatically added and monitored when the heartbeats are subscribed to, but this is to allow for the case where a process might already be dead and so can't be subscribed to|[symbol(list): process types; symbol(list): process names]||
|.hb.processwarning|function|.hb|Callback invoked if any process goes into a warning state.  Default implementation is to do nothing - modify as required|[table: processes currently in warning state]||
|.hb.processerror|function|.hb|Callback invoked if any process goes into an error state. Default implementation is to do nothing - modify as required|[table: processes currently in error state]||
|.hb.storeheartbeat|function|.hb|Store a heartbeat update.  This function should be added to you update callback when a heartbeat is received|[table: the heartbeat table data to store]||
|.hb.warningperiod|function|.hb|Return the warning period for a particular process type.  Default is to return warningtolerance * publishinterval. Can be overridden as required|[symbollist: the process types to return the warning period for]|timespan list of warning period|
|.hb.errorperiod|function|.hb|Return the error period for a particular process type.  Default is to return errortolerance * publishinterval. Can be overridden as required|[symbollist: the process types to return the error period for]|timespan list of error period|
|.rdb.moveandclear|function|.rdb|Move a variable (table) from one namespace to another, deleting its contents.  Useful during the end-of-day roll down for tables you do not want to save to the HDB|[symbol: the namespace to move the table from; symbol:the namespace to move the variable to; symbol: the name of the variable]|null|
|.api.f|function|.api|Find a function/variable/table/view in the current process|[string:search string]|table of matching elements|
|.api.p|function|.api|Find a public function/variable/table/view in the current process|[string:search string]|table of matching public elements|
|.api.u|function|.api|Find a non-standard q public function/variable/table/view in the current process.  This excludes the .q, .Q, .h, .o namespaces|[string:search string]|table of matching public elements|
|.api.s|function|.api|Search all function definitions for a specific string|[string: search string]|table of matching functions and definitions|
|.api.find|function|.api|Generic method for finding functions/variables/tables/views. f,p and u are based on this|[string: search string; boolean (list): public flags to include; boolean: whether the search is context senstive|table of matching elements|
|.api.search|function|.api|Generic method for searching all function definitions for a specific string. s is based on this|[string: search string; boolean: whether the search is context senstive|table of matching functions and definitions|
|.api.add|function|.api|Add a function to the api description table|[symbol:the name of the function; boolean:whether it should be called externally; string:the description; dict or string:the parameters for the function;string: what the function returns]|null|
|.api.fullapi|function|.api|Return the full function api table|[]|api table|
|.api.m|function|.api|Return the ordered approximate memory usage of each variable and view in the process. Views will be re-evaluated if required|[]|memory usage table|
|.api.mem|function|.api|Return the ordered approximate memory usage of each variable and view in the process. Views are only returned if view flag is set to true. Views will be re-evaluated if required|[boolean:return views]|memory usage table|
|.api.whereami|function|.api|Get the name of a supplied function definition. Can be used in the debugger e.g. .api.whereami[.z.s]|function definition|symbol: the name of the current function|
|.ps.publish|function|.ps|Publish a table of data|[symbol: name of table; table: table of data]||
|.ps.subscribe|function|.ps|Subscribe to a table and list of instruments|[symbol(list): table name. \` for all; symbol(list): symbols to subscribe to. \` for all]|mixed type list of table names and schemas|
|.ps.initialise|function|.ps|Initialise the pubsub routines.  Any tables that exist in the top level can be published|[]||
|.async.deferred|function|.async|Use async messaging to simulate sync communication|[int(list): handles to query; query]|(boolean list:success status; result list)|
|.async.postback|function|.async|Send an async message to a process and the results will be posted back within the postback function call|[int(list): handles to query; query; postback function]|boolean list: successful send status|
|.cmp.showcomp|function|.cmp|Show which files will be compressed and how; driven from csv file|[\`:/path/to/database; \`:/path/to/configcsv; maxagefilestocompress]|table of files to be compressed|
|.cmp.compressmaxage|function|.cmp|Run compression on files using parameters specified in configuration csv file, and specifying the maximum age of files to compress|[\`:/path/to/database; \`:/path/to/configcsv; maxagefilestocompress]||
|.cmp.docompression|function|.cmp|Run compression on files using parameters specified in configuration csv file|[\`:/path/to/database; \`:/path/to/configcsv]||
|.loader.loadallfiles|function|.loader|Generic loader function to read a directory of files in chunks and write them out to disk|[dictionary of load parameters. Should have keys of headers (symbol list), types (character list), separator (character), tablename (symbol), dbdir (symbol).  Optional params of dataprocessfunc (diadic function), datecol (name of column to extract date from: symbol), chunksize (amount of data to read at once:int), compression (compression parameters to use e.g. 16 1 0:int list), gc (boolean flag of whether to run garbage collection:boolean); directory containing files to load (symbol)]||
|.sort.sorttab|function|.sort|Sort and set the attributes for a table and set of partitions based on a configuration file (default is $KDBCONFIG/sort.csv)|[2 item list of (tablename e.g. \`trade; partitions to sort and apply attributes to e.g. \`:/hdb/2000.01.01/trade\`:hdb/2000.01.02/trade)]||
|.sort.getsortcsv|function|.sort|Read in the sort csv from the specified location|[symbol: the location of the file e.g. \`:config/sort.csv]||
|.gc.run|function|.gc|Run garbage collection, print debug info before and after|||
|.mem.objsize|function|.mem|Returns the calculated memory size in bytes used by an object.  It may take a little bit of time for objects with lots of nested structures (e.g. lots of nested columns)|[q object]|size of the object in bytes|
|.tplog.check|function|.tplog|Checks if tickerplant log can be replayed.  If it can or can replay the first X messages, then returns the log handle, else it will read log as byte stream and create a good log and then return the good log handle |[logfile (symbol), handle to the log file to check; lastmsgtoreplay (long), the index of the last message to be replayed from log ]|handle to log file, will be either the input log handle or handle to repaired log, depends on whether the log was corrupt|

grafana.q
----------
Grafana is an open source analytics platform, used to display time-series data
from a web application. Currently it supports a variety of data sources
including Graphite, InfluxDb & Prometheus with users including the likes of 
Paypal, Ebay, Intel and Booking.com.  However, there is no in-built support for
direct analysis of data from kdb+. Thus, using the 
[SimpleJSON data source](https://github.com/grafana/simple-json-datasource),
we have engineered an adaptor to allow visualisation of kdb+ data.

### Requirements
Grafana v5.2.2+
(Tested on Kdb v3.5+)
### Getting Started

1. Download and set up Grafana. This is well explained on the 
[Grafana website](https://grafana.com/get), where you have the option to either
download the software locally or let Grafana host it for you. For the purpose 
of this document, we host the software locally.

2. Pull down this repository with the adaptor already installed in code/common.

3. In your newly installed Grafana folder (eg.grafana-5.2.2/) run the command:
    ```./bin/grafana-server web```.
This will start your Grafana server. If you would like to alter the port which 
this is run on, this can be changed in:
    ```/grafana-5.2.2/conf/custom.ini```, Where custom.ini should be a copy of defaults.ini.

4. You can now open the Grafana server in your web browser where you will be 
greeted with a login page to fill in appropriately.

5. Once logged in, navigate to the configurations->plugin section where you 
will find the simple JSON adaptor, install this.

6. Upon installation of the JSON you can now set-up your datasource. 

7. Host your data on a port accesible to Grafana, eg. the RDB.

8. In the "add new datasource" panel, enter the details for the port in which 
your data is hosted, making the type SimpleJSON.

9. Run the test button on the bottom of your page, this should succeed and you 
are ready to go!

### Using the adaptor
As the adaptor is part of the TorQ framework it will automatically be loaded 
into TorQ sessions. From this point onwards you can proceed to use Grafana as 
it is intended, with the only difference coming in the form of the queries. Use 
cases and further examples of the queries can be seen in our blogpost:
[The Grafana-KDB Adaptor](https://www.aquaq.co.uk/q/ask-shall-receive-grafana-kdb-adaptor/).
For information and examples of how to execute server side functions in queries, please
read our followup blogpost on the subject: [Grafana kdb+ Adaptor Update](https://www.aquaq.co.uk/kdb/grafana-kdb-adaptor-update/). 
Here you can see examples of graphs, tables, heatmaps and single statistics. 
The best explanation of the inputs allowed in the query section can be seen pictorially here:

![GrafanaQueries](https://github.com/AquaQAnalytics/TorQ/blob/master/docs/graphics/grafana_chart.png?raw=true)

Upon opening the query box, in the metrics tab, the user will be provided with 
a populated drop down of all possible options. Server functions are not included
in the dropdown, but can be called by entering the letter f followed by the value
of ``` .grafana.del ``` (see below) before their function call. Due to the limitations
of the JSON messages, it is not possible for our adaptor to distinguish between panels. 
Consequently, every possible option is returned for each panel, the user can
reduce these choices by simply entering the first letter of their panel type, 
g for graph, t for table and o for other (heatmap or single stat). From here, 
you can follow the above diagram to specify your type of query.

### Limitations & Assumptions
This adaptor has been built to allow visualisation of real-time and historical 
data. It is capable of handling static and timeseries data.  In addition, the 
drop-down options have been formed such that only one query is possible per 
panel. If more than one query on a specfic panel is made it will throw an error. 
To get around this, we added the options of including all "syms" in queries so 
the options can be filtered out in the legend. 

Table queries should work for any table format supplied to the adaptor. However, 
time series data is limited by the requriment of a time column, in our adaptor 
we assume this column to be called time. This assumption can be modified to fit 
your data in the settings (config/settings/defualt.q) file which dictates the 
following lines at the start of the script:
```
// user defined column name of time column
timecol:@[value;`.grafana.timecol;`time];
// user defined column name of sym column
sym:@[value;`.grafana.sym;`sym];
// user defined date range to find syms from
timebackdate:@[value;`.grafana.timebackdate;2D];
// user defined number of ticks to return
ticks:@[value;`.grafana.ticks;1000];
// user defined query argument deliminator
del:@[value;`.grafana.del;"."];

```

```.grafana.timecol``` represents the name of the time column and thus can be 
reassigned if your time column has a different name, eg. date. One more common 
modification could be changing the variable ```.grafana.sym ``` which defines 
the name of the the sym column, which is normally referenced in financial data. 
However if the data is non-financial this could be tailored to represent another 
identifier such as name or postcode. This column is used to populate the drop 
down options in the query selector. 

```.grafana.timebackdate``` is a user definable variable which dictates how 
far back into a hdb the adaptor will look to gather options for distinct syms to 
populate the dropdowns. It is important to note that this should be increased if 
all your required syms are not in the last 2 days. Optionally a user could hard
code this list or implement their own search function to limit interrogation of 
the database. ```.grafana.ticks``` can be defined so that only n rows from the
end of the table will be queried. This can be left as large as the user likes,
but is included for managing large 
partitioned tables. 

One final important variable is ```.grafana.del```, this dictates the delimeter 
between options in the drop down menus. This has significant repercussions if 
one of your columns includes full stops, eg. email adresses. As a result we have 
left this as definable so that the user can alter this to a non-disruptive value 
for their data eg./.
