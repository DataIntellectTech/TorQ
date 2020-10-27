//- order the query params

\d .queryorder

orderquery:{[queryparams]
  query:([]proctype:`$();query:());
  if[queryparams`hdbvalidrange;query,:getprocqueryorder[queryparams;`proctypehdb;`hdbtimefilter]];
  if[queryparams`rdbvalidrange;query,:getprocqueryorder[queryparams;`proctyperdb;`rdbtimefilter]];
  :query;
 };

getprocqueryorder:{[queryparams;proctype;proctimefilter]
  :`proctype`query!(queryparams proctype;enlist[?],(gettablename;getwhereclause;getbyclause;getselectclause).\:(queryparams;proctimefilter));
 };

gettablename:{[queryparams;proctimefilter]queryparams`tablename};

getwhereclause:{[queryparams;proctimefilter]
  partitionfilter:queryparams`partitionfilter;
  whereclause:extractkeys[queryparams;`instrumentfilter,proctimefilter,`filters`freeformwhere];
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

getbyclause:{[queryparams;proctimefilter]
  byclause:extractkeys[queryparams;`timebar`grouping`freeformby];
  if[()~byclause;:0b];
  byclause:inter[`date,queryparams`attributecolumn;key byclause]xcols byclause; //- group on `date`sym first (if they exist), then timecol, then remaining args
  :byclause;
 };

getselectclause:{[queryparams;proctimefilter] extractkeys[queryparams;`columns`aggregations`freeformselect]};

extractkeys:{[queryparams;k]
  k:k inter key queryparams;
  :raze queryparams k;
 };
