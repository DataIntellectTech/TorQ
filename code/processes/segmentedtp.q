// Segmented TP process
// Contains all TP functionality with additional flexibility
// Configurable logging and subscriptions

.proc.loadf[getenv[`KDBCODE],"/processes/tickerplant.q"];
.proc.loadf[getenv[`KDBCODE],"/common/os.q"];
.u.j:.u.i:0

.proc.loadf[raze .proc.params`stpconfig]

\d .stp 

createdld:{[name;date] 
  .os.md dldir::hsym`$(,/)"stplogs/",string name,date}; 

logname.tabperiod:{[dir;tab;logfreq;dailyadj]
  ` sv(hsym dir;`$string[tab],ssr[;;""]/[-13_string logfreq xbar .z.p+dailyadj;":.D"])} 

logname.none:{[dir;tab;logfreq;dailyadj]}

logname.custom:{[dir;tab;logfreq;dailyadj]}

t:.u.t

subrequestall:.u.w

subrequestfiltered:([tabname:`$()]handle:`int$();filts:`$();columns:`$())

currlog:([tbl:`symbol$()]logname:`symbol$();handle:`int$()); 
 
openlog:{[multilog;dir;tab;logfreq;dailyadj] 
  lname:logname[multilog][dir;tab;logfreq;dailyadj]; 
  if[not type key lname;.[lname;();:;()]]; 
  h:hopen lname;
  `.stp.currlog upsert (tab;lname;h); 
  }; 

openlogerr:{[dir]
  lname:` sv(hsym dir;`$"errdatabase",string .z.d);
  if[not type key lname;.[lname;();:;()]];
  h:hopen lname;
  `.stp.currlog upsert (`err;lname;h);
  };

badmsg:{[e;t;x]
  .lg.o[`upd;"Bad message received, error: ",e];
  w:.stp.whichlog[`err;x];
  w[`handle] enlist(`upd;t;w[`data]);
  };

whichlog:{[t;x] currlog[t],enlist[`data]!enlist x} 

closelog:{[tab] 
  if[null h:currlog[tab;`handle];.lg.o[`closelog;"No open handle to log file"];:()]; 
  hclose h;  
  update handle:0N from `.stp.currlog where tbl=tab; 
 };  
 
rolllog:{[multilog;dir;tab;logfreq;dailyadj] 
  closelog[tab]; 
  openlog[multilog;dir;tab;logfreq;dailyadj]; 
 }; 

// assumes .eodtime.getperiod and .eodtime.nextperiod have been defined appropriately in code/common/eodtime.q 

// endp here assumes that .u.endp has been defined on the client side – perhaps a simple logging function 
endp:{(neg union/[subrequestall[;;0]])@\:(`.u.endp;x;y)} 

endofperiod:{ 
  endp . .eodtime`p`nextperiod;
  .eodtime.currperiod:.eodtime.nextperiod;
  if[.z.p>.eodtime.nextperiod:.eodtime.getperiod[.z.P];system"t 0";'"next period is in the past"];
  {if[not null currlog[x;`handle];rolllog[multilog;dldir;x;multilogperiod;0D01]]}each t; 
 };

endofday:{
  end d;
  d+:1;icounts::(`symbol$())!0#0,();
  if[.z.p>.eodtime.nextroll:.eodtime.getroll[.z.p];system"t 0";'"next roll is in the past"];
  .eodtime.dailyadj:.eodtime.getdailyadjustment[];
  closelog each t;
  init[];  
 };

end:.u.end

ts:{ 
  if[.eodtime.nextperiod < x; endofperiod[]]; 
  if[.eodtime.nextroll < x;if[d<("d"$x)-1;system"t 0";'"more than one day?"];endofday[]]; 
 }; 

suball:{
  del[x].z.w;
  :add[x];
 }

subfiltered:{[x;y]
  /delfiltered
  :addfiltered[x;y];
 }

add:{
  if[not (count .stp.subrequestall x)>i:.stp.subrequestall[x;]?.z.w;
    .stp.subrequestall[x],:.z.w];
  (x;$[99=type v:value x;sel[v]`;0#v])}

addfiltered:{[x;y]
  if[not .z.w in .stp.subrequestfiltered[x]`handle;
    @[`.stp.subrequestfiltered;x;:;(enlist[`handle]!enlist .z.w),y[x]]];
  (x;$[99=type v:value x;sel[v]`;0#v])}

pub:{[t;x]
 /  subgroups:flip (.u.w[t;;0]@/:value g;key g:group .u.w[t;;1]);
 /  {[t;x;w] if[count x:sel[x]w 1;-25!(w 0;(`upd;t;x))] }[t;x] each subgroups
  if[count x:sel[x]`;
    if[count h:.stp.subrequestall[t];-25!(h;(`upd;t;x))];
    if[t in key .stp.subrequestfiltered;
      w:.stp.subrequestfiltered[t];
      query:"select ",string[w`columns]," from ",string[t]," where ",string[w`filts];
      x:value query;
      -25!((),w`handle;(`upd;t;x))
    ]
  ]
 };

closesub:{[h]
  @[`.stp.subrequest;key .stp.subrequestall;except;h];
  delete from  `.stp.subrequestfiltered where handle=h;
 };

i:.u.i;
j:.u.j;
icounts:.u.icounts;
jcounts:.u.jcounts;
d:.u.d;
sel:.u.sel;
del:.u.del;

.z.ts:{
  pub'[t;value each t];
  @[`.;t;@[;`sym;`g#]0#];
  i::j;icounts::jcounts;
  ts .z.p
 };

init:{
  createdld[`database;.z.d];
  openlog[multilog;dldir;;0D00:00:00.001;0D00]each t;
 }

\d .

updtab:.stp.t!(count .stp.t)#{(enlist(count first x)#.z.p+.eodtime.dailyadj),x}

.u.upd:{[t;x]
  if[not -12=type first first x;
    if[.z.p>.eodtime.nextroll;.z.ts[]];
    x:updtab[t]@x
  ];
  t insert x;
  .stp.jcounts[t]+::count first x;
  if[t in key .stp.currlog;
    w:.stp.whichlog[t;x];
    w[`handle] enlist(`upd;t;w[`data])
  ];
  //multiple updates?
 }

.u.sub:{[x;y]
  if[not x in .stp.t;'x];
  if[y~`;:.stp.suball[x]];
  if[not y~`;:.stp.subfiltered[x;y]]
 }

.z.pc:{[f;x] f@x; .stp.closesub x}@[value;`.z.pc;{{}}]

.eodtime.currperiod:0D01 xbar .z.p
.eodtime.nextperiod:.eodtime.currperiod+.stp.multilogperiod

.eodtime.getperiod:{[p]
  z:.eodtime.rolltimeoffset-.eodtime.adjtime[p];
  z:`timespan$(mod) . "j"$z, 1D;
  .eodtime.nextperiod+$[z <= p;z+.stp.multilogperiod;z]
 }

.stp.init[]

if[.stp.errmode;
  .stp.openlogerr[.stp.dldir];
  .stp.upd:.u.upd;
  .u.upd:{[t;x] .[.stp.upd;(t;x);{.stp.badmsg[x;y;z]}[;t;x]]}
  ]

