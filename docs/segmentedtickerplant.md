## Segmented Tickerplant Documentation

**Introduction**

A key component of the TorQ framework has always been the Tickerplant (TP) process. This process is a slightly modified version of the process of the same name found in the KDB+ Tick framework, which receives ticks from a feedhandler, timestamps them, and publishes them to any subscribed processes such as a real-time database (RDB) while writing the updates to a log file on disk. While this process is perfectly functional, there is only really one configuration for it, and some users may prefer greater flexibility. To this end, the Segmented Tickerplant (STP) has been developed.

**Segmented Tickerplant**

The idea behind the STP was to create a process which retained all the functionality of the Tickerplant while adding flexibility in terms of logging and subscriptions. It is entirely backwards compatible, meaning that any processes that depend on a TP can equally utilise an STP without painful code changes. It can still be used to create Chained Tickerplants (CTPs), is still performance conscious and still timestamps the incoming data before publishing it to its subscribers.

What has been added are multiple logging modes, which allow the logs to be split and partitioned, and subscription modes, which alter how the data is batched and published, as well as error handling, which sends bad messages to a separate file.

**Starting a Segmented Tickerplant process**

Starting an STP process is similar to starting a tickerplant, we need to have an updated process.csv that contains a line for the STP process like the one below. Optional flags such as `-.stplg.batchmode` and `-.stplg.errmode` can be added to change settings for the process.

`localhost,{KDBBASEPORT}+103,segmentedtickerplant,stp1,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,0,,,${KDBCODE}/processes/segmentedtickerplant.q,1,-schemafile ${TORQAPPHOME}/database.q -.stplg.batchmode immediate -.stplg.errmode 0 -t 1,q`

The process can either be started using:

`bash torq.sh start stp1 -csv path/to/process.csv`

or:

`q ${TORQHOME}/torq.q -proctype segmentedtickerplant -procname stp1 -procfile path/to/proces.csv -load ${KDBCODE}/processes/segmentedtickerplant.q`

Useful configuration settings for STP processes:
 * .stplg.batchmode - Specifies the batch mode for the STP process
   .stplg.batchmode:`immediate 
 * .stplg.errmode   - Enables error trapping mode for the process.
   .stplg.errmode:1b 
 * 

Useful flags for STP process:
 *

**Logging Modes**

The default TP logging behaviour is to write all updates to disk in a single log file. This can be unwieldy as the whole file needs to be played through when a process starts, which can be slow as the number of ticks increases, and if the file is corrupted all the data is impacted. To add more flexibility, the following logging modes have been added which are set with the `.stplg.multilog` variable:

- None:

  This mode is essentially the default TP behaviour, where all ticks across all tables for a given day are stored in a single file, eg. `database20201026154808`. This is the simplest form of logging as everything is in one place.

```
    stplogs
    ├──stp1_2020.11.05/
    │  ├── err20201105000000
    │  ├── stpmeta
    │  └── stp1_20201105000000
    └──stp2_2020.11.06
       ├── err20201106000000
       ├── stpmeta
       └── stp1_20201106000000
```

- Periodic:

  In this mode all the updates are stored in a the same file but the logs are rolled according to a custom period, set with `.stplg.multilogperiod`. For example, if the period is set to an hour a new log file will be created every hour and stored in a daily partitioned directory. This means that if a subscriber goes down, only the last hour of logs need to be replayed rather than everything so far that day, and that any log file corruptions will only affect that time period of data rather than the whole day.

```
    stplogs
    ├──stp1_2020.11.05/
    │  ├── err20201105000000
    │  ├── periodic20201105000000
    │  ├── periodic20201105010000
    │  ├── periodic20201105020000
    │  └── stpmeta
    └──stp2_2020.11.06
       ├── err20201106000000
       ├── periodic20201106000000
       ├── periodic20201106010000
       ├── periodic20201106020000
       └── stpmeta
```

- Tabular:

  This mode is similar to the default behaviour except that each table has its own log file which is rolled daily in the form `trade20201026154808`. This has similar benefits to the previous case where only the ticks for individual tables need to be replayed for the day, and that any file mishaps are confined to a single table's worth of updates.

```
    stplogs/
    ├── stp1_2020.11.05
    │   ├── err20201105000000
    │   ├── logmsg_20201105000000
    │   ├── packets_20201105000000
    │   ├── quote_20201105000000
    │   ├── quote_iex_20201105000000
    │   ├── stpmeta
    │   ├── trade_20201105000000
    │   └── trade_iex_20201105000000
    └── stp1_2020.11.06
        ├── err20201106000000
        ├── logmsg_20201106000000
        ├── packets_20201106000000
        ├── quote_20201106000000
        ├── quote_iex_20201106000000
        ├── stpmeta
        ├── trade_20201106000000
        └── trade_iex_20201106000000
