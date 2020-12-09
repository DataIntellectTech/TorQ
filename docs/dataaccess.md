# Dataaccess API

A generic 'getdata' function for quering KDB+ data.

### Configuration

To use the *getdata* function on a TorQ process there are 2 options:
1) Pass "-dataaccess /path/to/tableproperties.csv" on the command line (see Example configuration trade/quote below for format)
2) Run ".dataaccessinit[`:/path/to/tableproperties.csv]" to initialise the code in a running process.

In both cases the filepath should point to a configuration file containing information about the tables you want to access via the *getdata* function.


**Example configuration file** - with 'trade' and 'quote' tables

|proctype   |tablename                     |primarytimecolumn     |attributecolumn                                                                 |instrumentcolumn|timezone|getrollover     |getpartitionrange     |
|--------------|-----------|------------------------------|----------------------|--------------------------------------------------------------------------------|----------------|--------|----------------|----------------------|
|hdb      |trade                        |time                  |sym                                                                             |sym             |UTC     |defaultrollover|defaultpartitionrange|
|rdb      |quote                        |time                  |sym                                                                             |sym             |UTC     |defaultrollover|defaultpartitionrange|


**Description of fields in csv**

|field      |description                                                          |
|-----------|---------------------------------------------------------------------|
|proctype    |denotes the type of process  i.e. rdb or hdb|
|tablename  |table to query - assumed unique across given proctype      |
|primarytimecolumn  |default time column from the tickerplant - used if no  `timecolumn parameter is passed      |
|attributecolumn    |primary attribute column - used in ordering of queries      |
|instrumentcolumn   |column containing instrument      |
|timezone   |timezone of interest (NYI)      |
|getrollover   |custom function to determine hdb/rdb rollover (see below)      |
|getpartitionrange   |custom function to determine partition range for the hdb (see below)      |


Examples of custom functions:

```q
//- return start of current day (UTC)
defaultrollover:{[].z.d+0D};

//- cast time range - to partition range
//- if timecolumn != primarytimecolum - look forward one partition to account for descrepancy between "date" & "`date$timecolumn"
defaultpartitionrange:{[timecolumn;primarytimecolumn;partitionfield;hdbtimerange]
    @[partitionfield$hdbtimerange;1;+;not timecolumn~primarytimecolumn]
 };
```



### Usage

**Valid Inputs**

|parameter     |required|checkfunction                 |invalidpairs          |description                                                                     |
|--------------|--------|------------------------------|----------------------|--------------------------------------------------------------------------------|
|tablename     |1       |.checkinputs.isvalidtable     |                      |table to query                                                                  |
|starttime     |1       |.checkinputs.checktimetype    |                      |startime - must be a valid time type (see timecolumn)                                                       |
|endtime       |1       |.checkinputs.checktimetype    |                      |endime - must be a valid time type (see timecolumn)                                                         |
|timecolumn    |0       |.checkinputs.checktimecolumn  |                      |column to apply (startime;endime) filter to                                     |
|instruments   |0       |.checkinputs.allsymbols       |                      |instruments to filter on - will usually have an attribute applied (see tableproperties.csv)                               |
|columns       |0       |.checkinputs.checkcolumnsexist|aggregations          |table columns to return - symbol list - assumed all if not present                            |
|grouping      |0       |.checkinputs.checkcolumnsexist|                      |columns to group by -  no grouping assumed if not present                       |
|aggregations  |0       |.checkinputs.checkaggregations|columns&#124;freeformcolumn|dictionary of aggregations - e.g ``` `last`max`wavg!(`time;`bidprice`askprice;(`asksize`askprice;`bidsize`bidprice))```|
|timebar       |0       |.checkinputs.checktimebar     |                      |list of (time grouping column; bar size; time type) valid types: \`nanosecond\`second\`minute\`hour\`day)|
|filters       |0       |.checkinputs.checkfilterformat|                      |a parse tree of ordered filters to apply                             |
|freeformwhere |0       |.checkinputs.isstring         |                      |where clause in string format                                                   |
|freeformby    |0       |.checkinputs.isstring         |                      |by clause in string format                                                      |
|freeformcolumn|0       |.checkinputs.isstring         |aggregations          |select clause in string format                         |



**Example function call**

```
q)getdata`tablename`starttime`endtime`instruments`columns!(`quote;2000.01.01D00:00;2000.01.06D10:00;`GOOG;`sym`time`bidprice`bidsize`askprice`asksize)
sym    time                          bidprice bidsize askprice asksize
----------------------------------------------------------------------
GOOG   2000.01.01D00:00:00.000000000 97.2     959.4   118.8    1172.6
GOOG   2000.01.01D02:24:00.000000000 90.9     932.4   111.1    1139.6
GOOG   2000.01.01D04:48:00.000000000 98.1     933.3   119.9    1140.7
GOOG   2000.01.01D07:12:00.000000000 94.5     939.6   115.5    1148.4
GOOG   2000.01.01D09:36:00.000000000 93.6     925.2   114.4    1130.8
...
```


**Description of fields in checkinputs.csv**

