# Analytics Library

A set of analytical functions is provided for the simplification of common operations. This set of tools is targeted at new kdb+ developers or business users. Data visualization would be an example application of this library, as an effective visualization of data incurs various manipulations of data sets. For example, a user wishes to produce a 15 minute bucketed sample of a time series, and forward fill it, then pivot it. All of the above can be achieved with the functions defined below. 

## General Usage
These set of function are defined in the `.al` namespace. All of the functions below have an input parameter in the form of a dictionary. The specifics of each dictionary are detailed in the *usage* section of each function. 

This set of utilities also includes a general set of error traps which were designed to give informative errors specific to each function. For example if a dictionary has not been provided then the error would be:

```
q).al.pivot[123]
'Input parameter must be a dictionary with keys:
        -table
        -by
        -piv
        -var
```

These error traps and messages are to guide the user in the correct use of the utilities and are designed to be as informative as possible.

## ffill

### Usage
This script contains the utility to dynamically forward fill a given table keyed by given columns.


Input is a dictionary containing:

*  table: Table to be forward filled
*  by: List of column names to key the table (optional)
*  keycols: List of columns names to be forward filled (optional)


OR 

- Table
	

This utility is equivalent to:  `update fills col1, fills col2 ... by col2 from table`


If you have a large data set or just a table with multiple columns typing this statement out can be quite laborious.
With this utility you simply specify the table or parameter dictionary and pass it to the function.
This utility also has the added functionality of being able to forward fill mixed list columns, i.e. strings.

### Examples
#### Example 1.1
By specifying the `by` condition in the input dictionary the function can forward fill keyed by specific column, for example:

```
q)table
time         sym  ask bid asize bsize a id
------------------------------------------
00:00:38.184 AMD  121 12  3     30    a 1
00:01:25.332 AMD  121 3   3     30    b 4
00:09:37.574 AAPL 63  32  3     30    b 3
00:21:24.796 AAPL 63      12            4
00:38:39.521 AAPL 121 3   5           a 3
00:40:41.670 MSFT 63  3   4     20    c 4
00:48:08.048 MSFT 63            40      3
00:48:39.290 IBM  63  3   12    40    d 2
00:57:47.067 AAPL     24  3     30      2
01:08:00.945 AAPL 121 12  3     20    b 3

```

We can create the input dictionary in the following way to specify the by clause of the `ffill` utility:

```
q)args:(`table`by)!(table;`sym)
```
Passing this to the function we can see the result:

```
q).al.ffill args
time         sym  ask bid asize bsize a id
------------------------------------------
00:00:38.184 AMD  121 12  3     30    a 1
00:01:25.332 AMD  121 3   3     30    b 4
00:09:37.574 AAPL 63  32  3     30    b 3
00:21:24.796 AAPL 63  32  12    30    b 4
00:38:39.521 AAPL 121 3   5     30    a 3
00:40:41.670 MSFT 63  3   4     20    c 4
00:48:08.048 MSFT 63  3   4     40    c 3
00:48:39.290 IBM  63  3   12    40    d 2
00:57:47.067 AAPL 121 24  3     30    a 2
01:08:00.945 AAPL 121 12  3     20    b 3

```

#### Example 1.2

By specifying the `keycols` condition in the input dictionary the function can forward fill only specific columns, for example:

Using the data set below we can create an input specifying which column we want to forward fill:

```
q)table
time                          sym  src price size mode
------------------------------------------------------
2018.02.13D08:02:09.322000000 AAPL N   32    513  "A"
2018.02.13D08:03:23.511000000 AAPL N   32    344  ""
2018.02.13D08:06:35.424000000 AAPL N   32    1933 "B"
2018.02.13D08:13:03.067000000 AAPL N   76    1009 "B"
2018.02.13D08:15:09.130000000 AAPL O   43    5199 "B"
2018.02.13D08:22:21.528000000 AAPL N   76    427  "A"
2018.02.13D08:23:46.489000000 AAPL N         7918 "B"
2018.02.13D08:26:34.645000000 AAPL N   43    420  ""
2018.02.13D08:27:41.633000000 AAPL N         5391 "A"
2018.02.13D08:28:00.078000000 AAPL N   54    713  "A"
2018.02.13D08:28:39.200000000 AAPL N         8117 "C"
2018.02.13D08:32:21.651000000 AAPL N   43    178  "A"

