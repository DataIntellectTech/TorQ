\d .proc
// engine.q - which q engine TorQ is running on, and what that engine can do
// TorQ runs on kdb+, L, PeachQ and Korze. torq.q loads this file first, so the engine is known before anything else;
// it is loaded again with the rest of code/common, where init finds the capabilities already set and does nothing.
// The engine can be given on start-up with -engine (kdb, l, peachq or korze) or the KDBENGINE environment variable;
// otherwise it is detected only once.

// set everything up, in order: the engine, its name and version, then the capabilities dict.
// Runs once: when this file is loaded again (with the rest of code/common), the capabilities are already set
init:{[]
  if[`capabilities in key `.proc;
      :()
      ];
  .proc.engine:getengine[];
  .proc.enginename:$[engine=`kdb;
                      $[5<=.z.K;"KDB-X";"kdb+"];
                        engine=`l;enlist "L";
                          engine=`peachq;"PeachQ";
                            engine=`korze;"Korze";"unknown q engine"];

  .proc.engineversion:$[engine=`peachq;
                          @[{$[10h=type v:value x;v;string v]};`.pq.version;(string .z.K)," ",string .z.k];
                          (string .z.K)," ",string .z.k];

  // compute capabilities dict once 
  .proc.capabilities:$[engine=`kdb;
                        versioncapabilities[.z.K;.z.k];
                          probecapabilities[]
                          ];
  }

//gets engine used (kdb, l or peachq)
getengine:{[]
  //get engine given on start-up or KDBENGINE environment variable if given
  cmdlineopts:.Q.opt .z.x;
  
  requested:$[`engine in key cmdlineopts;
              first cmdlineopts`engine;
              $[count e:getenv`KDBENGINE;e;""]
                ];
  if[count requested; 
      :`$lower trim requested
      ];

  //detect engine (kdb, l, peachq or korze)
  if[`version in key `.pq; 
      :`peachq
      ];
  //korze: its .z.K is a long (float for other engines), and it has the .S namespace
  if[(-7h=type .z.K) or `ckpt in key `.S;
      :`korze
      ];                                         
  if[any(`l~`$first .z.X;`pq in key `); 
      :`l
      ];                                 
  //kdb+: a licence in .z.l (trapped: older kdb+ has no .z.l), or a free 32-bit edition, where .z.l is empty
  :$[any(@[{0<count .z.l};::;1b];.z.o in `l32`m32`w32);
    `kdb;
    `unknown];                                                      
  }

// -25!(handles;::) - bc no handles, it only errors if -25! is missing
probebroadcast:{[found] -25!(0#0i;::); 1b}

// -30!(handle;0b;msg) answers a deferred sync request; fails with 'domain when handle is not in .z.W.
// As 0Wi never is. An engine without -30! fails with something else
probedeferred:{[found] @[{-30!(0Wi;0b;1); 1b};::;{x~"domain"}]}

// a unix socket which does not exist: an engine with unix sockets reports the failed connection (the operating system's
// "connection refused" or "no such file"; Korze a bare 'hop), one without them reports something else (PeachQ: 'nyi)
// by default on port 5 as unused by convention (below 1024: no q process can listen there unless run as root)
probeunixsockets:{[found]
  // for windows (w32, w64), 0b
  if[.z.o like "w*"; 
      :0b]; 
  // try socket, if it opens 1b. Else, see error message                                     
  @[{hclose hopen `:unix://5; 1b};::;{any x like/: ("*refused*";"*[Nn]o such file*";"hop")}]
  };        

probereval:{[found] 2~reval(value;"1+1")}

// .Q.w[], the memory statistics (Korze has no .Q.w)
probememstats:{[found] 99h=type .Q.w[]}

// does .z.ph evaluate "?expr" requests through .h.val? (PeachQ has .h.val but .z.ph never calls it, so existence is not enough)
// the second argument is the HTTP header dictionary q passes to .z.ph; it must hold Accept-Encoding. .h.val is put back afterwards
probehval:{[found]
  hadval:`val in key `.h;
  oldval:$[hadval;.h.val;::];
  .proc.hvalcalled:0b;
  .h.val:{[x] .proc.hvalcalled:1b; value x};
  @[.z.ph;("?1+1";(`Host,`$"Accept-Encoding")!("localhost";""));::];
  $[hadval;.h.val:oldval;![`.h;();0b;enlist`val]];
  .proc.hvalcalled}

// replay a log through a named pipe, as TorQ does for zipped logs (see replayinner in tickerlogreplay.q)
probeupd:{[x] .proc.probecount:.proc.probecount+1}
probecount:0
probepipereplay:{[found]
  if[not .z.o like "l*"; :0b];
  withscratch {[dir]
                logfile:hsym`$dir,"/log";
                pipe:dir,"/pipe";
                logfile set ();
                // a log with two messages 
                handle:hopen logfile;                                                   
                handle enlist (`.proc.probeupd;1);
                handle enlist (`.proc.probeupd;2);
                hclose handle;
                system "mkfifo '",pipe,"'";
                // feeds the pipe once something reads it
                system "(cat '",(1_string logfile),"' > '",pipe,"') >/dev/null 2>&1 &";     
                .proc.probecount:0;
                result:@[{-11!hsym`$x; 1b};pipe;0b];
                // stop the feeder if nothing read the pipe ("[t]": pkill must not match itself)
                system "pkill -f '",ssr[dir;"torqprobe";"[t]orqprobe"],"' ; true";       
                result and 2=.proc.probecount
              }
    }



