# Data Access API

# Introduction and Key Features

The Dataaccess API is a TorQ upgrade designed for cloud compatibility. 

Other Key upgrades of the API are:
- Compatibility with non kdb processes such as Google BigQuery and qREST
- Consistent queries across all processes 
- Data retrieval does not require q-SQL knowledge only q dictionary manipulation
- User friendly interface including more comprehensible error messages
- Queries are automatically optimised for each process
- Thorough testing allowing ease of further development

# Configuration

The API can initialised in a TorQ proccess by either:

1) Pass "-dataaccess /path/to/tableproperties.csv" on the startup line (see Example table properties file below for format)
2) Run ".dataaccess.init[`:/path/to/tableproperties.csv]" to initialise the code in a running process.

In both cases the filepath should point to `tableproperties.csv` a `.csv` containing information about all the tables you want API to query. The information provided defines default functionality for the API.

**Description of fields in tableproperties.csv**

|Field               |Description                                                                                        |
|--------------------|---------------------------------------------------------------------------------------------------|
|proctype            |denotes the type of process                                                                        |
|tablename           |table to query - assumed unique across given proctype                                              |
|primarytimecolumn   |default time column from the tickerplant - used if no  \`timecolumn parameter is passed            |
|attributecolumn     |primary attribute column - used in ordering of queries                                             |
|instrumentcolumn    |column containing instrument                                                                       |
|timezone            |timezone of the timestamps on the data (NYI)                                                       |
|getrollover         |custom function to determine last rollover from a timestamp                                        |
|getpartitionrange   |custom function to determine the partition range which should be used when querying hdb (see below)|

**Example configuration file** - with 'trade' and 'quote' tables in both a rdb and hdb

|proctype   |tablename  |primarytimecolumn     |attributecolumn       |instrumentcolumn|timezone|getrollover     |getpartitionrange   |
|-----------|-----------|----------------------|----------------------|----------------|--------|----------------|--------------------|
|rdb|trade|time|sym|sym||defaultrollover|defaultpartitionrange|
|hdb|trade|time|sym|sym||defaultrollover|defaultpartitionrange|
|rdb|quote|time|sym|sym||defaultrollover|defaultpartitionrange|
|hdb|quote|time|sym|sym||defaultrollover|defaultpartitionrange|


The API allows for the user to define either a blank or all proctype to define the tables in both the RDB and HDB. The following table is identical to the above


 |proctype   |tablename  |primarytimecolumn     |attributecolumn       |instrumentcolumn|timezone|getrollover     |getpartitionrange   |
 |-----------|-----------|----------------------|----------------------|----------------|--------|----------------|--------------------|
 |all|trade|time|sym|sym||defaultrollover|defaultpartitionrange|
 |all|quote|time|sym|sym||defaultrollover|defaultpartitionrange|


The following code is an example `code/dataaccess/customfuncs.q`, it defines the custom functions referenced in the above tables. This allows the developer to create functions to automatically query the correct process and partitions. 


```
\d .dataaccess

// Rollover in localtime
rollover:00:00;

//- (i) getrollover
//- Function to determine which partitions the getdata function should query
//- e.g If the box is based in Paris GMT+01:00 and rollover is at midnight London time then tzone:-01:00 
//- e.g If the box is UTC based and rollover is at 10pm UTC then rover: 22:00

