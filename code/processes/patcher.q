// if stack is running on multiple hosts 
// each host should be running its own patcher proc
.patch.multihosts: @[value;`.patch.multihosts;1b];

// table to store the function and version number
functionversion:([]time:`timestamp$();proctype:`symbol$();procname:`symbol$();function:`symbol$();oldversion:();newversion:())

// apply a patch to a process
// if proctype or procname ~ `, then it's applied to all processes 
applypatchtohandle:{[proctype;procname;handle;function;newversion]
 .lg.o[`applypatch;"applying function patch for ",(string function)," to ",.Q.s1`proctype`procname!(proctype;procname)];
 old:handle({.[{(1b;.patch.setdef[x;y])};(x;y);{(0b;(::))}]};function;newversion);
 // patching will fail if the process doesn't have .patch.setdef defined
 // that should be fine though because if it doesn't have that defined, it also wont recover on restart
 // so this way it will not end up in an inconsistent state
 $[first old;
  [.lg.o[`applypatch;"patch successfully applied"];
   `functionversion upsert (.proc.cp[];proctype;procname;function;last old;newversion)];
  .lg.o[`applypatch;"failed to apply patch"]];
 }

// function for USER to apply patches to stack
applypatch:{[nameortype;val;func;newversion]
 patchlocal[nameortype;val;func;newversion];      // apply patches to procs on current host
 if[.patch.multihosts;
  updatepatchers[nameortype;val;func;newversion]  // send patch update to other patchers if running on multiple hosts
  ]
 }

// applies patch to procs running on current host
patchlocal:{[nameortype;val;func;newversion]
 // get the list of connections
 if[not nameortype in ``proctype`procname; '"nameortype has to be one of ``proctype`procname"];
 if[not -11h=type func;'"func must be of type symbol"];
 c:.servers.getservers[nameortype;val;()!();1b;0b];
 
 // filters out processes running on different hosts
 c: c where 0 = first each (1_' exec string hpup from c) ss \: string .z.h;
 
 // send patches to necessary local procs and write patches to disk
 $[count c;
  [c:update function:func,newv:(count c)#newversion from c;
   applypatchtohandle .' flip value flip select proctype,procname,w,function,newv from c where .dotz.liveh w;
   .lg.o[`patchlocal;"writing patches to disk"];
   writefunctionversion[.patch.versiontab];
  ];
   .lg.o["could not get local handle to required process(es)"]
  ]
 }

// sends patch updates to all other patchers (useful if running on multiple hosts)
updatepatchers:{[nameortype;val;func;newversion]
 .lg.o[`updatepatchers;"obtaining handles of other patcher procs"];
 patcherprocs: select from .servers.SERVERS where proctype=.proc.proctype, procname<>.proc.procname, not null w;
 patcherhandles: exec w from patcherprocs;

 c:.servers.getservers[nameortype;val;()!();1b;0b];
 hoststopatch: extracthosts[c];             //  hosts running processes that need patching
 patcherhosts: extracthosts[patcherprocs];  //  connected hosts running a patcher proc

 // check that the hosts of all procs to be patched are running a connected patcher process 
 if[not all hoststopatch in patcherhosts,.z.h;
  .lg.e[`updatepatchers;"the following hosts do not have patchers running: ", "," sv string hoststopatch where hoststopatch in patcherhosts]];

 // send messages to patchers if handles exist
 $[count patcherhandles;
  [.lg.o[`updatepatchers;"sending patch updates to other patchers"];
   (neg patcherhandles) @\: (`patchlocal;nameortype;val;func;newversion);
  ];
   .lg.o[`updatepatchers;"no patcher handles found, patch updates not sent out"]
  ]
 }

// returns hostname of procs, given .servers.SERVERS or subset
extracthosts:{[x]
 distinct {[y] `$first ":" vs y} each 1_' string exec hpup from x
 }

rollback:{[pname;func;versiontime]
 if[not 1=count v:select from functionversion where procname=pname,function=func,time=versiontime;
  '"could not find specified version"];
 // get the handle
 applypatch[`procname;pname;func;first exec oldversion from v];
 }

// write the table to disk
writefunctionversion:{
 if[null x;
  .lg.o[`patcher;"functionversion table set to null- not saving"];
  :()];
 .lg.o[`saveversiontab;"saving functionversion to ",string .patch.versiontab];
 .patch.versiontab set functionversion;
 }

// read in the latest version from disk
`functionversion upsert .patch.getversiontab .patch.versiontab;

// connect to everything
.servers.CONNECTIONS:`ALL
.servers.startup[]

.z.exit:{[f;x] f@x; 
 writefunctionversion[.patch.versiontab]}@[value;`.z.exit;{{[x]}}]

\
// apply patches to all processes
applypatch[`;`;`.t1.test;{x+y}]
// apply patches just to hdbs
applypatch[`proctype;`hdb;`.t1.test;{x+y}]
// or specific hdb
applypatch[`procname;`hdb1;`.t1.test;{x+8}]
rollback[`rdb1;`.t1.test; .. version time ..]
// this should fail
rollback[`rdb1;`.t1.test1; .. version time ..]
