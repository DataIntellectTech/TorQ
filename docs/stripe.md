# Data striping

Data striping is the technique of logically segmenting data between processes so that they are stored on different processes.

The advantages of striping include performance and throughput improvements. Segmenting data on separate processes reduces latency when processing data. Total data throughput is increased as multiple processes can be accessed concurrently. In addition, the memory footprint per process is lower and processes can be split across multiple hosts. It is useful for load balancing across processes.

The reduction in data access in each process cumulatively multiplies the data throughput by the number of processes. It also allows the process to complete its task faster and without interruption, thereby reducing latency.

## Example of data striping in TorQ

A simple but effective way of data striping is to do it divide the data randomly across all processes. This will ensure an even distribution of data. However, querying (locating and retrieving) data can become complicated.

A common method for data striping between processes is to use an instrument (sym) filter. For example, to stripe data across 2 RDB processes, data with symbols starting with A-M and N-L will be striped to RDB1 and RDB2 respectively. However, a major problem with this method is the uneven distribution of data (a lot of symbols tend to start with A for example).

## Data hash striping with MD5

A way to get around this problem is to stripe the data using a hash value which allows for better distribution. The hash function will store the mappings for the symbols that it has already computed and for subsequent requests for those symbols, it looks them up. It is loaded into the segmented tickerplant to use as subscription requests. For this purpose, MD5 (Message-Digest algorithm 5) hash is chosen as it is a fast and [built-in](https://code.kx.com/q/ref/md5/) hash function in kdb+. It creates a hexadecimal byte array from an input string and the first hex value from the output byte array is used to create a hash map for the data hash striping.

---

For example, using the symbol **`AAPL`**, we get:

```q
q)md5"AAPL"
0x8b10e4ae9eeb5684921a9ab27e4d87aa
q)first string first md5"AAPL"
"8"
```

And with a series of symbols:

```q
q)f:{first string first md5 string x}each
q)f`AMD`AIG`AAPL`DELL`DOW`GOOG`HPQ`INTC`IBM`MSFT
"40809edfcb"
```

A hash map based on the **`sym`** column is created like so:

```q
q)show sym:`$-100?(thrl cross .Q.A),thrl:(.Q.A cross .Q.A cross .Q.A)
`JOYH`TVIJ`TQHN`OBW`SOOM`RRCM`KUKX`MBQD`ZAFH`FQCZ`SRPI`SGGF`XNAC`JKHN`DFUA`JH..
q)sym@group f sym
e| `JOYH`BUEF`DINP`CBPJ`ATCO`TUNG
7| `TVIJ`UXK`NMDQ`FWIQ
3| `TQHN`SOOM`DFUA`JFAH`CHGW`BLRY`XLXR
5| `OBW`DKDE`UWDT`ZMRZ`WTVX`RBMF`HFHO`KKQP`SBMO`LVXH
4| `RRCM`NCZF`QFYH`HFRR`LUMC`VMXY
1| `KUKX`SGGF`OMGO`ZKWU`UPIU`VZPV`VYMB`ALXK`TVZK
8| `MBQD`JHEA`UXNG`CWJL`GVBA`ZOFZ`QVAK
a| `ZAFH`RYUH`XGMA`EDQQ`HLZW`FTJM`LTVV`BTNI
b| `FQCZ`XNAC`PRFU`DSRE`BKKJ`DQAG`JBSS`GTQC
2| `SRPI`JGGQ`UJXC`TAFZ`DNBV
c| `JKHN`PKBH`UOE
f| `OZMV`KFKN`TDDC`ZSYF`ISAG`NJHL`KNKI`QSMN`VJYY
6| `SRXA`DKKJ`FGXC`LGHO`OBCR`XXYB`TBKR
d| `RYVW`SNKZ`PGBO`EPSV
0| `QRXI`LOY`MADY
9| `CWXD`KZJL`SYMB`EJDG
```

The hex keys will be divided across the number of striped processes, example 4 RDBs, like so:

```q
q).Q.s1(hex:lower .Q.nA til base)!(base:16)#til numproc:4
"\"0123456789abcdef\"!0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3"
q)show subreq:sym@group(hex!base#til numproc)f sym
2| `JOYH`ZAFH`SRPI`RYUH`JGGQ`SRXA`BUEF`DKKJ`UJXC`TAFZ`XGMA`DINP`CBPJ`FGXC`DNB..
3| `TVIJ`TQHN`SOOM`FQCZ`XNAC`DFUA`OZMV`KFKN`TDDC`JFAH`PRFU`CHGW`BLRY`ZSYF`ISA..
1| `OBW`KUKX`SGGF`RYVW`OMGO`DKDE`UWDT`ZMRZ`SNKZ`WTVX`ZKWU`UPIU`RBMF`VZPV`CWXD..
0| `RRCM`MBQD`JKHN`JHEA`NCZF`QFYH`QRXI`PKBH`UXNG`LOY`CWJL`GVBA`MADY`HFRR`LUMC..
```

---

An advantage of using data hash striping is such that a specific symbol will always be striped to the exact location based on the number of processes.

A minor disadvantage to this method is when the number of distinct symbols is relatively large (>10000) AND the number of processes is unevenly distributed (not exactly divisible by 16), it may result in some imbalances since some processes are receiving more hex keys than the others.

However, this can be easily resolved by using more hex values from the output byte array of MD5 to create the hash map for the data hash striping, i.e., the number of hash keys will be much greater than 16.

# Setting up data striping in TorQ

## 1) Example setup for data striping across **ALL** RDB instances

### $KDBCONFIG/process.csv

The process file should contain the RDB instances by specifying a different **`port`** and **`procname`** column. Set the **`load`** column to **`${KDBCODE}/processes/rdb.q`**.

> **NOTE**
>
> - The **`procname`** convention should always start with **`rdb1`**
> - Increment by 1 for each RDB instance
> - In the following format: **`rdb{i}`**
> - There is no need to create separate **`rdb{i}.q`** files

**`$KDBCONFIG/process.csv`** should look something like this:

```sh
host,port,proctype,procname,U,localtime,g,T,w,load,startwithall,extras,qcmd
localhost,{KDBBASEPORT}+1,discovery,discovery1,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,0,,,${KDBCODE}/processes/discovery.q,1,,q
localhost,{KDBBASEPORT}+2,segmentedtickerplant,stp1,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,0,,,${KDBCODE}/processes/segmentedtickerplant.q,1,-schemafile ${TORQAPPHOME}/database.q -tplogdir ${KDBTPLOG},q
localhost,{KDBBASEPORT}+3,rdb,rdb1,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/rdb.q,1,,q
localhost,{KDBBASEPORT}+4,rdb,rdb2,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/rdb.q,1,,q
localhost,{KDBBASEPORT}+5,rdb,rdb3,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/rdb.q,1,,q
localhost,{KDBBASEPORT}+6,rdb,rdb4,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/rdb.q,1,,q
```

### $KDBAPPCONFIG/settings/rdb.q

Set **`.rdb.subfiltered: 1b`**

---

## 2) Example setup for data striping across **SOME** RDB instances

> - 2 RDB instances unfiltered
> - 2 RDB instances striped

### $KDBCONFIG/process.csv

Add in **`-.rdb.subfiltered 1`** (to enable striping) in the **`extras`** column for the striped RDB instances. Add in **`-.ds.numseg {i}`** (count of striped RDB instances) in the **`extras`** column for the **`segmentedtickerplant`** instance.

> **NOTE**
>
> - It is **`-.rdb.subfiltered 1`** and not **`-.rdb.subfiltered 1b`**
> - The RDB instances **must** be grouped according to those being striped first
>   - i.e. **`rdb1`**, **`rdb2`** are striped and **`rdb3`**, **`rdb4`** are unfiltered
> - **`-.ds.numseg {i}`** (count of striped RDB instances) **must** be added to overwrite the **`-.ds.numseg`** variable from initialization (defaults to number of **`rdb`** **`proctype`**).

**`$KDBCONFIG/process.csv`** should look something like this:

```sh
host,port,proctype,procname,U,localtime,g,T,w,load,startwithall,extras,qcmd
localhost,{KDBBASEPORT}+1,discovery,discovery1,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,0,,,${KDBCODE}/processes/discovery.q,1,,q
localhost,{KDBBASEPORT}+2,segmentedtickerplant,stp1,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,0,,,${KDBCODE}/processes/segmentedtickerplant.q,1,-schemafile ${TORQAPPHOME}/database.q -tplogdir ${KDBTPLOG} -.ds.numSeg 2,q
localhost,{KDBBASEPORT}+3,rdb,rdb1,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/rdb.q,1,-.rdb.subfiltered 1,q
localhost,{KDBBASEPORT}+4,rdb,rdb2,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/rdb.q,1,-.rdb.subfiltered 1,q
localhost,{KDBBASEPORT}+5,rdb,rdb3,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/rdb.q,1,,q
localhost,{KDBBASEPORT}+6,rdb,rdb4,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/rdb.q,1,,q
```

### $KDBAPPCONFIG/settings/rdb.q

**Ensure** **`.rdb.subfiltered: 0b`**
