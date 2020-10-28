## Segmented Tickerplant Documentation

**Introduction**

A key component of the TorQ framework has always been the Tickerplant (TP) process. This process is a slightly modified version of the process of the same name found in the KDB+ Tick framework, which receives ticks from a feedhandler, timestamps them, and publishes them to any subscribed processes such as a real-time database (RDB) while writing the updates to a log file on disk. While this process is perfectly functional, there is only really one configuration for it, and some users may prefer greater flexibility. To this end, the Segmented Tickerplant (STP) has been developed.

**Segmented Tickerplant**

The idea behind the STP was to create a process which retained all the functionality of the Tickerplant while adding flexibility in terms of logging and subscriptions. It is entirely backwards compatible, meaning that any processes that depend on a TP can equally utilise an STP without painful code changes. It can still be used to create Chained Tickerplants (CTPs), is still performance conscious and still timestamps the incoming data before publishing it to its subscribers.

What has been added are multiple logging modes, which allow the logs to be split and partitioned, and subscription modes, which alter how the data is batched and published, as well as error handling, which sends bad messages to a separate file.

**Logging Modes**

The default TP logging behaviour is to write all updates to disk in a single log file. This can be unwieldy as the whole file needs to be played through when a process starts, which can be slow as the number of ticks increases, and if the file is corrupted all the data is impacted. To add more flexibility, the following logging modes have been added which are set with the `.stplg.multilog` variable:

- None:

  This mode is essentially the default TP behaviour, where all ticks across all tables for a given day are stored in a single file, eg. `database20201026154808`. This is the simplest form of logging as everything is in one place.

- Periodic:

  In this mode all the updates are stored in a the same file but the logs are rolled according to a custom period, set with `.stplg.multilogperiod`. For example, if the period is set to an hour a new log file will be created every hour and stored in a daily partitioned directory. This means that if a subscriber goes down, only the last hour of logs need to be replayed rather than everything so far that day, and that any log file corruptions will only affect that time period of data rather than the whole day.

  The files take the form `periodic20201026000`, `periodic202010260100`, `periodic202010260200`...

- Tabular:

  This mode is similar to the default behaviour except that each table has its own log file which is rolled daily in the form `trade20201026154808`. This has similar benefits to the previous case where only the ticks for individual tables need to be replayed for the day, and that any file mishaps are confined to a single table's worth of updates.

- Tabperiod:

  As the name suggests this mode combines the behaviour of the tabular and periodic logging modes, whereby each table has its own log file, each of which are rolled periodically as defined in the process. This adds the flexibility of both those modes when it comes to replays and file corruption too.

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

**Batching Modes**

The other main update is how updates are published to subscribers. Again, there are named modes which are set with the `.stplg.batchmode` variable and these allow the user to be flexible with process latency and throughput by altering the `.u.upd` and `.z.ts` functions:

- Defaultbatch:

  This is effectively the standard TP batching mode where, upon receiving a tick, the STP immediately logs it to disk and batches the update which is published to subscribers whenever the timer function is next called. This mode represents a good balance of latency and overall throughput.

- Immediate:

  In this mode no batching occurs, and the update is logged and published immediately upon entering the STP. This is less efficient in terms of overall throughput but ensures low latency.

- Memorybatch:

  In this mode, neither logging nor publishing happens immediately but everything is held in memory until the timer function is called, at which point the update is logged and published. High overall message throughput is possible with this mode, but there is a risk that some messages aren't logged in the case of STP failure.

- Performance:

  Put stuff in here when we have the numbers

**Error Trapping**

If the `.stplg.errmode` Boolean variable is set to true, an error log is opened on start up and the `.u.upd` function is wrapped in an error trap, so that if a bad message is received, it is not published but instead sent to the error log. The advantage of this is that bad updates are not sent through or replayed into the subscribers, which could cause issues, and they are easier to find and debug.

Note to self - what are the performance impacts of this? Add a line to the performance tests to just run again in other error mode