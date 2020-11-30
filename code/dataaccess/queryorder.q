//- order the query params

\d .queryorder

orderquery:{[queryparams]
  query:([]proctype:`$();query:());
  if[queryparams`hdbvalidrange;query,:getprocqueryorder[queryparams]];
  if[queryparams`rdbvalidrange;query,:getprocqueryorder[@[queryparams;`partitionfilter;:;()];]];
  :query;
 };

getprocqueryorder:{[queryparams]
    :`proctype`query!(queryparams`proctype;enlist[?],(gettable;getwhere;getby;getselect)\:queryparams);
 };

gettable:{[queryparams]queryparams`tablename};

getwhere:{[queryparams]
  partitionfilter:queryparams`partitionfilter;
  whereclause:extractkeys[queryparams;`instrumentfilter`timefilter`filters`freeformwhere];
  whereclause:reorderbyattributecolumn[queryparams;whereclause];
  :partitionfilter,whereclause;
 };

//- if we have filters otf (=;`sym;1#`APPL) or (in;`sym;`APPL`GOOG), where `sym is the column with the attribute - put them to the front
reorderbyattributecolumn:{[queryparams;whereclause]
  where1:where any(=;in)~/:\:first'[whereclause];
  if[0=count where1;:whereclause];
  attributecolumn:.dataaccess.gettableproperty[queryparams;`attributecolumn]; 
  where2:where1 inter where attributecolumn~/:whereclause[;1];
  if[0=count where2;:whereclause];
  attributeindex:first where2;
  :@[whereclause;0,attributeindex;:;whereclause attributeindex,0];
 };

getby:{[queryparams]
  byclause:extractkeys[queryparams;`timebar`grouping`freeformby];
  if[()~byclause;:0b];
  byclause:inter[`date,queryparams`attributecolumn;key byclause]xcols byclause; //- group on `date`sym first (if they exist), then timecol, then remaining args
  :byclause;
 };

getselect:{[queryparams] extractkeys[queryparams;`columns`aggregations`freeformselect]};

extractkeys:{[queryparams;k]
  k:k inter key queryparams;
  :raze queryparams k;
 };
