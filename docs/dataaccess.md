# Data Access API

# Introduction and Key Features

The Dataaccess API is a TorQ upgrade designed for seamless cross process data retrival.

Other key upgrades of the API are:
- Compatibility with non kdb+ processes such as Google BigQuery and qREST
- Consistent queries across all processes 
- Data retrieval does not require q-SQL knowledge only q dictionary manipulation
- User friendly interface including more comprehensible error messages
- Queries are automatically optimised for each process
- Thorough testing allowing ease of further development

A more conceptual discussion of the API can be seen at [Blog Post](https://www.aquaq.co.uk/torq-2/data-access-api/)

# Configuration

The API can be initialised in a TorQ proccess by either:

1) Pass `"-dataaccess /path/to/tableproperties.csv"` on the startup line (see Example table properties file below for format)
2) Run ``".dataaccess.init[`:path/to/tableproperties.csv]"`` to initialise the code in a running process.

In both cases the filepath should point to `tableproperties.csv` a `.csv` containing information about all the tables you want the API to query. The following table describes each of the columns of tableproperties.csv:

**Description of fields in tableproperties.csv**

|Field               |Description                                                                                        |Default                                 |
|--------------------|---------------------------------------------------------------------------------------------------|----------------------------------------|
|proctype            |Denotes the type of process the table is loaded in (passing `all` will involke default behaviour)  |procs in .gw.servers                    |
|tablename           |Table to query  (Tables within namespaces are allowed)                                             |N/A                                     |
|primarytimecolumn   |Default timecolumn used to determine the partitioning of a process                                 |\*                                      |
|attributecolumn     |Primary attribute column (see query optimisation)                                                  |N/A                                     |
|instrumentcolumn    |Column containing instrument                                                                       |N/A                                     |
|rolltimeoffset      |Rollovertime offset from midnight                                                                  |.eodtime.rolltimeoffset                 |
|rolltimezone        |Timezone of the Rollover Function                                                                  |.eodtime.rolltimezone                   |
|datatimezone        |Timezone of the primary time column timestamps                                                     |.eodtime.datatimezone                   |
|partitionfield      |Partition field of the data                                                                        |```$[.Q.qp[];.Q.pf;`]```                |
 
\* The Default behaviour of primarytimecolumn is:

1. If the table is defined in the tickerplant schema file then primarytimecolumn is set to be the time column defined by the tickerplant.
2. Else if a unique column of type z or p exists it is used. (If uniqueness isn't satisfied an error will occur here.)
3. Else if a unique column of type d exist then it is used.
4. Else the API will error.

**Example Default Configuration File**

If the user wishes to use the TorQ FSP (see section below) the following example will suffice:

|proctype|tablename|primarytimecolumn|attributecolumn|instrumentcolumn|rolltimeoffset|rolltimezone|datatimezone|partitionfield|
|--------|---------|-----------------|---------------|----------------|--------------|------------|------------|--------------|
||trade|time|sym|sym|||||
||quote|time|sym|sym|||||

This table will be configured as if it were the following 

|proctype|tablename|primarytimecolumn|attributecolumn|instrumentcolumn|rolltimeoffset|rolltimezone|datatimezone|partitionfield|
|--------|---------|-----------------|---------------|----------------|--------------|------------|------------|--------------|
|rdb     |trade    |time             |sym            |sym             |00:00         |GMT         |GMT         |              |
|hdb     |trade    |time             |sym            |sym             |00:00         |GMT         |GMT         |date          |
|rdb     |quote    |time             |sym            |sym             |00:00         |GMT         |GMT         |              |
|hdb     |quote    |time             |sym            |sym             |00:00         |GMT         |GMT         |date          |

A more complete explanation into the configuration can be seen in the Table Properties Configuration section.

# Usage

When using the API to send queries direct to a process, the overarching function is `getdata`. `getdata` is a dynamic, lightweight function which takes in a uniform dictionary (see table below) and the above configuration to build a process bespoke query. Input consistency permits the user to disregard the pragmatics described in `tableproperties.csv` allowing `getdata` to be called either directly within a process or via `.dataccess.getdata` (discussed in the Gateway section).

The `getdata` function is split into three sub functions:` .dataaccess.checkinputs`, `.eqp.extractqueryparams` and `queryorder.orderquery`. 

- `.dataaccess.checkinputs` checks if the input dictionary is valid (See custom API errors) 
- `.eqp.extractqueryparams` converts the arguments into q-SQL 
- `.queryorder.orderquery` is the API's query optimiser (See Debugging and Optimisation)

`getdata's` input takes the format of a dictionary who's keys represent attributes of a query and values that represent how these attributes are to look. Each of these parameter's in the input dictionary can map a very simplistic dictionary into queries that can become quite complex. The following table lists getdata's accepted arguments: 

**Valid Inputs**

