//- order the query params

\d .queryorder

orderquery:{[queryparams]
  query:enlist[?],(gettable;getwhere;getby;getselect)@\:queryparams;
  renamecolumns[queryparams;query];
  if[queryparams`optimisation;
    // If there is no by clause or if the by clause isn't on sym just enlist the query
    if[0b~@[query;3] ;:enlist query];
    // If there is a sym in the by clause
    if[`sym in value query[3];:splitquerybysym[query];]];
  :enlist query;
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
  attributecolumn:.checkinputs.gettableproperty[queryparams;`attributecolumn];
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
//- Check if the provided dictionary/list can be used to rename before the query is split and executed
renamecolumns:{[queryparams;query]
   // Get the rename list/dictionary
   order:queryparams `renamecolumn;
   // Get the old column names
   if[0b~ query[3];query[3]:()!()];
   if[()~query[4];
       query[4]:(cols queryparams[`tablename])!cols queryparams[`tablename]];
   // If the type of query is a list check the list isn't too long
   if[11h= type order;
       if[(count order)>count query[3],query[4];
           '`$"length of renamecolumns is too long"];
       :1];
   // If it is a dictionary check all the keys of the dictionary are column headings
   if[not all (key order) in key query[3],query[4];'`$"Dictionary keys need to be old column names"];
   :1;
   };

//- Converts a filter otf "sym in" to multiple queries otf "sym=" the reduces the amount of RAM used and if there is a `g attribute on sym speeds up the query
splitquerybysym:{[query]
  // extract the sym filter if applicable
  symfilter:where(in;`sym)~/:(@[query;2][;til 2]);
  // If there is no sym filter then return the original query
  if[0=count symfilter;:enlist query];
  query[2;symfilter;0]:=;
  // Extract the symlist
  symlist:raze .[query;2,symfilter,2];
  // Return a list of queries for each sym
  :{.[y;2,z,2;:;enlist x]}[;query;symfilter] each symlist;
  };

gethead:{[query];if[`head in key query;:query[`head]];:0W};
