//- order the query params

\d .queryorder

orderquery:{[queryparams]
    :enlist[?],(gettable;getwhere;getby;getselect)@\:queryparams;
 };

gettable:{[queryparams]queryparams`tablename};

getwhere:{[queryparams]
  whereclause:extractkeys[queryparams;`instrumentfilter`timefilter`filters`freeformwhere];
  whereclause:reorderwhere[queryparams;whereclause];
  :whereclause;
 };

//- Put the filter with the attribute column in the index place
reorderbyattr:{[queryparams;whereclause]
  // Gets the attribute column
  attributecolumn:.dataaccess.gettableproperty[queryparams;`attributecolumn];
  // Looks if any of the where clauses contain the attribute as a filter
  where1:where attributecolumn~/:whereclause[;1];
  // Checks if anythere is an s attribute on the time column and put filters on that next
  if[`time in 0!select columns from .dataaccess.metainfo[queryparams`tablename][`metas] where attributes=`s;where1:where1,where `time~/:whereclause[;1]];
  // If none of the filters are based on the attribute return original query
  if[0=count where1;:whereclause];
  // Put the filter based on the attributes to the top
  :@[whereclause;((til count where1),where1);:;whereclause where1,(til count where1)];
 };

getby:{[queryparams]
  byclause:extractkeys[queryparams;`timebar`grouping`freeformby];
  if[()~byclause;:0b];
  byclause:inter[`date,queryparams`attributecolumn;key byclause]xcols byclause; //- group on `date`sym first (if they exist), then timecol, then remaining args
  :byclause;
 };

getselect:{[queryparams] extractkeys[queryparams;`columns`aggregations`freeformcolumn]};

extractkeys:{[queryparams;k]
  k:k inter key queryparams;
  :raze queryparams k;
  };

//- Put the partition filter top of the query
orderpartedtable:{[queryparams;whereclause]
    // Errors out if there is no partition filter
    if[queryparams[`partitionfilter]~();'"Include a partition filter"];
    // Returns the query with the partion filter at the top
    :(queryparams[`partitionfilter],whereclause);
    };

//-reorder the where clause to filter through the partitions (if applicable) then the attribute column, then everything else
reorderwhere:{[queryparams;whereclause]
    // If applicable, put the filter on the attribute column at the top
    whereclause:reorderbyattr[queryparams;whereclause];
    // If the table isn't parted return the where clause
    if[not .Q.qp value queryparams[`tablename];:whereclause;];
    // If it is partitioned add the partition filter at the top
    :orderpartedtable[queryparams;whereclause];
    };
