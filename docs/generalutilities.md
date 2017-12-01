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


#### Example Unkeyed Table:
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
q)args:(`t`k)!(table;`sym)
q)args
t| `s#+`time`sym`ask`bid`asize`bsize`a`id!(`p#00:00:00.482 00:00:00.803 00:00..
k| `sym

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

#### Example Keyed Table:
We have the following table:
```
q)ktable
time        | sym  ask bid asize bsize a
------------| --------------------------
00:00:00.000| AAPL 73  90  3     30    a
00:00:00.000| MSFT 100 200 43    40    c
00:00:00.000| AMD  123 210 67    30    b
00:00:00.000| IBM  34  64  87    43    b
00:00:22.178| IBM  4   65        30
00:01:20.951| AAPL 35  130 3           a
00:06:06.973| MSFT 93  144 3     20
00:08:15.333| AAPL 98  167 3     20
00:08:23.291| IBM  69  84  12    30    b
00:10:27.142| IBM  92  85              c
..
```
Create the dictionary:
```
q)dict:(`t`k)!(ktable;`sym)
```
Pass the dictionary to the function:
```
q)ffill[dict]
time        | sym  ask bid asize bsize a
------------| --------------------------
00:00:00.000| AAPL 73  90  3     30    a
00:00:00.000| MSFT 100 200 43    40    c
00:00:00.000| AMD  123 210 67    30    b
00:00:00.000| IBM  34  64  87    43    b
00:00:22.178| IBM  4   65  87    30    b
00:01:20.951| AAPL 35  130 3     30    a
00:06:06.973| MSFT 93  144 3     20    c
00:08:15.333| AAPL 98  167 3     20    a
00:08:23.291| IBM  69  84  12    30    b
00:10:27.142| IBM  92  85  12    30    c
..
```

#### Example Mixed List:
Creating a dictionary:
```
q)margs:(`table`by)!(mtable;`sym)
```
Viewing the table where sym=`MSFT
```
q)select from mtable where sym=`MSFT
time         sym  price size mode logs env
------------------------------------------
00:08:15.126 MSFT 5     40   "B"  "AA" "I"
00:08:21.954 MSFT 5     20   ""   "AA" "I"
00:18:04.172 MSFT 2     40   "B"  "AA" "J"
00:37:26.653 MSFT 5     40   "B"  "GG" "H"
00:39:09.922 MSFT 5     20   ""   "FF" "J"
00:40:54.256 MSFT       30   ""   "GG" "J"
00:43:35.434 MSFT 5          ""   "GG" ""
00:44:03.381 MSFT 2     20   "B"  "GG" ""
00:45:26.982 MSFT 2     20   ""   "AA" "I"
01:06:32.281 MSFT 5          "B"  "AA" "H"
01:08:17.819 MSFT       40   ""   "AA" "J"
01:15:46.842 MSFT       20   ""   "GG" "J"
..
```
Passing the dictionary into the function and then into the same statement:
```
q)select from ffill[margs] where sym=`MSFT
time         sym  price size mode logs env
------------------------------------------
00:08:15.126 MSFT 5     40   B    "AA" "I"
00:08:21.954 MSFT 5     20   B    "AA" "I"
00:18:04.172 MSFT 2     40   B    "AA" "J"
00:37:26.653 MSFT 5     40   B    "GG" "H"
00:39:09.922 MSFT 5     20   B    "FF" "J"
00:40:54.256 MSFT 5     30   B    "GG" "J"
00:43:35.434 MSFT 5     30   B    "GG" "J"
00:44:03.381 MSFT 2     20   B    "GG" "J"
00:45:26.982 MSFT 2     20   B    "AA" "I"
01:06:32.281 MSFT 5     20   B    "AA" "H"
01:08:17.819 MSFT 5     40   B    "AA" "J"
01:15:46.842 MSFT 5     20   B    "GG" "J"
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

Here we are specificying the arguments for f and g as the default functions:
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

