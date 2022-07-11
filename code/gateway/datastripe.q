\d .ds

// create a function which will retrieve the access tables from the subscribers
getaccess:{[]

    // get handle(w) for each proctype given in list given by .server.getservers
    handles:(.servers.getservers[`proctype;;()!();1b;1b] .ds.subscribers)[`w];

    // get data from access tables in each subscriber and append to gateway access table, with trapping to default to empty table
    .gw.access: @[value;`.gw.access;([location:() ; table:()] start:() ; end:() ; stptime:() ; keycol:() ; proctype:())];
    .gw.access,: ;raze @[{[x] x(`.ds.getaccess;`)};;([location:() ; table:()] start:() ; end:() ; stptime:() ; keycol:() ; proctype:())] each handles;

    };

// create a function to update the access table at end of period
updateaccess:{[newtab]

    // append newtab to access table
    .gw.access,: newtab;

    };

\d .

.proc.addinitlist[(`.ds.getaccess;`)];