defaultrollover:{[partitionfield;hdbtime;tzone;rover]
    // If no time zone argument is supplied then just assume the stamps are in local time
    if[tzone~`;tzone:00:00];
    //Return the partition 
    :(partitionfield$hdbtime)+(tzone+rover)>`minute$hdbtime};

//- (ii) getpartitionrange
//- offset times for non-primary time columns
// example @[`date$(starttime;endtime);1;+;not `time~`time]

defaultpartitionrange:{[timecolumn;primarytimecolumn;partitionfield;hdbtimerange;rolloverf;timezone]
    // Get the partition fields from default rollover 
    hdbtimerange:partitionfield rolloverf[;;timezone;rollover]/: hdbtimerange;
    // Output the partitions allowing for non-primary timecolumn
    :@[hdbtimerange;1;+;not timecolumn~primarytimecolumn]};

// Gets the last rollover
lastrollover:{:defaultrollover[`date;.proc.cp[];`;rollover]};


```



# Usage

When using the API to send queries direct to a process, the overarching function is getdata. getdata is a dynamic lightweight function which takes in a uniform dictionary type (see table below) and the above configuration to build a process bespoke query. Input consistency permits the user to disregard a processes' pragmatics allowing it to be called either directly within a process or via `.dataccess.getdata` (discussed in the gateway).

The getdata function is split into three sub functions: checkinputs, extractqueryparams and queryorder. Checkinputs checks if the input dictionary is valid; extractqueryparams converts the arguments into q-SQL and queryorder is the API's query optimiser (See Debugging and Optimisation).

The following table lists getdata's accepted arguments: 

**Valid Inputs**

|Parameter     |Required|Example\*\*                                                                                   |Invalidpairs\*               |Description                                                                     |
|--------------|--------|------------------------------------------------------------------------------------------|-----------------------------|--------------------------------------------------------------------------------|
|tablename     |Yes       |\`quote                                                                                   |                             |table to query                                                                  |
|starttime     |Yes       |2020.12.18D12:00                                                                          |                             |start time - must be a valid time type (see timecolumn)                           |
|endtime       |Yes       |2020.12.20D12:00                                                                          |                             |end time - must be a valid time type (see timecolumn)                             |
|timecolumn    |No       |\`time                                                                                    |                             |column to apply (startime;endime) filter to                                     |
|instruments   |No       |\`AAPL\`GOOG                                                                              |                             |instruments to filter on - will usually have an attribute applied (see tableproperties.csv)|
|columns       |No       |\`sym\`bid\`ask\`bsize\`asize                                                             |aggregations                 |table columns to return - symbol list - assumed all if not present              |
|grouping      |No       |\`sym                                                                                     |                             |columns to group by -  no grouping assumed if not present                       |
|aggregations  |No       |\`last\`max\`wavg!(\`time;\`bidprice\`askprice;(\`asksize\`askprice;\`bidsize\`bidprice)) |columns&#124;freeformcolumn  |dictionary of aggregations                                                      |
|timebar       |No       |(10;\`minute;\`time)                                                                       |                             |list of (bar size; time type;timegrouping column) valid types: \`nanosecond\`second\`minute\`hour\`day)|
|filters       |No       |\`sym\`bid\`bsize!(enlist(like;"AAPL");((<;85);(>;83.5));enlist(not;within;5 43))         |                             |a dictionary of ordered filters to apply to keys of dictionary                  |
|freeformwhere |No       |"sym=\`AAPL, src=\`BARX, price within 60 85"                                              |                             |where clause in string format                                                   |
|freeformby    |No       |"sym:sym, source:src"                                                                     |                             |by clause in string format
|freeformcolumn|No       |"time, sym,mid\:0.5\*bid+ask"                                                             |aggregations                 |select clause in string format 
|ordering      |No       |enlist(\`desc\`bidprice)                                                                  |                             |list ordering results ascending or descending by column
|renamecolumn  |No       | \`old1\`old2\`old3!\`new1\`new2\`new3                                                    |                             | Either a dictionary of old!new or list of column names
|postprocessing|No|{flip x}| |Post-processing of the data|
|queryoptimisation|No|0b| | Determines whether the query optimiser should be turned on/off|

\* Invalid pairs are two dictionary keys not allowed to be defined simultaneously, this is done to prevent unexpected behaviour, such as `select price,mprice:max price from trade`. If an invalid key pair is desired the user should convert all inputs to the q-SQL version.

\*\* More complete examples are provided in the Examples section below

**Example function call**

```
q)getdata`tablename`starttime`endtime`instruments`columns!(`quote;2021.01.20D0;2021.01.23D0;`GOOG;`sym`time`bid`bsize)
sym    time                        bid   bsize
----------------------------------------------
GOOG 2021.01.21D13:36:45.714478000 71.57 1
GOOG 2021.01.21D13:36:45.714478000 70.86 2
GOOG 2021.01.21D13:36:45.714478000 70.91 8
GOOG 2021.01.21D13:36:45.714478000 70.91 6
...
```
`.dataaccess.buildquery` function provides the developer with an insight into the query that has been built for example

