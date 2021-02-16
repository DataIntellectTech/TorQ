\d .dataaccess

// checkinputs is the main function called when running a query - it checks:
//   (i) input format
//  (ii) whether any parameter pairs clash
// (iii) parameter specific checks
// The input dictionary accumulates some additional table information/inferred info
checkinputs:{[dict]
    //if[not in[`checksperformed;key dict];dict:.checkinputs.checkinputs dict];
    dict:checktablename dict;
    if[in[`columns;key dict];dict:rdbdate[dict;`columns];.dataaccess.checkcolumns[dict`tablename;dict`columns;`columns]];
    if[in[`timecolumn;key dict];.dataaccess.checktimecolumn[dict]];
    dict:filldefaulttimecolumn dict;
    if[in[`instrumentcolumn ;key dict];.dataaccess.checkcolumns[dict`tablename;dict`instrumentcolumn;`instrumentcolumn ]];
    if[in[`aggregations;key dict];.dataaccess.checkaggregations dict];
    if[in[`filters;key dict];.dataaccess.checkcolumns[dict`tablename;key dict`filters;`filters]];
    if[in[`grouping;key dict];dict:rdbdate[dict;`columns];.dataaccess.checkcolumns[dict`tablename;dict`grouping;`grouping]];
    if[in[`timebar;key dict];dict:rdbdate[dict;`columns];.dataaccess.checktimebar dict];
    if[in[`freeformwhere;key dict];dict:freeformrdbdate[dict;`freeformwhere];.dataaccess.checkfreeformwhere dict];
    if[in[`freeformby;key dict];dict:freeformrdbdate[dict;`freeformby];.dataaccess.checkfreeformby dict];
    if[in[`freeformcolumn;key dict];dict:freeformrdbdate[dict;`freeformcolumn];.dataaccess.checkfreeformcolumns dict];
    :dict;
  };

