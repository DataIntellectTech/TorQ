//- order the query params

\d .queryorder

orderquery:{[queryparams]enlist[?],(gettablename;getwhereclause;getbyclause;getselectclause)@\:queryparams};

gettablename:{[queryparams]queryparams`tablename};

getwhereclause:{[queryparams]
  datefilter:queryparams`datefilter;
  whereclause:extractkeys[queryparams;`instrumentfilter`timefilter`filters`freeformwhere];
  whereclause:reorderbyattributecolumn[queryparams;whereclause];
  :datefilter,whereclause;
 };

//- if we have filters otf (=;`sym;1#`APPL) or (in;`sym;`APPL`GOOG), where `sym is the column with the attribute - put them to the fron
reorderbyattributecolumn:{[queryparams;whereclause]
  where1:where any(=;in)~/:\:first'[whereclause];
  if[0=count where1;:whereclause];
  attributecolumn:.dataaccess.gettableproperty[queryparams`tablename;`any;`attributecolumn]; //- atm .dataaccess.tablepropertiesconfig has separate rows for the rdb/hdb - use `any to retieve whichever comes first
  where2:where1 inter where attributecolumn~/:whereclause[;1];
  if[0=count where2;:whereclause];
  attribureindex:first where2;
  :@[whereclause;0,attribureindex;:;whereclause attribureindex,0];
 };

getbyclause:{[queryparams]
  byclause:extractkeys[queryparams;`timebar`grouping`freeformby];
  if[()~byclause;:0b];
  byclause:inter[`date,queryparams`attributecolumn;key byclause]xcols byclause; //- group on `date`sym first (if they exist), then timecol, then remaining args
  :byclause;
 };

getselectclause:{[queryparams] extractkeys[queryparams;`columns`aggregations`freeformselect]};

extractkeys:{[queryparams;k]
  k:k inter key queryparams;
  :raze queryparams k;
 };
