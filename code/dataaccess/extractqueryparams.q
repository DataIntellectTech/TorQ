\d .eqp

//- table to store arguments
queryparams:`tablename`partitionfilter`attributecolumn`timefilter`instrumentfilter`columns`grouping`aggregations`filters`freeformwhere`freeformby`freeformcolumn!(`;();`;();();();();();();();();());

extractqueryparams:{[inputparams;queryparams]
  queryparams:extracttablename[inputparams;queryparams];
  queryparams:extractpartitionfilter[inputparams;queryparams];
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
  queryparams:extractfreeformcolumn[inputparams;queryparams];
  queryparams:jointableproperties[inputparams;queryparams];
  :queryparams;
 };

extracttablename:{[inputparams;queryparams]@[queryparams;`tablename;:;inputparams`tablename]};

extractpartitionfilter:{[inputparams;queryparams]
  if[`rdb~inputparams[`metainfo;`proctype];:@[queryparams;`partitionfilter;:;()]];  
  timecolumn:inputparams`timecolumn;
  partfield:.dataaccess.gettableproperty[inputparams;`partfield];
  timerange:inputparams[`metainfo]`starttime`endtime;
  partfilter:exec enlist(within;partfield;timerange)from inputparams;
  :@[queryparams;`partitionfilter;:;partfilter];
 };

extractattributecolumn:{[inputparams;queryparams]
  attributecolumn:.dataaccess.gettableproperty[inputparams;`attributecolumn];
  :@[queryparams;`attributecolumn;:;attributecolumn];
 };

extracttimefilter:{[inputparams;queryparams]
  procmeta:inputparams`metainfo;
  timecolumn:inputparams`timecolumn;
  addkeys:`proctype`validrange`timefilter;
  :queryparams,exec addkeys!(proctype;validrange;enlist(within;timecolumn;(starttime;endtime)))from procmeta;
 };

extractinstrumentfilter:{[inputparams;queryparams]
  if[not`instruments in key inputparams;:queryparams];
  instrumentcolumn:.dataaccess.gettableproperty[inputparams;`instrumentcolumn]; 
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
  timebar:`timecol`size`bucket!inputparams`timebar;
  timebucket:exec size*.checkinputs.timebarmap bucket from timebar;
  :@[queryparams;`timebar;:;timebar[1#`timecol]!enlist(.eqp.xbarfunc;timebucket;timebar`timecol)];
 };

xbarfunc:{[n;x]
  typ:type x;
  timebucket:n*0D00:00.000000001;
  if[typ~12h;:timebucket xbar x];
  if[typ in 13 14h;:timebucket xbar 0D+`date$x];
  if[typ~15h;:timebucket xbar`timespan$x];
  if[typ in 16 17 18 19h;:timebucket xbar`timespan$x];
  '`$"timebar type error"; //- type checks in checkinputs functions should stop it reaching here
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

extractfreeformcolumn:{[inputparams;queryparams]
  if[not`freeformcolumn in key inputparams;:queryparams];
  selectclause:parse["select ",inputparams[`freeformcolumn]," from x"][4];
  :@[queryparams;`freeformcolumn;:;selectclause];
 };

jointableproperties:{[inputparams;queryparams]queryparams,enlist[`tableproperties]#inputparams};
