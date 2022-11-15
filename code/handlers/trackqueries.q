\d .queries

// flags and variables
enabled:@[value;`enabled;1b]
ignoreuser:@[value;`ignoreuser;1b]
ignoreuserlist:@[value;`ignoreuserlist;(`sort;`gateway;`monitor;`reporter;`segmentedtickerplant;`metrics;`dqc;`dqe;`;.z.u)]
timerval:@[value;`settimer;0D00:00:10]
threshold:@[value;`threshold;50]

// table schema
queries:@[value;`queries;([]starttime:`timestamp$();endtime:`timestamp$();runtime:`long$();user:`symbol$();ip:`int$();prochost:`symbol$();procname:`symbol$();proctype:`symbol$();query:();success:`boolean$())]

// upsert successful query
logquery:{[endp;result;arg;startp] `.queries.queries upsert (startp;endp;`long$.001*endp-startp;.z.u;.z.a;.z.h;.proc.procname;.proc.proctype;arg;1b); result}
// upsert failed query
logqueryerror:{[endp;result;arg;startp] `.queries.queries upsert (startp;endp;`long$.001*endp-startp;.z.u;.z.a;.z.h;.proc.procname;.proc.proctype;arg;0b); 'result}

p1:{.queries.logquery[.proc.cp[];@[x;y;.queries.logqueryerror[.proc.cp[];;y;startp]];y;startp:.proc.cp[]]}
// for ignoring 'internal' messages
p2:{if[ignoreuser; if[any .z.u~/:ignoreuserlist; :x@y]]; p1[x;y]}

if[enabled; .z.pg:(p2).z.pg; .z.ps:(p2).z.ps;];

// functionality to save down tables to disk
savedown:{[dir;tabname;pt]
 pth:` sv .Q.par[dir;pt;tabname],`;
 numrows: count .queries.queries;
 .lg.o[`save;"saving ",(string numrows)," rows of " (string tabname)," data to partition ", string pt]
 err:{[e].lg.e[`savedata;"Failed to save client query data to disk : ",e];'e};
 if[numrows > 0;.[upsert;(pth;.Q.en[dir;.save.manipulate[tabname;.queries.queries]]);err];];
 .queries.queries:0#.queries.queries;
 };

rowcheck:{[dir;tabname;pt]
 countvalue:count .queries.queries;
 if[countvalue > .queries.threshold; savedown[dir;tabname;pt]];
 };

// timers set up to periodically save down to disk
if[enabled;
    settimers:{
     .timer.repeat[.proc.cp[];0Wp;0D00:00:10;(`.queries.rowcheck;`:data/hdb;`clientqueries;.z.d);"save client query data to disk"];
     .timer.repeat[.proc.cp[];0Wp;.queries.timerval;(`.queries.savedown;`:data/hdb;`clientqueries;.z.d);"save client query data to disk"];
      };
    .queries.settimers[];];
