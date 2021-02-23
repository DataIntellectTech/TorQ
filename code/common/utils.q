\d .checkinputs

//- utils for reading in config
readtableproperties:{[tablepropertiepath]
    table:`tablename`proctype xkey readcsv[tablepropertiepath;"sssssuus"];                                                            //read in table from file
  alltable:?[table;enlist(in;`proctype;enlist`all`);0b;()];                                                                         //find any instance of the use "all" or blank for proctype
  table:table,![alltable;();0b;(enlist`proctype)!enlist(enlist `hdb)],![alltable;();0b;(enlist`proctype)!enlist(enlist `rdb)];      //join rdb and hdb entries for any "all" or blank entries 
  table:![table;enlist(in;`proctype;enlist`all`);0b;`symbol$()];                                                                     //remove "all" or blank entries from table
  table:update 00:00 ^ timezone, 00:00 ^ rollovertime from table;
  :update  `date ^ partitionfield from table where proctype<>`rdb;
      };

readcheckinputs:{[checkinputspath] spliltcolumns[readcsv[checkinputspath;"sbs*"];`invalidpairs;`]};

readcsv:{[path;types]
  if[not pathexists path:hsym path;'path];
  :(types;1#",")0:path;
 };

pathexists:{[path] path~key path};

spliltcolumns:{[x;columns;types]@[x;columns;spliltandcast;types]};

spliltandcast:{[x;typ]typ$"|"vs/:x};


//- functions:
//- (i) .dataaccess.getmetainfo - mapping from tablename to metainfo;

getmetainfo:{
  partfield:$[()~key`.Q.pf;`;.Q.pf];
  metainfo:1!/:`columns`types`attributes xcol/:`c`t`a#/:0!/:meta each tables`.;
  :1!flip(`tablename`partfield`metas`proctype)!(tables`.;partfield;metainfo;.proc.proctype);
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
  tableproperties:.checkinputs.tablepropertiesconfig (inputparams`tablename;.proc.proctype);
  metainfo:.dataaccess.metainfo inputparams`tablename;
  inputparams[`metainfo]:metainfo;
  inputparams[`tableproperties]:tableproperties,enlist[`partfield]#metainfo;
  :.[inputparams;(`tableproperties;`getrollover`getpartitionrange);.Q.dd[`.dataaccess]];
 };

//- extract from subdict of inputparams
extractfromsubdict:{[inputparams;subdict;property]
  if[not property in key inputparams subdict;'`$"gettableproperty:invalid property"];
  :inputparams[subdict;property];
 };

gettableproperty:extractfromsubdict[;`tableproperties;];   //- extract from `tableproperties key in inputparams
