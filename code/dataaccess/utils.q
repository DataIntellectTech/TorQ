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
  keycols:`proctype`tablename;
  metainfo:keycols xkey .dataaccess.getmetainfo[];
  tableproperties:union[key metainfo;key tableproperties]#tableproperties:keycols xkey tableproperties;
  tableproperties:0!tableproperties lj metainfo;
  :@[tableproperties;`attributecolumn`instrumentcolumn;`sym^];
 };

getmetainfo:{
  metas:meta each tables`;
  metas:flip each`columns`types`attributes xcol/:`c`t`a#/:0!/:metas;
  metas:@[metas;`proctype`tablename;:;(.proc.proctype;tables`)];
  :`proctype`tablename xcols metas;
 };
  
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

//- extract table property from .dataaccess.tablepropertiesconfig
//- atm .dataaccess.tablepropertiesconfig has separate rows for the rdb/hdb - use `any to retieve whichever comes first
gettableproperty:{[tn;proctyp;property]
  tableproperties:select from tablepropertiesconfig where tablename=tn;
  if[not property in cols tableproperties;'`$"gettableproperty:invalid property"];
  if[not proctyp=`any;tableproperties:select from tableproperties where proctype=proctyp];
  :tableproperties[0;property];
 };
