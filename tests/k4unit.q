/ k4 unit testing, loads tests from csv's, runs+logs to database
/ csv columns: action,ms,bytes,lang,code (csv with colheaders)
/ if your code contains commas enclose the whole code in "quotes"
/ usage: q k4unit.q -p 5001

\d .KU
VERBOSE:@[value;`.KU.VERBOSE;1];                // 0 - no logging to console, 1 - log filenames, >1 - log tests
DEBUG:$[`stop in key .Q.opt .z.x;1;0];          // 0 - trap errors, 1 - suspend if errors (except action=`fail)
DELIM:@[value;`.KU.DELIM;","];                  // csv delimiter
SAVEFILE:@[value;`.KU.SAVEFILE;`:KUTR.csv];     // test results savefile
\d .

/ KUT <-> KUnit Tests
KUT:([]action:`symbol$();ms:`int$();bytes:`long$();lang:`symbol$();code:`symbol$();repeat:`int$();minver:`float$();file:`symbol$();comment:())
/ KUltd `:dirname and/or KUltf `:filename.csv
/ KUrt[] / run tests
/ KUTR <-> KUnit Test Results
/ KUrtf`:filename.csv / refresh expected <ms> and <bytes> based on observed results in KUTR
KUTR:flip `action`ms`bytes`lang`code`repeat`file`msx`bytesx`ok`okms`okbytes`valid`timestamp`csvline!"SIJSSISIJBBBBZI" $\: ();
/ look at KUTR in browser or q session
/ select from KUTR where not ok // KUerr
/ select from KUTR where not okms // KUslow
/ select count i by ok,okms,action from KUTR
/ select count i by ok,okms,action,file from KUTR
/ KUstr[] / save test results
/ KUltr[] / reload previously saved test results
/ action:
/ 	`beforeany - onetime, run before any tests
/		`beforeeach - run code before tests in every file
/			`before - run code before tests in this file ONLY
/			`run - run code, check execution time against ms
/			`true - run code, check if returns true(1b)
/			`fail - run code, it should fail (2+`two)
/			`after - run code after tests in this file ONLY
/		`aftereach - run code after tests in each file
/ 	`afterall - onetime, run code after all tests, use for cleanup/finalise
/ lang: k or q (or s if you really feel you must..), default q
/ code: code to be executed
/ repeat: number of repetitions (do[repeat;code]..), default 1
/ ms: max milliseconds it should take to run, 0 => ignore
/ bytes: bytes it should take to run, 0 => ignore
/ minver: minimum version of kdb+ (.z.K)
/ file: filename
/ action,ms,bytes,lang,code,file: from KUT
/ msx: milliseconds taken to eXecute code
/ bytesx: bytes used to eXecute code
/ ok: true if the test completes correctly (note: its correct for a fail task to fail)
/ okms: true if msx is not greater than ms, ie if performance is ok
/ okbytes: true if bytesx is not greater than bytes, ie if memory usage is ok
/ valid: true if the code is valid (ie doesn't crash - note: `fail code is valid if it fails)
/ timestamp: when test was run
/ comment: description of the test if it's obscure..

KUstr:{.KU.SAVEFILE 0:.KU.DELIM 0:update code:string code from KUTR} / save test results
KUltr:{`KUTR upsert("SIJSSIJSIBBBBZI";enlist .KU.DELIM)0:.KU.SAVEFILE} / reload previously saved test results

KUltf:{ / (load test file) - load tests in csv file <x> into KUT
	before:count KUT;
	this:update file:x,action:lower action,lang:`q^lower lang,code:`$code,ms:0^ms,bytes:0j^bytes,repeat:1|repeat,minver:0^minver from `action`ms`bytes`lang`code`repeat`minver`comment xcol("SIJS*IF*";enlist .KU.DELIM)0:x:hsym x;
	KUT,:select from this where minver<=.z.K;
	/KUT,:update file:x,action:lower action,lang:`q^lower lang,ms:0^ms,bytes:0j,repeat:1|repeat from `action`ms`lang`code`repeat`comment xcol("SISSI*";enlist .KU.DELIM)0:x:hsym x;
	neg before-count KUT}

