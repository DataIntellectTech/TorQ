\d .dataaccess

//- utils for reading in config
readtableproperties:{[] enrichtableproperties readcsv[first .proc.getconfigfile"tableproperties.csv";"sssssssss"]};
readcheckinputs:{[] spliltcolumns[readcsv[first .proc.getconfigfile"checkinputs.csv";"sbs*"];`invalidpairs;`]};

readcsv:{[path;types]
  if[not pathexists path:hsym path;'path];
  :(types;1#",")0:path;
 };

pathexists:{[path] path~key path};

spliltcolumns:{[x;columns;types]@[x;columns;spliltandcast;types]};

spliltandcast:{[x;typ]typ$"|"vs/:x};


//- read in meta info
enrichtableproperties:{[tableproperties]
  metainfo:joinmetainfo[getlivemetainfo[tableproperties];gethistmetainfo[tableproperties]];
  tableproperties:union[key metainfo;key tableproperties]#tableproperties: `tablename xkey tableproperties;
  tableproperties:0!tableproperties lj metainfo;
  :`tablename xkey@[tableproperties;`attributecolumn`instrumentcolumn;`sym^];
 };

getmetainfo:{[tableproperties;procfield;procmetafield]
  :raze getmetainfoforproc[procfield;procmetafield]'[key x;get x:tableproperties group tableproperties procfield];
 };

getmetainfoforproc:{[procfield;procmetafield;proctype;tableproperties] 
  :.servers.gethandlebytype[proctype;`any](getmetainforemote;procfield;procmetafield);
 };

gethistmetainfo:getmetainfo[;`proctypehdb;`hdbparams];
getlivemetainfo:getmetainfo[;`proctyperdb;`rdbparams];

getmetainforemote:{[procfield;procmetafield]
  columns:(`tablename;procfield;`partitionfield;procmetafield);
  :1!flip columns!(tables`;.proc.proctype;$[()~key`.Q.pf;`;.Q.pf];([]metainfo:1!/:`columns`types`attributes xcol/:`c`t`a#/:0!/:meta each tables`.;proctype:.proc.proctype));
 };

joinmetainfo:{[livemetainfo;histmetainfo] livemetainfo^histmetainfo};

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
  inputparams[`hdbparams`rdbparams]:tableproperties`hdbparams`rdbparams;
  inputparams[`tableproperties]:`hdbparams`rdbparams _tableproperties;
  :.[inputparams;(`tableproperties;`rollover`offset);.Q.dd[`.dataaccess]];
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
