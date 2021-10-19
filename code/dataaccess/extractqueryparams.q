\d .eqp

//- table to store arguments
queryparams:`tablename`partitionfilter`attributecolumn`timefilter`instrumentfilter`columns`grouping`aggregations`filters`ordering`freeformwhere`freeformby`freeformcolumn`optimisation!(`;();`;();();();();();();();();();();1b);

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
  queryparams:extractordering[inputparams;queryparams];
  queryparams:extractfreeformwhere[inputparams;queryparams];
  queryparams:extractfreeformby[inputparams;queryparams];
  queryparams:extractfreeformcolumn[inputparams;queryparams];
  queryparams:jointableproperties[inputparams;queryparams];
  queryparams:extractoptimisationkey[inputparams;queryparams];
  queryparams:extractcolumnnaming[inputparams;queryparams];
  :queryparams;
 };

extracttablename:{[inputparams;queryparams]@[queryparams;`tablename;:;inputparams`tablename]};

extractpartitionfilter:{[inputparams;queryparams]
  //If an RDB return the partitionfilters as empty
  if[`rdb~inputparams[`metainfo;`proctype];:@[queryparams;`partitionfilter;:;()]];
  //Get the  partition range function 
  getpartrangef:.checkinputs.gettableproperty[inputparams;`getpartitionrange];
  // Get the time column
  timecol:inputparams`timecolumn;
  // Get the time range function
  timerange:inputparams[`metainfo]`starttime`endtime;
  // Find the partition field
  partfield:.checkinputs.gettableproperty[inputparams;`partfield];
  //return a list of partions to search through
  partrange:.dacustomfuncs.partitionrange[(inputparams`tablename);timerange;.proc.proctype;timecol];
  // Return as kdb native filter
  partfilter:exec enlist(within;partfield;partrange)from inputparams;
  :@[queryparams;`partitionfilter;:;partfilter];
  };

extractattributecolumn:{[inputparams;queryparams]
  attributecolumn:.checkinputs.gettableproperty[inputparams;`attributecolumn];
  :@[queryparams;`attributecolumn;:;attributecolumn];
 };

extracttimefilter:{[inputparams;queryparams]
  procmeta:inputparams`metainfo;
  if[-14h~type procmeta[`endtime];procmeta[`endtime]:1+procmeta[`endtime]];
  timecolumn:inputparams`timecolumn;
  addkeys:`proctype`timefilter;
  :queryparams,exec addkeys!(proctype;enlist(within;timecolumn;(starttime;endtime)))from procmeta;
 };

extractinstrumentfilter:{[inputparams;queryparams]
  if[not`instruments in key inputparams;:queryparams];
  instrumentcolumn:.checkinputs.gettableproperty[inputparams;`instrumentcolumn]; 
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
  aggregations:(!). flip(extracteachaggregation'). ungroupaggregations inputparams;
  :@[queryparams;`aggregations;:;aggregations];
 };

ungroupaggregations:{[inputparams](key[inputparams`aggregations]where count each get inputparams`aggregations;raze inputparams`aggregations;.checkinputs.getdefaulttime[inputparams])};
extracteachaggregation:{[func;columns;deftime](`$string[func],raze .[string(),?[columns=`$((string deftime),".date");`date;columns];(::;0);upper];?[`sumsq=func;(sum;(xexp;columns;2));parse[string func],columns])};

extracttimebar:{[inputparams;queryparams]
  // If no key has been provided return the queryparams
  if[not`timebar in key inputparams;:queryparams];
  // Get the timebar params as a dictionary
  timebar:`size`bucket`timecol!inputparams`timebar;
  // Convert the timebucket to it's corresponding integer value 
  timebucket:exec size * .schema.timebarmap bucket from timebar;
  // Return as a kdb+ native function
  :@[queryparams;`timebar;:;timebar[1#`timecol]!enlist(xbarfunc;timebucket;timebar[`timecol])];
  };

xbarfunc:{[timebucket;x]
  typ:type x;
  if[typ~12h;:timebucket xbar x];
  if[typ in 13 14h;:timebucket xbar 0D+`date$x];
  if[typ~15h;:timebucket xbar`timespan$x];
  if[typ in 16 17 18 19h;:timebucket xbar`timespan$x];
  '`$"timebar type error"; //- type checks in checkinputs functions should stop it reaching here
 };

// extract where filter parameters from input dictionary
// the filters parameter is a dictionary of the form:
// `sym`price`size!(enlist(=;`AAPL);((within;80 100);(not in;81 83 85));enlist(>;50))
// this is translated into a kdb parse tree for use in the where clause:
// ((=;`sym;,`AAPL);(within;`price;80 100);(in[~:];`price;81 83 85);(>;`size;50))
// this function ensures symbol types are enlist for the parse tree and reorders
// filters prefaced with the 'not' keyword as neeeded
extractfilters:{[inputparams;queryparams]
  if[not`filters in key inputparams;:queryparams];
  f:inputparams`filters;
  f:@''[f;-1+count''[f];{$[11h~abs type x;enlist x;x]}];
  f:raze key[f]{$[not~first y;y[0],enlist(y 1),x,-1#y;(1#y),x,-1#y]}''get f;
  :@[queryparams;`filters;:;f];
 };

extractordering:{[inputparams;queryparams]
  if[not`ordering in key inputparams;:queryparams];
  go:{[x;input]if[first (input)[x]=`asc;:((input)[x;1] xasc)];if[first (input)[x]=`desc;:((input)[x;1] xdesc)];(input)[x]};
  order:go[;inputparams`ordering] each til count inputparams`ordering;
  :@[queryparams;`ordering;:;order];
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

extractoptimisationkey:{[inputparams;queryparams]
 A:((1#`optimisation)!1#1b)^inputparams;
 :@[queryparams;`optimisation;:;A`optimisation];
 };

jointableproperties:{[inputparams;queryparams]queryparams,enlist[`tableproperties]#inputparams};

//-Extract the column naming dictionary/list
extractcolumnnaming:{[inputparams;queryparams]
   // If No argument has been supplied return an empty list (this will return default behaviour in getdata.q)
   if[not `renamecolumn in key inputparams;:@[queryparams;`renamecolumn;:;()!()]];
   // Otherwise extract the column order list/dictionary
   :@[queryparams;`renamecolumn;:;@[inputparams;`renamecolumn]];
 };

processpostback:{[result;postback]:postback result;};
