/-default parameters
\d .idb

/-these parameters are only used once their value has been set with values retrieved from the WBD.
writedownmode:idbdir:savedir:currentpartition:symfilepath:`;
symsize:partitionsize:0;

/-force loads sym file
loadsym:{[]
    symfilehaschanged[];
    .lg.o[`load;"sym file has changed, reloading"];
    @[load;symfilepath; {.lg.e[`load;"failed to load sym file: ",string[symfilepath]," error: ",x];'x}];
 };

/-force loads IDB
loadidb:{[]
    partitioncounthaschanged[];
    .lg.o[`load;"number of partitions on disk has changed, reloading"];
    @[system; "l ", 1_string idbdir; {.lg.e[`load;"failed to load IDB: ",string[idbdir]," error: ",x];'x}];
 };

/- force loads the idb and the sym file
loaddb:{[]
    starttime:.proc.ct[];
    loadsym[];
    loadidb[];
    .lg.o[`load;"IDB load has been finished for partition: ",string[currentpartition],". Time taken(ms): ",string .proc.ct[]-starttime];
 };

/- sets current partition and force loads the idb and the sym file. Called by the WDB after EOD.
rollover:{[pt]
    currentpartition::pt;
    idbdir::.Q.dd[savedir; currentpartition];
    loaddb[];
 };

/- reloads the db. Called by wdb process midday/eod.
intradayreload:{[]
    starttime:.proc.ct[];
    if[symfilehaschanged[];loadsym[]];
    if[partitioncounthaschanged[];loadidb[]];
    .lg.o[`intradayreload;"IDB reload has been finished for partition: ",string[savedir],". Time taken(ms): ",string .proc.ct[]-starttime];
 };

/- checks if sym file has changed since last reload of the IDB. Records new sym size if changed.
symfilehaschanged:{[]
    $[symsize<>c:hcount symfilepath;[symsize::c; 1b];0b]
 };

/- checks if count of partitions has changed since last reload of the IDB. Records new partition count if changed.
/- the default writedown method doesn't need db reloading as no new directory is being created there.
partitioncounthaschanged:{[]
    if[writedownmode~`default;:0b];
    $[partitionsize<>c:count key idbdir;[partitionsize::c; 1b];0b]
 };

setparametersfromwdb:{[wdbHandle]
    .lg.o[`init;"querying WDB, HDB locations, current partition and writedown mode from WDB"];
    params:@[wdbHandle; (each;value;`.wdb.savedir`.wdb.hdbdir`.wdb.currentpartition`.wdb.writedownmode); {.lg.e[`connection; "Failed to retrieve values from WDB."]; 'x}];
    savedir::hsym params[0];
    currentpartition::params[2];
    symfilepath::.Q.dd[hsym params[1]; `sym];
    writedownmode::params[3];
    idbdir::.Q.dd[savedir; $[writedownmode~`default;`;currentpartition]];
    .lg.o[`init;"Current settings: db folder: ",string[idbdir],", sym file: ",string[symfilepath],", writedownmode: ", string writedownmode];
 };

init:{[]
    .lg.o[`init; "searching for servers"];
    .servers.startup[];
    .lg.o[`init;"getting connection handle to the WDB"];
    w:first exec w from .servers.getservers[`proctype;`wdb;()!();1b;1b];
    /-exit if no valid handle
    if[0=count w; .lg.e[`connection;"no connection to the WDB could be established... failed to initialise."];:()];
    .lg.o[`init;"found a WDB process"];
    /-setting parameters in .idb namespace from WDB
    setparametersfromwdb[w];
    .lg.o[`init;"loading the db and the sym file first time"];
    loaddb[];
    .lg.o[`init;"registering IDBs on WDB process..."];
    /-send sync message to WDB to register the existing IDBs.
    @[w;(`.servers.registerfromdiscovery;`idb;0b);{.lg.e[`connection;"Failed to register IDB with WDB."];'x}];
    .lg.o[`init; "Initialisation of the IDB is done."];
    }

\d .

.idb.init[];

/- helper function to support queries against the sym column
maptoint:{[symbol]
    sym?symbol
 };
