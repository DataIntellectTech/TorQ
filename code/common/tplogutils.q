/ - functions for checking and repairing (if required) a tickerplant log file
\d .tplog

HEADER: 8 # -8!(`upd;`trade;());			/ - header to build deserialisable msg
UPDMSG: `char$10 # 8 _ -8!(`upd;`trade;());	/ - first part of tp update msg
CHUNK: 10 * 1024 * 1024;					/ - size of default chunk to read (10MB)
MAXCHUNK: 8 * CHUNK;						/ - don't let single read exceed this

check: {[logfile;lastmsgtoreplay]
	/ - logfile (symbol) is the handle to the logsfile
	/ - lastmsgtoreplay (long) is index position of the last message to be replayed from the log
	.lg.o[`tplog.check;"Checking ",string[logfile]," .  Index of last message to replay is : ",string lastmsgtoreplay];
	/ - check if the logfile is corrupt
	loginfo: -11!(-2;logfile);
	.lg.o[`tplog.check;"Finished running check on log file.  Result is : ",.Q.s1 loginfo];
	:$[ 1 = count loginfo;
		/ - the log file is good so return the good log file handle
		[.lg.o[`tplog.check;"The logfile is not corrupt"];logfile];
	/ - elseif the number of messages to be replayed is lower than the number of good messages then don't bother repairing the log
	loginfo[0] <= lastmsgtoreplay + 1;
		[.lg.o[`tplog.check;"The logfile is corrupt but the number of messages to replay (",string[lastmsgtoreplay + 1],") is less than the number of messages (",string[loginfo 0],")that can be read from the log"];logfile];
	/ - else run the repair function and return out the handle for the "good" log
		[.lg.o[`tplog.check;"The logfile is corrupt, attempting to write a good log"];repair[logfile]]
	]
	};
	
repair: {[logfile]
	/ - append ".good" to the "good" log file
	goodlog: `$ string[logfile],".good";
	.lg.o[`tplog.repair;"Writing good log to ",string goodlog];
	/ - create file and open handle to it
	goodlogh: hopen goodlog set ();
	/ - loop through the file in chunks
	.lg.o[`tplog.repair;"Starting to loop through the log file - ",string logfile];
	repairover[logfile;goodlogh] over `start`size!(0j;CHUNK);
	.lg.o[`tplog.repair;"Finished looping through the log file - ",string logfile];
	/ - return goodlog
	goodlog
	};
	
repairover: {[logfile;goodlogh;d]
	/ - logfile (symbol) is the handle to the logsfile
	/ - goodlogh (int) is  the handle to the "good" log file
	/ - d (dictionary) has two keys start and size, the point to start reading from and size of chunk to read
	.lg.o[`tplog.repairover;"Reading logfile with an offset of : ",string[d`start]," bytes and a chunk of size : ",string[d`size]," bytes"];
	x:read1 logfile,d`start`size;			/ - read <size> bytes from <start>
	u: ss[`char$x;UPDMSG];					/ - find the start points of upd messages
	if[not count u;							/ - nothing in this block 
		if[hcount[logfile] <= sum d`start`size;:d];	/ - EOF - we're done
		:@[d;`start;+;d`size]];				/ - move on <size> bytes
	m: u _ x;								/ - split bytes into msgs
	mz: 0x0 vs' `int$ 8 + ms: count each m;	/ - message sizes as bytes
	hd: @[HEADER;7 6 5 4;:;] each mz;		/ - set msg size at correct part of hdr
	g: @[(1b;)@-9!;;(0b;)@] each hd,'m;		/ - try and deserialize each msg
	goodlogh g[;1] where k:g[;0];			/ - write good msgs to the "good" log 
	if[not any k;							/ - saw msg(s) but couldn't read
		if[MAXCHUNK <= d`size;				/ - read as much as we dare, give up
			:@[d;`start`size;:;(sum d`start`size;CHUNK)]];
		:@[d;`size;*;2]];					/ - read a bigger chunk
	ns: d[`start] + sums[ms] last where k;	/ - move to the end of the last good msg
	:@[d;`start`size;:;(ns;CHUNK)];       
	};