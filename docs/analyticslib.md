The following documentation describes the use of the forward fills, pivot, racking, and intervals
functionality for TorQ. 
The purpose of these functions is to simplify certain common operations so as to give the user the
tools necessary to build out and tailor the system for the functionality they require.
The functions all take dictionaries containing their arguments as parameters, and these are then
checked with a central checkargs[] function to ensure the correct arguments, and types of arguments,
are supplied.  
All functions contain usage examples, as well as an explanation on the type and form of the arguments 
they accept.

## ffills[]

This script contains the utility to dynamically forward fill a given table keyed by given columns.
Input parameters:
* Dictionary containing:
	* `table - Table to be forward filled
	* `by - list of column names to key the table (optional)
	* `col - list of coummns names to be forward filled (optional)

OR 

* Table
	
This utility is equivalent to:
* update fills a, fills b .... by keycols from table


If you have a large data set or just a table with multiple columns typing this statement out can be quite laborious.
With this utility you simply specifiy the table or parameter dictionary and pass it to the function.
This utility also has the added functionality of being able to forward fill mixed list columns, i.e. strings.
 
To achieve this functionality a function to forward fill mixed list columns was required. This function can be seen here:

```
forwardfill:{$[0h=type x;x maxs (til count x)*(0<count each x);fills x]};
```

If the column is a numerical column it passes through the conditional statement and the function fills gets called. 
If the column is a mixed list then a a boolean list is created with 0's at each index in the column where the count 0 is present this is then multiplied by the indexes of each element of the column which is used as 
input to the maxs function, thereby forward filling the column. 

#### Options

By specifying the `by condition in the input dictionary the function can forward fill keyed by specific column, for example:

Using the following table:
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

We can create the input dictionary in the following way to specifiy the by clause of the `ffill` utility:

```
q)args:(`table`by)!(table;`sym)
```
Passing this to the function we can see the result:

```
q)ffill args
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


By specifying the `col condition in the input dictionary the function can forward fill only specific columns, for example:

Using the same data set as before we can create a new input specifying which column we want to forward fill:

```
q)args:(`table`col)!(table;`asize)
q)ffill args
time         sym  ask bid asize bsize a id
------------------------------------------
00:00:38.184 AMD  121 12  3     30    a 1
00:01:25.332 AMD  121 3   3     30    b 4
00:09:37.574 AAPL 63  32  3     30    b 3
00:21:24.796 AAPL 63      12            4
00:38:39.521 AAPL 121 3   5           a 3
00:40:41.670 MSFT 63  3   5     20    c 4
00:48:08.048 MSFT 63      4     40      3
00:48:39.290 IBM  63  3   12    40    d 2
00:57:47.067 AAPL     24  3     30      2
01:08:00.945 AAPL 121 12  3     20    b 3

```
Note that with specifying the `by` condition the column was forward filled as it sits in the table.

Passing just a table into the function will forward fill all columns, for example:

```
q)ffill table
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


#### Example:
We have the following table:
```
q)table
time         sym  ask bid asize bsize a id
------------------------------------------
00:00:00.000 AAPL 73  90  3     30    a 1
00:00:00.000 AMD  123 210 67    30    b 4
00:00:00.000 IBM  34  64  87    43    b 4
00:00:00.000 MSFT 100 200 43    40    c 1
00:00:38.184 AMD  121 12  3     30    a 1
00:01:25.332 AMD  121 3   3     30    b 4
00:09:37.574 AAPL 63  32  3     30    b 3
00:21:24.796 AAPL 63      12            4
00:38:39.521 AAPL 121 3   5           a 3
00:40:41.670 MSFT 63  3         20      4
00:48:08.048 MSFT 63      4     40    c 3
00:48:39.290 IBM  63  3   12    40      2
00:57:47.067 AAPL     24  3     30      2
..
```
Create the dictionary:
```
q)args:(`table`by)!(table;`sym)
q)args
table| `s#+`time`sym`ask`bid`asize`bsize`a`id!(`p#00:00:00.482 00:00:00.803 00:00..
by| `sym

```
Pass the dictionary to the function:
```
q)ffill[args]
time         sym  ask bid asize bsize a id
------------------------------------------
00:00:00.000 AAPL 73  90  3     30    a 1
00:00:00.000 AMD  123 210 67    30    b 4
00:00:00.000 IBM  34  64  87    43    b 4
00:00:00.000 MSFT 100 200 43    40    c 1
00:00:38.184 AMD  121 12  3     30    a 1
00:01:25.332 AMD  121 3   3     30    b 4
00:09:37.574 AAPL 63  32  3     30    b 3
00:21:24.796 AAPL 63  32  12    30    b 4
00:38:39.521 AAPL 121 3   5     30    a 3
00:40:41.670 MSFT 63  3   43    20    c 4
00:48:08.048 MSFT 63  3   4     40    c 3
00:48:39.290 IBM  63  3   12    40    b 2
00:57:47.067 AAPL 121 24  3     30    a 2
..
```

## pivot[]
Modified from:

http://code.kx.com/q/cookbook/pivoting-tables/#a-very-general-pivot-function-and-an-example

This script contains the utility to pivot a table, specifying the keyed columns, the columns
you wish to pivot around and the values you wish to expose. This utility takes a dictionary as
input with the following parameters:

* `table 	- the table you want to pivot
* `by	- the keyed columns
* `piv	- the pivot columns
* `var	- the variables you want to see
* `f	- the function to create your column names (optional)
* `g 	- the function to sort your column names (optional)

The optional function f is a function of var and piv which creates column names for your
pivoted table.
The optional function g is a function of the keyed columns, piv and the return of f, which
sorts the columns in ascending order.

#### Example:
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
args:(`table`by`piv`v`f`g)!(q;`date`sym`time;`side`level;`price`size);
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
q)pivot[args]
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

#### Example:
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
args:(`table`by`piv`v)!(t;`sym;`lp;`price`size)
```
We then pass the dictionary into the pivot utility:
```
q)pivot[args]
sym   | price_BARX price_HSBC price_UBS
------| -------------------------------
EURGBP| 7          1          1
EURUSD| 8          4          4
AUDUSD| 4          0          0

```
Another way to manipulate the same data would be to key the table by sym and lp (i.e. currency pair and liquidity provider) and pivot by region to show both price and size. Setting up this dictionary and passing it to the pivot function we see the result below:
```
q)args:(`table`by`piv`v)!(t;`sym`lp;`region;`price`size)
q)pivot[args]
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


