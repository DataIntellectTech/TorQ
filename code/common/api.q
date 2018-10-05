// some functions to help build up an api and help the programmer
// allows searching of the q memory space for variables/functions based on pattern matching, returns any associated api entries
// could be used in conjunction with help.q

\d .api

// table to hold some extra descriptive info about each function/param etc
detail:([name:`u#`symbol$()] public:`boolean$(); descrip:();params:();return:())

// map from variable type name to full name
typemap:"fvab"!`function`variable`table`view

// Add a description to the api
add:{[name;public;descrip;params;return] `.api.detail upsert (name;public;descrip;params;return);}

// Get the full var names for a given namespace
varnames:{[ns;vartype;shortpath]
	vars:system vartype," ",string ns;
        // create the full path to the variable.  If it's in . or .q it doesn't have a suffix
        `$$[shortpath and ns in `.`.q;"";(string ns),"."],/:string vars}

// list out a given namespace for a specific variable type
list:{[ns;vartype]
	api:([]name:varnames[ns;vartype;1b]; vartype:typemap vartype; namespace:ns; public:$[ns in `.`.q;1b;0b]) lj .api.detail;
	// re-sort the api table according the order of the description table
	api iasc (exec name from .api.detail)?api`name}

// get all the namespaces in . form
allns:{`$(enlist enlist "."),".",/:string key `}

// Dump out everything across all name spaces
fullapi:{
	res:`name xkey raze list .' allns[] cross key typemap;
	// add in all the q binary functions
	res,([name:.Q.res] vartype:(count .Q.res)#`primitive; namespace:`;public:1b) lj .api.detail}

// find function
// s = search string
// p = public flag (1b or 0b)
// c = context sensitive
find:{[s;p;c]
	// Check the input type
	if[-11h=type s;$[null s; s:enlist"*";s:"*",(string s),"*"]];
	if[not 10h=abs type s:s,(); '"input type must be a symbol or string (character array)"];
 
 	// select from the fullapi on the name matches
	// select by so we only show the table and not the variable (tables appear in both the variable list and the table list)
 	$[c;
		select from fullapi[] where name like s,public in p,i=(last;i) fby name;
		select from fullapi[] where lower[name] like lower s,public in p,i=(last;i) fby name]} 

// find functions 
// f = find all
// p = find public
// u = find all public, user defined
f:find[;01b;0b]
p:find[;1b;0b]
u:{[x] delete from p[x] where namespace in `.q`.Q`.h`.o}

// search the definition of functions for a specific value. Return a table of ([]function;def)
// s = search string
// c = context sensitive
search:{[s;c]
	if[not 10h=type s,:(); '"search value must be a string (character array)"]; 
	raze {[f;s;c] 
		res:([]function:enlist f;definition:enlist def:last value value f);
		$[not 10h=type def; 0#res;
		  $[c;
			(def like s)#res;
			(lower[def] like lower[s])#res]]}[;s;c] each raze varnames[;"f";0b] each allns[]}

// search function
s:.api.search[;0b]

// input list of namespaces for exportconfig
torqnamespaces:` sv'`,'key[`]except`$'.Q.an;

// export the current state of config variables, takes in list of symbols of namespaces (e.g. `.usage`.procs)
exportconfig:{
  // selects only variables in inpoutted namespaces
  :?[.api.f`;
    ((=;`vartype;enlist`variable);(in;`namespace;enlist x));
    {x!x}enlist`name;
  // returns name, value and description
    `val`descrip!((value';`name);`descrip)
   ];
 }

// export all config variables
exportallconfig:{exportconfig torqnamespaces}


// Approximate memory usage statistics
mem:{`size xdesc update sizeMB:`int$size%2 xexp 20 from update size:{-22!value x}each variable from ([]variable:raze varnames[;;0b] .' allns[] cross $[x;"vb";enlist"v"])}
m:{mem[1b]}

// If in the error trap, find the name of the function you are in 
// e.g. .api.whereami[.z.s]
whereami:{funcs first where x~/:value each funcs:raze varnames[;"f";0b] each reverse allns[]}

\
/ examples

\c 23 200
// add some api entries to have some detail 
add[`.api.f;1b;"Find a function/variable/table/view in the current process";"[string:search string]";"table of matching elements"]
add[`.api.fp;1b;"Find a public function/variable/table/view in the current process";"[string:search string]";"table of matching public elements"]
add[`.api.add;1b;"Add a function to the api description table";"[symbol:the name of the function; boolean:whether it should be called externally; string:the description; dict or string:the parameters for the function;string: what the function returns]";"null"]
add[`.api.fullapi;1b;"Return the full function api table";"[]";"api table"]

show .api.f`ad		// search for a value
show .api.p`ad		// search for a public value
show .api.p"*ad"	// search for a specific pattern
show .api.u`ad		// search for a public value, exclude standard namespaces (.q, .Q, .h, .o)
show .api.s["*api*"]	// search the function definitions for the supplied pattern

show .api.memusage[]	// show the approximate memory usage of each variable in the process
