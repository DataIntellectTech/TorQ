// date/time clause
// sym clause (in correct place)
// other stuff clause
// rdb: return 0 result set if not for today
// format data column
// expand? 
\d .qb

ishdb:{@[{.proc.proctype in`hdb};`;1b]};
debug:0b;


// assumes timezone in UTC and queried time column = `time
// returns 00b - hdb only, 01b - rdb,hdb, 11b - rdb only

getdaterange:{[options]
 daterange:{[s;e]s+til 1+e-s};
 :(daterange)."d"$options`starttime`endtime;
 };

checkdb:{[options]
 daterange:getdaterange[options];
 r:{(min x;max x)}.z.d=daterange;
 checkdbdict:(00b;01b;11b)!(hdbonly[options];rdbhdb[options];rdbonly[options]);
 :checkdbdict[r];
 };

hdbonly:{[options]
 sd:"d"$options`starttime;
 st:"n"$options`starttime;
 ed:"d"$options`endtime;
 et:"n"$options`endtime;
 :(`sd`st`ed`et)!(sd;st;ed;et);
 };

rdbonly:{[options]
 sd:0Nd;
 st:"n"$options`starttime;
 ed:0Nd;
 et:"n"$options`endtime;
 :(`sd`st`ed`et)!(sd;st;ed;et);
 };

rdbhdb:{[options]
 sd:"d"$options`starttime;
 st:"n"$options`starttime;
 ed:0Nd;
 et:"n"$options`endtime;
 :(`sd`st`ed`et)!(sd;st;ed;et);
 };

// assume data with specified srctime is present in partitions up to three days in the future
// to account for delays over the weekend 
getdatesrctime:{[options]}
 d:(daterange)."d"$options`starttime`endtime; 
 :d,last[d]+1+til 3;
 };

buildwhere:{[options]
 // starttime: start timestamp
 // endtime: end timestamp
 // timecol: time column to look up on
 // pcolname: parted col lookup, usually sym
 // pcol: pcol values
 // querystring: string to be parsed and added to where clause 
 // other: other parsed conditions
 
 // add default values
 options:(`pcol`pcolname`timecol`other`querystring!(`;`sym;`time;();"")),options;
  
 // create intial empty where clause 
 whereclause:();
 
 // if pcol is specified, create a clause for that (e.g. sym clause)
 pcolclause:$[not`~options[`pcol];enlist(in;options[`pcolname];enlist options[`pcol]);()];
 
 // if start and endtime are defined, add a condition of 
 // date,pcol,time
 // if not defined, just set to pcol 

 $[ishdb[];
   $[options[`timecol]=`srctime;
     enlist(within;`date;enlist(`date$options[`starttime`endtime]+0 3));      // extend end date by 3 days when querying srctime col to account for delayed data over the weekend
     enlist(within;`date;enlist`date$options[`starttime`endtime])];
   ()],
 pcolclause,
 enlist(within;options[`timecol];options[`starttime`endtime]);
 whereclause,:pcolclause];
 
 // check if query string exists
 // querystring should be of type string
 if[not""~options`querystring;
   whereclause,:@[{first (parse x)2};"select from t where ",options[`querystring];()]];

 // peg on any additional conditions
 whereclause,:options[`other];
 
 if[not whereclause~();whereclause:enlist whereclause];
  
 if[debug;0N!whereclause];
 
 // return the where clause
 :whereclause;
 };

// deserialize any serialized columns in a table
deserialize:{keys[x]xkey @[0!x;exec c from meta x where t="X";-9!']};

format:{
 // make RDB and HDB queries return data in the same order
 // HDB will not be ordered by time
 // RDB will not return a date 
 
 // if the table is unkeyed, return it
 // this should be handled by the function creator
 if[0<count keys x;:x]; 
 
 // this only really applies for straight selects
  x:$[ishdb[];
    // sort hdb queries by time
    $[`time in cols x;`time xasc x;x];
    // if rdb query has date col, return
    $[`date in cols x;x;	
      // if rdb doesn't have date, but does have time, add a date
      `time in cols x;update date:`date$time from x;
      // else just return the table
      x]];
  // re-order columns, sort by time if HDB
  :(`date`sym`time inter cols[x])xcols x;
 };

// TESTS

debug:0b
.proc.proctype:`rdb
buildwhere ()!()
buildwhere `starttime`endtime!(.z.p - 1D;.z.p)
buildwhere (enlist`pcol)!enlist`a
buildwhere `starttime`endtime`pcol!(.z.p - 1D;.z.p;`a)
buildwhere `starttime`endtime`pcol!(.z.p - 1D;.z.p;`a`b)
buildwhere `starttime`endtime`pcol`pcolname!(.z.p - 1D;.z.p;`a;`otherid)
buildwhere `starttime`endtime`pcol`pcolname`timecol!(.z.p - 1D;.z.p;`a;`otherid;`mytime)
buildwhere `starttime`endtime`pcol`pcolname`timecol`querystring!(.z.p - 1D;.z.p;`a;`otherid;`mytime;"price>100")
buildwhere `starttime`endtime`pcol`pcolname`timecol`querystring!(.z.p - 1D;.z.p;`a;`otherid;`mytime;"price>100,size<20")
buildwhere `starttime`endtime`pcol`pcolname`timecol`querystring`other!(.z.p - 1D;.z.p;`a;`otherid;`mytime;"price>100,size<20";((in;`a;20);(=;`c;10)))

t:([]time:.z.p - desc 10?1D)
eval(?;t;buildwhere[`starttime`endtime!(.z.p - 0D12;.z.p - 0D06)];0b;())
eval(?;t;buildwhere[()!()];0b;())
format[t]

\
// in theory, the Audit functions should look like this:
getFullAudit:{[x]
 deserialize format eval(?;`parameterAudit;.qb.buildwhere[x];0b;())}

getLastAuditBySym:{[x]
 deserialize eval(?;`parameterAudit;.qb.buildwhere[x];(enlist`sym)!enlist`sym;())
 }
/

