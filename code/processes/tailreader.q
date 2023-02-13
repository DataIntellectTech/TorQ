\d .tr
partitiontype:@[value;`partitiontype;`date];                               /-set type of partition (defaults to `date)
gmttime:@[value;`gmttime;1b];                                              /-define whether the process is on gmttime or not
getpartition:@[value;`getpartition;                                        /-function to determine the partition value
  getpartition:{(`date^partitiontype)$(.z.D,.z.d)gmttime}];
currentpartition:@[value;`currentpartition;getpartition[]]
basedir:raze (getenv`KDBTAIL),"/tailer",(string .ds.segmentid),"/"         /-define associated tailer base directory
taildir:`$ basedir,string currentpartition;                                /-define tailDB direction
tailertype:`$first .proc.params[`tailertype]                               /-define tailer to make connection to 
.servers.CONNECTIONS:(.servers.CONNECTIONS union .tr.tailertype)except ` 
.servers.startup[];


\d .ds

getaccess:{[] `location`table xkey update location:.proc.procname,proctype:.proc.proctype from .ds.access};

// function to update the access table in the gateway. Takes the gateway handle as argument
updategw:{[h]neg[h](`.ds.updateaccess;getaccess[])};

\d .
endofday:{[pt]
  /- end of day function that will be triggered by EOD Sorter once TailDB is copied to HDB
  /-  updates partition and loads in next days partition
  .lg.o[`eod;"End of day message received - ",spt:string pt];
  .tr.currentpartition:pt+1;
  reload[];
  }

reload:{
  /- function to define the access table and tailDB dir and then reload both tables
  /- reload is triggered by tailer after savedown occurs
  .tr.taildir:`$ .tr.basedir,string .tr.currentpartition;
  accesstabdir:`$ (string .tr.taildir),"/access";
  .lg.o[`load;"Loading intradayDB"];
  @[.Q.l ;.tr.taildir;{.lg.e[`load;"Failed to load intradayDB with error: ",x]}];
  .lg.o[`load;"intradayDB loaded"];
  .lg.o[`load;"loading accesstable"];
   /- make a connection to the tailer to get the in-memory access table
  tailerhandle:$[count i:.servers.getservers[`proctype;.tr.tailertype;()!();1b;0b];first exec w from i;
    .lg.e[`tailerhandle;"Failed to get a valid handle to respective tailer process"]];
  .ds.access:@[tailerhandle;".ds.access";{.lg.e[`load;"Failed to load accesstable with error: ",x]}];
  .lg.o[`load;"loaded accesstable"];
  load hsym `$.tr.basedir,"sym";
  /- use tailer connection to retrieve stripe mapping for tables
  .ds.tblstripemapping::@[tailerhandle;".ds.tblstripemapping";{.lg.e[`reload;"Failed to load table stripe map from tailer"]}];
  /-update metainfo table for the dataaccessapi
  if[`dataaccess in key .proc.params;.dataaccess.metainfo:.dataaccess.metainfo upsert .checkinputs.getmetainfo[]]
  // update tailreader attributes for .gw.servers table in gateways
  gwhandles:$[count i:.servers.getservers[`proctype;`gateway;()!();1b;0b];exec w from i;.lg.e[`reload;"Unable to retrieve gateway handle(s)"]];
  .async.send[0b;;(`setattributes;.proc.procname;.proc.proctype;.proc.getattributes[])] each neg[gwhandles];
  }
