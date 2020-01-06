\d .dqe
schemacheck:{[tab;schema]
  origschema:select t from meta tab;
  checkschema:([]t:schema);
  $[origschema~checkschema;
    (1b;"schema of ",(string tab)," match proposed schema");
    (0b;"schema of ",(string tab)," did not match proposed schema")]
  }

colnamecheck:{[tab;colname]
  origcol:cols tab;
  $[origcol~colname;
    (1b;"column names of ",(string tab)," match proposed column names");
    (0b;"column names of ",(string tab)," did not match proposed column names")]
  }
