\d .dqe
rdbhdbcompare:{[tab]
  hdbmeta:(first exec w from .servers.SERVERS where procname=`hdb1)(meta;tab);
  rdbmeta:(first exec w from .servers.SERVERS where procname=`rdb1)(meta;tab);
  removeddate:select c,t,f from hdbmeta where c<>`date;
  $[removeddate~select c,t,f from rdbmeta;
    (1b;"schema of rdb and hdb matches");
    (0b;"schema of rdb and hdb doesnt match")]
  }
