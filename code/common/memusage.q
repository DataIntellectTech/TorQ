// Functionality to return approx. memory size of kdb+ objects

\d .mem

// half size for 2.x
version:.5*1+3.0<=.z.K;

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

objsize:{
	// flatten table/dict into list of objects
	x:$[.Q.qt x;(key x;value x:flip 0!x);
	    99h=type x;(key x;value x);
	    x];
	// special case to handle `g# attr
	// raw list + hash
	if[`g=attr x;x:(`#x;group x)];
	// atom is fixed at 16 bytes, GUID is 32 bytes
	$[0h>t:type x;$[-2h=t;32;16];
	// complex = pointers + size of each objects
	  0h=t;calcsize[count x;8;0]+sum .z.s each x;
	// list & enum list
	  t within 1 77h;vectorsize x;
	// ignore others
	  0]
	};

\d .
