\d .html

// set html home
if[count getenv`KDBHTML; .h.HOME:getenv`KDBHTML]

// PUB / SUB functionality
// pub/sub code for websockets - modified version of u.q from kx
// no point writing from scratch when something is tried/tested/working for years!
t:`symbol$()
w:()!()
modifier:()!()
dataformat:{[t;d] `name`data!(t;jsformat\:[d;typemap])}
updformat:{[t;d] `name`data!(t;(key d)!(d`tablename;jsformat[d`tabledata;typemap]))}

// init must be called with the list of tables
// modified so init can be called multiple times
// the default modifier is to serialize the data
// could add other modifiers
init:{
 new:(x,:()) except t;
 t::t,new;
 w,::new!(count new)#();
 modifier,::new!(count new)#{-8!.j.j updformat["upd";`tablename`tabledata!(x 1;x 2)]}}

del:{w[x]_:w[x;;0]?y};

//Version checking code. .z.pc is only used in versions prior to 3.3
close:{{.html.del[;y] each .html.t; x@y}@[value;x;{{[x]}}]}
if[.z.K >= 3.3;.z.wc:close[`.z.wc]; .z.pc:close[`.z.pc]]

// Create a new version of sel - for the time being, all pages get all data
/ sel:{$[`~y;x;select from x where sym in y]}
sel:{[x;y] x}

// Apply the modifier before sending the data
pub:{[t;x]{[t;x;w]if[count x:sel[x]w 1;(neg first w) modifier[t]@(`upd;t;x)]}[t;x]each w t}

add:{$[(count w x)>i:w[x;;0]?.z.w;.[`.u.w;(x;i;1);union;y];w[x],:enlist(.z.w;y)];(x;$[99=type v:value x;sel[v]y;0#v])}

sub:{if[x~`;:sub[;y]each t];if[not x in t;'x];del[x].z.w;add[x;y]}
// add wssub method - have to subscribe to everything, don't return anything
wssub:{sub[x;`];}

end:{(neg union/[w[;;0]])@\:(`.u.end;x)}

// JAVASCRIPT CONVERTERS

// ISO 8601 date time format, used for JSON.
jstsiso8601:{("-" sv "." vs string `date$x),"T",string[`second$x],"Z"}'
// convert to javascript timestamp format
jstsfromts:{"j"$946684800000j+86400000*"z"$x}
// times,seconds - all will end up as 1970 values
jstsfromt:{"j"$"t"$x}

// month
jstsfromm:{jstsfromts `date$x}

// mapping of types to formatting function
typemap:12 13 14 15 16 17 18 19h!(jstsiso8601;jstsfromm;jstsfromts;jstsiso8601;jstsfromt;jstsfromt;jstsfromt;jstsfromt); 

// given a table, format each of the columns that need formatted
jsformat:{ k:cols x; flip k !(y value t:type each x)@'value x:flip 0!x}

// EVALUATION FUNCTION

// evaluate: used to evaluate front end input data
// Arg: dictionary decoded front end JSON  
// format should be `func`arg1`arg2 ... `arg8!(function;arg1;arg2;...;arg3)
// all args except arg1 are optional
execdict:{$[not `func in key x;'"no func in dictionary";1=count key x;(value x`func) @ 1;1<count key x;(value x`func) . value x _ `func;()]}
// Arg: string JSON encoded string from front end
evaluate:{@[execdict;x;{'"failed to execute ",(-3!x)," : ",y}[x]]}

// PAGE REPLACEMENT FUNCTIONALITY (read a page, replace some variables)

// find replace on a dictionary of elements
// input should be [string;`find1`find2!("replace1";"replace2")]
replace:{(ssr/)[x;string key y;value y]}
// read a webpage
readpage:{
 $[count r:@[read1;`$":",p:.h.HOME,"/",x;""];
   "c"$r;
   p,": not found"]}

// need to be able to get the local address
// taken from dotz.q
IPA:(`int$())!`symbol$()
ipa:{$[`~r:IPA x;IPA[x]:$[`~r:.Q.host x;`$"."sv string"i"$0x0 vs x;r];r]}

getport:{string system"p"}

// read a page, replace the host and port details
// GLEN: MYKDBSERVER Must be an absolute URL. Since the javascript is run on client side it interprets localhost or 127.0.0.2 as a URL referring to a client's own computer
// Host must be formatted as a string for javascript, single or double quotes must be added to each side of it "server.aquaq.co.uk". 
// Otherwise javascript will try to find a variable called server and it's property aquaq, it's property co etc.
readpagereplaceHP:{replace[readpage[x];`MYKDBSERVER`MYKDBPORT!("\"",(string ipa .z.a),"\"";getport[])]}

// add handlers for .non type
.h.tx[`non]:{enlist x}
.h.ty[`non]:"text/html"

// idea here is to read a webpage and do a find/replace on it
// so q can server its own webpages, connecting back to itself
// example would be in the html5 source (lets assume the html5 source is called monitor.html)
// if you put MYKDBSERVER:MYKDBPORT for the websocket connection in monitor.html
// the create a function of
// monitorui:.html.readpagereplaceHP["index.html"] 
// then from the browser do
// http://monitorhost:monitorport/.non?monitorui[]
// then it should host it's own ui

// WEBSOCKET DEFINITION
.z.ws:{neg[.z.w] -8!.j.j[.html.evaluate[.j.k -9!x]];}
