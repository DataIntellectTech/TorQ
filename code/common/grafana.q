\d .grafana

// user defined column name of time column
timecol:@[value;`.grafana.timecol;`time];
// user defined column name of sym column
sym:@[value;`.grafana.sym;`sym];
// user defined date range to find syms from
timebackdate:@[value;`.grafana.timebackdate;2D];
// user defined number of ticks to return
ticks:@[value;`.grafana.ticks;1000];
// user defined query argument deliminator
del:@[value;`.grafana.del;"."];

// json types of kdb datatypes
types:.Q.t!`array`boolean,(3#`null),(5#`number),11#`string;
// milliseconds between 1970 and 2000
epoch:946684800000;

// wrapper if user has custom .z.pp
.z.pp:{[f;x]$[(`$"X-Grafana-Org-Id")in key last x;zpp;f]x}[@[value;`.z.pp;{{[x]}}]];

// return alive response for GET requests
.z.ph:{[f;x]
  $[(`$"X-Grafana-Org-Id")in key last x;"HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n";f x]
 }[@[value;`.z.ph;{{[x]}}]];


// retrieve and convert Grafana HTTP POST request then process as either timeseries or table
zpp:{
  // get API url from request
  // cuts at first whitespace char to avoid splitting function params
  r:(0;n?" ")cut n:first x;
  // convert grafana message to q
  rqt:.j.k r 1;
  $["query"~r 0;query[rqt];"search"~r 0;search rqt;`$"Annotation url nyi"]
 };

query:{[rqt]
  // retrieve final query and append to table to log
  rqtype:raze rqt[`targets]`type;
  :.h.hy[`json]$[rqtype~"timeserie";tsfunc rqt;tbfunc rqt];
 };

finddistinctsyms:{?[x;enlist(>;timecol;(-;.z.p;timebackdate));1b;{x!x}enlist sym]sym};

// prefixes string c to each string s, seperated by del
prefix:{[c;s] (c,del),/:s};

search:{[rqt]
  // build drop down case options from tables in port
  tabs:tables[];
  symtabs:tabs where sym in'cols each tabs;
  timetabs:tabs where timecol in'cols each tabs;
  rsp:string tabs;
  
  if[count timetabs;
    rsp,:s1:prefix["t";string timetabs];
    rsp,:s2:prefix["g";string timetabs];
    // suffix names of number columns to graph and other panel options
    rsp,:raze(s2,'del),/:'c1:string {cols[x] where`number=types (0!meta x)`t}each timetabs;
    rsp,:raze(prefix["o";string timetabs],'del),/:'c1;
    if[count symtabs;
      // suffix distinct syms to timeseries table and other panel options
      rsp,:raze(s1,'del),/:'c2:string each finddistinctsyms'[timetabs];
      rsp,:raze(prefix["o";string timetabs],'del),/:'{x[0] cross del,'string finddistinctsyms x 1}each (enlist each c1),'timetabs;
     ];
   ];
  :.h.hy[`json].j.j rsp;
 };

diskvals:{c:(count[x]-ticks)+til ticks;get'[.Q.ind[x;c]]};
memvals:{get'[?[x;enlist(within;`i;count[x]-ticks,0);0b;()]]};
catchvals:{@[diskvals;x;{[x;y]memvals x}[x]]};

istype:{[targ;char] (char,del)~2#targ};
isfunc:istype[;"f"]; istab:istype[;"t"];

// builds body of table response in Json adaptor schema
tabresponse:{[colname;coltype;rqt] .j.j enlist`columns`rows`type!(flip`text`type!(colname;coltype);catchvals rqt;`table)};

// process a table request and return in JSON format
tbfunc:{[rqt]
  rqt: raze rqt[`targets]`target;
  symname:0b;
  // if f.t.func, drop first 4 chars
  rqt:0!value $[isfunc[rqt] & istab 2_rqt; 4_rqt; 
                isfunc rqt; 2_rqt;
                istab rqt; [rqt: `$del vs rqt; if[2<count rqt; symname: rqt 2]; rqt 1];
                rqt];
  // get column names and associated types to fit format
  colname:cols rqt;
  coltype:types (0!meta rqt)`t;
  // search rqt for sym if symname was set
  if[-11h=type symname; rqt:?[rqt;enlist(=;sym;enlist symname);0b;()]];
  :tabresponse[colname;coltype;rqt];
 };

// process a timeseries request and return in Json format, takes in query and information dictionary
tsfunc:{[x]	
  targ: raze x[`targets]`target;
  / split arguments
  numargs:count args:$[isfunc targ;(0;1+targ?del)cut targ:2_targ;`$del vs targ];
  tyargs:$[10h=abs type args 0;`$1#;]args 0;
  // manipulate queried table
  coln:cols rqt:0!value args 1;
  // function to convert time to milliseconds, takes timestamp
  mil:{floor epoch+(`long$x)%1000000};
  // ensure time column is a timestamp
  if["p"<>meta[rqt][timecol;`t];rqt:@[rqt;timecol;+;.z.D]];
  // get time range from grafana
  range:"P"$-1_'x[`range]`from`to;
  // select desired time period only
  rqt:?[rqt;enlist(within;timecol;range);0b;()];
  // form milliseconds since epoch column
  rqt:@[rqt;`msec;:;mil rqt timecol];

  // cases for graph/table and sym arguments
  $[(2<numargs)and`g~tyargs;graphsym[args 2;rqt];
    (2<numargs)and`t~tyargs;tablesym[coln;rqt;args 2];
    (2=numargs)and`g~tyargs;graphnosym[coln;rqt];
    (2=numargs)and`t~tyargs;tablenosym[coln;rqt];
    (4=numargs)and`o~tyargs;othersym[args;rqt];
    (3=numargs)and`o~tyargs;othernosym[args 2;rqt]; 
    (2=numargs)and`o~tyargs;othernosym[coln except timecol;rqt];
    `$"Wrong input"]
 };

// build JSON response for graph & other panels with no sym seperation
buildnosym:{y,`target`datapoints!(z 0;value each ?[x;();0b;z!z])};
nosymresponse:{[rqt;colname] .j.j buildnosym[rqt]\[();colname]};

// timeserie request on non-specific panel w/ no preference on sym seperation
othernosym:{[coln;rqt]
  // return columns with json number type only
  colname:coln cross`msec;
  :nosymresponse[rqt;colname];
 };

// timeserie request on graph panel w/ no preference on sym seperation
graphnosym:{[coln;rqt]
  // return columns with json number type only
  coln:-1_coln where`number=types (0!meta rqt)`t;
  colname:coln cross`msec;
  :nosymresponse[rqt;colname];
 };

// timeserie request on table panel w/ no preference on sym seperation
tablenosym:{[coln;rqt]
  coltype:types -1_(0!meta rqt)`t;
  :tabresponse[coln;coltype;rqt];
 };

// timeserie request on non-specific panel w/ data for one sym returned
othersym:{[args;rqt]
  // specify what columns data to return, taken from drop down input
  outcol:args[2],`msec;
  data:flip value flip?[rqt;enlist(=;sym;enlist args 3);0b;outcol!outcol];
  :.j.j enlist `target`datapoints!(args 3;data);
 };

// timeserie request on graph panel w/ data for each sym returned
graphsym:{[colname;rqt]
  // return columns with json number type only
  syms:`$string ?[rqt;();1b;{x!x}enlist sym]sym;
  // specify what columns data to return, taken from drop down input
  outcol:colname,`msec;
  build:{[outcol;rqt;x;y]data:flip value flip?[rqt;enlist(=;sym;enlist y);0b;outcol!outcol];x,`target`datapoints!(y;data)};
  :.j.j build[outcol;rqt]\[();syms];
 };

// timeserie request on table panel w/ single sym specified
tablesym:{[coln;rqt;symname]
  coltype:types -1_(0!meta rqt)`t;
  // select data for requested sym only
  rqt:?[rqt;enlist(=;sym;enlist symname);0b;()];
  :tabresponse[coln;coltype;rqt];
 };
