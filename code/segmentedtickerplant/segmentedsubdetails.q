// the subdetails function adapted to also retrieve filters from the segmented tickerplant
segmentedsubdetails: {[tabs;instruments;id] (!). flip 2 cut (
	`schemalist ; .ps.subscribe\:[tabs;instruments];				//
	`logfilelist ; .stplg.replaylog[tabs];						//
	`rowcounts ; tabs#.stplg `rowcount;						//
	`date ; (.eodtime `d);								//
	`logdir ; `$getenv`KDBTPLOG;							//
	`filters ; ?[`tpconfig;enlist(=;`segmentID;id);0b;()]	//
	)}
