// Functionality to return approx. memory size of kdb+ objects

\d .mem

// half size for 2.x
version:.5*1+3.0<=.z.K;

// set the pointer size based on architecture
ptrsize:$["32"~1_string .z.o;4;8];

attrsize:{version*
	  // `u#2 4 5 unique 32*u
	  $[`u=a:attr x;32*count distinct x;
	  // `p#2 2 1 parted (8*u;32*u;8*u+1)
	    `p=a;8+48*count distinct x;
	    0]
	};

// (16 bytes + attribute overheads + raw size) to the nearest power of 2
calcsize:{[c;s;a] `long$2 xexp ceiling 2 xlog 16+a+s*c};

vectorsize:{calcsize[count x;typesize x;attrsize x]};

// raw size of atoms according to type, type 20h->76h have 4 bytes pointer size
typesize:{4^0N 1 16 0N 1 2 4 8 4 8 1 8 8 4 4 8 8 4 4 4 abs type x};

threshold:100000;

// pick samples randomly accoding to threshold and apply function
sampling:{[f;x]
        $[threshold<c:count x;f@threshold?x;f x]
        };

// scale sampling result back to total population
scaleSampling:{[f;x]
	sampling[f;x]*max(1;count[x]%threshold)
	};

objsize:{
	// count 0
	if[not count x;:0];
	// flatten table/dict into list of objects
	x:$[.Q.qt x;(key x;value x:flip 0!x);
	    99h=type x;(key x;value x);
	    x];
	// special case to handle `g# attr
	// raw list + hash
	if[`g=attr x;x:(`#x;group x)];
	// atom is fixed at 16 bytes, GUID is 32 bytes
	$[0h>t:type x;$[-2h=t;32;16];
        // list & enum list
          t within 1 76h;vectorsize x;
	// exit early for anything above 76h
	  76h<t;0;
	// complex = complex type in list, pointers + size of each objects
	  0h in t:sampling[type each;x];calcsize[count x;ptrsize;0]+"j"$scaleSampling[{[f;x]sum f each x}[.z.s];x];
	// complex = if only 1 type and simple list, pointers + sum count each*first type
	// assume count>1000 has no attrbutes (i.e. table unlikely to have 1000 columns, list of strings unlikely to have attr for some objects only
	  (d[0] within 1 76h)&1=count d:distinct t;calcsize[count x;ptrsize;0]+"j"$scaleSampling[{sum calcsize[count each x;typesize x 0;$[1000<count x;0;attrsize each x]]};x];
	// other complex, pointers + size of each objects
	  calcsize[count x;ptrsize;0]+"j"$scaleSampling[{[f;x]sum f each x}[.z.s];x]]
	};

\d .