KUltd:{ / (load test dir) - load all *.csv files in directory <x> which conform to k4unit into KUT
	before:count KUT;
	files:f where (lower[f:(` sv) each (x,'key x)] like "*.csv");
	KUltf each files where all each `action`lang`code in/: `$csv vs' first each read0 each files;
	neg before-count KUT}

KUrt:{ / (run tests) - run contents of KUT, save results to KUTR
	update csvline:(raze value exec 2+til count i by file from KUT) from `KUT;
	before:count KUTR;uf:exec asc distinct file from KUT;i:0;
	if[.KU.VERBOSE;.lg.o[`k4unit;"start"]];
	KUerrparse[`beforeany;] exec KUexec'[lang;code;repeat],file,csvline from KUT where action=`beforeany;
	do[count uf;
		ufi:uf[i];KUTI:select from KUT where file=ufi;
		if[.KU.VERBOSE;.lg.o[`k4unit;(string ufi)," ",(string exec count i from KUTI where action in `run`true`fail)," test(s)"]];
		KUerrparse[`beforeach;] exec KUexec'[lang;code;repeat],file,csvline from KUT where action=`beforeeach;
		KUerrparse[`before;] exec KUexec'[lang;code;repeat],file,csvline from KUTI where action=`before;
		/ preserve run,true,fail order
		exec KUact'[action;lang;code;repeat;ms;bytes;file;csvline] from KUTI where action in`true`fail`run;
		KUerrparse[`after;] exec KUexec'[lang;code;repeat],file,csvline from KUTI where action=`after;
		KUerrparse[`aftereach;] exec KUexec'[lang;code;repeat],file,csvline from KUT where action=`aftereach;
		i+:1];
	KUerrparse[`afterall;] exec KUexec'[lang;code;repeat],file,csvline from KUT where action=`afterall;
	if[.KU.VERBOSE;.lg.o[`k4unit;"end"]];
	neg before-count KUTR}

KUpexec:{[prefix;lang;code;repeat;allowfail]
	s:(string lang),")",prefix,$[1=repeat;string code;"do[",(string repeat),";",(string code),"]"];
	if[1<.KU.VERBOSE;.lg.o[`k4unit;s]];
	$[.KU.DEBUG & allowfail;value s;@[value;s;{(`err;`$x;y)}[;code]]]
	}

// If in error - it now returns the error as well as the offending code
KUexec:KUpexec["";;;;1b]

// Generate error logs from beforeeach, before, after and aftereach tests
KUerrparse:{[action;out]
	vals:1_' out where `err ~/: first each out:raze each flip value out;
	.lg.e[`KUexecerr;] each KUerrparseinner[action;;;;] .' vals;
	if[action in `run`true`fail;:1b]
	}

// Handle test runs including error handling
KUrunerr:{[action;out]
	$[`err~first out;
		// For run and true tests, log the error and signal the test failed, for fail tests signal no error
		$[action~`fail;0b;
			action in `run`true;[.lg.e[`KUexecerr;] KUerrparseinner[action;] . 1_out;1b]];
		// For true and fail tests add error string for 'stop mode' if it is activated
		$[action~`run;0b;
			action~`fail;$[.proc.stop;'string[action]," test failure in file ",string[out 1]," on line ",string out 2;1b];
			action~`true;$[first out;0b;$[.proc.stop;'string[action]," test failure in file ",string[out 1]," on line ",string out 2;1b]]
			]
		]
	}

// Generate more detailed error messages
KUerrparseinner:{[action;err;code;file;line] 
	string[action]," error in file ",string[file]," on line ",string[line]," - ",string[err],". Code: '",string[code],"'"
	}

KUact:{[action;lang;code;repeat;ms;bytes;file;line]
	msx:0;bytesx:0j;ok:okms:okbytes:valid:0b;
	if[action=`run;
		r:KUpexec["\\ts ";lang;code;repeat;1b];failed:KUrunerr[action;r,file,line];
		msx:`int$$[failed;0;r 0];bytesx:`long$$[failed;0;r 1];
		ok:not failed;okms:$[ms;not msx>ms;1b];okbytes:$[bytes;not bytesx>bytes;1b];valid:not failed
		];
	if[action=`true;
		r:KUpexec["";lang;code;repeat;1b];failed:KUrunerr[action;r,file,line];
		ok:$[failed;0b;r~1b];okms:okbytes:1b;valid:not failed];
	if[action=`fail;
		r:KUpexec["";lang;code;repeat;0b];failed:not KUrunerr[action;r,file,line];
		ok:failed;okms:okbytes:valid:1b];
	`KUTR insert(action;ms;bytes;lang;code;repeat;file;msx;bytesx;ok;okms;okbytes;valid;.z.Z;line);
	}

KUrtf:{ / (refresh test file) updates test file x with realistic <ms>/<bytes>/<repeat> based on seen values of msx/bytesx from KUTR
	if[not x in exec file from KUTR;'"no test results found"];
	/x 0:.KU.DELIM 0:select action,ms,lang,string code,repeat,comment from((`code xkey KUT)upsert select code,ms:floor 1.25*msx from KUTR)where file=x}
	kut:`code xkey select from KUT where file=x;kutr:select from KUTR where file=x,action=`run;
	kutr:update repeat:1,ms:floor 1.5*msx%repeat from kutr where 75<ms%repeat;
	kutr:update repeat:500000&floor repeat*50%1|msx,ms:75 from kutr where 75>=ms%repeat;
	kutr:update bytes:`long$floor 1.5*bytesx from kutr;
	x 0:.KU.DELIM 0:select action,ms,bytes,lang,string code,repeat,minver,comment from kut upsert select code,ms,bytes,repeat from kutr}

KUsaveresults:{set[hsym[`$getenv[`KDBTESTS],"/previousruns/",string[x]];y]}

KUf::distinct exec file from KUTR / fristance: KUrtf each KUf
KUslow::delete okms from select from KUTR where not okms
KUslowf::distinct exec file from KUslow
KUbig::delete okbytes from select from KUTR where not okbytes
KUbigf::distinct exec file from KUbig
KUerr::delete ok from select from KUTR where not ok
KUerrf::distinct exec file from KUerr
KUinvalid::delete ok,valid from select from KUTR where not valid
KUinvalidf::distinct exec file from KUinvalid

\d .
@[value;"\\l k4unit.custom.q";::];