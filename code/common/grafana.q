\d .grafana

// user defined column name of time column
timeCol:@[value;`.gdkb.timeCol;`time];
// user defined column name of sym column
sym:@[value;`.gkdb.sym;`sym];
// user defined date range to find syms from
timeBackdate:@[value;`.gkdb.timeBackdate;2D];
// user defined number of ticks to return
ticks:@[value;`.gkdb.ticks;1000];

// json types of kdb datatypes
types:.Q.t!`array`boolean,(3#`null),(5#`number),11#`string;
// milliseconds between 1970 and 2000
epoch:946684800000;

// wrapper if user has custom .z.pp
.z.pp:{[f;x]$[(`$"X-Grafana-Org-Id")in key last x;zpp;f]x}[@[value;`.z.pp;{{[x]}}]];

// return alive response for GET requests
.z.ph:{[f;x]"HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n";f x}[@[value;`.z.ph;{{[x]}}]];

// retrieve and convert Grafana HTTP POST request then process as either timeseries or table
zpp:{
  // get API url from request
  r:" " vs first x;
  // convert grafana mesage to q
  rqt:.j.k r 1;
  $["query"~r 0;query[rqt];"search"~r 0;search rqt;`$"Annotation url nyi"]
 };

query:{[rqt]
  // retrieve final query and append to table to log
  rqtype:raze rqt[`targets]`type;
  :.h.hy[`json]$[rqtype~"timeserie";tsfunc rqt;tbfunc rqt];
 };

finddistinctsyms:{?[x;enlist(>;timeCol;(-;.z.p;timeBackdate));1b;{x!x}enlist sym]sym};

search:{[rqt]
  // build drop down case options from tables in port
  tabs:tables[];
  symtabs:?[sym in'cols each tabs;tabs;count[tabs]#`] except `;
  timetabs:?[timeCol in'cols each tabs;tabs;count[tabs]#`] except `;
  rsp:string tabs;
  if[count timetabs;
    rsp,:s1:string` sv/:`t,/:timetabs;
    rsp,:s2:string` sv/:`g,/:timetabs; 
    rsp,:raze(s2,'"."),/:'c1:string {(cols x) where`number=types (0!meta x)`t}each timetabs;
    rsp,:raze((string` sv/:`o,/:timetabs),'"."),/:'c1;
    if[count symtabs;
      rsp,:raze(s1,'"."),/:'c2:string each finddistinctsyms'[timetabs];
      rsp,:raze((string` sv/:`o,/:timetabs),'"."),/:'{x[0] cross ".",'string finddistinctsyms x 1}each (enlist each c1),'timetabs;
     ];
   ];
  :.h.hy[`json].j.j rsp;
 };

diskvals:{c:count[x]-ticks+til ticks;get'[.Q.ind[x;c]]};
memvals:{get'[?[x;enlist(within;`i;count[x]-(ticks),0);0b;()]]};
catchvals:{@[diskvals;x;{[x;y]memvals x}[x]]};

// process a table request and return in JSON format
tbfunc:{[rqt]
  rqt:value raze rqt[`targets]`target;
  // get column names and associated types to fit format
  colName:cols rqt;
  colType:types (0!meta rqt)`t;
  // build body of response in Json adaptor schema
  :.j.j enlist`columns`rows`type!(flip`text`type!(colName;colType);catchvals rqt;`table);
 };

// process a timeseries request and return in Json format, takes in query and information dictionary
tsfunc:{[x]
  / split arguments
  numArgs:count args:`$"."vs raze x[`targets]`target;
  tyArgs:args 0;
  // manipulate queried table
  colN:cols rqt:value args 1;
  // function to convert time to milliseconds, takes timestamp
  mil:{floor epoch+(`long$x)%1000000};
  // ensure time column is a timestamp
  if["p"<>meta[rqt][timeCol;`t];rqt:@[rqt;timeCol;+;.z.D]];
  // get time range from grafana
  range:"P"$-1_'x[`range]`from`to;
  // select desired time period only
  rqt:?[rqt;enlist(within;timeCol;range);0b;()];
  // form milliseconds since epoch column
  rqt:@[rqt;`msec;:;mil rqt timeCol];

  // cases for graph/table and sym arguments
  $[(2<numArgs)and`g~tyArgs;graphsym[args 2;rqt];
    (2<numArgs)and`t~tyArgs;tablesym[colN;rqt;args 2];
    (2=numArgs)and`g~tyArgs;graphnosym[colN;rqt];
    (2=numArgs)and`t~tyArgs;tablenosym[colN;rqt];
    (4=numArgs)and`o~tyArgs;othersym[args;rqt];
    (3=numArgs)and`o~tyArgs;othernosym[args 2;rqt]; 
    `$"Wrong input"]
 };

// timeserie request on non-specific panel w/ no preference on sym seperation
othernosym:{[colN;rqt]
  // return columns with json number type only
  colName:colN cross`msec;
  build:{y,`target`datapoints!(z 0;value each ?[x;();0b;z!z])};
  :.j.j build[rqt]\[();colName];
 };

// timeserie request on grqph panel w/ no preference on sym seperation
graphnosym:{[colN;rqt]
  // return columns with json number type only
  colN:-1_colN where`number=types (0!meta rqt)`t;
  colName:colN cross`msec;
  build:{y,`target`datapoints!(z 0;value each ?[x;();0b;z!z])};
  :.j.j build[rqt]\[();colName];
 };

// timeserie request on table panel w/ no preference on sym seperation
tablenosym:{[colN;rqt]
  colType:types -1_(0!meta rqt)`t;
  :.j.j enlist`columns`rows`type!(flip`text`type!(colN;colType);catchvals rqt;`table);
 };

// timeserie request on non-specific panel w/ data for one sym returned
othersym:{[args;rqt]
  // specify what columns data to return, taken from drop down input
  outCol:args[2],`msec;
  data:flip value flip?[rqt;enlist(=;sym;enlist args 3);0b;outCol!outCol];
  :.j.j enlist `target`datapoints!(args 3;data);
 };

// timeserie request on graph panel w/ data for each sym returned
graphsym:{[colname;rqt]
  // return columns with json number type only
  syms:`$string ?[rqt;();1b;{x!x}enlist sym]sym;
  // specify what columns data to return, taken from drop down input
  outCol:colname,`msec;
  build:{[outCol;rqt;x;y]data:flip value flip?[rqt;enlist(=;sym;enlist y);0b;outCol!outCol];x,`target`datapoints!(y;data)};
  :.j.j build[outCol;rqt]\[();syms];
 };

// timeserie request on table panel w/ single sym specified
tablesym:{[colN;rqt;symname]
  colType:types -1_(0!meta rqt)`t;
  // select data for requested sym only
  rqt:?[rqt;enlist(=;sym;enlist symname);0b;()];
  :.j.j enlist`columns`rows`type!(flip`text`type!(colN;colType);catchvals rqt;`table);
 };
