/TorQ Orchestrator Process

\d .orch

/default parameters

/table for tracking scaling

processlimitscsv:hsym first .proc.getconfigfile"processlimits.csv";	/location of csv file

upperlimits:1!("SI";enlist ",")0:processlimitscsv;	/table of scalable processes and the max number of instances allowed for each

scaleprocslist:exec procname from upperlimits;	/list of scalable processes

/initialises connection to discovery process and creates keyed table containing the number of instances of each scalable process
getscaleprocsinstances:{[] 
	.servers.startup[];
	`.orch.procs set string@/:exec procname from .servers.procstab;
	`.orch.scaleprocsinstances set ([procname:scaleprocslist] instances:{sum procs like x,"*"}@/:string@/:scaleprocslist);
	}

getscaleprocsinstances[];

/function to scale up a process
scaleup:{[procname]
	system "bash addproc.sh ",string procname;
	/update number of processes by category
	getscaleprocsinstances[];
	/update table with record for scaling up
	}

/function to scale down a process
scaledown:{[]
	}
