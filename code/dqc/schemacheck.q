\d .dqc

/- checks that the meta of a table matches expectation
schemacheck:{[tab;colname;types;forkeys;attribute]
  origschema:meta tab;
  checkschema:([c:colname]t:types;f:forkeys;a:attribute);
  (c;"type of ",(","sv string(),colname)," ",$[c:origschema~checkschema;"matched";"did not match"]," proposed schema")
  }
