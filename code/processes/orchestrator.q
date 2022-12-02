/TorQ Orchestrator Process

\d .orch

/default parameters

scalingdetails:([] time:`timestamp$(); procname:`$(); dir:`$(); instancecreated:`$(); instanceremoved:`$(); totalnumofinstances:`int$(); lowerlimit:`int$(); upperlimit:`int$());	/table for tracking scaling

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
	$[scaleprocsinstances[procname;`instances]<limits[procname;`upper];
		[system "bash ${TORQHOME}/addproc.sh ",string procname;
		/update number of process instances
		getscaleprocsinstances[];
		/update table with record for scaling up
		`.orch.scalingdetails upsert (.z.p;procname;`up;`$(last procs where procs like string[procname],"*");`;scaleprocsinstances[procname;`instances];limits[procname;`lower];limits[procname;`upper])];
		.lg.o[`scale;"upper limit hit for ",string procname]
	];
	}

/function to scale down a process
scaledown:{[procname]
	$[scaleprocsinstances[procname;`instances]>limits[procname;`lower];
		[latestinstance:last procs where procs like string[procname],"*";
		system "bash ${TORQHOME}/removeproc.sh ",latestinstance;
		/update number of process instances
		getscaleprocsinstances[];
		/update table with record for scaling down
		`.orch.scalingdetails upsert (.z.p;procname;`down;`;`$latestinstance;scaleprocsinstances[procname;`instances];limits[procname;`lower];limits[procname;`upper])];
		.lg.o[`scale;"lower limit hit for ",string procname]
	];
	}


/function to ensure all processes have been scaled up to meet lower limit
initialscaling:{[procname]
        if[scaleprocsinstances[procname;`instances]<limits[procname;`lower];
                reqinstances:limits[procname;`lower]-scaleprocsinstances[procname;`instances]; 
		do[reqinstances;scaleup[procname]];
        ];
        }

initialscaling@/:scaleprocslist;