|field      |description                                                          |
|-----------|---------------------------------------------------------------------|
|parameter    |dictionary key to pass to getdata    |
|required   |whether this parameter is mandatory      |
|checkfunction   |function to determine whether the given value is valid      |
|invalid pairs   |whether a parameter is invalid in combination with some other parameter      |

### Further examples

**time default**

If the time column isn't specified it defaults to the value of ``` `primaryattributecolumn ```

```
getdata`tablename`starttime`endtime!(`xdaily;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000)
sym    time                          sourcetime                    bidprice bidsize askprice asksize
----------------------------------------------------------------------------------------------------
AAPL   2000.01.01D00:00:00.000000000 2000.01.01D00:00:00.000000000 97.2     959.4   118.8    1172.6
AAPL   2000.01.01D02:24:00.000000000 2000.01.01D02:24:00.000000000 90.9     932.4   111.1    1139.6
AAPL   2000.01.01D04:48:00.000000000 2000.01.01D04:48:00.000000000 98.1     933.3   119.9    1140.7
GOOG   2000.01.01D00:48:00.000000000 2000.01.01D01:36:00.000000000 93.6     1008    114.4    1232
GOOG   2000.01.01D03:12:00.000000000 2000.01.01D04:00:00.000000000 101.7    1078.2  124.3    1317.8
GOOG   2000.01.01D10:24:00.000000000 2000.01.01D11:12:00.000000000 96.3     940.5   117.7    1149.5
...
```








**Intsrument Filter**

Use the ``` `instruments ``` parameter to filter for ``` sym=`AAPL ```

```
getdata`tablename`starttime`endtime`instruments!(`xdaily;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000;`AAPL)
sym    time                          sourcetime                    bidprice bidsize askprice asksize
----------------------------------------------------------------------------------------------------
AAPL   2000.01.01D00:00:00.000000000 2000.01.01D00:00:00.000000000 97.2     959.4   118.8    1172.6
AAPL   2000.01.01D02:24:00.000000000 2000.01.01D02:24:00.000000000 90.9     932.4   111.1    1139.6
AAPL   2000.01.01D04:48:00.000000000 2000.01.01D04:48:00.000000000 98.1     933.3   119.9    1140.7
AAPL   2000.01.01D07:12:00.000000000 2000.01.01D07:12:00.000000000 94.5     939.6   115.5    1148.4
...
```





**Columns**

Use the ``` `columns ``` parameter to extract the following columns - ``` `sym`time`sourcetime`bidprice`askprice ```

```
getdata`tablename`starttime`endtime`columns!(`xdaily;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000;`sym`time`sourcetime`bidprice`askprice)
sym    time                          sourcetime                    bidprice askprice
------------------------------------------------------------------------------------
AAPL   2000.01.01D00:00:00.000000000 2000.01.01D00:00:00.000000000 97.2     118.8
AAPL   2000.01.01D02:24:00.000000000 2000.01.01D02:24:00.000000000 90.9     111.1
AAPL   2000.01.01D21:35:59.999999999 2000.01.01D21:35:59.999999999 94.5     115.5
GOOG   2000.01.01D00:48:00.000000000 2000.01.01D01:36:00.000000000 93.6     114.4
GOOG   2000.01.01D03:12:00.000000000 2000.01.01D04:00:00.000000000 101.7    124.3
GOOG   2000.01.01D05:36:00.000000000 2000.01.01D06:24:00.000000000 98.1     119.9
...
```




**Free form select**

Run a free form select using the ``` `freeformcolumn ``` parameter

```
getdata`tablename`starttime`endtime`freeformcolumn!(`xdaily;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000;"sym,time,mid:0.5*bidprice+askprice")
sym    time                          mid
----------------------------------------
AAPL   2000.01.01D00:00:00.000000000 108
AAPL   2000.01.01D02:24:00.000000000 101
AAPL   2000.01.01D21:35:59.999999999 105
GOOG   2000.01.01D00:48:00.000000000 104
GOOG   2000.01.01D15:11:59.999999999 117
GOOG   2000.01.01D17:35:59.999999999 114

...
```
This can be used in conjunction with the `columns` parameter, however the `columns` parameters will be returned first. It is advised to use the `columns` parameter for returning existing columns and the `freeformcolumn` for any derived columns.




**Grouping**

Use ``` `grouping ``` parameter to group average ``` `mid```, by ``` `sym ```

```
getdata`tablename`starttime`endtime`freeformcolumn`grouping!(`xdaily;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000;"avgmid:avg 0.5*bidprice+askprice";`sym)
sym   | avgmid
------| ------
AAPL  | 105.4
GOOG  | 107
USDCHF| 115.5
```





**String style grouping**

Group average ``` `mid```, by ``` `sym/`source ``` using the ``` `freeformby ``` parameter

```
getdata`tablename`starttime`endtime`freeformcolumn`freeformby!(`xdaily;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000;"avgmid:avg 0.5*bidprice+askprice";"sym:sym,source:source")
sym    source | avgmid
--------------| ------
AAPL   source0| 105.4
GOOG   source1| 107
USDCHF source2| 115.5
```





**Time bucket**

Group average ``` `mid```, by ``` `sym/`source ```  + 6 hour buckets using the ``` `timebar ``` parameter

```
getdata`tablename`starttime`endtime`freeformcolumn`freeformby`timebar!(`xdaily;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000;"avgmid:avg 0.5*bidprice+askprice";"sym:sym,source:source";(`time;6;`hour))
sym    time                          source | avgmid
--------------------------------------------| --------
AAPL   2000.01.01D00:00:00.000000000 source0| 106
AAPL   2000.01.01D06:00:00.000000000 source0| 104.5
AAPL   2000.01.01D12:00:00.000000000 source0| 104.3333
AAPL   2000.01.01D18:00:00.000000000 source0| 106.5
AAPL   2000.01.02D00:00:00.000000000 source0| 105.3333
...
```




**Aggregations**

aggregate by ``` `sym```/6 hour buckets - for each calculate
- min/max of both ``` `bidprice ``` and ``` `askprice ```
- wavg of ``` `bidsize`bidprice ``` / ``` `asksize`askprice ```

```
getdata`tablename`starttime`endtime`aggregations`grouping`timebar!(`xdaily;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000;`min`max`wavg!(`bidprice`askprice;`bidprice`askprice;(`bidsize`bidprice;`asksize`askprice));`sym;(`time;6;`hour))
sym    time                         | minBidprice minAskprice maxBidprice maxAskprice wavgBidsizeBidprice wavgAsksizeAskprice
------------------------------------| ---------------------------------------------------------------------------------------
AAPL   2000.01.01D00:00:00.000000000| 90.9        111.1       98.1        119.9       95.41806            116.6221
AAPL   2000.01.01D06:00:00.000000000| 93.6        114.4       94.5        115.5       94.05347            114.9542
AAPL   2000.01.01D12:00:00.000000000| 90.9        111.1       95.4        116.6       93.89125            114.756
AAPL   2000.01.01D18:00:00.000000000| 94.5        115.5       97.2        118.8       95.8601             117.1623
AAPL   2000.01.02D00:00:00.000000000| 91.8        112.2       98.1        119.9       94.80504            115.8728
...
```



**Filters**

Use the ``` `filters ``` parameter to execute a functional select style where clause

```
getdata`tablename`starttime`endtime`filters!(`xdaily;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000;enlist(=;`source;1#`source1))
date       sym    source  id    time                          sourcetime                    bidprice bidsize askprice asksize
-----------------------------------------------------------------------------------------------------------------------------
2000.01.01 GOOG   source1 "x10" 2000.01.01D00:48:00.000000000 2000.01.01D01:36:00.000000000 93.6     1008    114.4    1232
2000.01.01 GOOG   source1 "x11" 2000.01.01D03:12:00.000000000 2000.01.01D04:00:00.000000000 101.7    1078.2  124.3    1317.8
2000.01.01 GOOG   source1 "x12" 2000.01.01D05:36:00.000000000 2000.01.01D06:24:00.000000000 98.1     932.4   119.9    1139.6
2000.01.01 GOOG   source1 "x13" 2000.01.01D08:00:00.000000000 2000.01.01D08:48:00.000000000 91.8     910.8   112.2    1113.2
2000.01.01 GOOG   source1 "x14" 2000.01.01D10:24:00.000000000 2000.01.01D11:12:00.000000000 96.3     940.5   117.7    1149.5
2000.01.01 GOOG   source1 "x15" 2000.01.01D12:47:59.999999999 2000.01.01D13:35:59.999999999 90       974.7   110      1191.3

