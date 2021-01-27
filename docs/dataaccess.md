p

  
# Dataaccess API

The api allows for a user to send identical queries to multiple process types (not just an RDB/HDB), without adapting the query to accommodate to each processes’ semantics. The api strikes a balance of accessibility, whilst not constricting developers or giving unexpected outputs. It is designed to work with other non-KDB+ native applications such as BigQuery.

### Configuration

The *getdata* function will be available in rdb and hdb process types if the table properties config file path has been passed via the 
'dataaccess' flag on the startup line for the process. For other process types it can be initialized as below:

1) Pass "-dataaccess /path/to/tableproperties.csv" on the startup line (see Example configuration file below for format)
2) Run ".dataaccess.init[`:/path/to/tableproperties.csv]" to initialise the code in a running process.

In both cases the filepath should point to a configuration file containing information about the tables you want to access via the *getdata* function.


**Example configuration file** - with 'trade' and 'quote' tables

|proctype   |tablename  |primarytimecolumn     |attributecolumn       |instrumentcolumn|timezone|getrollover     |getpartitionrange   |
|-----------|-----------|----------------------|----------------------|----------------|--------|----------------|--------------------|
|rdb|trade|time|sym|sym||defaultrollover|defaultpartitionrange|
|hdb|trade|time|sym|sym||defaultrollover|defaultpartitionrange|
|rdb|quote|time|sym|sym||defaultrollover|defaultpartitionrange|
|hdb|quote|time|sym|sym||defaultrollover|defaultpartitionrange|



**Description of fields in csv**

|Field               |Description                                                                                        |
|--------------------|---------------------------------------------------------------------------------------------------|
|proctype            |denotes the type of process  i.e. rdb or hdb                                                       |
|tablename           |table to query - assumed unique across given proctype                                              |
|primarytimecolumn   |default time column from the tickerplant - used if no  \`timecolumn parameter is passed            |
|attributecolumn     |primary attribute column - used in ordering of queries                                             |
|instrumentcolumn    |column containing instrument                                                                       |
|timezone            |timezone of the timestamps on the data (NYI)                                                       |
|getrollover         |custom function to determine last rdb rollover from a timestamp                                    |
|getpartitionrange   |custom function to determine the partition range which should be used when querying hdb (see below)|


Examples of custom functions:

```
rollover:00:00;

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