|Parameter     |Required|Example\*\*                                                                                   |Invalidpairs\*               |Description                                                                     |
|--------------|----------|-----------------------------------------------------------------------------------------|---------------|--------------------------------------------------------------------------------|
|tablename     |Yes       |\`quote                                                                                  |               |Table to query                            |
|starttime     |Yes       |2020.12.18D12:00                                                                         |               |Start time - must be a valid time type (see timecolumn)                           |
|endtime       |Yes       |2020.12.20D12:00                                                                         |               |End time - must be a valid time type (see timecolumn)                             |
|timecolumn    |No       |\`time                                                                                    |                |Column to apply(startime;endime) filter to|
|instruments   |No       |\`AAPL\`GOOG                                                                              |                |Instruments to filter on - will usually have an attribute applied (see tableproperties.csv)|
|columns       |No       |\`sym\`bid\`ask\`bsize\`asize                                                             |aggregations    |Table columns to return - symbol list - assumed all if not present              |
|grouping      |No       |\`sym                                                                                     |                |Columns to group by -  no grouping assumed if not present|
|aggregations  |No       |\`max\`wavg!(\`bidprice\`askprice;(\`asksize\`askprice;\`bidsize\`bidprice))              |columns&#124;freeformcolumn |dictionary of aggregations |
|timebar       |No       |(10;\`minute;\`time)                                                                      |                |List of (bar size; time type;timegrouping column) valid types: \`nanosecond\`second\`minute\`hour\`day)|
|filters       |No       |\`sym\`bid\`bsize!(enlist(like;"AAPL");((<;85);(>;83.5));enlist(not;within;5 43))         |                 |Dictionary of ordered filters to apply to keys of dictionary|
|freeformwhere |No       |"sym=\`AAPL, src=\`BARX, price within 60 85"                                              |                 |Where clause in string format                                                   |
|freeformby    |No       |"sym:sym, source:src"                                                                     |                 |By clause in string format
|freeformcolumn|No       |"time, sym,mid\:0.5\*bid+ask"                                                             |aggregations     |Select clause in string format 
|ordering      |No       |enlist(\`desc\`bidprice)                                                                  |                 |List ordering results ascending or descending by column
|renamecolumn  |No       | \`old1\`old2\`old3!\`new1\`new2\`new3                                                    |                 |Either a dictionary of old!new or list of column names|
|postprocessing|No       |{flip x}                                                                                  |                 |Post-processing of the data|
|queryoptimisation|No    |0b                                                                                        |                 |Determines whether the query optimiser should be turned on/off, Default is 1b|
|sublist       |No       |42                                                                                        |                 |[Sublist](https://code.kx.com/q/ref/sublist/)|
|getquery      |No       |1b                                                                                        |                 |Runs `.dataaccess.buildquery` in each of the processes|

\* Invalid pairs are two dictionary keys not allowed to be defined simultaneously, this is done to prevent unexpected behaviour such as the following query:

```select price,mprice:max price from trade``` 

Although the above is a valid query the result may be unexpected as the column lengths don't match up.

If an invalid key pair is desired the user should convert all inputs to the q-SQL version.

\*\* More complete examples are provided in the Examples section below

**Example function call**

```
q)getdata`tablename`starttime`endtime`instruments`columns!(`quote;2021.01.20D0;2021.01.23D0;`GOOG;`sym`bid`bsize)
sym  bid   bsize
----------------
GOOG 71.57 1
GOOG 70.86 2
GOOG 70.91 8
GOOG 70.91 6
...
```
From within a kdb+ process the `.dataaccess.buildquery` function provides the developer with an insight into the query that has been built for example:

```
q).dataaccess.buildquery `tablename`starttime`endtime`instruments`columns!(`quote;2021.01.20D0;2021.01.23D0;`GOOG;`sym`time`bid`bsize)
? `quote ((=;`sym;,`GOOG);(within;`time;2021.01.20D00:00:00.000000000 2021.01.23D00:00:00.000000000)) 0b `sym`time`bid`bsize!`sym`time`bid`bsize

```
Alternatively, the ``` `getquery``` key can also be used to produce an identical result:

```
q)getdata `tablename`starttime`endtime`instruments`columns`getquery!(`quote;2021.01.20D0;2021.01.23D0;`GOOG;`sym`time`bid`bsize;1b)
? `quote ((=;`sym;,`GOOG);(within;`time;2021.01.20D00:00:00.000000000 2021.01.23D00:00:00.000000000)) 0b `sym`time`bid`bsize!`sym`time`bid`bsize

