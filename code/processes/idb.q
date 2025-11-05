/-default parameters
\d .idb

wdbtypes:@[value;wdbtypes;`wdb];
wdbconnsleepintv:@[value;`wdbconnsleepintv;10];
wdbcheckcycles:@[value;`wdvcheckcycles;0W];

/-these parameters are only used once their value has been set with values retrieved from the WBD.
writedownmode:idbdir:savedir:currentpartition:symfilepath:`;
symsize:partitionsize:0;

/-force loads sym file
loadsym:{[]
    .lg.o[`load;"loading the sym file"];
    @[load;symfilepath; {.lg.e[`load;"failed to load sym file: ",string[symfilepath]," error: ",x]}];
    symsize::hcount symfilepath;
 };

/-force loads IDB
loadidb:{[]
    .lg.o[`load;"loading the db"];
    @[system; "l ", 1_string idbdir; {.lg.e[`load;"failed to load IDB: ",string[idbdir]," error: ",x]}];
    partitionsize::count key idbdir;
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
    idbdir::.Q.dd[savedir; $[writedownmode~`default;`;currentpartition]];
    .lg.o[`rollover;"IDB folder has been set to: ",string[idbdir]];
    loaddb[];
 };

/- reloads the db. Called by wdb process midday/eod.
intradayreload:{[]
    starttime:.proc.ct[];
    if[symfilehaschanged[];loadsym[]];
    if[partitioncounthaschanged[];loadidb[]];
    clearrowcountcache[];
    .lg.o[`intradayreload;"IDB reload has been finished for partition: ",string[currentpartition],". Time taken(ms): ",string .proc.ct[]-starttime];
 };

/- checks if sym file has changed since last reload of the IDB. Records new sym size if changed.
symfilehaschanged:{[]
    $[symsize<>c:hcount symfilepath;[symsize::c; 1b];0b]
 };

/- checks if count of partitions has changed since last reload of the IDB. Records new partition count if changed.
/- the default writedown method doesn't need db reloading as no new directory is being created there.
/- First check is to ensure that a single intraday partition exists (so loadidb doesn't fail)
partitioncounthaschanged:{[]
    if[(1j~partitionsize)&writedownmode~`default;:0b];
    $[partitionsize<>c:count key idbdir;[partitionsize::c; 1b];0b]
 };

/- each time data gets appended to current partition we are invalidating the row count cache
/- this makes sure running "count trade" queries will return correct row count
clearrowcountcache:{.Q.pn:.Q.pt!(count .Q.pt)#()};

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
    /- If no valid conneciton to wdb, reattempt
    .servers.startupdepcycles[`wdb;wdbconnsleepintv;wdbcheckcycles];
    .lg.o[`init;"getting connection handle to the WDB"];
    w:.servers.gethandlebytype[wdbtypes;`any];
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

/- set the reload the function
reload:.idb.intradayreload;

/-Get the relevant IDB attributes
.proc.getattributes:{`partition`tables!(.idb.currentpartition;tables[])};

.idb.init[];

/- helper function to support queries against the sym column
maptoint:{[val]
    $[(abs type val) in 5 6 7h;
        /- if using an integer column, clamp value between 0 and max int (null maps to 0)
        0| 2147483647& `long$ val;
        /- if using a symbol column, enumerate against the hdb sym file
        sym?`TORQNULLSYMBOL^val]
 };

/- helper function to support queries against the sym column in partbyfirstchar 
mapfctoint:{[val]
     .Q.an?$[0<type x;first each;first] string val
 };