```
q.dataaccess.buildquery `tablename`starttime`endtime`instruments`columns!(`quote;2021.01.20D0;2021.01.23D0;`GOOG;`sym`time`bid`bsize)
? `quote ((=;`sym;,`GOOG);(within;`time;2021.01.20D00:00:00.000000000 2021.01.23D00:00:00.000000000)) 0b `sym`time`bid`bsize!`sym`time`bid`bsize

```
## Aggregations 

The aggregations key is a dictionary led method of perfoming mathematical operations on columns of a table. The dictionary should be of the form: 

``` `agg1`agg2`...`aggn!((`col11`col12...`col1a);(`col21`col22...`col2b);...;(`coln1`coln2...`colnm)```

Certain aggregations are cross proccess enabled . The key accepts the following table of inputs:

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

The following function can be used to merge two aggregation dictionaries: 

```
f:{{(key x,y)!{:$[0=count raze x[z];y[z];$[2=count raze y[z];($[1=count x[z];raze x[z];x[z]];raze y[z]);raze x[z],raze y[z]]]}[x;y;] each key x,y}/[x]}
```

```
q)A
min| price
q)B
min| time
q)E
wavg| bid bsize
q)f[(A;B;E)]
min | `price`time
wavg| ,`bid`bsize
```

## Filters

The filters key is a dictionary led method of controlling which entries of a given table are being queried by setting out a criteria. The dictionary uses a table column as the key and the entries as the condition to be applied to that column. Any condition to be applied should be entered as a nest of two item lists for each condition and each sublist entered as an operator first followed by conditional values, for example:

``` `col1`col2`...`coln!((op;cond);((op;cond);(op;cond));...;(op;cond)```

For negative conditionals, the not operator can be included as the first item of a three item list for the operators in, like and within, e.g.

``` enlist`col1!enlist(not;within;`cond1`cond2)```

**Table of available Filters**

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
|`not`       |negative conditional when used with in,like or within|```(enlist`col)!enlist(not;in/like/within;input)```          |

# Gateway

Accepting a uniform dictionary allows queries to be sent to the gateway using `.dataaccess.getdata` similar to `getdata` however `.dataaccess.getdata`
 
- Leverages the checkinputs library from within the gateway to catch errors 
- Uses `.gw.servers` to dynamically determine the appropriate processes to call the getdata function in 
- Determines the query type to send to the process(es)
- Accepts further optional arguments to better determine the behaviour of the function see table below:

|Input Key|Example        |Default behaviour           |Description                                       |
|---------|---------------|----------------------------|--------------------------------------------------|
|postback |()             |()                          |Post back function for retuning async queries only|
|join     |`raze`         |`.dataaccess.multiprocjoin` |Join function to merge the tables                 |
|timeout  |`00:00:03`     |0Wn                         |Maximum time for query to run                     |

The key benefit of using `.dataaccess.getdata` is when capturing cross process aggregations, as seen below where the user gets the max/min bid/ask across the RDB and HDB.

```
g"querydict"
tablename   | `quote
starttime   | 2021.02.08D00:00:00.000000000
endtime     | 2021.02.09D09:00:00.000000000
aggregations| `max`min!(`ask`bid;`ask`bid)
q)g"querydicttoday"
tablename   | `quote
starttime   | 2021.02.09D00:00:00.000000000
endtime     | 2021.02.09D09:00:00.000000000
aggregations| `max`min!(`ask`bid;`ask`bid)
q)g"querydictyesterday"
tablename   | `quote
starttime   | 2021.02.08D00:00:00.000000000
endtime     | 2021.02.09D00:00:00.000000000
aggregations| `max`min!(`ask`bid;`ask`bid)
q)g".dataaccess.getdata querydict"
maxAsk maxBid minAsk minBid
---------------------------
214.41 213.49 8.43   7.43
q)g".dataaccess.getdata querydictyesterday"
maxAsk maxBid minAsk minBid
---------------------------
214.41 213.49 8.8    7.82
q)g".dataaccess.getdata querydicttoday"
maxAsk maxBid minAsk minBid
---------------------------
94.81  93.82  8.43   7.43
```
Such behaviour is not demonstrated when using freeform queries for example:
```
g"querydict"
tablename     | `quote
starttime     | 2021.02.08D00:00:00.000000000
endtime       | 2021.02.09D09:00:00.000000000
freeformcolumn| "max ask,max bid,min ask,min bid"
q)g".dataaccess.getdata querydict"
ask    bid    ask1 bid1
-----------------------
214.41 213.49 8.8  7.82
94.81  93.82  8.43 7.43

```
As seen in the aggregations section, only aggregations which can be factored across processes are enabled, this is because defining the irreducible aggregations would result in inaccuracies. Should the user wish to use these aggregations or define other joins and timeouts: they should adapt the``` `join``` key appropriately.

## Checkinputs

A key goal of the API is to prevent unwanted behaviour and return helpful error messages- this is done by the checkinputs. There are two checkinputs libraries firstly common `.checkinputs` this library is loaded into all proccess and is used to undergo basic input checks on each key as defined in `checkinputs.csv` (example below). Upon hitting the process more bespoke `.dataaccess` checks are performed. 


**Description of fields in checkinputs.csv**

|Field        |Description                                                            |
|-------------|-----------------------------------------------------------------------|
|parameter    |Dictionary key to pass to getdata                                      |
|required     |Whether this parameter is mandatory                                    |
|checkfunction|Function to determine whether the given value is valid                 |
|invalid pairs|Whether a parameter is invalid in combination with some other parameter|

**Example `checkinputs.csv`**

|parameter|required|checkfunction|invalidpairs|description|
|---------|--------|-------------|------------|-----------|
|tablename|1|.checkinputs.checktable||table to query|
|starttime|1|.checkinputs.checktimetype||starttime - see timecolumn|
|endtime|1|.checkinputs.checkendtime||endtime - see timecolumn|
|timecolumn|0|.checkinputs.checktimecolumn||column to apply (startime;endime) filter to|
|instruments|0|.checkinputs.checkinstruments||instruments of interest - see tableproperties.csv|
|columns|0|.checkinputs.checkcolumns|aggregations|table columns to return - assumed all if not present|
|grouping|0|.checkinputs.checkgrouping||columns to group by -  no grouping assumed if not present|
|aggregations|0|.checkinputs.checkaggregations|columns|freeformcolumn|dictionary of aggregations - e.g \`last\`max\`wavg!(\`time;\`bidprice\`askprice;(\`asksize\`askprice;\`bidsize\`bidprice))|
|timebar|0|.checkinputs.checktimebar||list of (time column to group on;size;type - \`nanosecond\`second\`minute\`hour\`day)|
|filters|0|.checkinputs.checkfilters||a dictionary of columns + conditions in string format|
|ordering|0|.checkinputs.checkordering||a list of pairs regarding the direction (\`asc or \`desc) of ordering and a column to order|
|freeformwhere|0|.checkinputs.isstring||where clause in string format|
|freeformby|0|.checkinputs.isstring||by clause in string format|
|freeformcolumn|0|.checkinputs.isstring|aggregations|select clause in string format|
|instrumentcolumn|0|.checkinputs.checkinstrumentcolumn||column to select instrument parameter from|
|queryoptimisation|0|.checkinputs.isbool||Toogle query optimiser|
|postprocessing|0|.checkinputs.checkpostprocessing||applies postback lambda functions to data|
|join|0|.checkinputs.checkjoin||Joins queries together|
|postback|0|.checkinputs.checkpostback||sends async queries back|
|timeout|0|.checkinputs.checktimeout||Checks the time of the timeout|
|sqlquery|0|.checkinputs.isstring||allows for sql query inputs (not supported by dataaccess)|
|firstlastsort|0|.checkinputs.checkcolumns||allows for use of firstlastsort (not supported by dataaccess)|


### Custom Api Errors

Below is a list of all the errors the API will return:
Error|Function|Library|
|-----|---------|-------------|
|Table:{tablename} doesn't exist|checktablename|dataaccess|
|Column(s) {badcol} presented in {parameter} is not a valid column for {tab}|checkcolumns|dataaccess|
| If the distinct function is used, it cannot be present with any other aggregations including more of itself|
| Aggregations dictionary contains undefined function(s)|checkaggregations|dataaccess|
| Incorrect number of input(s) entred for the following aggregations|checkaggregations|dataaccess|
| Aggregations parameter must be supplied in order to perform group by statements|
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

## Automatic Query Optimisation

The queries are automatically optimised using `.queryorder.orderquery` this function is designed to improve the performance of certain queries  by prioritising filters against the attribute columns defined in `tableproperties.csv`. It can be toggled off by setting the value of ``` `queryoptimisation``` in the input dictionary to `0b`.

