/TorQ Orchestrator Process

\d .orch

/default parameters

scalingdetails:([] time:`timestamp$(); procname:`$(); dir:`$(); totalnumofinstances:`int$(); lowerlimit:`int$(); upperlimit:`int$());	/table for tracking scaling

processlimitscsv:hsym first .proc.getconfigfile"processlimits.csv";	/location of csv file
limits:1!("SII";enlist ",")0:processlimitscsv;	/table of scalable processes and the max number of instances allowed for each
scaleprocslist:exec procname from limits;	/list of scalable processes

/initialises connection to discovery process and creates keyed table containing the number of instances of each scalable process
getscaleprocsinstances:{[] 
	.servers.startup[];
	`.orch.procs set string@/:exec procname from .servers.procstab;
	`.orch.scaleprocsinstances set ([procname:scaleprocslist] instances:{sum procs like x,"*"}@/:string@/:scaleprocslist);
	}

getscaleprocsinstances[];

/function to scale up a process
scaleup:{[procname]
	$[.orch.scaleprocsinstances[procname;`instances]<.orch.limits[procname;`upper];
		[system "bash addproc.sh ",string procname;
		/update number of process instances
		getscaleprocsinstances[];
		/update table with record for scaling up
		`.orch.scalingdetails upsert (.z.p;procname;`up;.orch.scaleprocsinstances[procname;`instances];.orch.limits[procname;`lower];.orch.limits[procname;`upper])];
		.lg.o[`scale;"upper limit hit for ",string procname]
	];
	}

/function to scale down a process
scaledown:{[procname]
	$[.orch.scaleprocsinstances[procname;`instances]>.orch.limits[procname;`lower];
		[latestinstance:last .orch.procs where .orch.procs like string[procname],"*";
		system "bash removeproc.sh ",latestinstance;
		/update number of process instances
		getscaleprocsinstances[];
		/update table with record for scaling down
		`.orch.scalingdetails upsert (.z.p;procname;`down;.orch.scaleprocsinstances[procname;`instances];.orch.limits[procname;`lower];.orch.limits[procname;`upper])];
		.lg.o[`scale;"lower limit hit for ",string procname]
	];
	}