// ---------------------------------------------------------------------------------------------------------------------
// Features. TorQ checks these instead of .z.K, so a new engine, or a new release of one, is picked up without changes.
// For kdb+ we check  the release which introduced the feature (versioncapabilities)
// any other engine each feature is tried in a trap: if it runs the engine has it, any error means it does not
// (the table comes after the probes: q builds it when the file is loaded, so the probes must already exist)

// feature  - what TorQ checks
// kdbK     - the kdb+ release which introduced it, with the date it first worked where the release was not enough (0Nd: no date)
// atstart  - 1b: checked when TorQ starts; 0b: checked by supports the first time it is asked for
// probe    - the name of the function in .proc which checks it on any other engine, 1b if it works
features:flip `feature`kdbK`kdbdate`atstart`probe!flip (
  / feature      kdbK   kdbdate      atstart  probe                 used in
  (`broadcast;   3.4;   0Nd;         1b;      `probebroadcast);     / -25! broadcast publish                     u.q, pubsub.q
  (`deferred;    3.6;   0Nd;         1b;      `probedeferred);      / -30! deferred sync responses               gateway.q
  (`unixsockets; 3.4;   0Nd;         1b;      `probeunixsockets);   / unix domain sockets                        trackservers.q
  (`reval;       3.3;   0Nd;         1b;      `probereval);         / reval, to block writes                     writeaccess.q
  (`hval;        3.5;   2019.11.13;  1b;      `probehval);          / .z.ph evaluates requests with .h.val       permissions.q
  (`pipereplay;  4.0;   0Nd;         0b;      `probepipereplay);     / -11! replay from a named pipe             tickerlogreplay.q
  (`memstats;    2.0;   0Nd;         1b;      `probememstats))      / .Q.w[] memory statistics                   dbwriteutils.q, monitoringchecks.q, memoryusage.q

// run f with a scratch directory, which is removed afterwards (q creates it when the first file is written)
withscratch:{[f]
  candidates:(getenv each `TMPDIR`TEMP`TMP),enlist "/tmp";                    / macOS and Linux set TMPDIR, Windows TEMP
  tmp:ssr[first candidates where 0<count each candidates;"\\";"/"];
  dir:$["/"=last tmp;-1_tmp;tmp],"/torqprobe_",string[.z.i],"_",string first 1?1000000000;
  result:@[f;dir;0b];
  @[{hdel each (` sv/: x,/:key x),x};hsym`$dir;::];
  result
  }

// kdb+/KDB-X: by the version K and release date k (an argument so the rules can be tested for any version)
versioncapabilities:{[K;k]
  exec feature!((K>=kdbK) and k>=kdbdate) from features
  }

// for any other engine than kdb, try each feature checked at start-up
probecapabilities:{[]
  {[found;f;p] found,(enlist f)!enlist 1b~@[p;found;0b]}/[(`symbol$())!`boolean$();
    exec feature from features where atstart;
    .proc exec probe from features where atstart]
    }

// feature -> 1b/0b: from the capabilities, or checked the first time it is asked for (pipereplay) and remembered;
// 0b for a name which is not a feature
supports:{[name]
  if[11h=type name; 
  	:.proc.supports each name];
  if[not name in key capabilities;
      // a name that is not in the features table is not supported
      if[not count probes:.proc exec probe from features where feature=name; 
      	:0b];
      .proc.capabilities:capabilities,(enlist name)!enlist 1b~@[first probes;capabilities;0b]
      ];
  capabilities name
  }


// show engine, version and capabilities
logengine:{[]
  .lg.o[`init;"q engine ",enginename," ",engineversion,", capabilities: ",", " sv {string[x],"=",string y}'[key capabilities;value capabilities]]
  }

init[];

\d .
