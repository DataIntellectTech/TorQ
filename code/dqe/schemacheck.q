\d .dqe
schemacheck:{[tab;types;colname;attribute]
  origschema:select c,t,a from meta tab;
  checkschema:([]c:colname;t:types;a:attribute);
  (c;"type of ",(","sv string(),col)," ",$[c:origschema~checkschema;"matched";"did not match"]," proposed schema")
  }
