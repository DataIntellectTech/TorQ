# Dataaccess API

A generic 'getdata' function for quering KDB+ data.

### Configuration

To use the getdata function on a TorQ process there are 2 options:
1) Pass "-dataaccess /path/to/tableproperties.csv" on the command line (see Example configuration trade/quote below for format)
2) Run "init[`:/path/to/tableproperties.csv]" to initialise the code in a running process.


**Example configuration - 'trade' and 'quote' table**

|proctypehdb   |proctyperdb|tablename                     |primarytimecolumn     |attributecolumn                                                                 |instrumentcolumn|timezone|getrollover     |getpartitionrange     |
|--------------|-----------|------------------------------|----------------------|--------------------------------------------------------------------------------|----------------|--------|----------------|----------------------|
|fxhdb      |fxrdb   |trade                        |time                  |sym                                                                             |sym             |UTC     |defaultrollover|defaultpartitionrange|
|fxhdb      |fxrdb   |quote                        |time                  |sym                                                                             |sym             |UTC     |defaultrollover|defaultpartitionrange|


**Description of fields in csv**

|field      |description                                                          |
|-----------|---------------------------------------------------------------------|
|proctypehdb    |hdb process of proctype `fxhdb (add to .servers.CONNECTIONS)|
|proctyperdb    |rdb process of proctype `fxrdb (add to .servers.CONNECTIONS)|
|tablename  |table to query (assumed unique across dbs)      |
|primarytimecolumn  |time column from the tickerplant (use this if no  `timecolumn parameter is passed)      |
|attributecolumn    |primary attribute column      |
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


### 
**Valid Inputs**

|parameter     |required|checkfunction                 |invalidpairs          |description                                                                     |
|--------------|--------|------------------------------|----------------------|--------------------------------------------------------------------------------|
|tablename     |1       |.checkinputs.isvalidtable     |                      |table to query                                                                  |
|starttime     |1       |.checkinputs.checktimetype    |                      |startime - see timecolumn                                                       |
|endtime       |1       |.checkinputs.checktimetype    |                      |endime - see timecolumn                                                         |
|timecolumn    |0       |.checkinputs.checktimecolumn  |                      |column to apply (startime;endime) filter to                                     |
|instruments   |0       |.checkinputs.allsymbols       |                      |instruments of interest - see tableproperties.csv                               |
|columns       |0       |.checkinputs.checkcolumnsexist|aggregations          |table columns to return - assumed all if not present                            |
|grouping      |0       |.checkinputs.checkcolumnsexist|                      |columns to group by -  no grouping assumed if not present                       |
|aggregations  |0       |.checkinputs.checkaggregations|columns&#124;freeformcolumn|dictionary of aggregations - e.g `last`max`wavg!(`time;`bidprice`askprice;(`asksize`askprice;`bidsize`bidprice))|
|timebar       |0       |.checkinputs.checktimebar     |                      |list of (time column to group on;size;type - `nanosecond`second`minute`hour`day)|
|filters       |0       |.checkinputs.checkfilterformat|                      |a dictionary of columns + conditions in string format                           |
|freeformwhere |0       |.checkinputs.isstring         |                      |where clause in string format                                                   |
|freeformby    |0       |.checkinputs.isstring         |                      |by clause in string format                                                      |
|freeformcolumn|0       |.checkinputs.isstring         |aggregations          |select clause in string format                         |


**Description of fields in csv**

|field      |description                                                          |
|-----------|---------------------------------------------------------------------|
|parameter    |dictionary key to pass to getdata    |
|required   |whether this parameter is mandatory      |
|checkfunction   |function to determine whether the given value is valid      |
|invalid pairs   |whether a parameter is invalid in combination with some other parameter      |

