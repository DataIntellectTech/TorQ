//This script will cut off any slow subscibers if they exceed a memory limit

\d .subcut
cutenabled:@[value;`cutenabled;0b]		//flag for enabling subscriber cutoff. true means slow subscribers will be cut off
maxsize:@[value;`maxsize;1000]			//a global value for the max queue size of a subscriber
procsize:@[value;`procsize;()!()]			//a dictionary of process type and that processes queue size. This value will take precedence over maxsize
checkfreq:@[value;`checkfreq;0D00:01]		//the frequency for running the queue size check on subscribers


.proc.extrausage:"Subscriber Cutt-off:\n
 [-.subcut.cutenabled [0|1]]\t\t\tBoolean variable to switch subscribercutoff.q on or off. Default is 0b
 [-.subcut.maxsize x]\t\t\tThe default queue size for when a subscriber will be cut off if exceeded. Default is ***
 [-.subcut.procsize x]\t\t\tA dictionary that can be populated with process type and a queue size limit for that process. eg.`rdb!1000. This value overwrites maxsize for that process type. Default is ()!()
 [-.subcut.checkfreq x]\t\t\tThe period of time to check the queue length of subscribers. Default is 0D00:01" 


checksubs:{

	.lg.o[`subscribercutoff;"Subscriber cut-off enabled.Checking handle sizes"];
	
	{[handle]
	//Get process type for input handle from ,clients.clients
	proctype:first exec u from .clients.clients where w=handle;
	
	//if this process type is in dictionary procsize check the handle size against the procsize limit, else check the handle size against the maxsize limit
        $[proctype in key procsize;
                {[handle;proctype]if[(sum .z.W[handle]) > first procsize[proctype];(hclose handle;.u.del[;handle] each .u.t;.lg.o[`subscribercutoff;"Cutting off subscriber on handle ",string handle])]}[handle;proctype];
                {[handle]if[(sum .z.W[handle]) > maxsize;(hclose handle;.u.del[;handle] each .u.t;.lg.o[`subscribercutoff;"Cutting off subscriber on handle ",string handle])]}handle]} each key .z.W
	 }


if[cutenabled;.timer.rep[.proc.cp[];0Wp;checkfreq;(`.subcut.checksubs`);0h;"run subscribercutoff";1b]];
