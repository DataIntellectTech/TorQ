\d .checkinputs

// checkinputs is the main function called when running a query - it checks:
//   (i) input format
//  (ii) whether any parameter pairs clash
// (iii) parameter specific checks
// The input dictionary accumulates some additional table information/inferred info
checkinputs:{[dict]
    dict:isdictionary dict;
    if[in[`sqlquery;key dict];:isstring[dict;`sqlquery]];
    dict:checkdictionary dict;
    dict:checkinvalidcombinations dict;
    dict:checkrepeatparams dict;
    dict:checkeachparam[dict;1b];
    dict:checkeachparam[dict;0b];
    :@[dict;`checksperformed;:;1b];
  };

checkdictionary:{[dict]
    if[not checkkeytype dict;'`$.schema.errors[`checkkeytype;`errormessage]];
    if[not checkrequiredparams dict;'`$.checkinputs.formatstring[.schema.errors[`checkrequiredparams;`errormessage];.checkinputs.getrequiredparams[]except key dict]];
    if[not checkparamnames dict;'`$.checkinputs.formatstring[.schema.errors[`checkparamnames;`errormessage];key[dict]except .checkinputs.getvalidparams[]]];
    :dict;
  };

isdictionary:{[dict]$[99h~type dict;:dict;'`$.schema.errors[`isdictionary;`errormessage]]};
checkkeytype:{[dict]11h~type key dict};
checkrequiredparams:{[dict]all .checkinputs.getrequiredparams[]in key dict};
getrequiredparams:{[]exec parameter from .checkinputs.checkinputsconfig where required}
checkparamnames:{[dict]all key[dict]in .checkinputs.getvalidparams[]};
getvalidparams:{[]exec parameter from .checkinputs.checkinputsconfig};

checkinvalidcombinations:{[dict]
    parameters:key dict;
    xinvalidpairs:select parameter,invalidpairs:invalidpairs inter\:parameters from .checkinputs.checkinputsconfig where parameter in parameters;
    xinvalidpairs:select from xinvalidpairs where 0<>count'[invalidpairs];
    if[0=count xinvalidpairs;:dict];
    :checkeachpair[raze each flip xinvalidpairs];
  };

checkeachpair:{[invalidpair]'`$.checkinputs.formatstring[.schema.errors[`checkeachpair;`errormessage];invalidpair]};

// function to check if any parameters are repeated
checkrepeatparams:{[dict]
    if[any repeats:1<count each group key dict;
        '`$.checkinputs.formatstring[.schema.errors[`checkrepeatparams;`errormessage];where repeats]];
    :dict;};

// loop thorugh input parameters to execute parameter specific checks
checkeachparam:{[dict;isrequired]
    config:select from .checkinputs.checkinputsconfig where parameter in key dict,required=isrequired;
    :checkparam/[dict;config];
  };

// extract parameter specific function from config to check the input
checkparam:{[dict;config]
    (first config[`checkfunction])[dict;first config`parameter]};

// check tablename parameter is of type symbol
checktable:{[dict;parameter]:checktype[-11h;dict;parameter];};

// check that endtime is of temporal type and that it is greater than or equal to starttime
checkendtime:{[dict;parameter]
    dict:checktimetype[dict;parameter];
    :checktimeorder dict};

// check that inputted value is of valid type: -12 -14 -15h
checktimetype:{[dict;parameter]:checktype[-12 -14 -15h;dict;parameter];};

// check timecolumn is of type symbol
// check starttime <= endtime
checktimecolumn:{[dict;parameter]:checktype[-11h;dict;parameter];};

// check starttime <= endtime
checktimeorder:{[dict]
    if[dict[`starttime] > dict`endtime;'`$.schema.errors[`checktimeorder;`errormessage]];
    :dict;};

// check parameter is of type symbol
checksyminput:{[dict;parameter]
    :checktype[-11 11h;dict;parameter];};

// check parameter is of type 
checksublist:{[dict;parameter]
    :checktype[-5 -6 -7h;dict;parameter];};

// check aggregations are of type dictionary, that the dictionary has symbol keys, that 
// the dictionary has symbol values
checkaggregations:{[dict;parameter]
    dict:checktype[99h;dict;parameter];
    input:dict parameter;
    if[not 11h~abs type key input;
        '`$.schema.errors[`checkaggregationkey;`errormessage],.schema.examples[`aggregations1;`example]];
    if[not all 11h~/:abs raze type''[get input];
        '`$.schema.errors[`checkaggregationparameter;`errormessage],.schema.examples[`aggregations1;`example]];
    :dict;
  };

// check that timebar parameter has three elements of respective types: numeric, symbol,
// symbol.
checktimebar:{[dict;parameter]
    input:dict parameter;
    if[not(3=count input)&0h~type input;
        '`$.schema.errors[`timebarlength;`errormessage]];
    input:`size`bucket`timecol!input;
    if[not any -6 -7h~\:type input`size;
        '`$.schema.errors[`firsttimebar;`errormessage]];
    if[not -11h~type input`bucket;
        '`$.schema.errors[`secondtimebar;`errormessage]];
    if[not -11h~type input`timecol;
        '`$.schema.errors[`thirdtimebar;`errormessage]];
    :dict;
  };

// check that filters parameter is of type dictionary, has symbol keys, the values are 
// in (where function;value(s)) pairs and (not)within filtering functions have two values
// associated with it.
checkfilters:{[dict;parameter]
    dict:checktype[99h;dict;parameter];
    dict[parameter]:@[(dict parameter);where {not all 0h=type each x}each (dict parameter);enlist];
    input:dict parameter;
    if[not 11h~abs type key input;
        '`$.schema.errors[`filterkey;`errormessage],.schema.examples[`filters1;`example]];
    (input`nottest):enlist(not;in;10 30);
    filterpairs:raze value input;
    if[any not in[count each filterpairs;2 3];
        '`$.schema.errors[`filterpair;`errormessage],.schema.examples[`filters1;`example]];
    if[not 15 in value each first each filterpairs where 3=count each filterpairs;
        '`$.schema.errors[`filternot;`errormessage],.schema.examples[`filters1;`example]];
    nots:where(~:)~/:ops:first each filterpairs;
    notfilters:@\:[;1]filterpairs nots;
    if[not all in[ops;.schema.allowedops];'`$.schema.errors[`allowedops;`errormessage]];
    if[not all in[notfilters;.schema.allowednot];'`$.schema.errors[`allowednot;`errormessage]];
    .checkinputs.withincheck'[filterpairs];
    .checkinputs.inequalitycheck'[filterpairs];
    :dict;
  };

withincheck:{[pair]
    if[(("within"~string first pair)| "within[~:]"~string first pair)& 2<>count last pair;
        '`$.schema.errors[`withincheck;`errormessage],.schema.examples[`filters3;`example]];};

inequalitycheck:{[pair]
    errmess:.schema.errors[`inequalities;`errormessage],.schema.examples[`filters3;`example];
    errmess2:.schema.errors[`equalities;`errormessage],.schema.examples[`filters3;`example];
    if[(("~<"~string first pair)|(enlist"<")~string first pair)& 1<>count last pair;
        '`$errmess2];
    if[(("~>"~string first pair)|(enlist">")~string first pair)& 1<>count last pair;
        '`$errmess2];
    if[(((enlist"=")~string first pair)|(enlist"~")~string first pair)&1<>count last pair;
        '`$errmess2];
    if[("~="~string first pair)&1<>count last pair;
        '`$errmess];};

// check that ordering parameter contains only symbols and is paired in the format
// (direction;column).
checkordering:{[dict;parameter]
    if[11h=type dict parameter;dict[parameter]:enlist dict parameter];
    input:dict parameter;
    if[11h<>type raze input;
        '`$.schema.errors[`checkorderingpair;`errormessage],.schema.examples[`ordering1;`example]];
    if[0<>count except[count each input;2];
        '`$.schema.errors[`checkorderingarrangment;`errormessage],.schema.examples[`ordering1;`example]];
    if[0<>count except[first each input;`asc`desc];
        '`$.schema.errors[`checkorderingdirection;`errormessage],.schema.examples[`ordering1;`example]];
    grouping:$[`grouping in key dict;(),dict`grouping;()];
    timebar:$[`timebar in key dict;dict`timebar;()];
    if[`aggregations in key dict;
        aggs:dict`aggregations;
        aggs:flip(key[aggs]where count each get aggs;raze aggs);
        names:{
            if[count[x 1]in 1 2;
                :`$raze string[x 0],.[string (),x 1;(::;0);upper]]
        }'[aggs];
        if[any raze {1<sum y=x}[last each aggs]'[last each input];
            '`$.schema.errors[`orderingvague;`errormessage],.schema.examples[`ordering2;`example]];
        if[any not in[last each input;names,grouping,timebar[2],last each aggs];
            '`$.schema.errors[`orderingnocolumn;`errormessage]]];
    if[in[`columns;key dict];
        if[not enlist[`]~columns:(),dict`columns;
            if[any not l:last'[input]in columns;
                badorder:","sv string last'[input]where not l; 
                '`$.checkinputs.formatstring[.schema.errors[`badorder;`errormessage];`$badorder]]]];
    :dict;};
    
// check that the instrumentcol parameter is of type symbol
checkinstrumentcolumn:{[dict;parameter]:checktype[-11h;dict;parameter];};

checkrenamecolumn:{[dict;parameter]
    dict:checktype[99 -11 11h;dict;parameter];
    input:dict parameter;
    if[type[input]in -11 11h;:dict];
    if[99h~type input;
        if[not (type key input)~11h;
            '`$.schema.errors[`renamekey;`errormessage],.schema.examples[`renamecolumn;`example]];
        if[not (type raze input)~11h;
            '`$.schema.errors[`renameinput;`errormessage],.schema.examples[`renamecolumn;`example]]];
  :dict;};

checkpostprocessing:{[dict;parameter]
    dict:checktype[100h;dict;parameter];
    if[1<>count (get dict parameter)[1];
        '`$.schema.errors[`postback;`errormessage]];
    :dict;};

isstring:{[dict;parameter]:checktype[10h;dict;parameter];};

checktype:{[validtypes;dict;parameter]
    inputtype:type dict parameter;
    if[not any validtypes~\:inputtype;'`$.checkinputs.formatstring[.schema.errors[`checktype;`errormessage];`parameter`validtypes`inputtype!(parameter;validtypes;inputtype)]];
    :dict;
    };

isboolean:{[dict;parameter]:checktype[-1h;dict;parameter];};

isnumb:{[dict;parameter]:checktype[-7h;dict;parameter]};

checkjoin:{[dict;parameter]:checktype[107h;dict;parameter];};

checkpostback:{[dict;parameter]
    if[()~dict parameter;:dict];
    if[not `sync in key dict;'`$.schema.errors[`asyncpostback;`errormessage]]
    if[not dict`sync;'`$.schema.errors[`asyncpostback;`errormessage]]
    :checkpostprocessing[dict;parameter]};

checktimeout:{[dict;parameter]
    checktype[-16h;dict;parameter];
    :dict};
