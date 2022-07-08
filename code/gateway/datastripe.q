\ .ds

// create a function which will retrieve the access tables from the subscribers
getaccess:{[]

    // get handle(w) for each proctype given in list given by .server.getservers
    handles:(.servers.getservers[`proctype;;()!();1b;1b] .ds.subscribers)[`w];

    // get data from access tables in each subscriber and append to gateway access table
    .gw.access: @[value;`.gw.access;([location:() ; table:()] start:() ; end:() ; stptime:() ; keycol:())];
    .gw.access: .gw.access ,/ ({[x] x"`location`table xkey update location:.proc.procname,proctype:.proc.proctype from .ds.access"} each handles);

    }

.gw.endofperiod:{[currp;nextp;data]
    getaccess[];
    }

initdatastripe:{[]
    getaccess[];
    endofperiod::.gw.endofperiod;
    }

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];
