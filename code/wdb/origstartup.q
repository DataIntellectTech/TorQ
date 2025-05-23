\d .wdb
startup:{[]
    .lg.o[`init; "searching for servers"];
    .servers.startup[];
    .lg.o[`init; "writedown mode set to ",(string .wdb.writedownmode)];
    $[writedownmode~`partbyattr;
      .lg.o[`init; "partition has been set to [savedir]/[",(string partitiontype),"]/[tablename]/[parted column(s)]/"];
      writedownmode~`partbyenum;
      .lg.o[`init; "partition has been set to [savedir]/[",(string partitiontype),"]/[parted column enumerated]/[tablename]/"];
      .lg.o[`init; "partition has been set to [savedir]/[",(string partitiontype),"]/[tablename]/"]];
    if[saveenabled;
       //check if tickerplant is available and if not exit with error
       if[not .finspace.enabled; /-TODO Remove when tickerplant fixed in finspace
          .servers.startupdepcycles[.wdb.tickerplanttypes; .wdb.tpconnsleepintv; .wdb.tpcheckcycles];
         ];
       subscribe[];
       /- add missing tables to partitions in case an IDB process wants to connect. Only applicable for partbyenum writedown mode
       if[.wdb.writedownmode in `default`partbyenum;initmissingtables[currentpartition]];
       // if for replay table maxrows were customised, we want to check row count for each table, save and gc where needed
       if[(not .wdb.numtab~.wdb.replaynumtab)or .wdb.numrows<>.wdb.replaynumrows;
          tabs:exec table from .sub.SUBSCRIPTIONS;
          tabmaxrowpairs:{(x;.wdb.maxrows[x])}each tabs;
          {replaymaxrowcheck[first x;last x]}each tabmaxrowpairs];
      ];
    @[`.; `upd; :; .wdb.upd];
 }
