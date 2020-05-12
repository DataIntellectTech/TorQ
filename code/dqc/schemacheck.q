\d .dqc

/- checks that the meta of a table matches expectation
schemacheck:{[tab;colname;types;forkeys;attribute]
  .lg.o[`dqc;"checking schema of table mathces expectation"];
  origschema:0!meta tab;
  checkschema:([]c:colname;t:types;f:forkeys;a:attribute);
  $[all c:((flip origschema)each key flip origschema)~'(flip checkschema)each key flip checkschema;
    (1b;"Schema of ",(string tab)," matched proposed schema");
    (0b;"The following columns from the schema of table ",(string tab)," did not match expectation: ",(("columnname";"types";"foreignkeys";"attribute")[where not c]),"Expected: ",(raze string checkschema[(`c`t`f`a)[where not c]]),"Actual Schema: ",(raze string origschema[(`c`t`f`a)[where not c]]))]
  }