...
```



**Free form Filters**

Use the ``` `freefromby ``` parameter to execute the same filter as above

```
getdata`tablename`starttime`endtime`freeformwhere!(`xdaily;2000.01.01D00:00:00.000000000;2000.01.06D10:00:00.000000000;"source=`source1")
date       sym    source  id    time                          sourcetime                    bidprice bidsize askprice asksize
-----------------------------------------------------------------------------------------------------------------------------
2000.01.01 GOOG   source1 "x10" 2000.01.01D00:48:00.000000000 2000.01.01D01:36:00.000000000 93.6     1008    114.4    1232
2000.01.01 GOOG   source1 "x11" 2000.01.01D03:12:00.000000000 2000.01.01D04:00:00.000000000 101.7    1078.2  124.3    1317.8
2000.01.01 GOOG   source1 "x12" 2000.01.01D05:36:00.000000000 2000.01.01D06:24:00.000000000 98.1     932.4   119.9    1139.6
2000.01.01 GOOG   source1 "x13" 2000.01.01D08:00:00.000000000 2000.01.01D08:48:00.000000000 91.8     910.8   112.2    1113.2
2000.01.01 GOOG   source1 "x14" 2000.01.01D10:24:00.000000000 2000.01.01D11:12:00.000000000 96.3     940.5   117.7    1149.5
2000.01.01 GOOG   source1 "x15" 2000.01.01D12:47:59.999999999 2000.01.01D13:35:59.999999999 90       974.7   110      1191.3
...
```
