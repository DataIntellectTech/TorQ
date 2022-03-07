// Bespoke Monitor config : Finance Starter Pack

\d .servers
// list of connections to make at start up
// can't use `ALL as the tickerplant doesn't publish heartbeats
CONNECTIONS:`discovery`rdb`hdb`wdb`sort`gateway`housekeeping`reporter`feed`sortworker