// function to check the validity of tablenames
checktablename:{[dict]
    if[not dict[`tablename]in exec tablename from .checkinputs.tablepropertiesconfig;'`$.checkinputs.formatstring["Table:{tablename} doesn't exist";dict]];
    dict:.checkinputs.jointableproperties dict;
    :update metainfo:(metainfo,`starttime`endtime!(starttime;endtime))from dict;
  };

//check that time column is of the correct type
checktimecolumn:{[dict]
    .dataaccess.checkcolumns[dict`tablename;dict`timecolumn;`timecolumn];
    if[not first (exec t from meta dict`tablename where c=dict`timecolumn) in "pzd";'`$.checkinputs.formatstring["Parameter:`timecolumn - column:{column} in table:{table} is of type:{type}, validtypes:-12 -14 -15h";`column`table`type!(dict`timecolumn;dict`tablename;(type( exec from dict`tablename)dict`timecolumn))]];
  };

// function to fill in default columns to reduce the amount of information a user has to
// fill in
filldefaulttimecolumn:{[dict]
    defaulttimecolumn:`time^.checkinputs.gettableproperty[dict;`primarytimecolumn];
    if[not`timecolumn in key dict;:@[dict;`timecolumn;:;defaulttimecolumn]];
    :dict;
  };

// function to check the validity of columns with respect to the chosen tablename
// parameter
 checkcolumns:{[table;columns;parameter]
    if[not all(`~columns)& parameter~`columns;
        columns,:();
        avblecols:`time.date,cols table;
        if[any not in[columns;avblecols];
            badcol:columns where not in[columns;avblecols];
            '`$.checkinputs.formatstring["Column(s) {badcol} presented in {parameter} is not a valid column for {tab}";`badcol`tab`parameter!(badcol;table;parameter)]]];};

// function to add date column on request on rdb processes
rdbdate:{[dict;parameter]
    if[.proc.proctype=`rdb;dict:@[dict;parameter;:;{$[x<>`date;x;`time.date]} each (dict parameter)]];
    :dict;
  };

// function to add date column to free form parameters on rdb processes
freeformrdbdate:{[dict;parameter]
    if[.proc.proctype=`rdb;dict:@[dict;parameter;:;ssr[(dict parameter);"date";"time.date"]]];
    :dict;
 };

timebarmap:`nanosecond`timespan`microsecond`second`minute`hour`day!1 1 1000 1000000000 60000000000 3600000000000 86400000000000;

//- should be of the format: `last`max`wavg!(`time;`bidprice`askprice;(`asksize`askprice;`bidsize`bidprice))
//- returns columns: `lastMid`maxBidprice`maxAskprice`wavgAsksizeAskprice`wavgBidsizeBidprice
checkaggregations:{[dict]
    example:"`last`max`wavg!(`time;`bidprice`askprice;(`asksize`askprice;`bidsize`bidprice))";
    input:dict`aggregations;
    .dataaccess.checkcolumns[dict`tablename;raze last each input;`aggregations];
    columns:distinct(raze/)get input;
    dict:checkcolumns[dict`tablename;raze last each input;`aggregations];
    validfuncs:`avg`cor`count`cov`dev`distinct`first`last`max`med`min`prd`sum`var`wavg`wsum; //- these functions support 'map reduce' - in future custom functions could be added
    inputfuncs:key input;
    if[(`distinct in key input)&(not ((count flip(key[input]where count each get input;raze input)))=1); '`$"If the distinct function is used, it cannot be present with any other aggregations including more of itself"]
    if[any not inputfuncs in validfuncs;'`$.checkinputs.formatstring["Aggregations dictionary contains undefined function(s) {}";distinct inputfuncs except validfuncs]];
    dvalidfuncs:(key input) inter `cor`cov`wavg`wsum;
    if[0<>count except[count each raze input dvalidfuncs;2];'`$.checkinputs.formatstring["Incorrect number of input(s) entred for the following aggregations{}";dvalidfuncs]];
    :dict;
 };

// check that the timebar size chosen isn't too small for DA to handle
checktimebar:{[dict]
    if[not in[`aggregations;key dict];
        '`$"Aggregations parameter must be supplied in order to perform group by statements"];
    .dataaccess.checkcolumns[dict`tablename;last dict`timebar;`timebar];
    returnone:`first`last`avg`count`dev`max`med`min`prd`sum`var`wavg`wsum;
    input:dict`aggregations;
    input:flip(key[input]where count each get input;raze input);
    if[any not in[first each input;returnone];
        '`$"In order to use a grouping parameter, only aggregations that return single values may be used"];
    size:dict[`timebar][1];
    if[not in[size;key .dataaccess.timebarmap];
        '`$.checkinputs.formatstring["The input size of the timebar argument: {size}, is not an appropriate size. Appropriate sizes are: {app}";`size`app!(size;key .dataaccess.timebarmap)]];
    if[1>floor (dict`timebar)[0]*.dataaccess.timebarmap(dict`timebar)[1];
        '`$"Timebar parameter's intervals are too small. Time-bucket intervals must be greater than (or equal to) one nanosecond"];
    if[not first (exec t from meta dict`tablename where c=(dict`timebar)[2]) in "pmnuvtzd";'`$.checkinputs.formatstring["Parameter:`timebar - column:{column} in table:{table} is of type:{type}, validtypes:-12 -13 -14 -15 -16 -17 -18 -19h";`column`table`type!((dict`timebar)[2];dict`tablename;(type( exec from dict`tablename)(dict`timebar)[2]))]];
 };

// check errors in the freeform parameters
checkfreeformwhere:{[dict]
    example:"bidprice<0w,bidsize>`sym bidprice>0w";
    cond:"," vs dict`freeformwhere;
    cond:(parse each cond);
    if[any (not(first each  cond[;1]) in (in;within;like))*((type each first each cond[;1])=102h);'`$"Not operator must be used in conjucture with in, like or within oporators"];
    if[any 2=count each cond;cond:?[2=count each cond;cond[;1];cond[]]];
    .dataaccess.checkcolumns[dict`tablename;cond[;1];`freeformwhere];
    allowedops:(<;>;<>;in;within;like;<=;>=;=;~;not);
    if[not all [last each (cond[;0] in allowedops)];'`$(dict`freeformwhere)," contains operators which can not be accepted. The following are allowed operators: =, <, >, <=, >=, in, within, like. The last three may be preceeded with 'not' e.g. (not within;80 100)"];
 };

checkfreeformby:{[dict]
    example:"sym:sym, source:src";
    if[not ((dict`freeformby) ss "!")~`long$();'`$"Freeformby parameter must not be entered as dictionary. Parameter should be entered in the following format: ",example];
    cond:"," vs dict`freeformby;
    cond:(parse each cond);
    .dataaccess.checkcolumns[dict`tablename;cond;`freeformby];
 };

checkfreeformcolumns:{[dict]
    example:"sym,time,mid:0.5*bidprice+askprice";
    cond:(dict`freeformcolumn),",",(dict`freeformcolumn);
    cond:"," vs cond;
    if[(cond ?\:":")~(count each cond);.dataaccess.checkcolumns[dict`tablename;`$cond;`freeformby]];
    if[not (cond ?\:":")~(count each cond);
        loc:(cond ?\:":")=(count each cond);
        .dataaccess.checkcolumns[dict`tablename;`$(cond where loc);`freeformby];
        rcond:(1+(cond where not loc) ?\:":")_'(cond where not loc),'" ";
        isletter:rcond in .Q.an;
        scond:" " vs trim ?[raze isletter;raze rcond;" "];
        scond:(7h$((count scond)%2))#scond;
        validfuncs:`avg`cor`count`cov`dev`distinct`first`last`max`med`min`prd`sum`var`wavg`wsum`0`1`2`3`4`5`6`7`8`9`;
        .dataaccess.checkcolumns[dict`tablename;(`$scond) except validfuncs;`freeformcolumns];]
 };
