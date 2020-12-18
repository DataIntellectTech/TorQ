\d .checkinputs

//- checkinputs is the main function called by getdata - it checks:
// (i) input format
// (ii) whether any parameter pairs clash
// (iii) parameter specific checks
// The input dict accumulates some additional table information/inferred information
checkinputs:{[dict]
  dict:checkdictionary dict;
  dict:checkinvalidcombinations dict;
  dict:checkeachparam[dict;1b];
  dict:filldefaulttimecolumn dict;
  dict:checkeachparam[dict;0b];
  :dict;
 };

checkdictionary:{[dict]
  if[not isdictionary dict;'`$"Input parameter must be a dictionary"];
  if[not checkkeytype dict;'`$"keys must be of type 11h"];
  if[not checkrequiredparams dict;'`$.dataaccess.formatstring["required params missing:{}";.dataaccess.getrequiredparams[]except key dict]];
  if[not checkparamnames dict;'`$.dataaccess.formatstring["invalid param names:{}";key[dict]except .dataaccess.getvalidparams[]]];
  :dict;
 };

isdictionary:{[dict]99h~type dict};
checkkeytype:{[dict]11h~type key dict};
checkrequiredparams:{[dict]all .dataaccess.getrequiredparams[]in key dict};
checkparamnames:{[dict]all key[dict]in .dataaccess.getvalidparams[]};

filldefaulttimecolumn:{[dict]
  defaulttimecolumn:`time^.dataaccess.gettableproperty[dict;`primarytimecolumn];
  if[`timecolumn in key dict;:dict];
  if[not`timecolumn in key dict;:@[dict;`timecolumn;:;defaulttimecolumn]];
 };

checkinvalidcombinations:{[dict]
  parameters:key dict;
  xinvalidpairs:select parameter,invalidpairs:invalidpairs inter\:parameters from .dataaccess.checkinputsconfig where parameter in parameters;
  xinvalidpairs:select from xinvalidpairs where 0<>count'[invalidpairs];
  if[0=count xinvalidpairs;:dict];
  checkeachpair'[xinvalidpairs];
 };

checkeachpair:{[invalidpair]'`$.dataaccess.formatstring["parameter:{parameter} cannot be used in combination with parameter(s):{invalidpairs}";invalidpair]};

//- loop through input parameters
//- execute parameter specific checks
checkeachparam:{[dict;isrequired]
  config:select from .dataaccess.checkinputsconfig where parameter in key dict,required=isrequired;
  :checkparam/[dict;config];
 };

//- extract parameter specific function from confing - to check the input
checkparam:{[dict;config] config[`checkfunction][dict;config`parameter]};

//- generic function to takes in an atom/list of valid types and compare it against input types 
checktype:{[validtypes;dict;parameter]
  inputtype:type dict parameter;
  if[not any validtypes~\:inputtype;'`$.dataaccess.formatstring["{parameter} input type incorrect - valid type(s):{validtypes} - input type:{inputtype}";`parameter`validtypes`inputtype!(parameter;validtypes;inputtype)]];
  :dict;
 };

//- check if table exists + param is of type symbol
//- if `tablename is in the correct format - we can then join on table properties from config
isvalidtable:{[dict;parameter]
  dict:issymbol[dict;parameter];
  dict:tableexists[dict;parameter];
  :.dataaccess.jointableproperties dict;
 };

tableexists:{[dict;parameter]
  if[not dict[`tablename]in exec tablename from .dataaccess.tablepropertiesconfig;'`$.dataaccess.formatstring["table:{tablename} doesn't exist";dict]];
  :dict;
 };

//- run checks to see if input columns exist
checkcolumnsexist:{[dict;parameter]
  dict:allsymbols[dict;parameter];
  :columnsexist[dict;parameter;dict parameter];
 };

//- for a given list of columns check names against metas
columnsexist:{[dict;parameter;columns]
  dict:checkinvalidcolumns[dict;parameter;columns];
  :dict;
 };

//- return error for any invalid columns
checkinvalidcolumns:{[dict;parameter;columns]
  validcolumns:exec columns from dict[`metainfo;`metas];
  invalidcolumns:except[(),columns;validcolumns];
  errorparams:dict,`parameter`proctype`validcolumns`invalidcolumns!(parameter;dict[`metainfo;`proctype];validcolumns;invalidcolumns);
  if[count invalidcolumns;'`$.dataaccess.formatstring["parameter:{parameter} - table:{tablename} on process:{proctype} doesn't contain:{invalidcolumns} - validcolumns:{validcolumns}";errorparams]];
  :dict;
 };

//- check starttime/endtime values are of valid type
checktimetype:{[dict;parameter]:checktype[-12 -14 -15h;dict;parameter]};

//- check param is of type symbol
//- check starttime<=endtime
//- use rollover function to split rdb/hdb range (rollover is the time before which data is in the rdb)
//- check the column exists for the given table
//- check the given `timecolumn has valid type (e.g don't pass timecolumn:`sym)
checktimecolumn:{[dict;parameter]
  dict:issymbol[dict;parameter];
  dict:checktimeorder[dict;parameter];
  dict:extracttime dict;
  dict:columnsexist[dict;parameter;dict`timecolumn];
  :checkcolumntype[dict;parameter;dict`timecolumn;-12 -14 -15h];
 };

checktimeorder:{[dict;parameter]
  if[dict[`starttime]>dict`endtime;'`$"starttime>endtime"];
  :dict;
 };

extracttime:{[dict]
  :update metainfo:(metainfo,`starttime`endtime!(starttime;endtime))from dict;
 };

//- check type of column given by `timecolumn
//- check against table metas
checkcolumntype:{[dict;parameter;column;validtypes]
  dict:checkinvalidcolumntype[dict;parameter;column;validtypes];
  :dict;
 };

checkinvalidcolumntype:{[dict;parameter;column;validtypes]
  inputtype:convertstringtype dict[`metainfo;`metas][column;`types];
  errorparams:@[dict;`parameter`column`validtypes`inputtype;:;(parameter;column;validtypes;inputtype)];
  if[not any inputtype~/:validtypes;'`$.dataaccess.formatstring["parameter:{parameter} - column:{column} in table:{tablename} is of type:{inputtype}, validtypes:{validtypes}";errorparams]];
  :dict;
 };

convertstringtype:{[x]`short$(-1 1)[x~upper x]*.Q.t?lower x};

issymbol:{[dict;parameter]:checktype[-11h;dict;parameter]};
allsymbols:{[dict;parameter]:checktype[11 -11h;dict;parameter]};

//- should be of the format: `last`max`wavg!(`time;`bidprice`askprice;(`asksize`askprice;`bidsize`bidprice))
//- returns columns: `lastMid`maxBidprice`maxAskprice`wavgAsksizeAskprice`wavgBidsizeBidprice
checkaggregations:{[dict;parameter]
  example:"`last`max`wavg!(`time;`bidprice`askprice;(`asksize`askprice;`bidsize`bidprice))";
  input:dict parameter;
  if[not 99h~type input;'`$"aggregations parameter must be of type dict - example:",example];
  if[not 11h~abs type key input;'`$"aggregations parameter key must be of type 11h - example:",example];
  if[not all 11h~/:abs raze type''[get input];'`$"aggregations parameter values must be of type symbol - example:",example];
  columns:distinct(raze/)get input;
  dict:columnsexist[dict;parameter;columns];
  validfuncs:`avg`cor`count`cov`dev`distinct`first`last`max`med`min`prd`sum`var`wavg`wsum; //- these functions support 'map reduce' - in future custom functions could be added
  inputfuncs:key input;
  if[any not inputfuncs in validfuncs;'`$.dataaccess.formatstring["invalid functions passed to aggregation parameter:{}";inputfuncs except validfuncs]];
  :dict;
 };

//- check for a list of length 3
//- (timecolumn - symbol;time bar size - int/long;see key timebarmap)
checktimebar:{[dict;parameter]
  input:dict parameter;
  if[not(3=count input)&0h~type input;'`$"timebar parameter must be a list of length 3"];
  input:`timecol`size`bucket!input;
  if[not -11h~type input`timecol;'`$"first argument of timebar must be have type -11h"];
  dict:columnsexist[dict;parameter;input`timecol];
  dict:checkcolumntype[dict;parameter;input`timecol;-12 -13 -14 -15 -16 -17 -18 -19h];
  if[not any -6 -7h~\:type input`size;'`$"type of the second argument of timebar must be either -6h or -7h"];
  if[not -11h~type input`bucket;'`$"third argument of timebar must be of type -11h"];
  if[not input[`bucket]in key timebarmap;'`$.dataaccess.formatstring["third argument of timebar must be one of:{validargs}";enlist[`validargs]!enlist key timebarmap]];
  :dict;
 };

timebarmap:`nanosecond`second`minute`hour`day!1 1000000000 60000000000 3600000000000 86400000000000;

checkfilterformat:{[dict;parameter]
  input:dict parameter;
  allowedops:(<;>;<>;in;within;like;<=;>=;=;~;not);
  allowednot:(in;within;like);
  if[not 99h~type input;'`$"filter parameter must be a dictionary - e.g. `sym`price`size!(enlist(=;`AAPL);((within;80 100);(not in;81 83 85));enlist(>;50))"];
  if[not all 0h=raze type''[get input];'"singular conditions must be enlisted - e.g. `sym`price!(enlist(=;`AAPL);((within;80 100);(not in;81 83 85)))"]; 
  nots:where(~:)~/:ops:first each filters:raze get input;
  notfilters:@\:[;1]filters nots;
  if[not all ops in allowedops;'"allowed operators are: =, <, >, <>, <=, >=, in, within, like. The last 3 may be prefaced with 'not' e.g. (not;within;80 100)"];
  if[not all notfilters in allowednot;'"not may only preface the keywords 'in', 'within' or 'like'"];
  :dict;
 };

isstring:{[dict;parameter]:checktype[10h;dict;parameter]};
