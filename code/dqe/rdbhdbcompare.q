\d .dqe
rdbhdbcompare:{[tab;hdbproc;rdbproc]                             //- function should be run on dqc, compares hdb and rdb parameters
  hdbmeta:(first exec w from .servers.getservers[`procname;hdbproc;()!();1b;0b])(meta;tab);
  rdbmeta:(first exec w from .servers.getservers[`procname;rdbproc;()!();1b;0b])(meta;tab);
  removeddate:select c,t,f from hdbmeta where c<>`date;
  $[removeddate~select c,t,f from rdbmeta;
    (1b;"schema of rdb and hdb matches");
    (0b;"schema of rdb and hdb doesnt match")]
  }
