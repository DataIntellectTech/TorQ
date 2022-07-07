/\ .ds

// create a function which will retrieve the access tables from the subscribers
getaccess:{[]

    // get handles for subscribers
    rdbhandles: first value flip ?[`.gw.servers;enlist (=;`servertype;enlist `rdb);0b;(enlist `handle)!(enlist `handle)];
    wdbhandles: first value flip ?[`.gw.servers;enlist (=;`servertype;enlist `wdb);0b;(enlist `handle)!(enlist `handle)];
    handles:rdbhandles,wdbhandles;

    // get data from access tables in each subscriber and append to gateway access table
    .gw.access: @[value;`.gw.access;([location:() ; table:()] start:() ; end:() ; stptime:() ; keycol:())]
    .gw.access: .gw.access ,/ {[x] x"`location`table xkey update location:.proc.procname,proctype:.proc.proctype from .ds.access"} each handles;

    }

/getaccess[]