# Further Development

## Debugging and Optimisation

A key focus of the API is to improve accessibility whilst maintaining a strong performance. There are cases where the accessibilty impedes the usabilty or the query speed drops below what could be developed. In these situations one should ensure the user has a query with one of the table attributes, the query only pulls in the essential data and evaluates the output of `dataaccess.buildquery` to see whether the execute query is what is expected. 

## Testing Library
Each subfunction of getdata has thorough tests found in `${KDBTESTS}/dataaccess/`. To run the tests:

1. Set environment variables
2. Ensure your TorQ stack is not running
3. Navigate to the appropriate testing directory
4. Run `. run.sh -d`  

## Implimentation with TorQ FSP

The API is compatible with the most recent TorQ Finance-Starter-Package, the fastest way to import the API is opening {APPCONFIG}/processes.csv and adding the following flag `  -dataaccess ${KDBCONFIG}/tableproperties.csv` to the rdb, hdb and gateway extras column.

## Implimentation with q-REST
 
The API is compatible with q-REST. To do this:

1. Download q-REST from https://github.com/AquaQAnalytics/q-REST
2. Open `application.properties` and point `kdb.host/port` to the gateway
3. qCon into the gateway and run `.dataaccess.enableqrest[]`
4. Use the execute function argument to send `.json`s of the form:
```
{
"function_name": ".dataaccess.qrest",
"arguments":{
"tablename":"quote",
"starttime":"2021.02.17D10:00:00.000000000",
"endtime":"2021.02.18D12:00:00.000000000",
"freeformby":"sym",
"aggregations":" `max`min!(`ask`bid;`ask)",
"filters":"`sym`bid`bsize!(enlist(like;`8APL);((<;85);(>;83.5));enlist(~:;within;5 43))"
}
}
```

q-REST doesn't present all the freedom of the API, in particular:

1. All dictionary values must be in string format
2. Nested quotion marks are not permitted
3. Running `.dataaccess.enableqrest[]` will change the output of *all* queries to the gateway not just qREST ones
4. When using the filter argument and like argument: 
  1. The second argument in a filter should be a symbol e.g (like;``` `AMD```)
  2. The following patterns `\*,?,^,[,]` should be replaced by the numberics:`8,1,6,9,0` retrospectively
  3. Like can not be used with any numberics

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

Group average ``` `mid```, by  6 hour buckets using the ``` `timebar ``` parameter

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
q) getdata`tablename`starttime`endtime`aggregations`postback!(`quote;2021.02.12D0;2021.02.12D12;((enlist `max)!enlist `ask`bid);{flip x})
maxAsk| 91.74
maxBid| 90.65

.dataaccess.buildquery `tablename`starttime`endtime`aggregations`postback!(`quote;2021.02.12D0;2021.02.12D12;((enlist `max)!enlist `ask`bid);{flip x})
? `quote ,(within;`time;2021.02.12D00:00:00.000000000 2021.02.12D12:00:00.000000000) 0b `maxAsk`maxBid!((max;`ask);(max;`bid))

```