```
This method is preferable as it has been extended to work from within the gateway (see Gateway section) or another exotic process:

```
q).dataaccess.getdata `tablename`starttime`endtime`instruments`columns`getquery!(`quote;2021.01.20D0;.z.d+12:00;`GOOG;`sym`time`bid`bsize;1b)
`rdb
(?;`quote;((=;`sym;,`GOOG);(within;`time;2021.01.20D00:00:00.000000000 2021.03.16D12:00:00.000000000));0b;`sym`time`bid`bsize!`sym`time`bid`bsize)
`hdb
(?;`quote;((within;`date;2021.01.20 2021.03.17);(=;`sym;,`GOOG);(within;`time;2021.01.20D00:00:00.000000000 2021.03.16D12:00:00.000000000));0b;`sym`time`bid`bsize!`sym`time`bid`bsize)
```

## Aggregations 

The aggregations key is a dictionary led method of perfoming mathematical operations on columns of a table. The dictionary should be of the form: 

``` `agg1`agg2`...`aggn!((`col11`col12...`col1a);(`col21`col22...`col2b);...;(`coln1`coln2...`colnm)```

Certain aggregations are cross proccess enabled, that is they can be calculated across multiple proccess (See example in the Gateway section). The key accepts the following table of inputs:

**Table of Avaliable Aggregations**

|Aggregation|Description                                          |Example                                          |Cross Process Enabled (See Gateway)|
|-----------|-----------------------------------------------------|-------------------------------------------------|-----------------------------------|
|`avg`      |Return the mean of a list                            |```(enlist`avg)!enlist enlist `price```          |No                                 |
|`cor`      |Return Pearson's Correlation coefficient of two lists|```(enlist `cor)!enlist enlist `bid`ask```       |No                                 |
|`count`    |Return The length of a list                          |```(enlist`count)!enlist enlist `price```        |Yes                                |
|`cov`      |Return the covariance of a list pair                 |```(enlist `cov)!enlist enlist `bid`ask```       |No                                 |
|`dev`      |Return the standard deviation of a list              |```(enlist`dev)!enlist enlist `price```          |No                                 |
|`distinct` |Return distinct elements of a list                   |```(enlist`distinct)!enlist enlist `sym```       |Yes                                |
|`first`    |Return first element of a list                       |```(enlist`first)!enlist enlist `price```        |Yes                                |
|`last`     |Return the final value in a list                     |```(enlist`last)!enlist enlist `price```         |Yes                                |
|`max`      |Return the maximum value of a list                   |```(enlist`max)!enlist enlist `price```          |Yes                                |
|`med`      |Return the median value of a list                    |```(enlist`med)!enlist enlist `price```          |No                                 |
|`min`      |Return the minimum value of a list                   |```(enlist`min)!enlist enlist `price```          |Yes                                |   
|`prd`      |Return the product of a list                         |```(enlist`prd)!enlist enlist `price```          |Yes                                |
|`sum`      |Return the total of a list                           |```(enlist`sum)!enlist enlist `price```          |No                                 |
|`var`      |Return the Variance of a list                        |```(enlist`var)!enlist enlist `price```          |No                                 |
|`wavg`     |Return the weighted mean of two lists                |```(enlist`wavg)!enlist enlist `asize`ask```     |No                                 |
|`wsum`     |Return the weighted sum of two lists                 |```(enlist`wsum)!enlist enlist `asize`ask```     |No                                 |

The postprocessing key provides a work around for creating these cross process aggregations (see the postprocessing example in Further Examples section).

The following function can be used to merge two aggregation dictionaries: 

```
q)f:{{(key x,y)!{:$[0=count raze x[z];y[z];$[2=count raze y[z];($[1=count x[z];raze x[z];x[z]];raze y[z]);raze x[z],raze y[z]]]}[x;y;] each key x,y}/[x]}
```

```
q)A
min| price
q)B
min| time
q)C
wavg| bid bsize
q)f[(A;B;C)]
min | `price`time
wavg| ,`bid`bsize
```

## Filters

The filters key is a dictionary led method of controlling which entries of a given table are being queried by setting out a criteria. The dictionary uses a table column as the key and the entries as the condition to be applied to that column. Any condition to be applied should be entered as a nest of two item lists for each condition and each sublist entered as an operator first followed by conditional values, for example:

``` `col1`col2`...`coln!((op;cond);((op;cond);(op;cond));...;(op;cond)```

For negative conditionals, the not and ~: operators can be included as the first item of a three item list for the operators in, like and within, e.g.

``` enlist`col1!enlist(not;within;`cond1`cond2)```

**Table of Available Filters**

|Operator    |Description                                          |Example                                          |
|------------|-----------------------------------------------------|-------------------------------------------------|
|`<`         |less than                                            |```(enlist`col)!enlist(<;input)```               |
|`>`         |greater than                                         |```(enlist`col)!enlist(>;input)```               |
|`<>`        |not equal                                            |```(enlist`col)!enlist(<>;input)```              |
|`<=`        |less than or equal to                                |```(enlist`col)!enlist(<=;input)```              |
|`>=`        |greater than or equal to                             |```(enlist`col)!enlist(>=;input)```              |
|`=`         |equal to                                             |```(enlist`col)!enlist(=;input)```               |
|`~`         |match/comparison                                     |```(enlist`col)!enlist(~;input)```               |
|`in`        |column value is an item of input list                |```(enlist`col)!enlist(in;input)```              |
|`within`    |column value is within bounds of two inputs          |```(enlist`col)!enlist(within;input)```          |
|`like`      |column symbol or string matches input string pattern |```(enlist`col)!enlist(like;input)```            |
|`not`       |negative conditional when used with in,like or within|```(enlist`col)!enlist(not;in/like/within;input)```         |

# Gateway

The documentation for the gateway outside the API can be found [here](https://github.com/AquaQAnalytics/TorQ/blob/master/docs/Processes.md)

Accepting a uniform dictionary allows queries to be sent to the gateway using `.dataaccess.getdata`. Using `.dataaccess.getdata` allows the user to
 
- Leverage the checkinputs library from within the gateway and catch errors before they hit the process
- Uses `.gw.servers` to dynamically determine the appropriate processes to execute `getdata` in 
- Determines the query type to send to the process(es)
- Provide further optional arguments to better determine the behaviour of the function see table below:

**Gateway Accepted Keys**

|Input Key|Example        |Default behaviour              |Description                                       |
|---------|---------------|-------------------------------|--------------------------------------------------|
|postback |`{0N!x}`       |()                             |Post back function for retuning async queries only|
|join     |`raze`         |`.dataaccess.multiprocjoin`    |Join function to merge the tables                 |
|timeout  |`00:00:03`     |0Wn                            |Maximum time for query to run                     |
|procs    |``` `rdb`hdb```|`.dataaccess.attributesrouting`|Choose which processes to run `getdata` in \*     |

\* By default, `.dataaccess.forceservers` is set to `0b`. In this case, only a subset of `.dataaccess.attributesrouting` can be used. However, if `.dataaccess.forceservers` is set to `1b` any server in `.gw.servers` can be used.

One major benefit of using `.dataaccess.getdata` can be seen when performing aggregations across different processes. An example of this can be seen below, where the user gets the max/min of bid/ask across both the RDB and HDB.

```
q)querydict:`tablename`starttime`endtime`aggregations!(`quote;2021.02.08D00:00:00.000000000;2021.02.09D09:00:00.000000000;`max`min!(`ask`bid;`ask`bid))
q)querydicttoday:`tablename`starttime`endtime`aggregations!(`quote;2021.02.09D00:00:00.000000000;2021.02.09D09:00:00.000000000;`max`min!(`ask`bid;`ask`bid))
q)querydictyesterday:`tablename`starttime`endtime`aggregations!(`quote;2021.02.09D00:00:00.000000000;2021.02.09D09:00:00.000000000;`max`min!(`ask`bid;`ask`bid))

// open connection to the gateway g
q)g:hopen`::1234:admin:admin

q)g(`.dataaccess.getdata;querydict)
maxAsk maxBid minAsk minBid
---------------------------
214.41 213.49 8.43   7.43
q)g(`.dataaccess.getdata;querydictyesterday)
maxAsk maxBid minAsk minBid
---------------------------
214.41 213.49 8.8    7.82
q)g(`.dataaccess.getdata;querydicttoday)
maxAsk maxBid minAsk minBid
---------------------------
94.81  93.82  8.43   7.43
```
The cross process aggregations also work with groupings and freeformby keys, for example 

```
q)querydict1:`tablename`starttime`endtime`aggregations`ordering`head!(`quote;2021.03.16D01:00:00.000000000;2021.03.17D18:00:00.000000000;"sym";`max`min!(`ask`bid;`ask`bid);`desc`maxAsk;-2)
q)g(`.dataaccess.getdata;querydict1)
sym | maxAsk maxBid minAsk minBid
----| ---------------------------
DELL| 29.37  28.33  7.87   6.84
DOW | 24.52  23.48  2.56   1.55
```
Such behaviour is not demonstrated when using freeform queries, for example:
```
q)querydict2:`tablename`starttime`endtime`aggregations`freeformcolumn!(`quote;2021.02.08D00:00:00.000000000;2021.02.09D09:00:00.000000000;"max ask,min ask,max bid, min bid")
q)g(`.dataaccess.getdata;querydict2)
ask    bid    ask1 bid1
-----------------------
214.41 213.49 8.8  7.82
94.81  93.82  8.43 7.43
```
Updates to the dataaccess gateway code sees an ability to perform all
map-reducable aggregations (except median) currently available to be performed
over multiple processes without the need for a grouping based upon the
partitioning field. The gateway now collects all the appropriate aggregates
needed to calculate a value, and then re-aggregates the collected data based
upon groupings when brought back to the gateway process. For complete clarity
the full list of aggregations that can span multiple processes without
a partitioned grouping are as follows: `avg`, `cor`, `count`, `cov`, `dev`,
`first`, `last`, `max`, `min`, `prd`, `sum`, `var`, `wavg` and `wsum`.

## Checkinputs

A key goal of the API is to prevent unwanted behaviour and return helpful error messages- this is done by  `.dataaccess.checkinputs`. which under the covers runs two different checking libraries:

- `.checkinputs` A set of universal basic input checks as defined in `checkinputs.csv` (example `.csv` below). These checks are performed from within the gateway if applicable. 
- `.dataaccess`  A set of process bespoke checks, performed from within the queried proccess.


**Description of Fields in checkinputs.csv**

|Field        |Description                                                            |
|-------------|-----------------------------------------------------------------------|
|parameter    |Dictionary key to pass to `getdata`                                    |
|required     |Whether this parameter is mandatory                                    |
|checkfunction|Function to determine whether the given value is valid                 |
|invalid pairs|Whether a parameter is invalid in combination with some other parameter|

**Example `checkinputs.csv`**

|parameter|required|checkfunction|invalidpairs|description|
|---------|--------|-------------|------------|-----------|
|tablename|1|.checkinputs.checktable||table to query
|starttime|1|.checkinputs.checktimetype||starttime - see timecolumn
|endtime|1|.checkinputs.checkendtime||endtime - see timecolumn
|timecolumn|0|.checkinputs.checktimecolumn||column to apply (startime;endime) filter to
|instruments|0|.checkinputs.checkinstruments||instruments of interest - see tableproperties.csv
|columns|0|.checkinputs.checkcolumns||table columns to return - assumed all if not present
|grouping|0|.checkinputs.checkgrouping||columns to group by -  no grouping assumed if not present
|aggregations|0|.checkinputs.checkaggregations|columns|freeformcolumn|dictionary of aggregations - e.g \`last\`max\`wavg!(\`time;\`bidprice\`askprice;(\`asksize\`askprice;\`bidsize\`bidprice))
|timebar|0|.checkinputs.checktimebar||list of (time column to group on;size;type - \`nanosecond\`second\`minute\`hour\`day)
|filters|0|.checkinputs.checkfilters||a dictionary of columns + conditions in string format
|ordering|0|.checkinputs.checkordering||a list of pairs regarding the direction (\`asc or \`desc) of ordering and a column to order
|freeformwhere|0|.checkinputs.isstring||where clause in string format
|freeformby|0|.checkinputs.isstring||by clause in string format
|freeformcolumn|0|.checkinputs.isstring||select clause in string format
|instrumentcolumn|0|.checkinputs.checkinstrumentcolumn||column to select instrument parameter from
|renamecolumn|0|.checkinputs.checkrenamecolumn||dictionary to rename a column in results
|postprocessing|0|.checkinputs.checkpostprocessing||applies postback lambda functions to data
|join|0|.checkinputs.checkjoin||Joins queries together
|postback|0|.checkinputs.checkpostback||sends async queries back
|timeout|0|.checkinputs.checktimeout||Checks the time of the timeout
|sublist|0|.checkinputs.checksublist||checks the head parameter
|procs|0|.checkinputs.checkprocs||Checks the procs is the correct servers
|sqlquery|0|.checkinputs.isstring||Select clause in string format
|getquery|0|.checkinputs.isboolean||Returns the queries in each of the process
|dryrun|0|.checkinputs.isboolean||Calculates the number of MB processed
|firstlastsort|0|.checkinputs.checkinstrumentcolumn||Allows for use of firstlastsort (not supported by dataaccess)
|optimisation|0|.checkinputs.isboolean||Toggle optimastion in queryorder


The csv file enables developers simple extension, modification or deletion of the accepted inputs. 

For example if the user want to add a key ``` `docs``` which accepts a boolean input they would add the following line to `checkinputs.csv` 

docs|0|.checkinputs.isboolean||info about docs function|

Furthermore, using the `.checkinputs.isboolean` function would provide the user with a more comprehesive error message than `'type` see messages below.

### Custom API Errors

Below is a list of all the errors the API will return:
Error|Function|Library|
|-----|---------|-------------|
|Table:{tablename} doesn't exist|checktablename|dataaccess|
|Column(s) {badcol} presented in {parameter} is not a valid column for {tab}|checkcolumns|dataaccess|
| If the distinct function is used, it cannot be present with any other aggregations including more of itself|checkaggregations|dataaccess|
| Aggregations dictionary contains undefined function(s)|checkaggregations|dataaccess|
| Incorrect number of input(s) entred for the following aggregations|checkaggregations|dataaccess|
| Aggregations parameter must be supplied in order to perform group by statements|checkaggregations|dataaccess|
| In order to use a grouping parameter, only aggregations that return single values may be used|checkaggregations|dataaccess|
| The inputted size of the timebar argument: {size}, is not an appropriate size. Appropriate sizes are:|checktimebar|dataaccess|
| Timebar parameter's intervals are too small. Time-bucket intervals must be greater than (or equal to) one nanosecond|checktimebar|dataaccess|
|Input dictionary must have keys of type 11h|checkdictionary|checkinputs|
|Required parameters missing:{}|checkdictionary|checkinputs|
|Invalid parameter present:{}|checkdictionary|checkinputs|
|Input must be a dictionary|isdictionary|checkinputs|
|Parameter:{parameter} cannot be used in conjunction with parameter(s):{invalidpairs}|checkeachpair|checkinputs|
|{} parameter(s) used more than once|checkrepeatparams|checkinputs|
|Starttime parameter must be <= endtime parameter|checktimeorder|checkinputs|
|Aggregations parameter key must be of type 11h - example:|checkaggregations|checkinputs|
|Aggregations parameter values must be of type symbol - example:|checkaggregations|checkinputs|
|First argument of timebar must be either -6h or -7h|checktimebar|checkinputs|
|Second argument of timebar must be of type -11h|checktimebar|checkinputs|
|Third argument of timebar must be have type -11h|checktimebar|checkinputs|
|Filters parameter key must be of type 11h - example:|checkfilters|checkinputs|
|Filters parameter values must be paired in the form (filter function;value(s)) or a list of three of the form (not;filter function;value(s)) - example:|checkfilters|checkinputs|
|Filters parameter values containing three elements must have the first element being the not keyword - example|checkfilters|checkinputs|
|Allowed operators are: =, <, >, <=, >=, in, within, like. The last three may be preceeded with 'not' e.g. (not within;80 100)|checkfilters|checkinputs|
|The 'not' keyword may only preceed the operators within, in and like.|checkfilters|checkinputs|
|(not)within statements within the filter parameter must contain exatly two values associated with it - example:|withincheck|checkinputs|
|The use of inequalities in the filter parameter warrants only one value|inequalitycheck|checkinputs|
|The use of equalities in the filter parameter warrants only one value - example:|inequalitycheck|checkinputs|
|Ordering parameter must contain pairs of symbols as its input - example:|checkordering|checkinputs|
|Ordering parameter's values must be paired in the form (direction;column) - example:|checkordering|checkinputs|
|The first item in each of the ordering parameter's pairs must be either \`asc or \`desc - example:|checkordering|checkinputs|
|Ordering parameter vague. Ordering by a column that aggregated more than once|checkordering|checkinputs|
|Ordering parameter contains column that is not defined by aggregations, grouping or timebar parameter|checkordering|checkinputs|

## Table Properties Configuration

Although the default configuration is often the best, there are examples when the user will have to define there own `tableproperties.csv` file. This will happen whenever a process has tables spanning timezones or a table has two columns of type p. We provide a complete example for clearer explanation:

Suppose a vanilla TorQ process has two tables trade and quote for a New York FX market (timezone ET). 

In our scenario the TorQ system is GMT based and the rollover times are as follows: 
- trade rolls over at midnight GMT  
- quote rolls over at 01:00 am New York time (ET) 

The meta for tables in the hdb are:  

```
q)meta trade
c    | t f a
-----| -----
date | d
time | p
sym  | s   p
price| f
size | i
stop | b
cond | c
ex   | c
side | s

q)meta quote
c     | t f a
------| -----
date  | d
time  | p
extime| p
sym   | s   p
bid   | f
ask   | f
bsize | j
asize | j
mode  | c
ex    | c
src   | s

```

Determining the correct primary time column for the trade table is simple as time is the unique column with of type p.

The quote table is more complicated as it has two time columns extime and time.
- The extime column is the time when the trade was made
- The time column is the time when the data entered the tickerplant

The time column is the most illuminating into the partition structure. 

The reason extime is not the primary time column is due to the latency between the exchange and TorQ process. 
Suppose the latency from the feed to tickerplant was a consistent 200ms. Now consider the following quote

- Quote1 comes into the exchange at 2020.02.02D00:59:59.900000000(ET) 
- Quote1 comes into the tickerplant at 2020.02.03D06:00:00.100000000(GMT)
- Quote1 will be in partition 2020.02.03
 
As such the partitioning structure is dependent on the time column not the extime column.
 
The p attribute on the sym column shows why it should be used as the attribute column.

For this example the following `tableproperties.csv` should be defined.   

|proctype|tablename|primarytimecolumn|attributecolumn|instrumentcolumn|rolltimeoffset|rolltimezone|datatimezone|partitionfield|
|--------|---------|-----------------|---------------|----------------|--------------|------------|------------|--------------|
|rdb     |trade    |time             |sym            |sym             |00:00         |GMT         |GMT         |              |
|hdb     |trade    |time             |sym            |sym             |00:00         |GMT         |GMT         |date          |
|rdb     |quote    |time             |sym            |sym             |01:00         |ET          |GMT         |              |
|hdb     |quote    |time             |sym            |sym             |01:00         |ET          |GMT         |date          |
 

## Query Optimisation

The queries are automatically optimised using `.queryorder.orderquery` this function is designed to improve the performance of certain queries as well as return intuative results.
This is done by:

- Prioritising filters against the primary attribute column in tableproperties.csv
- [Swapping in for multiple = statements and razing the result together](https://code.kx.com/q/wp/query-scaling/#efficient-select-statements-using-attributes)

Furthermore, columns are ordered to put date then sym columns to the left.

Optimisation can be toggled off by setting the value of ``` `queryoptimisation``` in the input dictionary to `0b`.

### Debugging and Optimisation

A key focus of the API is to improve accessibility whilst maintaining a strong performance. There are cases where the accessibilty impedes the usabilty or the query speed drops below what could be developed. In these situations one should ensure:

1. The user has a filter against a table attributes
2. The query only pulls in the essential data 
3. The output of `dataaccess.buildquery` is what is expected.

## Metrics 

### Introduction

A test was performed to determine the performance of: 

- The `getdata` function with optimisation on
- The `getdata` function with optimisation off
- Raw kdb+ query

### Methodology

Each query was run against 10/100/1000 sym TorQ stack each with a 5GB HDB (68 million rows over 22 partitions) and a 120 MB RDB (2 million rows) quotes table. 

### Query List

|Queryname|Call|
|---------|----|
|Optimised1|``` `tablename`starttime`endtime`freeformby`aggregations`freeformwhere)!(`quote;00:00+2020.12.17D10;.z.d+12:00;\"sym\";(`max`min)!((`ask`bid);(`ask`bid));\"sym in `AMD`HPQ`DOW`MSFT`AIG`IBM ```|
|kdb1|```select max ask,min bid,max bid,min ask by sym from quote where sym in `AMD`HPQ`DOW`MSFT`AIG`IBM```|
|Optimised2|```(`tablename`starttime`endtime`aggregations`timebar)!(`quote;2021.02.23D1;.z.p;(enlist(`max))!enlist(enlist(`ask));(6;`hour;`time))```|
|kdb2|```select max ask by 21600000000000 xbar time from quote where time>2021.02.23```|
|Optimised3|```(`tablename`starttime`endtime`filters!(`quote;2021.01.20D0;2021.02.25D12;`bsize`sym`bid!(enlist(not;within;5 43);enlist(like;\"*OW\");((<;85);(>;83.5)))))```|
|kdb3|```select from quote where bid within(83.5;85),not bsize within(5;43),sym like "*OW"```|


### Results

The results show the average execution time in ms for each query 

|Queryname   |10 syms |100 syms|1000 syms|
|------------|--------|--------|---------|
|Optimised1  |17      |53      |22       |
|Unoptimised1|8       |58      |17       |
|kdb1        |27      |50      |19       |
|Optimised2  |365     |220     |327      |
|Unoptimised2|320     |224     |649      |
|kdb2        |404     |362     |488      |
|Optimised3  |291     |153     |145      |
|Unoptimised3|283     |360     |391      |
|kdb3        |344     |392     |413      |

### Discussion

- Case 1 - Limited difference amongst all three queries, this occurs whenever a query can't be optimised or the dataset is too small for a change to be noticed.
- Case 2 - The API's strong all round performance, this occurs whenever a kdb+ query doesn't use the semantics of a process
- Case 3 - Demonstrates the performance boost of the API's optimiser, this occurs whenever a kdb+ query is not optimised


## Testing Library
Each subfunction of `getdata` has thorough tests found in `${KDBTESTS}/dataaccess/`. To run the tests:

1. Set environment variables
2. Ensure your TorQ stack is not running
3. Navigate to the appropriate testing directory
4. Run `. run.sh -d`

## Logging
Upon calling either `.dataaccess.getdata` or `getdata` the corresponding user, startime, endtime, handle, success and any error messages are upserted to the `.dataaccess.stats` table for example when a good and bad query are sent to the gateway:

```
// Good gateway query
q)g".dataaccess.getdata`tablename`starttime`endtime`aggregations`grouping!(`quote;2021.02.12D0;.z.p;((enlist `max)!enlist `ask`bid);`sym)"
sym | maxAsk maxBid
----| -------------
AAPL| 246.33 245.26
AIG | 85.07  84
...
// Bad gateway query
q)g".dataaccess.getdata`tablename`starttime`endtime`aggregations`grouping!(`quote;2021.02.12D0;15;((enlist `max)!enlist `ask`bid);`sym)"
'`endtime input type incorrect - valid type(s):-12 -14 -15h - input type:-7h
  [0]  g".dataaccess.getdata`tablename`starttime`endtime`aggregations`grouping!(`quote;2021.02.12D0;15;((enlist `max)!enlist `ask`bid);`sym)"
       ^
```
The following are the gateway and rdb logs:
```
// The logging in the gateway returns 

q)g".dataaccess.stats"
querynumber| user  starttime                     endtime                       handle request                                                                                                                                        success error
-----------| -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
1          | admin 2021.03.25D14:52:03.380485000 2021.03.25D14:52:04.138481000 11     `tablename`starttime`endtime`aggregations`grouping!(`quote;2021.02.12D00:00:00.000000000;2021.03.25D14:52:03.380478000;(,`max)!,`ask`bid;`sym) 1
2          | admin 2021.03.25D14:52:20.546227000 2021.03.25D14:52:20.546341000 11     `tablename`starttime`endtime`aggregations`grouping!(`quote;2021.02.12D00:00:00.000000000;15;(,`max)!,`ask`bid;`sym)                            0       `endtime input type incorrect - valid type(s):-12 -14 -15h - input type:-7h

// The bad query errored out in the gateway, consequently only the good query is seen in the rdb logs

q).dataaccess.stats
querynumber| user    starttime                     endtime                       handle request                                                                                                                                                                          success error
-----------| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
1          | gateway 2021.03.25D14:52:03.381980000 2021.03.25D14:52:03.407870000 10     `tablename`starttime`endtime`aggregations`grouping`checksperformed`procs!(`quote;2021.02.12D00:00:00.000000000;2021.03.25D14:52:03.380478000;(,`max)!,`ask`bid;`sym;1b;`hdb`rdb) 1

```
Logging can be toggled off from within a process by setting the value of `.dataaccess.logging` to `0b`.

# Further Integration

This section describes the remaining features of the API as well as how the API can be leveraged to work with other AquaQ technologies.

## Implementation with TorQ FSP

The API is compatible with the most recent [TorQ Finance-Starter-Package](https://github.com/AquaQAnalytics/TorQ-Finance-Starter-Pack), the fastest way to import the API is opening `{APPCONFIG}/processes.csv` and adding the following flag ` -dataaccess ${KDBCONFIG}/dataaccess/tableproperties.csv` to the `rdb`, `hdb` and `gateway` extras column. For example:

```
host,port,proctype,procname,U,localtime,g,T,w,load,startwithall,extras,qcmd
localhost,{KDBBASEPORT}+2,rdb,rdb1,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/rdb.q,1,-dataaccess ${KDBCONFIG}/dataaccess/tableproperties.csv ,q
localhost,{KDBBASEPORT}+3,hdb,hdb1,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,60,4000,${KDBHDB},1,-dataaccess ${KDBCONFIG}/dataaccess/tableproperties.csv,q
localhost,{KDBBASEPORT}+4,hdb,hdb2,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,60,4000,${KDBHDB},1,,q
localhost,{KDBBASEPORT}+7,gateway,gateway1,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,,4000,${KDBCODE}/processes/gateway.q,1,-dataaccess ${KDBCONFIG}/dataaccess/tableproperties.csv,q
```

## Implementation with q-REST
 
The API is compatible with q-REST. To do this:

1. Download [q-REST](https://github.com/AquaQAnalytics/q-REST)
2. Open `application.properties` and point `kdb.host/port` to the gateway
3. Use the execute function argument to send `.json`s of the form:
```
{
"function_name": ".dataaccess.qrest",
"arguments":{
"tablename":"quote",
"starttime":"2021.02.17D10:00:00.000000000",
"endtime":"2021.02.18D12:00:00.000000000",
"freeformby":"sym",
"aggregations":" `max`min!(`ask`bid;`ask)",
"filters":"`sym`bid`bsize!(enlist(like;'*PL');((<;85);(>;83.5));enlist(~:;within;5 43))"
}
}
```

q-REST requires some modifications to the input dictionary:

1. All dictionary values must be in string format
2. Nested quotion marks are not permitted (Even when escaped out using `\"`)
3. The second argument in a `like` filter should be have ' rather than " e.g ```(like; 'AMD')```


## Implementation with Google BigQuery

As key goal of the API has been TorQ's integration with other SQL databases such as Google BigQuery the successful outcome is discussed in the following blog:

```!!! ADD A BLOG HERE!!!```

# Further Examples

For every key in the dictionary the following examples provide a query, output and the functional select executed from within the process. 

**Time default**

If the time column isn't specified it defaults to the value of ``` `primaryattributecolumn ```

```
getdata`tablename`starttime`endtime!(`quote;2021.01.20D0;2021.01.23D0)
date       time                          sym  bid   ask   bsize asize mode ex src
----------------------------------------------------------------------------------
2021.01.21 2021.01.21D13:36:45.714478000 AAPL 84.01 84.87 77    33    A    N  BARX
2021.01.21 2021.01.21D13:36:45.714478000 AAPL 83.1  84.52 58    84    Y    N  DB
2021.01.21 2021.01.21D13:36:45.714478000 AAPL 83.3  84.63 76    28    I    N  DB
2021.01.21 2021.01.21D13:36:45.714478000 AAPL 83.58 84.93 13    89    Y    N  SUN
2021.01.21 2021.01.21D13:36:46.113465000 AAPL 83.96 84.24 50    73    Y    N  DB

...
.dataaccess.buildquery `tablename`starttime`endtime!(`quote;2021.01.20D0;2021.01.23D0)
? `quote ,(within;`time;2021.01.20D00:00:00.000000000 2021.01.23D00:00:00.000000000) 0b ()
```

**Intsrument Filter**

Use the ``` `instruments ``` parameter to filter for ``` sym=`AAPL ```

```
getdata`tablename`starttime`endtime`instruments!(`quote;2021.01.20D0;2021.01.23D0;`AAPL)
date       time                          sym  bid   ask   bsize asize mode ex src
----------------------------------------------------------------------------------
2021.01.21 2021.01.21D13:36:45.714478000 AAPL 84.01 84.87 77    33    A    N  BARX
2021.01.21 2021.01.21D13:36:45.714478000 AAPL 83.1  84.52 58    84    Y    N  DB
2021.01.21 2021.01.21D13:36:45.714478000 AAPL 83.3  84.63 76    28    I    N  DB
2021.01.21 2021.01.21D13:36:45.714478000 AAPL 83.58 84.93 13    89    Y    N  SUN
2021.01.21 2021.01.21D13:36:46.113465000 AAPL 83.96 84.24 50    73    Y    N  DB
..
...
q).dataaccess.buildquery `tablename`starttime`endtime`instruments!(`quote;2021.01.20D0;2021.01.23D0;`AAPL)
? `quote ((=;`sym;,`AAPL);(within;`time;2021.01.20D00:00:00.000000000 2021.01.23D00:00:00.000000000)) 0b ()
```

**Columns**

Use the ``` `columns ``` parameter to extract the following columns - ``` `sym`time`bid ```

```
getdata`tablename`starttime`endtime`columns!(`quote;2021.01.20D0;2021.01.23D0;`sym`time`bid)
sym  time                          bid
----------------------------------------
AAPL 2021.01.21D13:36:45.714478000 84.01
AAPL 2021.01.21D13:36:45.714478000 83.1
AAPL 2021.01.21D13:36:45.714478000 83.3
AAPL 2021.01.21D13:36:45.714478000 83.58
AAPL 2021.01.21D13:36:46.113465000 83.96

...
q).dataaccess.buildquery `tablename`starttime`endtime`columns!(`quote;2021.01.20D0;2021.01.23D0;`sym`time`bid)
? `quote ,(within;`time;2021.01.20D00:00:00.000000000 2021.01.23D00:00:00.000000000) 0b `sym`time`bid!`sym`time`bid

```

**Free form select**

Run a free form select using the ``` `freeformcolumn ``` parameter

```
getdata`tablename`starttime`endtime`freeformcolumn!(`quote;2021.01.20D0;2021.01.23D0;"sym,time,mid:0.5*bid+ask")
sym  time                          mid
-----------------------------------------
AAPL 2021.01.21D13:36:45.714478000 84.44
AAPL 2021.01.21D13:36:45.714478000 83.81
AAPL 2021.01.21D13:36:45.714478000 83.965
AAPL 2021.01.21D13:36:45.714478000 84.255
AAPL 2021.01.21D13:36:46.113465000 84.1

...
q).dataaccess.buildquery `tablename`starttime`endtime`freeformcolumn!(`quote;2021.01.20D0;2021.01.23D0;"sym,time,mid:0.5*bid+ask")
? `quote ,(within;`time;2021.01.20D00:00:00.000000000 2021.01.23D00:00:00.000000000) 0b `sym`time`mid!(`sym;`time;(*;0.5;(+;`bid;`ask)))
```
This can be used in conjunction with the `columns` parameter, however the `columns` parameters will be returned first. It is advised to use the `columns` parameter for returning existing columns and the `freeformcolumn` for any derived columns.

**Grouping**

Use ``` `grouping ``` parameter to group average ``` `mid```, by ``` `sym ```

```
getdata`tablename`starttime`endtime`freeformcolumn`grouping!(`quote;2021.01.20D0;2021.01.23D0;"avgmid:avg 0.5*bid+ask";`sym)
sym | avgmid
----| --------
AAPL| 70.63876
AIG | 31.37041
AMD | 36.46488
DELL| 8.34496
DOW | 22.8436

q).dataaccess.buildquery `tablename`starttime`endtime`freeformcolumn`grouping!(`quote;2021.01.20D0;2021.01.23D0;"avgmid:avg 0.5*bid+ask";`sym)
? `quote ,(within;`time;2021.01.20D00:00:00.000000000 2021.01.23D00:00:00.000000000) (,`sym)!,`sym (,`avgmid)!,(avg;(*;0.5;(+;`bid;`ask)))
```

**String style grouping**

Group average ``` `mid```, by ``` instru:sym ``` using the ``` `freeformby ``` parameter

```
getdata`tablename`starttime`endtime`freeformcolumn`freeformby!(`quote;2021.01.20D0;2021.01.23D0;"avgmid:avg 0.5*bid+ask";"instr:sym")
instr| avgmid
-----| --------
AAPL | 70.63876
AIG  | 31.37041
AMD  | 36.46488
DELL | 8.34496
DOW  | 22.8436

q).dataaccess.buildquery `tablename`starttime`endtime`freeformcolumn`freeformby!(`quote;2021.01.20D0;2021.01.23D0;"avgmid:avg 0.5*bid+ask";"instr:sym")
? `quote ,(within;`time;2021.01.20D00:00:00.000000000 2021.01.23D00:00:00.000000000) (,`instr)!,`sym (,`avgmid)!,(avg;(*;0.5;(+;`bid;`ask)))

```

**Time bucket**

Group max ask by  6 hour buckets using the ``` `timebar ``` parameter

```
getdata(`tablename`starttime`endtime`aggregations`instruments`timebar)!(`quote;2021.01.21D1;2021.01.28D23;(enlist(`max))!enlist(enlist(`ask));`AAPL;(6;`hour;`time))
time                         | maxAsk
-----------------------------| ------
2021.01.21D12:00:00.000000000| 98.99
2021.01.21D18:00:00.000000000| 73.28
2021.01.22D12:00:00.000000000| 97.16
2021.01.22D18:00:00.000000000| 92.58
...
q).dataaccess.buildquery (`tablename`starttime`endtime`aggregations`instruments`timebar)!(`quote;2021.01.21D1;2021.01.28D23;(enlist(`max))!enlist(enlist(`ask));`AAPL;(6;`hour;`time))
? `quote ((=;`sym;,`AAPL);(within;`time;2021.01.21D01:00:00.000000000 2021.01.28D23:00:00.000000000)) (,`time)!,({[timebucket;x]
  typ:type x;
  if[typ~12h;:timebucket xbar x];
  if[typ in 13 14h;:..

```

**Aggregations**

Max of both ``` `bidprice ``` and ``` `askprice ```


```
getdata`tablename`starttime`endtime`aggregations!(`quote;2021.01.20D0;2021.01.23D0;((enlist `max)!enlist `ask`bid))
maxAsk maxBid
-------------
109.5  108.6

q).dataaccess.buildquery `tablename`starttime`endtime`aggregations!(`quote;2021.01.20D0;2021.01.23D0;((enlist `max)!enlist `ask`bid))
? `quote ,(within;`time;2021.01.20D00:00:00.000000000 2021.01.23D00:00:00.000000000) 0b `maxAsk`maxBid!((max;`ask);(max;`bid))


```

**Filters**

Use the ``` `filters ``` parameter to execute a functional select style where clause

```
getdata`tablename`starttime`endtime`filters!(`quote;2021.01.20D0;2021.01.23D0;(enlist(`src))!enlist enlist(in;`GETGO`DB))
date       time                          sym  bid   ask   bsize asize mode ex src
---------------------------------------------------------------------------------
2021.01.21 2021.01.21D13:36:45.714478000 AAPL 83.1  84.52 58    84    Y    N  DB
2021.01.21 2021.01.21D13:36:45.714478000 AAPL 83.3  84.63 76    28    I    N  DB
2021.01.21 2021.01.21D13:36:46.113465000 AAPL 83.96 84.24 50    73    Y    N  DB
2021.01.21 2021.01.21D13:36:46.113465000 AAPL 83.8  84.76 78    32    Z    N  DB
2021.01.21 2021.01.21D13:36:48.714396000 AAPL 83.5  84.99 42    71    R    N  DB
..
q).dataaccess.buildquery `tablename`starttime`endtime`filters!(`quote;2021.01.20D0;2021.01.23D0;(enlist(`src))!enlist enlist(in;`GETGO`DB))
? `quote ((within;`time;2021.01.20D00:00:00.000000000 2021.01.23D00:00:00.000000000);(in;`src;,`GETGO`DB)) 0b ()

...
```

**Free form Filters**

Use the ``` `freefromwhere ``` parameter to execute the same filter as above

```
getdata`tablename`starttime`endtime`freeformwhere!(`quote;2021.01.20D0;2021.01.23D0;"src in `DB`GETGO")
date       time                          sym  bid   ask   bsize asize mode ex src
---------------------------------------------------------------------------------
2021.01.21 2021.01.21D13:36:45.714478000 AAPL 83.1  84.52 58    84    Y    N  DB
2021.01.21 2021.01.21D13:36:45.714478000 AAPL 83.3  84.63 76    28    I    N  DB
2021.01.21 2021.01.21D13:36:46.113465000 AAPL 83.96 84.24 50    73    Y    N  DB
2021.01.21 2021.01.21D13:36:46.113465000 AAPL 83.8  84.76 78    32    Z    N  DB
2021.01.21 2021.01.21D13:36:48.714396000 AAPL 83.5  84.99 42    71    R    N  DB

...
q).dataaccess.buildquery `tablename`starttime`endtime`freeformwhere!(`quote;2021.01.20D0;2021.01.23D0;"src in `DB`GETGO")
? `quote ((within;`time;2021.01.20D00:00:00.000000000 2021.01.23D00:00:00.000000000);(in;`src;,`DB`GETGO)) 0b ()


```
**Ordering**

Use the ``` `ordering ``` parameter to sort results by column ascending or descending

```
getdata`tablename`starttime`endtime`ordering!(`quote;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000;enlist(`asc`asksize))
sym    time                          sourcetime                    bidprice bidsize askprice asksize
----------------------------------------------------------------------------------------------------
AAPL   2000.01.01D02:24:00.000000000 2000.01.01D02:24:00.000000000 90.9     932.4   111.1    1139.6
AAPL   2000.01.01D04:48:00.000000000 2000.01.01D04:48:00.000000000 98.1     933.3   119.9    1140.7
GOOG   2000.01.01D10:24:00.000000000 2000.01.01D11:12:00.000000000 96.3     940.5   117.7    1149.5
AAPL   2000.01.01D00:00:00.000000000 2000.01.01D00:00:00.000000000 97.2     959.4   118.8    1172.6
GOOG   2000.01.01D00:48:00.000000000 2000.01.01D01:36:00.000000000 93.6     1008    114.4    1232
GOOG   2000.01.01D03:12:00.000000000 2000.01.01D04:00:00.000000000 101.7    1078.2  124.3    1317.8
...
q).dataaccess.buildquery `tablename`starttime`endtime`ordering!(`quote;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000;enlist(`asc`asksize))
? `quote ,(within;`time;2000.01.01D00:00:00.000000000 2000.01.06D10:00:00.000000000) 0b ()
```

**Rename Columns**

Use the ``` `renamecolumn ``` parameter to rename the columns 

```
getdata (`tablename`starttime`endtime`freeformby`freeformcolumn`instruments`renamecolumn)!(`trade;2021.01.18D0;2021.01.20D0;"sym,date";"max price";`IBM`AAPL`INTC;`sym`price`date!`newsym`newprice`newdate)
newdate    newsym| newprice
-----------------| --------
2021.01.18 IBM   | 69.64
2021.01.19 IBM   | 55.91
2021.01.18 AAPL  | 121.66
2021.01.19 AAPL  | 111.67
2021.01.18 INTC  | 70.77
2021.01.19 INTC  | 65.6
```

**Postprocessing**

Use the ``` `postproccessing``` key to under go post proccessing on a table for example flipping the table into a dictionary

```
q)getdata`tablename`starttime`endtime`aggregations`postback!(`quote;2021.02.12D0;2021.02.12D12;((enlist `max)!enlist `ask`bid);{flip x})
maxAsk| 91.74
maxBid| 90.65

q).dataaccess.buildquery `tablename`starttime`endtime`aggregations`postback!(`quote;2021.02.12D0;2021.02.12D12;((enlist `max)!enlist `ask`bid);{flip x})
? `quote ,(within;`time;2021.02.12D00:00:00.000000000 2021.02.12D12:00:00.000000000) 0b `maxAsk`maxBid!((max;`ask);(max;`bid))

```
More complex example collecting the avg price across multiple processes in the gateway g
``` 

q)g".dataaccess.getdata`tablename`starttime`endtime`aggregations`postprocessing!(`quote;2021.02.12D0;.z.p;(`sum`count)!2#`ask;{flip x})"
sumAsk  | 1.288549e+09
countAsk| 28738958
q)g".dataaccess.getdata`tablename`starttime`endtime`aggregations`postprocessing!(`quote;2021.02.12D0;.z.p;(`sum`count)!2#`ask;{select avgprice: sumAsk%countAsk from x})"
avgprice
--------
44.83632

```

**Sublist**

Use the ``` `sublist``` key to return the first n rows of a table, for example we get the first 2 rows of the table.

```
q)getdata `tablename`starttime`endtime`freeformby`aggregations`ordering`sublist!(`quote;00:00+2021.02.17D10;.z.d+18:00;\"sym\";(`max`min)!((`ask`bid);(`ask`bid));enlist(`desc;`maxAsk);2)

sym | maxAsk maxBid minAsk minBid
----| ---------------------------
AAPL| 171.23 170.36 56.35  55.32
GOOG| 101.09 99.96  45.57  44.47

q).dataaccess.buildquery `tablename`starttime`endtime`freeformby`aggregations`ordering`head!(`quote;00:00+2021.02.17D10;.z.d+18:00;\"sym\";(`max`min)!((`ask`bid);(`ask`bid));enlist(`desc;`maxAsk);2)
? `quote ,(within;`time;2021.02.17D10:00:00.000000000 2021.03.03D18:00:00.000000000) (,`sym)!,`sym `maxAsk`maxBid`minAsk`minBid!((max;`ask);(max;`bid);(min;`ask);(min;`bid))

q)getdata `tablename`starttime`endtime`freeformby`aggregations`ordering`sublist!(`quote;00:00+2021.02.17D10;.z.d+18:00;\"sym\";(`max`min)!((`ask`bid);(`ask`bid));enlist(`desc;`maxAsk);2 3)"
sym | maxAsk maxBid minAsk minBid
----| ---------------------------
INTC| 68.51  67.56  44.59  43.63
IBM | 48.53  47.61  37.1   36.11
HPQ | 46.09  45.05  29.97  29.03

```
