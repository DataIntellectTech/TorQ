\d .rmvr

//function for replacing environment variables with the associated full path. 

removeenvvar:{
 	// positions of {}
	pos:ss[x]each"{}";
	// check the formatting is ok
	$[0=count first pos; :x;
	1<count distinct count each pos; '"environment variable contains unmatched brackets: ",x;
	(any pos[0]>pos[1]) or any pos[0]<prev pos[1]; '"failed to match environment variable brackets on supplied string: ",x;
	()];

	// cut out each environment variable, and retrieve the meaning
	raze {$["{"=first x;getenv`$1 _ -1 _ x;x]}each (raze flip 0 1+pos) cut x}
