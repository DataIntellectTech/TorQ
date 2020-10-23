\d .checkinputs

checkinputs:{[dict]
  dict:checkdictionary dict;
  dict:checkinvalidcombinations dict;
  dict:checkeachparam dict;
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

checkinvalidcombinations:{[dict]
  parameters:key dict;
  invalidcombinations:select parameter,invalidpairs:invalidpairs inter\:parameters from .dataaccess.checkinputsconfig where parameter in parameters;
  invalidcombinations:select from invalidcombinations where 0<>count'[invalidpairs];
  if[0=count invalidcombinations;:dict];
  checkeachcombination'[invalidcombinations];
 };

checkeachcombination:{[invalidcombination]'`$.dataaccess.formatstring["parameter:{parameter} cannot be used in combination with parameter(s):{invalidpairs}";invalidcombination]};

//- run check on each parameter
checkeachparam:{[dict]
  config:select from .dataaccess.checkinputsconfig where parameter in key dict;
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

tableexists:{[dict;parameter]
  if[not dict[`tablename]in .dataaccess.tablepropertiesconfig`tablename;'`$.dataaccess.formatstring["table:{tablename} doesn't exist";dict]];
  :dict;
 };

columnsexist:{[dict;parameter;columns]
  validcolumns:exec`#asc(union/)columns from .dataaccess.tablepropertiesconfig where tablename=dict`tablename;
  invalidcolumns:except[(),columns;validcolumns];
  if[count invalidcolumns;'`$.dataaccess.formatstring["{tablename} doesn't contain {invalidcolumns} - validcolumns:{validcolumns}";dict,`validcolumns`invalidcolumns!(validcolumns;invalidcolumns)]];
  :dict;
 };

//- check if table exists + param is of type symbol
isvalidtable:{[dict;parameter]
  dict:issymbol[dict;parameter];
  :tableexists[dict;parameter];
 };

//- check starttime/endtime values are of valid type
//- todo:have a way of returning the column type given tablename/timecolumn
checktimecolumntype:{[dict;parameter]
  dict:checktype[-12 -14 -15h;dict;parameter];
  :casttimecolumn[dict;parameter];
 };

//- todo:cast column type to valid value (currently just casts to itself)
casttimecolumn:{[dict;parameter]
  columntype:type dict parameter; //- in future it may be worth having config/a function to get the meta of the input table i.e getcolumntype[dict`tablename;dict`timecolumn]
  :dict;
 };

//- check param is of type symbol
//- todo: make a function to check if time column exists in table
checktimecolumn:{[dict;parameter]
  dict:issymbol[dict;parameter];
  checktimeorder[dict;parameter];
  :columnsexist[dict;parameter;dict`timecolumn];
 };

checktimeorder:{[dict;parameter]
  if[dict[`starttime]>dict`endtime;'`$"starttime>endtime"];
  dict;
 };

checkcolumnsexist:{[dict;parameter]
  dict:allsymbols[dict;parameter];
  :columnsexist[dict;parameter;dict parameter];
 }

issymbol:{[dict;parameter]:checktype[-11h;dict;parameter]};
allsymbols:{[dict;parameter]:checktype[11 -11h;dict;parameter]};

//- sould be otf: `last`max`wavg!(`mid;`mid`bidprice`askprice;(`asksize`askprice;`bidsize`bidprice))
//- returns columns: `lastMid`maxMid`maxMid`maxBidprice`maxAskprice`wavgAsksizeAskprice`wavgBidsizeBidprice
checkaggregations:{[dict;parameter]
  example:"`last`max`wavg!(`mid;`mid`bidprice`askprice;(`asksize`askprice;`bidsize`bidprice))";
  input:dict parameter;
  if[not 99h~type input;'`$"aggregations parameter must be of type dict - example:",example];
  if[not 11h~abs type key input;'`$"aggregations parameter key must be of type 11h - example:",example];
  if[not all 11h~/:abs raze type''[get input];'`$"aggregations parameter values must be of type symbol - example:",example];
  columns:(union/)get input; //- todo: check requested columns are valid - columnsexists[dict`tablename;columns]
  validfuncs:`avg`cor`count`cov`dev`distinct`first`last`max`med`min`prd`sum`var`wavg`wsum; //- these functions support 'map reduce' - in future custom functions could be added
  inputfuncs:key input;
  if[any not inputfuncs in validfuncs;'`$.dataaccess.formatstring["invalid functions passed to aggregation parameter:{}";inputfuncs except validfuncs]];
  :dict;
 };

checktimebar:{[dict;parameter]
  input:dict parameter;
  if[not(3=count input)&0h~type input;'`$"timebar parameter must be a list of length 3"];
  input:`timecol`size`bucket!input;
  if[not -11h~type input`timecol;'`$"first argument of timebar must be have type -11h"];
  dict:columnsexist[dict;parameter;dict`timecolumn];
  if[not any -6 -7h~\:type input`size;'`$"type of the second argument of timebar must be either -6h or -7h"];
  if[not -11h~type input`bucket;'`$"third argument of timebar must be of type -11h"];
  if[not input[`bucket]in`nanosecond`second`minute`hour`timespan;'`$"third argument of timebar must be one of:`nanosecond`second`minute`hour`timespan"];
  :dict;
 };

checkfilterformat:{[dict;parameter]
  if[not 0h~type first dict parameter;'`$"filter parameter passed incorrectly - example ((>;`size;5);(=;`price;(max;`price)))"];
  :dict;
 };

isstring:{[dict;parameter]:checktype[10h;dict;parameter]};