## intervals[]

parameters:start,end,interval,round (optional)

The intervals.q utility in the .utils namespace is used to output a
list of equally spaced intervals between given start and end points.

#### Usage

Parameters should be passed in the form of a dictionary, where start
and end must be of the same type and interval can be either a long int
or of the same type as start and end (i.e if start:09:00 and end:12:00,
and intervals of 5 mins were required interval could equal 05:00 or 5)

Allowed data types are:
date, month, time, minute, second, timestamp, timespan, integer, short, long

#### Examples

##### Using minute datatype:
```
q)params:`start`end`interval`round!(09:32;12:00;00:30;0b)
q)intervals[params]
09:32 10:02 10:32 11:02 11:32
```

or with round applied.
```
q)params:`start`end`interval`round!(09:32;12:00;00:30;1b)
q)intervals[params]
09:30 10:00 10:30 11:00 11:30 12:00
```
by default round is set to 1b, hence the result above can be
obtained without inputting a value for round via:
```
q)params:`start`end`interval!(09:32;12:00;00:30)
q)intervals[params]
09:30 10:00 10:30 11:00 11:30 12:00
```
#### Some examples using other datatypes:
##### Date
```
q)params:`start`end`interval!(2001.04.07;2001.05.01;5)
q)intervals[params]
2001.04.05 2001.04.10 2001.04.15 2001.04.20 2001.04.25 2001.04.30
```
and without rounding
```
q)params:`start`end`interval`round!(2001.04.07;2001.05.01;5;0b)
q)intervals[params]
2001.04.07 2001.04.12 2001.04.17 2001.04.22 2001.04.27
```
##### Second
```
q)params:`start`end`interval!(00:20:30 01:00:00 00:10:00)
q)intervals[params]
00:20:00 00:30:00 00:40:00 00:50:00 01:00:00
```
and without rounding
```
q)params:`start`end`interval`round!(00:20:30 01:00:00 00:10:00)
q)intervals[params]
00:20:30 00:30:30 00:40:30 00:50:30
```
##### timespan
```
q)params:`start`end`interval!(00:01:00.000000007;00:05:00.000000001;50000000000)
q)interval[params]
0D00:00:50.000000000 0D00:01:40.000000000 0D00:02:30.000000000 0D00:03:20.000000000 0D00:04:10.000000000 0D00:05:00.000000000
```
## rack[]
The rack utility gives the user the ability to create a rack table
(the cross product of distinct values at the input).

#### Input parameters:
* table (required) - keyed or unkeyed in-memory table
* keycols (required) - the columns of the table you want to create the rack from.
* base (optional) - this is an additional table, against which the rack can be created
* intervals.start (optional) - start time to create a timeseries rack
* intervals.end (optional) - end time to create a time series rack
* intervals.interval (optional) - the interval for the time racking
* intervals.round (optional) - should rounding be carried out when creating the timeseries
* fullexpansion (optional, default is 0b) - determines whether the required columns of input table will be expanded themselves or not.
#### Usage
- All the above arguments must be provided in dictionary form.
- A timeseries is optional but if it is required then start, end, and interval must be specified (round remains optional with a default value of 1b).
- Keyed tables can be provided, these will be unkeyed by the function and crossed as standard unkeyed tables.


Should full expansion be required the function we use is:
```
racktable:args[`base] cross (((0#args[`keycols]#args[`table]) upsert distinct (cross/)value flip args[`keycols]#args[`table]) cross timeseries);
```
Essentially the keycolumns are separated from the table and a cross-over is used on their values, this operation means
seperating the values from the table headers so as a final step the distinct crossed values are upserted into an empty table made up of the key column names of the original table. The result is then crossed against a base and timeseries. If these aren't provided explicitly by the user they are simple null lists which have no effect on the output.

If full expansion isn't required the process is similar to the above but there's no expansion carried out on the initial table columns.
```
     racktable:args[`base] cross ((args[`keycols]#args[`table]) cross timeseries)]
```

#### Examples
- no fullexpansion, only table and keycols specified
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

q)rack[dic]
sym exch
--------
a   nyse
b   nyse
a   cme
```
(simplest case, only returns unaltered keycols)


- timeseries,fullexpansion specified, table is a keyed table
```
q)dic
table        | (+(,`sym)!,`a`b`a)!+`exch`price!(`nyse`nyse`cme;1 2 3)
keycols      | `sym`exch
timeseries   | `start`end`interval!09:00 12:00 01:00
fullexpansion| 1b

q)rack[dic]
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

- timeseries,fullexpansion specified,base specified, table is keyed
```
q)dic
table        | (+(,`sym)!,`a`b`a)!+`exch`price!(`nyse`nyse`cme;1 2 3)
keycols      | `sym`exch
timeseries   | `start`end`interval!00:00:00 02:00:00 00:30:00
base         | +(,`base)!,`buy`sell`buy`sell
fullexpansion| 1b

q)rack[dic]
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