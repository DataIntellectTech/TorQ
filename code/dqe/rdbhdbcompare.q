\d .dqe
rdbhdbcompare:{[tab]                                    // this function should be ran in the rdb
  h:hopen (`::56003:admin:admin);
  hdbmeta:h(meta;tab);
  removeddate:select c,t,f from hdbmeta where c<>`date;
  $[removeddate~select c,t,f from meta tab;
    (1b;"schema of rdb and hdb matches");
    (0b;"schema of rdb and hdb doesnt match")]
  }
