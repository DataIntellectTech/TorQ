/-default parameters
\d .idb

/- loads the idb and the sym file for given partition
loaddb:{[pt]
    ptdir: ` sv  .idb.savedir,(`$string[pt]),`;
    if[() ~ key ptdir;.lg.e[`load;"missing intraday db folder: ",string ptdir];.idb.setupsuccess:0b];
    @[system; "l ", 1_string ptdir; {.lg.e[`load;"failed to reload db from folder: ",string[y]," error: ",x];.idb.setupsuccess:0b}[;ptdir]];
    symfilepath: ` sv .idb.savedir,`sym;
    @[load; symfilepath; {.lg.e[`load;"failed to reload sym file: ",x];.idb.setupsuccess:0b}];
 };

/- reloads the db. Called by wdb process midday/eod.
intradayreload:{[pt]
    /- first check if IDB is properly setup, if not, try to setup again
    if[not .idb.setupsuccess;setup[.idb.savedir;pt]];
    loaddb[pt];
 };

/- sets up the idb. Creates a symlink to hdb sym file for further usage
/- 1. savedir - the location of wdbhdb
/- 2. pt - current partition of the wdb(and idb). It is the current date normally
setup:{[savedir;pt]
    .idb.setupsuccess:1b;
    .lg.o[`init;"setup has been called for db dir: ",string[savedir]," and partition: ", string pt];
    .idb.savedir:savedir;
    symlinkpath:` sv .idb.savedir,`sym;
    hdbsymfile:` sv .idb.hdbdir,`sym;
    /- we create a link here to the hdb symfile - this only has to be done once, and its place is NOT the partition folder
    /- as that gets manipulated by the wdb continuously
    $[0=count key symlinkpath;.os.createalias[hdbsymfile;symlinkpath];
      .lg.o[`init;"symbolic link already exists: ",string symlinkpath]];
    if[0=count key symlinkpath;.lg.e[`init;"IDB setup failed. IDB is still not setup."];.idb.setupsuccess:0b];
    /- loading the initial db, the wdb supposed to create the table schemas there already
    loaddb[pt];
    .lg.o[`init;"setup finished"];
 };

\d .
/- helper function to support queries against the sym column
maptoint:{[symbol]
    sym?symbol
 };

.idb.setup[.idb.savedir;.idb.initialpartition];
