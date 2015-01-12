\d .async

// send a query down a handle, flush the handle, return a status as to whether it is succesfully sent (0b or 1b)
// the query is wrapped so it gets send back to the originating process
// the result will be returned as either 
// if w is true, the result will be wrapped in the status i.e. 
// (1b;result) or (0b;"error: error string")
// otherwise it will just return the result
// there are several error traps here as we need to trap
// 1. that the query is successfully sent and flushed
// 2. that the query is executed successfully on the server side
// 3. that the result is successfully sent back down the handle (i.e. the client hasn't closed while the server is still running the query)
send:{[w;h;q] 
 // build the query to send
 tosend:$[w; ({[q] @[neg .z.w;@[{[q] (1b;value q)};q;{(0b;"error: server fail:",x)}];()]};q);
             ({[q] @[neg .z.w;@[{[q] value q};q;{"error: server fail:",x}];()]};q)];
 .[{x@y; x(::);1b};(h;tosend);0b]}

// use this to make deferred sync calls
// it will send the query down each of the handles, then block and wait on the handles
// result set is (successvector (1 for each handle); result vector)
deferred:{[handles;query]
 // send the query down each handle
 sent:send[1b;;query] each handles:neg abs handles,();

 // block and wait for the results
 res:{$[y;@[x;(::);(0b;"error: comm fail: handle closed while waiting for result")];(0b;"error: comm fail: failed to send query")]}'[abs handles;sent];

 // return results
 (res[;0];res[;1])}

// Wrap the supplied query in a postback function
// Don't block the handle when waiting
// Success vector is returned 
postback:{[handles;query;postback] send[0b;;({[q;p] (p;@[value;q;{"error: server fail:",x}])};query;postback)] each handles:neg abs handles,()}

\
// Test
\d .
{@[system;"q -p ",string x;{"failed to open ",(string x),": ",y}[x]]} each testports:9995 + til 3;
system"sleep 1";
h:raze @[hopen;;()]each testports
if[0=count h; '"no test processes available"]

// run some tests
// all good
-1"test 1.1";
\t r1:.async.deferred[h;({system"sleep 1";system"p"};())]
show r1
-1"test 1.2";
// both fail
\t r2:.async.deferred[h;({1+`a;1};())]
show r2
-1"test 1.3";
// last handle fails - handle invalid
\t r3:.async.deferred[h,923482;({system"sleep 1";system"p"};())]
show r3
-1"test 1.4";
// server exits while client is waiting for result
\t r4:.async.deferred[last h;({exit 0};())]
show r4
\t r5:.async.deferred[h;"select from ([]1 2 3)"]
show r5

// drop the last handle - it's dead
h:-1 _ h

// define a function to handle the posted back result
showresult:{show x}
// All the postback functions will execute very quickly as they don't block
.async.postback[h;({"result 2.1: ",string x+y};2;3);`showresult]
// send postback as lambda
.async.postback[h;({"result 2.2: ",string x+y};2;3);showresult]
// send postback as lambda
.async.postback[h;({"result 2.3: ",string x+y};2;`a);showresult]

// Tidy up
@[;"exit 0";()] each neg h
