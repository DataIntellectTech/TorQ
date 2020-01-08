\d .dqe
schemacheck:{[tab;schema;colname]
  origschema:select t,c from meta tab;
  checkschema:([]t:schema;c:colname);
  (c;"type of ",(","sv string(),col)," ",$[c:origschema~checkschema;"matched";"did not match"]," proposed schema")
  }
