/TorQ Orchestrator Process

\d .orch

/default parameters

scalingdetails:([] time:`timestamp$(); procname:`$(); dir:`$(); instancecreated:`$(); instanceremoved:`$(); totalnumofinstances:`int$(); lowerlimit:`int$(); upperlimit:`int$());	/table for tracking scaling

inputcsv:hsym first .proc.getconfigfile"processlimits.csv";	/location of csv file
limits:@[{.lg.o[`scale;"Opening ", x];`procname xkey ("SII"; enlist ",") 0:`$x}; (string inputcsv); {.lg.e[`scale;"failed to open ", (x)," : ",y];'y}[string inputcsv]];	/table of scalable processes and the max number of instances allowed for each

scaleprocslist:exec procname from limits;	/list of scalable processes

/initialises connection to discovery process and creates keyed table containing the number of instances of each scalable process
getscaleprocsinstances:{[] 
	.servers.startup[];
	`.orch.procs set exec procname from .servers.procstab where proctype=`hdb;
	scaleprocsinstances:count each group first each ` vs/:procs; 
	`.orch.scaleprocsinstances set ([procname:key scaleprocsinstances] instances:value scaleprocsinstances);
	}

getscaleprocsinstances[];

/function to scale up or down a process
scale:{[procname;dir]
	if[dir=`up;op:"-u ";limitcheck:{x>=y};limit:`upper;parentproc:procname];
	
	if[dir=`down;op:"-d ";limitcheck:{x<=y};limit:`lower;parentproc:first ` vs procname];

	if[limitcheck[scaleprocsinstances[parentproc;`instances];limits[parentproc;limit]]; .lg.o[`scale;string[limit]," limit hit for ",string parentproc]; :()];

	system "bash ${TORQHOME}/scale.sh ",op,string procname;
	/update number of process instances
	getscaleprocsinstances[];
	/update table with record for scaling
	`.orch.scalingdetails upsert (.z.p;parentproc;dir;$[dir=`up;` sv parentproc,`$string .orch.scaleprocsinstances[parentproc;`instances];`];$[dir=`down;procname;`];scaleprocsinstances[parentproc;`instances];limits[parentproc;`lower];limits[parentproc;`upper]);	
	}

/function to ensure all processes have been scaled up to meet lower limit
initialscaling:{[procname]
	if[scaleprocsinstances[procname;`instances]<limits[procname;`lower];
		reqinstances:limits[procname;`lower]-scaleprocsinstances[procname;`instances]; 
		do[reqinstances;scale[procname;`up]];
	];
	}

initialscaling@/:scaleprocslist;
