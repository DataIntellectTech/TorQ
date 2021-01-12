// master mode sends patch updates to any slave patchers (patchers with mastermode off) running
// useful when stack is running on multiple hosts with slaves on different hosts to master
.patch.mastermode: @[value;`.patch.mastermode;1b]
.patch.patchcurrhost: @[value;`.patch.patchcurrhost;1b]  // only send patch updates to processes running on same host as patcher

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

applypatch:{[nameortype;val;func;newversion]
 // get the list of connections
 if[not nameortype in ``proctype`procname; '"nameortype has to be one of ``proctype`procname"];
 if[not -11h=type func;'"func must be of type symbol"];
 c:.servers.getservers[nameortype;val;()!();1b;0b];
 if[.patch.patchcurrhost;
  // filters out processes running on different hosts
  c: c where 0 = first each (1_' exec string hpup from c) ss \: string .z.h];
 if[0=count c;'"could not get handle to required process(es)"];
 c:update function:func,newv:(count c)#newversion from c;
 applypatchtohandle .' flip value flip select proctype,procname,w,function,newv from c where .dotz.liveh w;
 writefunctionversion[.patch.versiontab];
 if[.patch.mastermode;
  .lg.o[`applypatch;"obtaining slave patcher handles"];
  patcherhandles: exec w from .servers.SERVERS where proctype=.proc.proctype, procname<>.proc.procname, not null w;
  $[count patcherhandles;
  [.lg.o[`applypatch;"sending patch message to slave patchers"];
   patcherhandles @\: (`applypatch;nameortype;val;func;newversion);
  ];
   .lg.o[`applypatch;"no slave handles found, patch updates not send to slaves"]
   ]
  ]
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
