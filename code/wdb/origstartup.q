\d .wdb
startup:{[]
    .lg.o[`init; "searching for servers"];
    .servers.startup[];
    .lg.o[`init; "writedown mode set to ",(string .wdb.writedownmode)];
    $[writedownmode~`partbyattr;
      .lg.o[`init; "partition has been set to [savedir]/[",(string partitiontype),"]/[tablename]/[parted column(s)]/"];
      writedownmode~`partbyenum;
      .lg.o[`init; "partition has been set to [savedir]/[",(string partitiontype),"]/[parted symbol column enumerated]/[tablename]/"];
      .lg.o[`init; "partition has been set to [savedir]/[",(string partitiontype),"]/[tablename]/"]];
    if[saveenabled;
       //check if tickerplant is available and if not exit with error
       if[not .finspace.enabled; /-TODO Remove when tickerplant fixed in finspace
          .servers.startupdepcycles[.wdb.tickerplanttypes; .wdb.tpconnsleepintv; .wdb.tpcheckcycles];
         ];
       subscribe[];
      ];
    @[`.; `upd; :; .wdb.upd];
 }