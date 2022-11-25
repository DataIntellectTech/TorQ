/TorQ orchestrator process

\d .orchestrator

/default parameters

/table for tracking scaling
/list of scalable processes
/current number of processes by their proctype

/function to scale up a process
scaleup:{[procname]
	system "bash addproc.sh ",string procname;
	/update number of processes by category
	/update table with record for scaling up
	}

/function to scale down a process
scaledown:{[]
	}
