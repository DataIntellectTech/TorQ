\d .dqc

/- checks that the meta of a table matches expectation
schemacheck:{[tab;colname;types;forkeys;attribute]
  .lg.o[`dqc;"checking schema of table mathces expectation"];
  origschema:0!meta tab;
  checkschema:([]c:colname;t:types;f:forkeys;a:attribute);
  $[all ((flip 0!origschema)each key flip 0!origschema)~'(flip 0!checkschema)each key flip 0!checkschema;
  }
