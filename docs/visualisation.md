
Visualisation
=============

kdb+ supports websockets and so HTML5 GUIs can be built. We have
incorporated a set of server side and client side utilities to ease HTML
GUI development.

<a name="ut"></a>

kdb+ Utilities
--------------

The server side utilities are contained in html.q. These utilise some
community code, specifically json.k and a modified version of u.q, both
from Kx Systems. The supplied functionality includes:

-   json.k provides two way conversion between kdb+ data structures and
    JSON;

-   u.q is the standard pub/sub functionality provided with kdb+tick,
    and a modified version is incorporated to publish data structures
    which can be easily interpreted in JavaScript;

-   functions for reformatting temporal types to be JSON compliant;

-   page serving to utilise the inbuilt kdb+ webserver to serve custom
    web pages. An example would be instead of having to serve a page
    with a hardcoded websocket connection host and port, the kdb+
    process can serve a page connecting back to itself no matter which
    host or port it is running on.

<a name="java"></a>

JavaScript Utilities
--------------------

The JavaScript utilities are contained in kdbconnect.js. The library
allows you to:

-   create a connection to the kdb+ process;

-   display the socket status;

-   sending queries;

-   binding results returned from kdb+ to updates in the webpage.

<a name="out"></a>

Outline
-------

All communication between websockets and kdb+ is asynchronous. The
approach we have adopted is to ensure that all data sent to the web
browser is encoded as a JSON object containing a tag to enable the web
page to decipher what the data relates to. The format we have chosen is
for kdb+ to send dictionaries of the form:

    `name`data!("dataID";dataObject) 

All the packing can be done by .html.dataformat. Please note that the
temporal types are converted to longs which can easily be converted to
JavaScript Date types. This formatting can be modified in the formating
dictionary .html.typemap.

    q)a:flip `minute`time`date`month`timestamp`timespan`datetime`float`sym!enlist each (09:00; 09:00:00.0;.z.d; `month$.z.d; .z.p; .z.n;.z.z;20f;`a)
    q).html.dataformat["start";(enlist `tradegraph)!enlist a]
    name| "start"
    data| (,`tradegraph)!,+`minute`time`date`month`timestamp`timespan`datetime`float`sym!(,32400000;,32400000;,1396828800000;,1396310400000;,"2014-04-07T13:23:01Z";,48181023;,"2014-04-07T13:23:01Z";,20f;,`a)
    q)first (.html.dataformat["start";(enlist `tradegraph)!enlist a])[`data;`tradegraph]                                                                                     
    minute   | 32400000
    time     | 32400000
    date     | 1396828800000
    month    | 1396310400000
    timestamp| "2014-04-07T13:23:01Z"
    timespan | 48181023
    datetime | "2014-04-07T13:23:01Z"
    float    | 20f
    sym      | `a

We have also extended this structure to allow web pages to receive data
in a way similar to the standard kdb+tick pub/sub format. In this case,
the data object looks like:

    `name`data!("upd";`tablename`tabledata!(`trade;([]time:09:00 09:05 09:10; price:12 13 14)))

This can be packed with .html.updformat:

    q).html.updformat["upd";`tablename`tabledata!(`trade;a)]                                                                                                                 
    name| "upd"
    data| `tablename`tabledata!(`trade;+`minute`time`date`month`timestamp`timespan`datetime`float`sym!(,32400000;,32400000;,1396828800000;,1396310400000;,"2014-04-07T13:23:01Z";,48181023;,"2014-04-07T13:23:01Z";,20f;,`a))
    q)first(.html.updformat["upd";`tablename`tabledata!(`trade;a)])[`data;`tabledata]                                                                                        
    minute   | 32400000
    time     | 32400000
    date     | 1396828800000
    month    | 1396310400000
    timestamp| "2014-04-07T13:23:01Z"
    timespan | 48181023
    datetime | "2014-04-07T13:23:01Z"
    float    | 20f
    sym      | `a

To utilise the pub/sub functionality, the web page must connect to the
kdb+ process and subscribe for updates. Subscriptions are done using

    .html.wssub[`tablename]

Publications from the kdb+ side are done with

    .html.pub[`tablename;tabledata]

On the JavaScript side the incoming messages (data events) must be bound
to page updates. For example, there might be an initialisation event
called “start” which allows the web page to retrieve all the initial
data from the process. The code below redraws the areas of the page with
the received data.

    /* Bind data - Data type "start" will execute the callback function */
    KDBCONNECT.bind("data","start",function(data){
      // Check that data is not empty
      if(data.hbtable.length !== 0)
       // Write HTML table to div element with id heartbeat-table
       { $("#heartbeat-table").html(MONITOR.jsonTable(data.hbtable));}
      if(data.lmtable.length !== 0)
       // Write HTML table to div element with id logmsg-table
       { $("#logmsg-table").html(MONITOR.jsonTable(data.lmtable));}	 
      if(data.lmchart.length !== 0)
       // Log message error chart
       { MONITOR.barChart(data.lmchart,"logmsg-chart","Error Count","myTab"); }
      });

Similarly the upd messages must be bound to page updates. In this case,
the structure is slightly different:

    KDBCONNECT.bind("data","upd",function(data){
      if(data.tabledata.length===0) return;
      if(data.tablename === "heartbeat")
        { $("#heartbeat-table").html(MONITOR.jsonTable(data.tabledata));}
      if(data.tablename === "logmsg")
        { $("#logmsg-table").html(MONITOR.jsonTable(data.tabledata));}
      if(data.tablename === "lmchart")
        { MONITOR.barChart(data.tabledata,"logmsg-chart","Error Count","myTab"); }
     });

To display the WebSocket connection status the event “ws\_event” must be
bound and it will output one of these default messages: “Connecting...”,
“Connected” and “Disconnected” depending on the connection state of the
WebSocket. Alternatively the value of the readyState attribute will
determine the WebSocket status.

    // Select html element using jQuery
    var $statusMsg = $("#status-msg");	
    KDBCONNECT.bind("ws_event",function(data){
      // Data is the default message string
      $statusMsg.html(data);
    });
    KDBCONNECT.core.websocket.readyState // Returns 1 if connected.

Errors can be displayed by binding the event called “error”.

    KDBCONNECT.bind("error",function(data){
      $statusMsg.html("Error - " + data);
    });

<a name="eg"></a>

Example
-------

A basic example is provided with the Monitor process. To get this to
work, u.q from kdb+tick should be placed in the code/common directory to
allow all processes to publish updates. It should be noted that this is
not intended as a production monitoring visualisation screen, moreso a
demonstration of functionality. See section monitorgui for more
details.

<a name="work"></a>

Further Work
------------

Further work planned includes:

-   allow subscriptions on a key basis- currently all subscribers
    receive all updates;

-   add JavaScript controls to allow in-place updates based on key
    pairs, and scrolling window updates e.g. add N new rows to
    top/bottom of the specified table;

-   allow multiple websocket connections to be maintained at the same
    time.