q)args:(`table`keycols)!(table;`price)
q).al.ffill args
time                          sym  src price size mode
------------------------------------------------------
2018.02.13D08:02:09.322000000 AAPL N   32    513  "A"
2018.02.13D08:03:23.511000000 AAPL N   32    344  ""
2018.02.13D08:06:35.424000000 AAPL N   32    1933 "B"
2018.02.13D08:13:03.067000000 AAPL N   76    1009 "B"
2018.02.13D08:15:09.130000000 AAPL O   43    5199 "B"
2018.02.13D08:22:21.528000000 AAPL N   76    427  "A"
2018.02.13D08:23:46.489000000 AAPL N   76    7918 "B"
2018.02.13D08:26:34.645000000 AAPL N   43    420  ""
2018.02.13D08:27:41.633000000 AAPL N   43    5391 "A"
2018.02.13D08:28:00.078000000 AAPL N   54    713  "A"
2018.02.13D08:28:39.200000000 AAPL N   54    8117 "C"
2018.02.13D08:32:21.651000000 AAPL N   43    178  "A"


```
Note that without specifying the `by` condition the column was forward filled as it sits in the table.

#### Example 1.3

Passing just a table into the function will forward fill all columns, for example:

```
q)table
time         sym  ask bid asize bsize a id
------------------------------------------
00:00:38.184 AMD  121 12  3     30    a 1
00:01:25.332 AMD  121 3   3     30    b 4
00:09:37.574 AAPL 63  32  3     30    b 3
00:21:24.796 AAPL 63      12            4
00:38:39.521 AAPL 121 3   5           a 3
00:40:41.670 MSFT 63  3   4     20    c 4
00:48:08.048 MSFT 63            40      3
00:48:39.290 IBM  63  3   12    40    d 2
00:57:47.067 AAPL     24  3     30      2
01:08:00.945 AAPL 121 12  3     20    b 3

q).al.ffill table
time         sym  ask bid asize bsize a id
------------------------------------------
00:00:38.184 AMD  121 12  3     30    a 1
00:01:25.332 AMD  121 3   3     30    b 4
00:09:37.574 AAPL 63  32  3     30    b 3
00:21:24.796 AAPL 63  32  12    30    b 4
00:38:39.521 AAPL 121 3   5     30    a 3
00:40:41.670 MSFT 63  3   5     20    a 4
00:48:08.048 MSFT 63  3   4     40    c 3
00:48:39.290 IBM  63  3   12    40    c 2
00:57:47.067 AAPL 63  24  3     30    c 2
01:08:00.945 AAPL 121 12  3     20    b 3

```

## pivot
A pivot table is a design tool used to reorganize and summarize selected columns and rows of data to gain a better understanding of the data being provided. An indepth explanation of how to pivot a table is available [here](http://code.kx.com/q/cookbook/pivoting-tables/).

This is a modified version of code available on [code.kx](http://code.kx.com/q/cookbook/pivoting-tables/#a-very-general-pivot-function-and-an-example)

### Usage
This script contains the utility to pivot a table, specifying the keyed columns, the columns you wish to pivot around and the values you wish to expose. Note that this method always produces the last value for the grouping. To circumvent this you can do your own aggregation on the table before using the pivot function. For example you can create a column to calculate the sum: `update totsum:sum price by sym,src from table` and then pivot the data.

This utility takes a dictionary as input with the following parameters:

* 	table: The table you want to pivot
* 	by:	 The keyed columns
* 	piv:	 The pivot columns
* 	var:	 The variables you want to see
* 	f:	 The function to create your column names (optional)
* 	g: 	 The function to sort your column names (optional)


The optional function f is a function of var and piv which creates column names for your
pivoted table.
The optional function g is a function of the keyed columns, piv and the return of f, which
sorts the columns in ascending order.

### Examples
#### Example 1.1
We have a table of quotes:

```
q)quote
date       sym  time         side level price    size
-----------------------------------------------------
2009.01.05 bafc 09:30:00.619 B    0     88.31803 96
2009.01.05 oljg 09:30:15.770 A    2     24.72941 14
2009.01.05 mgab 09:30:30.993 B    0     33.80173 2
2009.01.05 cflm 09:30:45.457 A    4     13.08412 98
2009.01.05 jgjm 09:31:00.668 B    0     80.2705  26
2009.01.05 cnkk 09:31:15.988 A    1     23.27025 38
..
```

We can key the table by date,sym and time, pivot around both side and level showing price 
and size at each time. The input dictionary is created in the following way:

```
args:(`table`by`piv`var)!(quote;`date`sym`time;`side`level;`price`size);
```

Here we are specifying the arguments for f and g as the default functions:
```
// create _ separated column headers
f:{[v;P] `$"_" sv' string (v,()) cross P}
// return the headers in order
g:{[k;P;c] k,asc c}
```

The pivot function is then called and the output can be seen below:
```
q).al.pivot[args]
date       sym  time        | price_A_0 price_A_1 price_A_2 price_A_3 price_A_4 price_B_0 price_B_1 price_B_2  price_B_3 price_B_4 size_A_0 size_A_1 size_A_2 size_A_3 size_A_4 size_B_0 size_B_1 size_B_2 size_B_3 size_B_4
----------------------------| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
2009.01.05 bafc 09:30:00.619|                                                   88.31803                                                                                        96
2009.01.05 bafc 10:05:30.395|                                                                                            60.77025                                                                                   73
2009.01.05 bafc 10:11:00.990|                                                                       0.03195086                                                                                    71
2009.01.05 bafc 10:41:00.031|                                                             68.8886                                                                                        60
2009.01.05 bafc 10:41:15.924|                     4.926275                                                                                           56
2009.01.05 bafc 11:06:30.361|                                                             84.28182                                                                                       10
2009.01.05 bafc 11:52:30.361|                                                   8.733561                                                                                        7
..
```

#### Example 1.2
We have the following table showing some FX data:
```
q)t
sym    time  price size lp   region
-----------------------------------
EURGBP 09:00 1     870  UBS  LON
EURGBP 09:07 7     296  BARX LON
EURGBP 09:19 3     850  BARX LON
EURGBP 09:27 1     540  HSBC NYC
EURUSD 09:31 4     995  UBS  LON
AUDUSD 09:38 0     396  HSBC NYC
EURUSD 09:41 6     152  UBS  LON
EURUSD 09:42 4     317  HSBC NYC
EURGBP 09:43 6     670  HSBC LON
EURGBP 09:47 7     345  BARX NYC
..
```
We want to see the different prices each liquidity provider has for each currency pair. For this we need to pivot the table t by sym around the lp's to show the various prices. We first create out parameter dictionary:
```
args:(`table`by`piv`var)!(t;`sym;`lp;`price`size)
```
We then pass the dictionary into the pivot utility:
```
q).al.pivot[args]
sym   | price_BARX price_HSBC price_UBS
------| -------------------------------
EURGBP| 7          1          1
EURUSD| 8          4          4
AUDUSD| 4          0          0

```
Another way to manipulate the same data would be to key the table by sym and lp (i.e. currency pair and liquidity provider) and pivot by region to show both price and size. Setting up this dictionary and passing it to the pivot function we see the result below:
```
q)args:(`table`by`piv`v)!(t;`sym`lp;`region;`price`size)
q).al.pivot[args]
sym    lp  | price_LON price_NYC size_LON size_NYC
-----------| -------------------------------------
EURGBP UBS | 1         3         870      32
EURGBP BARX| 7         7         296      345
EURGBP HSBC| 6         1         670      540
EURUSD UBS | 4         1         995      494
AUDUSD HSBC| 5         0         879      396
EURUSD HSBC| 1         4         459      317
EURUSD BARX| 6         8         62       299
AUDUSD BARX| 4         2         817      716
AUDUSD UBS | 3         0         744      217

```


## intervals

The intervals.q utility in the .al namespace is used to output a
list of equally spaced intervals between given start and end points.

### Usage


Input is a dictionary containing:

*  start: Starting integer number
*  end: Ending integer number
*  interval: Interval spacing between values
*  round: Toggle rounding to nearest specified interval (optional)



Parameters should be passed in the form of a dictionary, where start
and end must be of the same type and interval can be either a long int
or of the same type as start and end (i.e if start:09:00 and end:12:00,
and intervals of 5 minutes were required interval could equal 00:05 or 5)

Allowed data types are:

*	 date 
*  month 
*  time 
*  minute 
*  second 
*  timestamp 
*  timespan 
*  integer 
*  short 
*  long


### Example

Using minute datatype:
```
q)params:`start`end`interval`round!(09:32;12:00;00:30;0b)
q).al.intervals[params]
09:32 10:02 10:32 11:02 11:32
```

or with round applied.
```
q)params:`start`end`interval`round!(09:32;12:00;00:30;1b)
q).al.intervals[params]
09:30 10:00 10:30 11:00 11:30 12:00
```
by default round is set to 1b, hence the result above can be
obtained without inputting a value for round via:
```
q)params:`start`end`interval!(09:32;12:00;00:30)
q).al.intervals[params]
09:30 10:00 10:30 11:00 11:30 12:00
```