```



### Usage

**Valid Inputs**

|parameter     |required|example                                                                                   |invalidpairs\*               |description                                                                     |
|--------------|--------|------------------------------------------------------------------------------------------|-----------------------------|--------------------------------------------------------------------------------|
|tablename     |1       |\`quote                                                                                   |                             |table to query                                                                  |
|starttime     |1       |2020.12.18D12:00                                                                          |                             |startime - must be a valid time type (see timecolumn)                           |
|endtime       |1       |2020.12.20D12:00                                                                          |                             |endime - must be a valid time type (see timecolumn)                             |
|timecolumn    |0       |\`time                                                                                    |                             |column to apply (startime;endime) filter to                                     |
|instruments   |0       |\`AAPL\`GOOG                                                                              |                             |instruments to filter on - will usually have an attribute applied (see tableproperties.csv)|
|columns       |0       |\`sym\`bid\`ask\`bsize\`asize                                                             |aggregations                 |table columns to return - symbol list - assumed all if not present              |
|grouping      |0       |\`sym                                                                                     |                             |columns to group by -  no grouping assumed if not present                       |
|aggregations  |0       |\`last\`max\`wavg!(\`time;\`bidprice\`askprice;(\`asksize\`askprice;\`bidsize\`bidprice)) |columns&#124;freeformcolumn  |dictionary of aggregations                                                      |
|timebar       |0       |(\`time;10;\`minute)                                                                      |                             |list of (time grouping column; bar size; time type) valid types: \`nanosecond\`second\`minute\`hour\`day)|
|filters       |0       |\`sym\`bid\`bsize!(enlist(like;"AAPL");((<;85);(>;83.5));enlist(not;within;5 43))         |                             |a dictionary of ordered filters to apply to keys of dictionary                  |
|freeformwhere |0       |"sym=\`AAPL, src=\`BARX, price within 60 85"                                              |                             |where clause in string format                                                   |
|freeformby    |0       |"sym:sym, source:src"                                                                     |                             |by clause in string format
|freeformcolumn|0       |"time, sym,mid\:0.5\*bid+ask"                                                             |aggregations                 |select clause in string format 
|ordering      |0       |enlist(\`desc\`bidprice)                                                                  |                             |list ordering results ascending or descending by column
|renamecolumn  |0       | \`old1\`old2\`old3!\`new1\`new2\`new3                                                    |                             | Either a dictionary of old!new or list of column names

\* Invalid pairs are two dictionary keys not allowed to be defined simultaneously.


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
**Table of avaliable Aggregations**

|Aggregation|Full Name    |Description                                          |Example                                          |
|-----------|-------------|-----------------------------------------------------|-------------------------------------------------|
|`avg`      |Mean         |Return the mean of a list                            |```enlist(`avg)!enlist(`price)```                |
|`cor`      |Correlation  |Return Pearson's Correlation coefficient of two lists|```(enlist `cor)!enlist(enlist(`bid`ask))```     |
|`count`    |Count        |Return The length of a list                          |```enlist(`count)!enlist(`price)```              |
|`cov`      |Covariance   |Return the covariance of a list pair                 |```(enlist `cov)!enlist(enlist(`bid`ask))```     |
|`dev`      |Deviation    |Return the standard deviation of a list              |```enlist(`dev)!enlist(`price)```                |
|`distinct` |Distinct     |Return distinct elements of a list                   |```enlist(`distinct)!enlist(`sym)```             |
|`first`    |First        |Return first element of a list                       |```enlist(`first)!enlist(`price)```              |
|`last`     |Last         |Return the final value in a list                     |```enlist(`last)!enlist(`price)```               |
|`max`      |Maximum      |Return the maximum value of a list                   |```enlist(`max)!enlist(`price)```                |
|`med`      |Median       |Return the median value of a list                    |```enlist(`med)!enlist(`price)```                |
|`min`      |Minimum      |Return the minimum value of a list                   |```enlist(`min)!enlist(`price)```                |
|`prd`      |Product      |Return the product of a list                         |```enlist(`prd)!enlist(`price)```                |
|`sum`      |Sum          |Return the total of a list                           |```enlist(`sum)!enlist(`price)```                |
|`var`      |Variance     |Return the Variance of a list                        |```enlist(`var)!enlist(`price)```                |
|`wavg`     |Weighted Mean|Return the weighted mean of two lists                |```((enlist(`wavg))!enlist(enlist(`asize`ask))```|
|`wsum`     |Weighted Sum |Return the weighted sum of two lists                 |```((enlist(`wavg))!enlist(enlist(`asize`ask))```|

### Checkinputs

**Description of fields in checkinputs.csv**

|Field        |Description                                                            |
|-------------|-----------------------------------------------------------------------|
|parameter    |Dictionary key to pass to getdata                                      |
|required     |Whether this parameter is mandatory                                    |
|checkfunction|Function to determine whether the given value is valid                 |
|invalid pairs|Whether a parameter is invalid in combination with some other parameter|

**Custom Api Errors**

One of the goals of the API is to catch errors and return more insightful error messages. Below is a list of all the errors the API will return:

- Table:{tablename} doesn't exist
- Column(s) {badcol} presented in {parameter} is not a valid column for {tab}
- If the distinct function is used, it cannot be present with any other aggregations including more of itself
- Aggregations dictionary contains undefined function(s)
- Incorrect number of input(s) entred for the following aggregations
- Aggregations parameter must be supplied in order to perform group by statements
- In order to use a grouping parameter, only aggregations that return single values may be used
- The inputted size of the timebar argument: {size}, is not an appropriate size. Appropriate sizes are:
- Timebar parameter's intervals are too small. Time-bucket intervals must be greater than (or equal to) one nanosecond
- Length of renamecolumns is too long
- Dictionary keys need to be old column names


**Developer's Footnote**

The api is designed improve accessibility whilst maintaining a fast query speed. There are cases where the accessibilty impedes the usabilty or the query speed drops below what could be developed. In these situations one should ensure the user has a query with one of the table attributes, the query only pulls in the essential data and evaluates the output of `dataaccess.buildquery` to see whether the execute query is what is expected.  

### Further examples


**time default**

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
```


**Columns**

Use the ``` `columns ``` parameter to extract the following columns - ``` `sym`time`sourcetime`bidprice`askprice ```

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

```





**Time bucket**

Group average ``` `mid```, by ``` `sym/`source ```  + 6 hour buckets using the ``` `timebar ``` parameter

```
getdata(`tablename`starttime`endtime`aggregations`instruments`timebar)!(`quote;2021.01.21D1;2021.01.28D23;(enlist(`max))!enlist(enlist(`ask));`AAPL;(6;`hour;`time))
time                         | maxAsk
-----------------------------| ------
2021.01.21D12:00:00.000000000| 98.99
2021.01.21D18:00:00.000000000| 73.28
2021.01.22D12:00:00.000000000| 97.16
2021.01.22D18:00:00.000000000| 92.58
...
```




**Aggregations**

aggregate by ``` `sym```/6 hour buckets - for each calculate
- min/max of both ``` `bidprice ``` and ``` `askprice ```
- wavg of ``` `bidsize`bidprice ``` / ``` `asksize`askprice ```

```
getdata`tablename`starttime`endtime`aggregations!(`quote;2021.01.20D0;2021.01.23D0;((enlist `max)!enlist `ask`bid))
maxAsk maxBid
-------------
109.5  108.6

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
```
**Ordering**

Use the ``` `ordering ``` parameter to sort results by column ascending or descending

```
getdata`tablename`starttime`endtime`ordering!(`quote;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000;enlist(`asc`askprice))
sym    time                          sourcetime                    bidprice bidsize askprice asksize
----------------------------------------------------------------------------------------------------
AAPL   2000.01.01D02:24:00.000000000 2000.01.01D02:24:00.000000000 90.9     932.4   111.1    1139.6
AAPL   2000.01.01D04:48:00.000000000 2000.01.01D04:48:00.000000000 98.1     933.3   119.9    1140.7
GOOG   2000.01.01D10:24:00.000000000 2000.01.01D11:12:00.000000000 96.3     940.5   117.7    1149.5
AAPL   2000.01.01D00:00:00.000000000 2000.01.01D00:00:00.000000000 97.2     959.4   118.8    1172.6
GOOG   2000.01.01D00:48:00.000000000 2000.01.01D01:36:00.000000000 93.6     1008    114.4    1232
GOOG   2000.01.01D03:12:00.000000000 2000.01.01D04:00:00.000000000 101.7    1078.2  124.3    1317.8
...
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
