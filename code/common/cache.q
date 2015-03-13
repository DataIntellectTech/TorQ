// cache the result of functions in memory

\d .cache

// the maximum size of the cache in MB
maxsize:@[value;`.cache.maxsize;100]

// the maximum size of any individual result set in MB
maxindividual:@[value;`.cache.maxindividual;50]

// make sure the maxindividual isn't bigger than maxsize 
maxindividual:maxsize&maxindividual

MB:2 xexp 20

// a table to store the cache values in memory
cache:([id:`u#`long$()] lastrun:`timestamp$();lastaccess:`timestamp$();size:`long$())

// a dictionary of the functions
funcs:(`u#`long$())!()
// the results of the functions
results:(`u#`long$())!()

// table to track the cache performance
perf:([]time:`timestamp$();id:`long$();status:`symbol$())

id:0j
getid:{:id+::1}

// add to cache
add:{[function;id;status]
	// Don't trap the error here - if it throws an error, we want it to be propagated out
	res:value function;
	$[(maxindividual*MB)>size:-22!res;
		// check if we need more space to store this item
		[now:.proc.cp[];
		if[0>requiredsize:(maxsize*MB) - size+sum exec size from cache; evict[neg requiredsize;now]];
		// Insert to the cache table
		`.cache.cache upsert (id;now;now;size);
		// and insert to the function and results dictionary
		funcs[id]:enlist function;
		results[id]:enlist res;
		// Update the performance
		trackperf[id;status;now]];
		// Otherwise just log it as an addfail - the result set is too big
		trackperf[id;`fail;.proc.cp[]]];
	// Return the result	
	res}

// Drop some ids from the cache
drop:{[ids]
	ids,:();
	delete from `.cache.cache where id in ids;
	.cache.results : ids _ .cache.results;
	}
	
// evict some items from the cache - need to clear enough space for the new item
// evict the least recently accessed items which make up the total size
// feel free to write a more intelligent cache eviction policy !
evict:{[reqsize;currenttime]
	r:select from 
		(update totalsize:sums size from `lastaccess xasc select lastaccess,id,size from cache)
	where prev[totalsize]<reqsize;
	drop[r`id];
	trackperf[r`id;`evict;currenttime];
	}

trackperf:{[id;status;currenttime] `.cache.perf insert ((count id)#currenttime;id;(count id)#status)}

// check the cache to see if a function exists with a young enough result set
execute:{[func;age]
	// check for a value in the cache which we can use
	$[count r:select id,lastrun from .cache.cache where .cache.funcs[id]~\:enlist func;
		// There is a value in the cache.
		[r:first r;
		// We need to check the age - if the specified age is greater than the actual age, return it
		// else delete it
  		$[age > (now:.proc.cp[]) - r`lastrun;
			// update the cache stats, return the cached result
		 	[update lastaccess:now from `.cache.cache where id=r`id;
			 trackperf[r`id;`hit;now];
			 first results[r`id]];
			// value found, but too old - re-run it under the same id
			[drop[r`id];
			 add[func;r`id;`rerun]]]];
		// it's not in the cache, so add it
		add[func;getid[];`add]]}

// get the cache performance
getperf:{update function:.cache.funcs[id] from .cache.perf}

\

// examples	
\d . 
f:{system"sleep 2";20+x}
g:{til x}
// first time should be slow
-1"calling f ",(-3!f)," first time should be slow";
\t .cache.execute[(`f;2);0D00:01]
-1"\nsecond time fast, provided the result value isn't too old (i.e. older than 0D00:01)";
\t .cache.execute[(`f;2);0D00:01]
-1"\nNote the access time for f has been updated";
show .cache.cache
-1"\nCall g a few times - can cause big result sets";
.cache.execute[(`g;5000000);0D00:01];
.cache.execute[(`g;4000000);0D00:01];
.cache.execute[(`f;2);0D00:01];
-1"\nCalling g with different params causes old results to be removed - need to clear out space";
-1"The results will be cleared out in the order corresponding to their last access time";
-1"\nBefore:";
show .cache.cache
.cache.execute[(`g;5100000);0D00:01];
-1"\nAfter:";
show .cache.cache
-1"\nCalling f with a very short cache age causes the result to be refreshed";
\t .cache.execute[(`f;2);0D00:00:00.000000001]
show .cache.cache
-1"\nCan execute strings and adhoc functions";
.cache.execute["20+35";0D00:30];
.cache.execute[({x+y};20;30);1D];
show .cache.cache
-1"\nCan track the performance of the cache - see what is sticking for a long time, what gets evicted quickly etc";
show .cache.getperf[]