```

- Tabperiod (default):

  As the name suggests this mode combines the behaviour of the tabular and periodic logging modes, whereby each table has its own log file, each of which are rolled periodically as defined in the process. This adds the flexibility of both those modes when it comes to replays and file corruption too.

```
    stplogs/
    ├── stp1_2020.11.05
    │   ├── err20201105000000
    │   ├── err20201105010000
    │   ├── logmsg_20201105000000
    │   ├── logmsg_20201105010000
    │   ├── packets_20201105000000
    │   ├── packets_20201105010000
    │   ├── quote_20201105000000
    │   ├── quote_20201105010000
    │   ├── quote_iex_20201105000000
    │   ├── quote_iex_20201105010000
    │   ├── stpmeta
    │   ├── trade_20201105000000
    │   ├── trade_20201105010000
    │   ├── trade_iex_20201105000000
    │   └── trade_iex_20201105010000
    └── stp1_2020.11.06
        ├── err20201106000000
        ├── err20201106010000
        ├── logmsg_20201106000000
        ├── logmsg_20201106010000
        ├── packets_20201106000000
        ├── packets_20201106010000
        ├── quote_20201106000000
        ├── quote_20201106010000
        ├── quote_iex_20201106000000
        ├── quote_iex_20201106010000
        ├── stpmeta
        ├── trade_20201106000000
        ├── trade_20201106010000
        ├── trade_iex_20201106000000
        └── trade_iex_20201106010000
```

- Custom:

  This mode allows the user to have more granular control over how each table is logged. The variable `.stplg.customcsv` points to a CSV file containing two columns, table and mode, and this allows the user to decide which logging mode to use for each table. An example CSV is below:

  ```
  table,mode
  trade,periodic
  trade_iex,periodic
  quote,tabular
  quote_iex,tabluar
  heartbeat,tabperiod
  ```

  Here we have the trade and trade_iex tables both being saved to the same periodic log file, the quote and quote_iex tables both having their own daily log file and the heartbeat table having a periodic log file all to itself. This mode may be advantageous in the case where some tables receive far more updates than others, so they can have more rigorously partitioned logs, and the sparser tables can be pooled together. There is some complexity associated with this mode, as there can be different log files rolling at different times.

  New logging modes can be added to your system through easy additions, a update function (`.stplg.upd`) and a timing function (`.stplg.zts`) are needed for this. The memory batch upd and zts code for example:

```
.stplg.upd[`memorybatch]:{[t;x;now]
  t insert updtab[t] . (x;now);
 };

zts[`memorybatch]:{
  {[t]
    if[count value t;
      `..loghandles[t] enlist (`upd;t;value flip value t);
      @[`.stplg.msgcount;t;+;1];
      @[`.stplg.rowcount;t;+;count value t];
      .stpps.pubclear[t]];
  }each .stpps.t;
 };
```
  Each of these logging modes use a extra table called stpmeta which contains information about the files present in this logs directory. This table contains the pathway to the log (logname), the tables that are present in this file (tbls), the message count (msgcount) and the schema.  

**Batching Modes**

The other main update is how updates are published to subscribers. Again, there are named modes which are set with the `.stplg.batchmode` variable and these allow the user to be flexible with process latency and throughput by altering the `.u.upd` and `.z.ts` functions:

- Defaultbatch:

  This is effectively the standard TP batching mode where, upon receiving a tick, the STP immediately logs it to disk and batches the update which is published to subscribers whenever the timer function is next called. This mode represents a good balance of latency and overall throughput.

- Immediate:

  In this mode no batching occurs, and the update is logged and published immediately upon entering the STP. This is less efficient in terms of overall throughput but ensures low latency.

- Memorybatch:

  In this mode, neither logging nor publishing happens immediately but everything is held in memory until the timer function is called, at which point the update is logged and published. High overall message throughput is possible with this mode, but there is a risk that some messages aren't logged in the case of STP failure.

- Performance stats:

Performance data below is collected from an STP  is from a 2 minute sample size. For batched data we batched the same data that was sent for single updates but in batches of 100 rows of data. 

Single row updates:
|STP batch mode|Feed mode|Average mps|Max mps|
|--------------|---------|-----------|-------|
|vanilla TP immediate|single|75211.81|82582|
|vanilla TP batch|single|98413.48|112476|
|immediate|single|89092.55|96659|
|default batch|single|99465.77|109733|
|memory batch|single|173587.3|184969|

Batched updates:
|STP batch mode|Feed mode|Average mps|Max mps|
|--------------|---------|-----------|-------|
|vanilla TP immediate|bulk|1775813|2034100|
|vanilla TP batch|bulk|1805003|1993700|
|immediate|bulk|1803027|2034700|
|default batch|bulk|1899106|2167500|
|memory batch|bulk|2115197|2473200|

Through batching the data at the tickerplant the performance of the tickerplant can be improved significantly. By batching your data you can reduce the number of updates needed to be sent is reduced and the rows sent to sent to subscribers per second is increased. The performance of the batching modes on the STP have similar performance to one another and minor performance costs compared to a standard tickerplant. 

- New Batching modes:
  New batching modes can be added to your system through two easy additions, a update function (`.stplg.upd`) and a timing function (`.stplg.zts`) are needed for this. Here is the memory batch upd and zts code for example:

```
\d .stplg

