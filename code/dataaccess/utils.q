\d .dataaccess

//- utils for reading in config
readtableproperties:{[tablepropertiepath] `tablename xkey readcsv[tablepropertiepath;"sssssssss"]};
readcheckinputs:{[checkinputspath] spliltcolumns[readcsv[checkinputspath;"sbs*"];`invalidpairs;`]};

readcsv:{[path;types]
  if[not pathexists path:hsym path;'path];
  :(types;1#",")0:path;
 };

pathexists:{[path] path~key path};

spliltcolumns:{[x;columns;types]@[x;columns;spliltandcast;types]};

spliltandcast:{[x;typ]typ$"|"vs/:x};


//- functions to:
//- (i) .dataaccess.procmetainfo - keeps track of metas for each connected proc (.z.pc will drop from this table)
//- (ii) .dataaccess.metainfo - mapping from tablename to metainfo (derived from .dataaccess.procmetainfo);
getprocmetainfo:{[connectiontab] `procname`proctype xkey .dataaccess.geteachprocmetainfo each .dataaccess.joinprocfields connectiontab};
getmetainfo:{[procmetainfo] exec uj/[metainfo]from procmetainfo};

joinprocfields:{[connectiontab]
  procfieldmap:exec([]proctype:proctypehdb,proctyperdb)!([]procfield:(,)[count[proctypehdb]#`proctypehdb;count[proctyperdb]#`proctyperdb])from .dataaccess.tablepropertiesconfig;
  :#[`procname`proctype`w;connectiontab]lj update procmetafield:`hdbparams`rdbparams `proctypehdb`proctyperdb?procfield from procfieldmap;
 };

geteachprocmetainfo:{[connectiondict]`procfield`procmetafield _update metainfo:w(.dataaccess.getprocmetainforemote;procfield;procmetafield)from connectiondict}; 

getprocmetainforemote:{[procfield;procmetafield]
  partitionfield:$[()~key`.Q.pf;`;.Q.pf];
  metainfo:([]metainfo:1!/:`columns`types`attributes xcol/:`c`t`a#/:0!/:meta each tables`.;proctype:.proc.proctype);
  if[`~partitionfield;:1!flip(`tablename;procmetafield)!(tables`;metainfo)];
  if[not`~partitionfield;:1!flip(`tablename;`partitionfield;procmetafield)!(tables`;partitionfield;metainfo)];
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

//- join table properties for a given table onto input params
jointableproperties:{[inputparams]
  tableproperties:.dataaccess.tablepropertiesconfig inputparams`tablename;
  metainfo:.dataaccess.metainfo inputparams`tablename;
  inputparams[`hdbparams`rdbparams]:metainfo`hdbparams`rdbparams;
  inputparams[`tableproperties]:tableproperties,enlist[`partitionfield]#metainfo;
  :.[inputparams;(`tableproperties;`getrollover`getpartitionrange);.Q.dd[`.dataaccess]];
 };

//- extract from subdict of inputparams
extractfromsubdict:{[inputparams;subdict;property]
  if[not property in key inputparams subdict;`$"gettableproperty:invalid property"];
  :inputparams[subdict,property];
 };

gettableproperty:extractfromsubdict[;`tableproperties;];   //- extract from `tableproperties key in inputparams
gethdbparams:extractfromsubdict[;`hdbparams;];             //- extract from `hdbparams key in inputparams
getrdbparams:extractfromsubdict[;`rdbparams;];             //- extract from `rdbparams key in inputparams
