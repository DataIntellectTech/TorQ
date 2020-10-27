\d .dataaccess

//- utils for reading in config
readtableproperties:{[path;types] readcsv[path;types]};
readcheckinputs:{[path;types] spliltcolumns[readcsv[path;types];`invalidpairs;`]};

readcsv:{[path;types]
  if[not pathexists path:hsym path;'path];
  :(types;1#",")0:path;
 };

pathexists:{[path] path~key path};

spliltcolumns:{[x;columns;types]@[x;columns;spliltandcast;types]};

spliltandcast:{[x;typ]typ$"|"vs/:x};


//- read in meta info
enrichtableproperties:{[tableproperties]
  //- in future this will loop through a list of processes - for now just take meta from current process
  metainfo:`tablename xkey joinmetainfo[getlivemetainfo[];gethistmetainfo[]];
  tableproperties:union[key metainfo;key tableproperties]#tableproperties: `tablename xkey tableproperties;
  tableproperties:0!tableproperties lj metainfo;
  :`tablename xkey@[tableproperties;`attributecolumn`instrumentcolumn;`sym^];
 };

gethistmetainfo:{[]
  x:0!update proctypehdb:.proc.proctype,proctyperdb:`,partitionfield:.dataaccess.getpartitiontype[]from getmetainfo[];
  newcols:@[cols x;cols[x]?`tablemeta;:;`hdbtablemeta];
  :`tablename xkey newcols xcol x;
 };

getlivemetainfo:{[]
  //x:0!update proctypehdb:`,proctyperdb:.proc.proctype from getmetainfo[];
  x:0!update proctypehdb:`,proctyperdb:`$ssr[string .proc.proctype;"hdb";"rdb"],tablemeta:![;enlist(=;`columns;1#`date);0b;`symbol$()]each tablemeta from .dataaccess.getmetainfo[];  //temp code
  newcols:@[cols x;cols[x]?`tablemeta;:;`rdbtablemeta];
  :`tablename xkey newcols xcol x;
 };

getmetainfo:{[]
  metas:meta each tables`.;
  metas:([]tablemeta:1!/:`columns`types`attributes xcol/:`c`t`a#/:0!/:metas);
  :([]tablename:tables`),'metas;
 };

joinmetainfo:{[livemetainfo;histmetainfo] `hdbtablemeta`rdbtablemeta _/:update metainfo:([]hdb:hdbtablemeta;rdb:rdbtablemeta)from livemetainfo^histmetainfo};

getpartitiontype:{[]$[()~key`.Q.pf;`;.Q.pf]};

//- misc utils
getvalidparams:{[]checkinputsconfig`parameter};
getrequiredparams:{[]exec parameter from checkinputsconfig where required};

//- formatstring - inserts text into strings
//- formatstring["I have {} apples and {} oranges";10] - "I have 10 apples and 10 oranges"
//- formatstring["I have {n1} apples and {n2} oranges";`n1`n2!10 20] - "I have 10 apples and 20 oranges"
//- params can be type (+/-)1-19, otherwise ignored
formatstring:{[str;params]
  if[not 99h~type params;params:enlist[`]!enlist[params]];
  if[not 11h~type key params;:params];
  params:where[abs[type each params]within 1 19]#params;
  params:-1_/:.Q.s each params;
  ssr/[str;"{",'string[key params],'"}";get params]
 };

//- join table properties for a given table onto input params
jointableproperties:{[inputparams]
  tableproperties:.dataaccess.tablepropertiesconfig inputparams`tablename;
  inputparams[`hdbparams]:exec proctype:proctypehdb,metainfo:metainfo`hdb from tableproperties;
  inputparams[`rdbparams]:exec proctype:proctyperdb,metainfo:metainfo`rdb from tableproperties;
  inputparams[`tableproperties]:`proctypehdb`proctyperdb`metainfo _tableproperties;
  inputparams:.[inputparams;(`tableproperties;`rollover`offset);.Q.dd[`.dataaccess]];
  :inputparams;
 };

//- extract from subdict of inputparams
extractfromsubdict:{[inputparams;subdict;property]
  if[not property in key inputparams subdict;'`$"gettableproperty:invalid property"];
  :inputparams[subdict;property];
 };

gettableproperty:extractfromsubdict[;`tableproperties;];   //- extract from `tableproperties key in inputparams
gethdbparams:extractfromsubdict[;`hdbparams;];             //- extract from `hdbparams key in inputparams
getrdbparams:extractfromsubdict[;`rdbparams;];             //- extract from `rdbparams key in inputparams


//- rollover times between rdb and hdb
.dataaccess.defaultrollover:{[].z.d+0D};

//- offset times for non-primary time columns
.dataaccess.defaultoffset:{[timecolumn;primarytimecolumn;daterange]@[daterange;1;+;not timecolumn~primarytimecolumn]};
