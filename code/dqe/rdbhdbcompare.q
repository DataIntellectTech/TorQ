\d .dqe
rdbhdbcompare:{[tab]
  hdbmeta:(first exec w from .servers.getservers[`procname;`hdb1;()!();1b;0b])(meta;tab);
  rdbmeta:(first exec w from .servers.getservers[`procname;`rdb1;()!();1b;0b])(meta;tab);
  removeddate:select c,t,f from hdbmeta where c<>`date;
  $[removeddate~select c,t,f from rdbmeta;
    (1b;"schema of rdb and hdb matches");
    (0b;"schema of rdb and hdb doesnt match")]
  }
