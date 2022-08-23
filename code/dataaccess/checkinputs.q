\d .dataaccess

// checkinputs is the main function called when running a query - it checks:
//   (i) input format
//  (ii) whether any parameter pairs clash
// (iii) parameter specific checks
// The input dictionary accumulates some additional table information/inferred info
checkinputs:{[dict]
    if[not in[`checksperformed;key dict];dict:.checkinputs.checkinputs dict];
    dict:checktablename dict;
    if[in[`columns;key dict];.dataaccess.checkcolumns[dict`tablename;dict`columns;`columns];dict:rdbdate[dict;`columns]];
    if[in[`timecolumn;key dict];dict:.dataaccess.checktimecolumn[dict];dict:rdbdate[dict;`timecolumn]];
    dict:filldefaulttimecolumn dict;
    if[in[`instrumentcolumn ;key dict];.dataaccess.checkcolumns[dict`tablename;dict`instrumentcolumn;`instrumentcolumn ]];
    if[in[`aggregations;key dict];.dataaccess.checkaggregations dict;dict:rdbdate[dict;`aggregations]];
    if[in[`filters;key dict];.dataaccess.checkcolumns[dict`tablename;key dict`filters;`filters]];
    if[in[`grouping;key dict];.dataaccess.checkcolumns[dict`tablename;dict`grouping;`grouping];dict:rdbdate[dict;`grouping]];
    if[in[`timebar;key dict];.dataaccess.checktimebar dict;dict:rdbdate[dict;`timebar]];
    if[in[`freeformwhere;key dict];.dataaccess.checkfreeformwhere dict;dict:freeformrdbdate[dict;`freeformwhere]];
    if[in[`freeformby;key dict];.dataaccess.checkfreeformby dict;dict:freeformrdbdate[dict;`freeformby]];
    if[in[`freeformcolumn;key dict];.dataaccess.checkfreeformcolumns dict;dict:freeformrdbdate[dict;`freeformcolumn]];
    if[in[`sqlquery;key dict];'`$.checkinputs.formatstring[.schema.errors[`sqlquery;`errormessage];.proc.proctype]];
    if[in[`firstlastsort;key dict];'`$.checkinputs.formatstring[.schema.errors[`firstlastsort;`errormessage];.proc.proctype]];
    :dict;
  };

// function to check the validity of tablenames
checktablename:{[dict]
    if[not dict[`tablename]in exec tablename from .checkinputs.tablepropertiesconfig where proctype in (.proc.proctype,`,`all);
        '`$.checkinputs.formatstring[.schema.errors[`tableexists;`errormessage];dict]];
    dict:.checkinputs.jointableproperties dict;
    :update metainfo:(metainfo,`starttime`endtime!(starttime;endtime))from dict;
  };

//check that time column is of the correct type
checktimecolumn:{[dict]
    .dataaccess.checkcolumns[dict`tablename;dict`timecolumn;`timecolumn];
    if[dict[`timecolumn]~`date;:dict];
    if[not first (exec t from meta dict`tablename where c=(dict[`timecolumn])) in "pzd";'`$.checkinputs.formatstring["Parameter:`timecolumn - column:{column} in table:{table} is of type:{type}, validtypes:-12 -14 -15h";`column`table`type!(dict`timecolumn;dict`tablename;(type( exec from dict`tablename)dict`timecolumn))]];    :dict;
  };


// function to fill in default columns to reduce the amount of information a user has to
// fill in
filldefaulttimecolumn:{[dict]
    if[not `timecolumn in key dict;    
        :@[dict;`timecolumn;:;.checkinputs.getdefaulttime dict]];
    :dict;
  };

// function to check the validity of columns with respect to the chosen tablename
// parameter
 checkcolumns:{[table;columns;parameter]
    if[not all(`~columns)& parameter~`columns;
        columns,:();
        avblecols:`date,cols table;
        if[any not in[columns;avblecols];
            badcol:columns where not in[columns;avblecols];
            '`$.checkinputs.formatstring[.schema.errors[`checkcolumns;`errormessage];`badcol`tab`parameter!(badcol;table;parameter)]]];};

// function to add date column on request on rdb processes
rdbdate:{[dict;parameter]
    if[.proc.proctype=`rdb;
        f:{[y;x]$[x~`date;`$((string .checkinputs.getdefaulttime y),".date");x]};
        :@[dict;parameter;:;f[dict;] each dict parameter]];
    :dict;
  };

// function to add date column to free form parameters on rdb processes
freeformrdbdate:{[dict;parameter]
    if[.proc.proctype=`rdb;
        :@[dict;parameter;:;ssr[(dict parameter);"date";(string (.checkinputs.getdefaulttime dict)),".date"]]];
    :dict;
 };

//- returns columns: `lastMid`maxBidprice`maxAskprice`wavgAsksizeAskprice`wavgBidsizeBidprice
checkaggregations:{[dict]
    input:dict`aggregations;
    .dataaccess.checkcolumns[dict`tablename;raze last each input;`aggregations];
    columns:distinct(raze/)get input;
    dict:checkcolumns[dict`tablename;raze last each input;`aggregations];
    inputfuncs:key input;
    if[(`distinct in key input)&(not ((count flip(key[input]where count each get input;raze input)))=1); '`$.schema.errors[`distinctagg;`errormessage]]
    if[any not inputfuncs in .schema.validfuncs;'`$.checkinputs.formatstring[.schema.errors[`undefinedaggs;`errormessage];distinct inputfuncs except .schema.validfuncs]];
    dvalidfuncs:(key input) inter .schema.dvalidfuncs;
    if[0<>count except[count each raze input dvalidfuncs;2];'`$.checkinputs.formatstring[.schema.errors[`agglength;`errormessage];dvalidfuncs]];
    :dict;
 };

// check that the timebar size chosen isn't too small for DA to handle
checktimebar:{[dict]
    if[not in[`aggregations;key dict];
        '`$.schema.errors[`aggtimebar;`errormessage]];
    .dataaccess.checkcolumns[dict`tablename;last dict`timebar;`timebar];
    input:dict`aggregations;
    input:flip(key[input]where count each get input;raze input);
    if[any not in[first each input;.schema.returnone];
        '`$.schema.errors[`singleaggtimebar;`errormessage]];
    size:dict[`timebar][1];
    if[not in[size;key .schema.timebarmap];
        '`$.checkinputs.formatstring[.schema.errors[`timebarsize;`errormessage];`size`app!(size;key .schema.timebarmap)]];
    if[1>floor (dict`timebar)[0]*.schema.timebarmap(dict`timebar)[1];
        '`$.schema.errors[`smalltimebar;`errormessage]];
    if[(not first (exec t from meta dict`tablename where c=(dict`timebar)[2]) in "pmnuvtzd") & (not (dict`timebar)[2]=`date);'`$.checkinputs.formatstring["Parameter:`timebar - column:{column} in table:{table} is of type:{type}, validtypes:-12 -13 -14 -15 -16 -17 -18 -19h";`column`table`type!((dict`timebar)[2];dict`tablename;(type( exec from dict`tablename)(dict`timebar)[2]))]];
    :dict;
 };

// check errors in the freeform parameters
checkfreeformwhere:{[dict]
    cond:"," vs dict`freeformwhere;
    cond:(parse each cond);
    if[any (not(first each  cond[;1]) in (in;within;like))*((type each first each cond[;1])=102h);'`$.schema.errors[`freeformnot;`errormessage]];
    if[any 2=count each cond;cond:?[2=count each cond;cond[;1];cond[]]];
    .dataaccess.checkcolumns[dict`tablename;cond[;1];`freeformwhere];
    if[not all [last each (cond[;0] in .schema.allowedops)];'`$(dict`freeformwhere),.schema.errors[`freeformoperators;`errormessage]];
 };

checkfreeformby:{[dict]
    if[not ((dict`freeformby) ss "!")~`long$();'`$.schema.errors[`freeformbydict;`errormessage],.schema.examples[`freeformby;`example]];
    cond:"," vs dict`freeformby;
    cond:(parse each cond);
    .dataaccess.checkcolumns[dict`tablename;cond;`freeformby];
 };

checkfreeformcolumns:{[dict]
    example:"sym,time,mid:0.5*bidprice+askprice";
    validfuncs:`avg`cor`count`cov`dev`distinct`first`last`max`med`min`prd`sum`var`wavg`wsum`0`1`2`3`4`5`6`7`8`9`;
    cond:(dict`freeformcolumn),",",(dict`freeformcolumn);
    cond:"," vs cond;
    if[(cond ?\:":")~(count each cond);
        cond:cond,'" ";
        cond:distinct " " vs raze cond;
        .dataaccess.checkcolumns[dict`tablename;(`$cond) except validfuncs;`freeformby]];
    if[not (cond ?\:":")~(count each cond);
        loc:(cond ?\:":")=(count each cond);
        .dataaccess.checkcolumns[dict`tablename;`$(cond where loc);`freeformby];
        rcond:(1+(cond where not loc) ?\:":")_'(cond where not loc),'" ";
        isletter:rcond in .Q.an;
        scond:distinct " " vs trim ?[raze isletter;raze rcond;" "];
        .dataaccess.checkcolumns[dict`tablename;(`$scond) except validfuncs;`freeformcolumns];]
 };
