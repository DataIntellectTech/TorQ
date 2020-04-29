\d .dqc

/- takes a query as a string, tries to evaluate it and adds to results table
/- whether or not it passed
freeform:{[query]
  if[not 10h=type query;
    :(0b;"error: query must be sent as type string")];
  if[11h=type a:@[value;query;{`error}];
    c:not `error=a;
    :(c;query,$[c;" passed";" failed"])];
  (1b;query," passed")
  } 
