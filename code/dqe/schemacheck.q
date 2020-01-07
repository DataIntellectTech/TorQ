\d .dqe
schemacheck:{[tab;schema]
  origschema:select t from meta tab;
  checkschema:([]t:schema);
  (c;"attribute of ",(","sv string(),col)," ",$[c:origschema~checkschema;"matched";"did not match"]," proposed schema")
  }

colnamecheck:{[tab;colname]
  origcol:cols tab;
  (c;"attribute of ",(","sv string(),col)," ",$[c:origcol~colname;"matched";"did not match"]," proposed column names")
  }