```
q)params:`start`end`interval!(2001.04.07;2001.05.01;5)
q).al.intervals[params]
2001.04.05 2001.04.10 2001.04.15 2001.04.20 2001.04.25 2001.04.30
```
and without rounding
```
q)params:`start`end`interval`round!(2001.04.07;2001.05.01;5;0b)
q).al.intervals[params]
2001.04.07 2001.04.12 2001.04.17 2001.04.22 2001.04.27
```
```
q)params:`start`end`interval!(00:20:30 01:00:00 00:10:00)
q).al.intervals[params]
00:20:00 00:30:00 00:40:00 00:50:00 01:00:00
```
```
q)params:`start`end`interval`round!(00:20:30 01:00:00 00:10:00)
q).al.intervals[params]
00:20:30 00:30:30 00:40:30 00:50:30
```
```
q)params:`start`end`interval!(00:01:00.000000007;00:05:00.000000001;50000000000)
q).al.intervals[params]
0D00:00:50.000000000 0D00:01:40.000000000 0D00:02:30.000000000 0D00:03:20.000000000 0D00:04:10.000000000 0D00:05:00.000000000
```
## rack
The rack utility gives the user the ability to create a rack table
(the cross product of distinct values at the input).

### Usage

Input is be a dictionary containing:

*  table: Keyed or unkeyed in memory table
*  keycols:  The columns of the table you want to create the rack from.
*  base: This is an additional table, against which the rack can be created (optional)
*  timeseries.start: Start time to create a timeseries rack (optional)
*  timeseries.end: End time to create a time series rack (optional)
*  timeseries.interval: The interval for the time racking (optional)
*  timeseries.round: Should rounding be carried out when creating the timeseries (optional)
*  fullexpansion: Determines whether the required columns of input table will be expanded themselves or not. (optional, default is 0b)


	
A timeseries is optional but if it is required then start, end, and interval must be specified as a dictionary called 'timeseries' (round remains optional with a default value of 1b).
Keyed tables can be provided, these will be unkeyed by the function and crossed as standard unkeyed tables.

Full expansion in this case refers to the level to which the data is crossed with itself and the user-defined intervals. For example were full expansion disabled then the table would be crossed with the user defined intervals and then crossed with the base. If full expansion is enabled then all of the table columns are crossed with each other before being crossed with the intervals and then the base. Allowing for a more in depth and detailed representation of the data.

### Examples
#### Example 1.1

* no fullexpansion, only table and keycols specified

```
q)t
sym exch price
--------------
a   nyse 1
b   nyse 2
a   cme  3

