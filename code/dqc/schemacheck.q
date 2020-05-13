\d .dqc

/- checks that the meta of a table matches expectation
schemacheck:{[tab;colname;types;forkeys;attribute]
  .lg.o[`dqc;"checking schema of table mathces expectation"];
  origschema:0!meta tab;
  checkschema:([]c:colname;t:types;f:forkeys;a:attribute);
  / Function to replace empty symbols with underscores in error messages.
  f: {@[x;where 0=count each string x;{`$"_"}]};
  $[all c:checkschema~'origschema;
    (1b;"Schema of ",(string tab)," matched proposed schema");
    (0b;"The following columns from the schema of table ",(string tab)," did not match expectation: ",(", "sv string origschema[`c][where not c]),". Expected schema from the columns: ",(", "sv raze each string f each checkschema[where not c][`t`f`a]),". Actaul Schema: ",", "sv raze each string f each origschema[where not c][`t`f`a])]
  }