upd[`memorybatch]:{[t;x;now]
  t insert updtab[t] . (x;now);
 };

zts[`memorybatch]:{
  {[t]
    if[count value t;
      `..loghandles[t] enlist (`upd;t;value flip value t);
      @[`.stplg.msgcount;t;+;1];
      @[`.stplg.rowcount;t;+;count value t];
      .stpps.pubclear[t]];
  }each .stpps.t;
 };

\d .
```

**Error Trapping**

If the `.stplg.errmode` Boolean variable is set to true, an error log is opened on start up and the `.u.upd` function is wrapped in an error trap, so that if a bad message is received, it is not published but instead sent to the error log. The advantage of this is that bad updates are not sent through or replayed into the subscribers, which could cause issues, and they are easier to find and debug.

Note to self - what are the performance impacts of this? Add a line to the performance tests to just run again in other error mode

**Time Zone Behaviour**
One of the most important jobs of a tickerplant is to add the time value to the data it recieves before it's sent to any subscribers. This is a very important job to maintain data quality in your system so that users can trust it. 
A difference of time zones for processes may cause issues for eod processes.
Different processes can have different time zone settings to time stamp for different data from different markets and to roll over correctly at the end of day. One system could have different processes handling US or EU data.

**Chained STP**
A chained tickerplant (TP) is a TP that is subscribed to another TP like a chain of TPs hence the name. This is useful for systems that need to behave differently for different subscribers, for example if you have a slow subscriber. When using the Chained STP, all endofday/endofperiod messages still originate from the STP and are merely passed on to subscribers through the Chained STP. Also, the Chained STP process is dependent on the Segmented TP. Therefore, if the connection to the STP dies, the ChainedSTP process will die. 

With these new changes to the tickerplant, we have added new features to chained tickerplants as well. Under a typical tick system there is one TP log for the main TP for each day, if a CTP goes down or needs to replay data the replay must happen from the main TP. A chained STP can have it's own log file and be in a different logging mode than the main TP, e.g. top level has no batching and chained STP has memory batching, to allow greater flexability. 
There are 3 different logging modes for the Chained STP:

- None: Chained STP does not create or access any log files.

- Create: Chained STP creates its own log files independent of the STP logs. Subscribers then access the chained STP log files during replays

- Parent: STP logs are passed to subscribers during replays. Chained STP does not create any logs itself 

**Customisation and Flexability**
 New functionality added is to enable the use of different upd functions in one ticker plant process for each table. This can be done a new variable `.stplg.updtab`. This is a dictionary that contains the upd functions for each table. Changes can be made to this like so:

```
.stplg.updtab[`tabname]:updfunction

q) .stplg.updtab
quote   | {(enlist(count first x)#y),x}
trade   | {(enlist(count first x)#y),x}
tabname | updfunction
...
```

This allows a system to have a greater degree of flexability without necessitating additional processes. For example a table containing stats on updates can be created using this functionality to create a unique upd function for this. 
 A table can be created including the sequence number which is the number of messages sent out by the stp and is updated in the upd function.

```
Example of sequence numbering for upd function

.stplg.seqnum is the variable that the sequence number is stored under

.stplg.upd[`seqnum]:{
    (enlist(count first x)#y),(enlist(count first x)#(`long$ .stplg.seqnum)),x
 };
```