q)k
`sym`exch

create a dictionary
q)dic:`table`keycols!(t;k)

q).al.rack[dic]
sym exch
--------
a   nyse
b   nyse
a   cme
```
(simplest case, only returns unaltered keycols)

#### Example 1.2

* timeseries,fullexpansion specified, table is a keyed table

```
q)dic
table        | (+(,`sym)!,`a`b`a)!+`exch`price!(`nyse`nyse`cme;1 2 3)
keycols      | `sym`exch
timeseries   | `start`end`interval!09:00 12:00 01:00
fullexpansion| 1b

q).al.rack[dic]
sym exch interval
-----------------
a   nyse 09:00
a   nyse 10:00
a   nyse 11:00
a   nyse 12:00
a   cme  09:00
a   cme  10:00
a   cme  11:00
a   cme  12:00
b   nyse 09:00
b   nyse 10:00
b   nyse 11:00
b   nyse 12:00
b   cme  09:00
b   cme  10:00
b   cme  11:00
b   cme  12:00
```
#### Example 1.3

* timeseries,fullexpansion specified,base specified, table is keyed

```
q)dic
table        | (+(,`sym)!,`a`b`a)!+`exch`price!(`nyse`nyse`cme;1 2 3)
keycols      | `sym`exch
timeseries   | `start`end`interval!00:00:00 02:00:00 00:30:00
base         | +(,`base)!,`buy`sell`buy`sell
fullexpansion| 1b

q).al.rack[dic]
base sym exch interval
----------------------
buy  a   nyse 00:00:00
buy  a   nyse 00:30:00
buy  a   nyse 01:00:00
buy  a   nyse 01:30:00
buy  a   nyse 02:00:00
buy  a   cme  00:00:00
buy  a   cme  00:30:00
buy  a   cme  01:00:00
buy  a   cme  01:30:00
buy  a   cme  02:00:00
buy  b   nyse 00:00:00
buy  b   nyse 00:30:00
buy  b   nyse 01:00:00
buy  b   nyse 01:30:00
buy  b   nyse 02:00:00
buy  b   cme  00:00:00
buy  b   cme  00:30:00
buy  b   cme  01:00:00
buy  b   cme  01:30:00
buy  b   cme  02:00:00
```
