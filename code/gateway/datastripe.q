\ .ds

// create a function which will retrieve the access tables from the subscribers
getaccess:{[]

    // get handle(w) for each proctype given in list given by .server.getservers
    handles:(.servers.getservers[`proctype;;()!();1b;1b] .ds.subscribers)[`w];

    // get data from access tables in each subscriber and append to gateway access table
    .gw.access: @[value;`.gw.access;([location:() ; table:()] start:() ; end:() ; stptime:() ; keycol:() ; proctype:())];
    .gw.access,: raze {x(`.ds.getaccess;`)} each handles;

    };

\ .d

initdatastripe:{[]
    getaccess[];
    };

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];
