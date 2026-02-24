//Master slave algorithm
//Each process initially assumes it's the master process
//Master process is determined by oldest process start time
//Connect to other slave processes and retrieve details to determine which process is master

//run lines
//q torq.q -load masterslave.q -proctype lb -procname lb1 -p 6100 -debug -parentproctype wdb
//q torq.q -load masterslave.q -proctype lb -procname lb2 -p 6101 -debug -parentproctype wdb

//test cases
//one process starts up, it becomes master
//two processes, only one is master
//two processes, master dies, slave takes over
//two processes, one is made master, new process added, original master(if it's starttime
// is still oldest)
//two processes, one is made master, an older process is connected, recently connected process
// should then become master
//3 processes, one master, master dies, one of the remaining two takes over

.servers.CONNECTIONS:show distinct .servers.CONNECTIONS,.proc.proctype;
.servers.startup[];
show .servers.SERVERS;

\d .masterslave

init:{
 .masterslave.checkifmaster[];
 .servers.connectcustom:{[f;x] show .servers.SERVERS; show x;.masterslave.addmember[x `.proc.procname];f@x}@[value;`.servers.connectcustom;{{}}];
 .masterslave.masterupdate[]
 };

//table
statustable:([handle:`int$()] procname:`$();starttimeUTC:`timestamp$();ismaster:`boolean$());

//store own process start timestamp
start:.z.p;

//set details dict with own details
details:{
 `procname`starttimeUTC!(.proc.procname;.masterslave.start)
 };

//get details of procname provided
getdetails:{[processname]
 (first exec w from .servers.SERVERS where procname=processname,not null w) (`.masterslave.details;[])
 };

//update .masterslave.statustable with other proc details and update ismaster col to determine which process is master
addmember:{[processname]
 `.masterslave.statustable upsert .masterslave.getdetails[processname],
  (`handle`ismaster)!(first exec w from .servers.SERVERS  where procname=processname,not null w;1b)
 };

masterupdate:{update ismaster:starttimeUTC=min starttimeUTC from `.masterslave.statustable};

//is the process itself the master
ammaster:{first exec ismaster from .masterslave.statustable where handle=0};

//find which process is the master - can only be run after checkifmaster has been run
findmaster:{exec handle, procname from .masterslave.statustable where ismaster=1b};

//wrapper func for finding master
checkifmaster:{
 (.masterslave.addmember')[exec procname from .servers.SERVERS where proctype=.proc.proctype, not null w];
 .masterslave.masterupdate[]
 };



//
//push msgs from master to slaves
//sendtoslaves:{}
//check if master
//1=ammaster[]
//>send msg from master to slave


//push msgs from slaves to master
//sendtomaster:{}
//check if slave
//0=ammaster[]
//>send msg from slave to master 





deletedropped:{[W]delete from `.masterslave.statustable where handle=W};

//add pc override here
//remove dropped connection from statustable
//tell other alive processes to renegotiate who the master is
pc:{[W]
 if[W=0;show "Handle is 0";.masterslave.deletedropped[W]];
 .masterslave.checkifmaster[]
 };


//\d .

//.z.pc call
// .z.pc:{x y;.masterslave.pc[y]}@[value;`.z.pc;{{[x]}}]

