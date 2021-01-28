\d .dataaccess
// All queries have initial checks performed then sent to the correct processes
syncexec:{[o] .checkinputs.checkinputs[o];.requests.logger[o;()];.gw.syncexec[(`getdata;o);datesrouting[o]]};
syncexecj:{[o;j] o:.checkinputs.checkinputs[o];.requests.logger[o;()];.gw.syncexecj[(`getdata;o);datesrouting[o];j]};
syncexecjt:{[o;j;t] o:.checkinputs.checkinputs[o];.requests.logger[o;()];.gw.syncexecjt[(`getdata;o);datesrouting[o];j;t]};
syncexecs:{[o;s] o:.checkinputs.checkinputs[o];.requests.logger[o;()];.gw.syncexec[(`getdata;o);s]};
syncexecsj:{[o;s;j] o:.checkinputs.checkinputs[o];.requests.logger[o;()];.gw.syncexecj[(`getdata;o);s;j]};
syncexecsjt:{[o;s;j;t] o:.checkinputs.checkinputs[o];.requests.logger[o;()];.gw.syncexecjt[(`getdata;o);s;j;t]};




// Decides which processes send the query to 
datesrouting:{[input]
    //Get the start and end time
    timespan:input[`starttime`endtime];
    // Get most recent Rollover
    rollover:lastrollover[];
    :@[`hdb`rdb;where(timespan[0]<rollover;timespan[1]>rollover)];
    };
