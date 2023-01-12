\d .ds

// create a function which will retrieve the access tables from the subscribers
getaccess:{[]

    // get handle(w) for each proctype given in list given by .server.getservers
    handles:(.servers.getservers[`proctype;;()!();1b;1b] .ds.subscribers)[`w];

    // get data from access tables in each subscriber and append to gateway access table, with trapping to default to empty table
    .gw.access: @[value;`.gw.access;([location:() ; table:()] start:() ; end:() ; stptime:() ; keycol:() ; proctype:())];
    .gw.access,: raze @[{[x] x(`.ds.getaccess;`)};;([location:() ; table:()] start:() ; end:() ; stptime:() ; keycol:() ; proctype:())] each handles;

    };

// create a function to update the access table at end of period
updateaccess:{[newtab]

    // append newtab to access table
    .gw.access,: newtab;

    };

// create a function to retrieve stripe mapping
getstripemapping:{[]
    .lg.o[`.ds.getstripemapping;"reloading stripe mapping"];
    rdbhandle:first exec w from .servers.getservers[`proctype;`rdb_seg1;()!();1b;0b];
    .ds.subreq::rdbhandle".ds.subreq";      // retrieve from rdb (consider changing to avoid blocking handle)
    .lg.o[`.ds.getstripemapping;"stripe map reload complete"];
    };

\d .

.proc.addinitlist[(`.ds.getaccess;`)];
