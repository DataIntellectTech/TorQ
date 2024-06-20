/-default parameters
\d .idb

/- loads the idb and the sym file for current partition
loaddb:{[pt]
    ptdir: ` sv  .idb.savedir,(`$string[pt]),`;
    if[() ~ key ptdir;.lg.e[`load;"missing intraday db folder: ",string ptdir]];
    system"l ", 1_string ptdir;
    symfilepath: ` sv .idb.savedir,`sym;
    @[load; symfilepath; {.lg.e[`load;"failed to reload sym file: ",x]}];
 };

/- reloads the db. Called by wdb process midday.
intradayreload:{[pt]
    loaddb[pt];
 };

/- sets up the idb pased on input from wdb.
/- 1. savedir - the location of wdbhdb
/- 1. pt - current partition of the wdb(and idb). It is the current date normally
setup:{[savedir;pt]
    .lg.o[`init;"setup has been called for db dir: ",string[savedir]," and partition: ", string pt];
    .idb.savedir:savedir;
    symlinkpath:` sv .idb.savedir,`sym;
    hdbsymfile:` sv .idb.hdbdir,`sym;
    /- we create a link here to the hdb symfile - this only has to be done once, and it's place is NOT the partition folder
    /- as that gets manipulated by the wdb continously
    .lg.o[`init;"creating symlink for sym file in hdb: ",string[hdbsymfile]," at: ",string[symlinkpath]];
    $[0=count key symlinkpath;.os.symlink[hdbsymfile;symlinkpath];.lg.o[`init;"symbolic link already exists: ",string symlinkpath]];
    /- loading the initial db, the wdb supposed to create the table schemas there already
    loaddb[pt];
    .lg.o[`init;"setup finished"];
 };

\d .
/- helper function to support queries against the sym column
maptoint:{[symbol]
    sym?symbol
 };
