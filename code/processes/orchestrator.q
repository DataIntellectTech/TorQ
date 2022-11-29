/TorQ Orchestrator Process

\d .orch

/default parameters

scalingdetails:([] time:`timestamp$(); procname:`$(); dir:`$(); totalnumofinstances:`int$(); limit:`int$());	/table for tracking scaling

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
	/update number of process instances
	getscaleprocsinstances[];
	/update table with record for scaling up
	`.orch.scalingdetails upsert (.z.p;procname;`up;.orch.scaleprocsinstances[procname;`instances];.orch.upperlimits[procname;`limit]);
	}

/function to scale down a process
scaledown:{[procname]
	system "bash removeproc.sh ",string procname;
	/update number of process instances
	getscaleprocsinstances[];
	/update table with record for scaling down
	`.orch.scalingdetails upsert (.z.p;procname;`down;.orch.scaleprocsinstances[procname;`instances];.orch.upperlimits[procname;`limit]);
	}
