/-default parameters
\d .idb

/- loads the idb and the sym file for given partition
loaddb:{[pt]
    ptdir: ` sv  .idb.savedir,(`$string[pt]),`;
    if[() ~ key ptdir;.lg.e[`load;"missing intraday db folder: ",string ptdir]];
    @[system; "l ", 1_string ptdir; {.lg.e[`load;"failed to reload db from folder: ",string[y]," error: ",x]}[;ptdir]];
    symfilepath: ` sv .idb.savedir,`sym;
    @[load; symfilepath; {.lg.e[`load;"failed to reload sym file: ",x]}];
 };

/- reloads the db. Called by wdb process midday/eod.
intradayreload:{[pt]
    loaddb[pt];
 };

/- sets up the idb pased on input from wdb. Creates a symlink to hdb sym file for further usage
/- 1. savedir - the location of wdbhdb
/- 2. pt - current partition of the wdb(and idb). It is the current date normally
setup:{[savedir;pt]
    .lg.o[`init;"setup has been called for db dir: ",string[savedir]," and partition: ", string pt];
    .idb.savedir:savedir;
    symlinkpath:` sv .idb.savedir,`sym;
    hdbsymfile:` sv .idb.hdbdir,`sym;
    /- we create a link here to the hdb symfile - this only has to be done once, and its place is NOT the partition folder
    /- as that gets manipulated by the wdb continously
    .lg.o[`init;"creating symlink for sym file in hdb: ",string[hdbsymfile]," at: ",string[symlinkpath]];
    $[0=count key symlinkpath;.os.createalias[hdbsymfile;symlinkpath];.lg.o[`init;"symbolic link already exists: ",string symlinkpath]];
    /- loading the initial db, the wdb supposed to create the table schemas there already
    loaddb[pt];
    .lg.o[`init;"setup finished"];
 };

\d .
/- helper function to support queries against the sym column
maptoint:{[symbol]
    sym?symbol
 };
