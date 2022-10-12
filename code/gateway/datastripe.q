\d .ds

// function to add datastripe processes to the gateway connections
addsegprocs:{
    // Allows config file to be overwritten in process.csv
    stripeconf:$[not""~x:first .proc.params[`.ds.stripeconfig];x;"striping.json"];
    scpath:first .proc.getconfigfile[stripeconf];
	// Check for successful json read in
    stripeconfig:@[{.j.k read1 x}; scpath;{.lg.e[`configload;"Failed to load in striping.json file: ",x]}];
    // get relevant proctypes from the json file
	stripeprocs:{[stripeconfig;segments]
	    stripeconfig[segments][1]
		};
	relevantprocs:`$raze exec rdbtypes,tailers,tailreaders from stripeprocs[stripeconfig;] each key stripeconfig;
	// adds all relevant processes of all segments to server table
	.servers.register[.servers.procstab;;0b] each relevantprocs;
	.servers.CONNECTIONS,:relevantprocs;
	.gw.addserversfromconnectiontable[.servers.CONNECTIONS]
	};
    
// create a function which will retrieve the access tables from the subscribers
getaccess:{[]

    // get handle(w) for each proctype given in list given by .server.getservers
    handles:(.servers.getservers[`proctype;;()!();1b;1b] .servers.CONNECTIONS)[`w];

    // get data from access tables in each subscriber and append to gateway access table, with trapping to default to empty table
    .gw.access: @[value;`.gw.access;([location:() ; table:()] start:() ; end:() ; stptime:() ; keycol:() ; proctype:() ; segment:())];
    .gw.access,: raze @[{[x] x(`.ds.getaccess;`)};;([location:() ; table:()] start:() ; end:() ; stptime:() ; keycol:() ; proctype:() ; segment:())] each handles;

    };

// create a function to update the access table at end of period
updateaccess:{[newtab]

    // append newtab to access table
    .gw.access,: newtab;

    };
	
initdatastripe:{
     addsegprocs[];
     getaccess[];
     }
\d .

.proc.addinitlist[(`.ds.initdatastripe;`)];
