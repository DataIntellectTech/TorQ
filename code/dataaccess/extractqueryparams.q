\d .eqp

//- table to store arguments
queryparams:`tablename`datefilter`attributecolumn`timefilter`instrumentfilter`columns`grouping`aggregations`filters`freeformwhere`freeformby`freeformselect!(`;();`;();();();();();();();();());

extractqueryparams:{[inputparams;queryparams]
  queryparams:extracttablename[inputparams;queryparams];
  queryparams:extractdatefilter[inputparams;queryparams];
  queryparams:extractattributecolumn[inputparams;queryparams];
  queryparams:extracttimefilter[inputparams;queryparams];
  queryparams:extractinstrumentfilter[inputparams;queryparams];
  queryparams:extractcolumns[inputparams;queryparams];
  queryparams:extractgrouping[inputparams;queryparams];
  queryparams:extractaggregations[inputparams;queryparams];
  queryparams:extracttimebar[inputparams;queryparams];
  queryparams:extractfilters[inputparams;queryparams];
  queryparams:extractfreeformwhere[inputparams;queryparams];
  queryparams:extractfreeformby[inputparams;queryparams];
  queryparams:extractfreeformselect[inputparams;queryparams];
  :queryparams;
 };

extracttablename:{[inputparams;queryparams]@[queryparams;`tablename;:;inputparams`tablename]};

extractdatefilter:{[inputparams;queryparams]
  dates:`date$inputparams`starttime`endtime;
  datefilter:exec enlist(within;`date;dates)from inputparams;
  :@[queryparams;`datefilter;:;datefilter];
 };

extractattributecolumn:{[inputparams;queryparams]
  attributecolumn:.dataaccess.gettableproperty[inputparams`tablename;`any;`attributecolumn]; //- atm .dataaccess.tablepropertiesconfig has separate rows for the rdb/hdb - use `any to retieve whichever comes first
  :@[queryparams;`attributecolumn;:;attributecolumn];
 };

extracttimefilter:{[inputparams;queryparams]
  timefilter:exec enlist(within;timecolumn;(starttime;endtime))from inputparams;
  :@[queryparams;`timefilter;:;timefilter];
 };

extractinstrumentfilter:{[inputparams;queryparams]
  if[not`instruments in key inputparams;:queryparams];
  instrumentcolumn:.dataaccess.gettableproperty[inputparams`tablename;`any;`instrumentcolumn]; //- atm .dataaccess.tablepropertiesconfig has separate rows for the rdb/hdb - use `any to retieve whichever comes first
  instruments:enlist inputparams`instruments;
  filterfunc:$[1=count first instruments;=;in];
  instrumentfilter:enlist(filterfunc;instrumentcolumn;instruments);
  :@[queryparams;`instrumentfilter;:;instrumentfilter];
 };

extractcolumns:{[inputparams;queryparams]
  if[not`columns in key inputparams;:queryparams];
  columns:(),inputparams`columns;
  :@[queryparams;`columns;:;columns!columns];
 };

extractgrouping:{[inputparams;queryparams]
  if[not`grouping in key inputparams;:queryparams];
  grouping:(),inputparams`grouping;
  :@[queryparams;`grouping;:;grouping!grouping];
 };

extractaggregations:{[inputparams;queryparams]
  if[not`aggregations in key inputparams;:queryparams];
  aggregations:(!). flip(extracteachaggregation'). ungroupaggregations inputparams`aggregations;;
  :@[queryparams;`aggregations;:;aggregations];
 };

ungroupaggregations:{[aggregations](key[aggregations]where count each get aggregations;raze aggregations)};
extracteachaggregation:{[func;columns](`$string[func],raze .[string(),columns;(::;0);upper];parse[string func],columns)};

extracttimebar:{[inputparams;queryparams]
  if[not`timebar in key inputparams;:queryparams];
  timebar:inputparams`timebar;
  :@[queryparams;`filters;:;enlist[timebar 0]!enlist timebar];
 };

extractfilters:{[inputparams;queryparams]
  if[not`filters in key inputparams;:queryparams];
  :@[queryparams;`filters;:;inputparams`filters];
 };

extractfreeformwhere:{[inputparams;queryparams]
  if[not`freeformwhere in key inputparams;:queryparams];
  whereclause:parse["select from x where ",inputparams`freeformwhere][2;0];
  :@[queryparams;`freeformwhere;:;whereclause];
 };

extractfreeformby:{[inputparams;queryparams]
  if[not`freeformby in key inputparams;:queryparams];
  byclause:parse["select by ",inputparams[`freeformby]," from x"][3];
  :@[queryparams;`freeformby;:;byclause];
 };

extractfreeformselect:{[inputparams;queryparams]
  if[not`freeformselect in key inputparams;:queryparams];
  selectclause:parse["select ",inputparams[`freeformselect]," from x"][4];
  :@[queryparams;`freeformselect;:;selectclause];
 };
