\d .wdb
startup:{[]
        .lg.o[`init;"searching for servers"];
        .servers.startup[];
        if[writedownmode in partwritemodes;
                .lg.o[`init;"writedown mode set to ",(string .wdb.writedownmode)]
                ];
        .lg.o[`init;"partition has been set to [savedir]/[", (string partitiontype),"]/[tablename]/", $[writedownmode in partwritemodes;"[parted column(s)]/";""]];
        if[saveenabled;
                //check if tickerplant is available and if not exit with error
                if[not .finspace.enabled;                                                       /-TODO Remove when tickerplant fixed in finspace
                        .servers.startupdepcycles[.wdb.tickerplanttypes;.wdb.tpconnsleepintv;.wdb.tpcheckcycles];
                ];
                subscribe[];
		];
	@[`.;`upd;:;.wdb.upd];
        }
