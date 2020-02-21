//Master slave algorithm
//Each process initially assumes it's the master process
//Master process is determined by oldest process start time 
//Connect to other slave processes and retrieve details to determine which process is master

//run lines
//q torq.q -load lb.q -proctype lb -procname lb1 -p 6100 -debug -parentproctype wdb
//q torq.q -load lb.q -proctype lb -procname lb2 -p 6101 -debug -parentproctype wdb


// the list of processes to connect to
.servers.CONNECTIONS:`lb

// custom function, this is invoked when a new outbound connection is created
// to be customised to invoke negotiation of processes
.servers.connectcustom:{.lg.o[`connect;"found new connection"]; show x}

// create connections
.servers.startup[]

\d .masterslave

//table scehma of connected lb processes with ismaster status
statustable:([handle:`int$()] procname:`symbol$();starttimeUTC:`timestamp$();ismaster:`boolean$())

//store own process start timestamp
start:.z.p

//set details dict with own details
details:{`procname`starttimeUTC`ismaster!(.proc.procname;.masterslave.start;1b)} 

//get details of procname provided
getdetails:{[processname] (first exec w from .servers.SERVERS where procname like processname) ".masterslave.details[]"}

//update .masterslave.statustable with other proc details and update ismaster col to determine which process is master 
addmember:{[processname]
    update ismaster:0b from (`.masterslave.statustable upsert .masterslave.getdetails[processname],(enlist `handle)!(enlist first exec w from .servers.SERVERS  where procname like processname)) where starttimeUTC<>min starttimeUTC}

//is the process itself the master
ammaster:{exec ismaster from .masterslave.statustable where handle=0}

//find which process is the master
findmaster:{first exec handle from .masterslave.statustable where ismaster=1b}

//wrapper func for finding master
checkifmaster:{
    .servers.startup[];
    .masterslave.addmember each string exec procname from .servers.SERVERS where proctype like "lb", not null w
 }

//add pc override here
//remove dropped connection from statustable
//tell other alive processes to renegotiate who the master is 


\d .

//populate statutable and find which process is master
.masterslave.checkifmaster[]


//.z.pc call 
