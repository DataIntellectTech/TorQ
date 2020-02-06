\d .dqe
hdbmeta:neg[exec w from .servers.SERVERS where procname=`hdb1]() /// not sure what to put yet
rdbmeta:neg[exec w from .servers.SERVERS where procname=`rdb1]()
rdbhdbcompare:{[tab]                                    // this function should be ran in the rdb
  removeddate:select c,t,f from hdbmeta where c<>`date;
  $[removeddate~select c,t,f from rdbmeta;
    (1b;"schema of rdb and hdb matches");
    (0b;"schema of rdb and hdb doesnt match")]
  }
