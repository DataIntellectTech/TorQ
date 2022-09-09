\d .tr
partitiontype:@[value;`partitiontype;`date];                               /-set type of partition (defaults to `date)
gmttime:@[value;`gmttime;1b];                                              /-define whether the process is on gmttime or not
getpartition:@[value;`getpartition;                                        /-function to determine the partition value
  getpartition:{(`date^partitiontype)$(.z.D,.z.d)gmttime}];
currentpartition:@[value;`currentpartition;getpartition[]]
basedir:raze (getenv`KDBTAIL),"/tailer",(string .ds.segmentid),"/"         /-define associated tailer base directory
taildir:`$ basedir,string currentpartition;                                /-define tailDB direction

/- log message if tailreader is started without datastriping activated
if[not .ds.datastripe;.lg.o[`load;"Datastriping is disabled: please verify whether ",(string .proc.procname)," process should be running."]];

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
  .ds.access:@[.Q.l;accesstabdir;{.lg.e[`load;"Failed to load tailer accesstable with error: ",x]}];
  /- select last set of entries from accesstable
  .ds.access:select by table from .ds.access;
  .lg.o[`load;"loaded accesstable"];
  load hsym `$.tr.basedir,"sym"
  }

/- checks to see if the tailDB exists and if so loads in the accestable and tailDB on tailreader startup
$[not ()~ key hsym .tr.taildir;reload[];.lg.o[`load;"No tailDB present for this date"]];
/- logs as INF not ERR as it is expected on first time use that there is no data to load in
