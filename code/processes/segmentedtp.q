// Segmented TP process
// Contains all TP functionality with additional flexibility
// Configurable logging and subscriptions

.proc.loadf[getenv[`KDBCODE],"/processes/tickerplant.q"];
.proc.loadf[getenv[`KDBCODE],"/common/os.q"];
.u.j:.u.i:0

.proc.loadf[raze .proc.params`stpconfig]

\d .stp 

dldir:` 

createdld:{[name;date] 
  .os.md dldir::hsym`$(,/)"stplogs/",string name,date}; 

logname.tabperiod:{[dir;tab;logfreq;dailyadj]
  ` sv(hsym dir;`$string[tab],ssr[;;""]/[-13_string logfreq xbar .z.p+dailyadj;":.D"])} 

logname.none:{[dir;tab;logfreq;dailyadj]}

logname.custom:{[dir;tab;logfreq;dailyadj]}

t:.u.t

currlog:([tbl:`symbol$()]logname:`symbol$();handle:`int$()); 
 
openlog:{[multilog;dir;tab;logfreq;dailyadj] 
  lname:logname[multilog][dir;tab;logfreq;dailyadj]; 
  if[not type key lname;.[lname;();:;()]]; 
  h:hopen lname;
  `.stp.currlog upsert (tab;lname;h); 
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
endp:{(neg union/[w[;;0]])@\:(`.u.endp;x;y)} 

endofperiod:{ 
  endp . .eodtime`p`nextperiod;  
  if[.z.p>.eodtime.nextperiod:.eodtime.getperiod[.z.p];system"t 0";'"next period is in the past"]; 
  {if[not null currlog[x;`handle];rolllog[multilog;dldir;x;multilogperiod;0D01]]}each t; 
 }; 

endofday:{
  end d;
  d+:1;icounts::(`symbol$())!0#0,();
  if[.z.p>.eodtime.nextroll:.eodtime.getroll[.z.p];system"t 0";'"next roll is in the past"];
  .eodtime.dailyadj:.eodtime.getdailyadjustment[];
  closelog each t;
  init[];  
 }  

end:.u.end

ts:{ 
  if[.eodtime.nextperiod < x; endofperiod[]]; 
  if[.eodtime.nextroll < x;if[d<("d"$x)-1;system"t 0";'"more than one day?"];endofday[]]; 
 }; 

/pub:.u.pub;

pub:{[t;x]
  subgroups:flip (.u.w[t;;0]@/:value g;key g:group .u.w[t;;1]);
  {[t;x;w] if[count x:sel[x]w 1;-25!(w 0;(`upd;t;x))] }[t;x] each subgroups
 };

i:.u.i;
j:.u.j;
icounts:.u.icounts;
jcounts:.u.jcounts;
d:.u.d;
sel:.u.sel;

.z.ts:{
  pub'[t;value each t];
  @[`.;t;@[;`sym;`g#]0#];
  i::j;icounts::jcounts;
  ts .z.p
 };

init:{
  createdld[`database;.z.D];
  openlog[multilog;dldir;;multilogperiod;0D01]each t;
 }

\d .

.u.upd:{[t;x]
 if[not -12=type first first x;
     if[.z.p>.eodtime.nextroll;.z.ts[]
         ];
     /a:"n"$a;
     a:.z.p+.eodtime.dailyadj;
     x:$[0>type first x;
         a,x;
         (enlist(count first x)#a),x
         ]
    ];
 t insert x;
 .stp.jcounts[t]+::count first x;
 if[t in key .stp.currlog;
   w:.stp.whichlog[t;x];
   w[`handle] enlist(`upd;t;w[`data])
 ];
 //multiple updates?
 }

.eodtime.nextperiod:.stp.multilogperiod xbar .z.p+2*.stp.multilogperiod

.eodtime.getperiod:{[p]
  z:.eodtime.rolltimeoffset-.eodtime.adjtime[p];
  z:`timespan$(mod) . "j"$z, 1D;
  .eodtime.nextperiod+$[z <= p;z+.stp.multilogperiod;z]
 }

.stp.init[]
