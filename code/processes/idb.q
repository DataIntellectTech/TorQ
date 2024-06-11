/-default parameters
\d .idb

reload:{[pt]
    .lg.o[`reload;"reload command has been called remotely with partition: ", string pt];
    .lg.o[`reload;"Doing nothing."];
    .lg.o[`reload;"Finished reloading IDB"];
 };

/- loads the idb and the sym file. Called by the wdb process after every writedown.
intradayreload:{[pt]
    ptdir: ` sv  .idb.savedir,(`$string[pt]),`;
    if[0=count key ptdir;:()];
    system"l ", 1_string ptdir;
    symfilepath: ` sv .idb.savedir,`sym;
    @[load; symfilepath; {.lg.e[`reload;"failed to reload sym file: ",x]}];
    .idb.currentpartition:pt;
 };

initpartition:{[pt]
    .lg.o[`init;"Initializing partition: ", string pt];
    .lg.o[`init;"Nothing to do"];
 };

/- make sure to request connections for all the correct types
.servers.CONNECTIONS:(distinct .servers.CONNECTIONS,`wdb) except `;

startup:{[]
    .lg.o[`init;"searching for servers"];
    .servers.startup[];
    // make sure the wdb folder exists
    .os.md .idb.savedir;
    // create a symlink to the hdb sym file in the wdb folder
    symlinkpath:` sv .idb.savedir,`sym;
    $[0=count key symlinkpath;.os.symlink[` sv .idb.hdbdir,`sym;symlinkpath];.lg.o[`init;"symbolic link already exists: ",string symlinkpath]];
    .lg.o[`init;"idb startup completed"];
 };

/- initialise the idb process
.idb.startup[];

\d .
/- helper function to support queries against the sym column
maptoint:{[symbol]
    sym?symbol
 };
