// Engine compatibility tests - helper functions (each returns 1b when the check passes)

.et.port:120+"J"$getenv`KDBBASEPORT;
.et.h:0Ni;
.et.connect:{[] .et.h:hopen .et.port; 1b};
.et.dirs:();                                                                                          / every scratch directory made, removed by .et.cleanup at the end
.et.tmp:{[] d:$[count t:getenv`TMPDIR;t;"/tmp"],"/torqengtest_",string[.z.i],"_",string first 1?1000000000; system "mkdir -p ",d; .et.dirs:.et.dirs,enlist d; d};
.et.cleanup:{[] {system "rm -rf '",x,"'"} each .et.dirs; .et.dirs:(); 1b};

// ---------------------------------------------------------------- engine detection
.et.engineknown:{[] .proc.engine in `kdb`l`peachq`korze`unknown};
.et.engineexpected:{[] $[count e:getenv`TORQTEST_ENGINE; .proc.engine~`$e; 1b]};
.et.detectstable:{[] .proc.engine~.proc.getengine[]};
.et.names:{[] (10h=type .proc.enginename) and (10h=type .proc.engineversion) and (0<count .proc.enginename) and 0<count .proc.engineversion};
.et.nameformengine:{[] .proc.enginename~$[.proc.engine=`kdb;$[5<=.z.K;"KDB-X";"kdb+"];.proc.engine=`l;enlist "L";.proc.engine=`peachq;"PeachQ";.proc.engine=`korze;"Korze";"unknown q engine"]};

// ---------------------------------------------------------------- capabilities
.et.atstart:{[] $[.proc.engine=`kdb;.proc.features`feature;exec feature from .proc.features where atstart]};         / the features checked at start-up (all of them on kdb+); others are added to the end of the capabilities when asked for
.et.capsshape:{[] (99h=type .proc.capabilities) and (1h=type value .proc.capabilities) and (.et.atstart[])~(count .et.atstart[])#key .proc.capabilities};
// kdb+: decided by version - and the probes must agree with the version on kdb+ (this validates the probes)
.et.capssource:{[] $[.proc.engine=`kdb;.proc.capabilities~.proc.versioncapabilities[.z.K;.z.k];.proc.capabilities~.proc.probecapabilities[]]};
.et.probesmatchversion:{[] if[not .proc.engine=`kdb; :1b]; probed:.proc.probecapabilities[]; probed~(key probed)#.proc.versioncapabilities[.z.K;.z.k]};
// independent functional checks against the test server (not the probe helper), compared with .proc.capabilities
.et.broadcastworks:{[] @[{.et.h".srv.b:0b"; -25!(enlist .et.h;(`.srv.set;1b)); 1b~.et.h".srv.b"};::;0b]};
.et.deferredworks:{[] @[{`deferredok~.et.h"defer"};::;0b]};
.et.unixworks:{[] @[{u:hopen`$":unix://",string .et.port; r:u"1+1"; hclose u; 2~r};::;0b]};
.et.revalworks:{[] @[{2~reval(value;"1+1")};::;0b]};
.et.hvalworks:{[] had:`val in key `.h; old:$[had;.h.val;::]; .et.hv:0b; .h.val:{[x] .et.hv:1b; value x};
  @[.z.ph;("?2+2";(`Host,`$"Accept-Encoding")!("localhost";""));::]; $[had;.h.val:old;![`.h;();0b;enlist`val]]; .et.hv};
.et.pupd:{[x] .et.pc:.et.pc+1};
.et.pipeworks:{[] @[{d:.et.tmp[]; l:hsym`$d,"/log"; l set (); h:hopen l; do[3;h enlist (`.et.pupd;1)]; hclose h;
  p:d,"/pipe"; system "mkfifo ",p; system "(timeout 5 cat ",(1_string l)," > ",p,") >/dev/null 2>&1 &";
  .et.pc:0; -11!hsym`$p; system "rm -rf ",d; 3=.et.pc};::;0b]};
.et.memstatsworks:{[] @[{99h=type .Q.w[]};::;0b]};                                        / .Q.w[] gives the memory statistics (Korze has no .Q.w)
// a name that is not a feature: 0b, nothing added to the capabilities; several names: an answer for each
.et.supportsunknown:{[] k:key .proc.capabilities; (0b~.proc.supports`zznosuch) and (0b~.proc.supports`) and k~key .proc.capabilities};
.et.supportslist:{[] (.proc.supports`broadcast`zznosuch`deferred)~(.proc.supports`broadcast;0b;.proc.supports`deferred)};
// kdb+'s alphabet constants exist on every engine (engine.q defines them where the engine does not: Korze)
.et.alphabets:{[] (.Q.A~"ABCDEFGHIJKLMNOPQRSTUVWXYZ") and .Q.a~"abcdefghijklmnopqrstuvwxyz"};
.et.matches:{[f;works] works~.proc.capabilities f};

// ---------------------------------------------------------------- u.q: .u.pub uses -25! only when it can
// (pubsub.q later points .u.pub at .stpps.pub, so check what u.q itself defined)
.et.upub:{[] $[.u.broadcast and .proc.capabilities`broadcast; all `pub_broadcast`pub_default in key `.u; not any `pub_broadcast`pub_default in key `.u]};
// where u.q defined the -25! version, it delivers to a .u.w subscriber
.et.upubbroadcast:{[] if[not `pub_broadcast in key `.u; :1b];
  had:`w in key `.u; oldw:$[had;.u.w;::]; .et.h".srv.cnt:0";
  .u.w:(enlist`trade)!enlist enlist (.et.h;`);
  r:@[{.u.pub_broadcast[`trade;([]sym:`a`b;price:1 2f)]; .et.h".srv.cnt"};::;{x}];
  $[had;.u.w:oldw;![`.u;();0b;enlist`w]]; .et.upubresult:r; 2~r};

// ---------------------------------------------------------------- trackservers.q: unix domain sockets
.et.domainsockets:{[] .servers.domainsocketsenabled[]~(not .z.o like "w*") and .proc.capabilities`unixsockets};

// ---------------------------------------------------------------- tickerlogreplay.q: zipped logs need pipereplay
// replayinner is process code, so take its definition from the file and run it with a zipped log name
.et.replayinner:{[]
  f:read0 hsym`$getenv[`KDBCODE],"/processes/tickerlogreplay.q";
  i:first where f like "replayinner:{*"; j:i+first where (i _ f) like " };*";
  value "\n" sv f i+til 1+j-i;
  .replay.zipped:1b; m:"Zipped log files can only be directly replayed on kdb+ 4.0 or higher";
  r:@[replayinner[0];`:/tmp/torqengtest_none.log.gz;{x}];
  .replay.zipped:0b;
  not r~m};

// ---------------------------------------------------------------- helpers
.et.lgcapture:{[f;x] olde:.lg.e; .et.errs:(); .lg.e:{[x;y] .et.errs,:enlist (x;y)}; r:@[f;x;{x}]; .lg.e:olde; (r;.et.errs)};
// ---------------------------------------------------------------- grafana.q: type map sized to .Q.t
.et.grafana:{[] (key[.grafana.types]~.Q.t) and (count .grafana.types)=count .Q.t};

// ---------------------------------------------------------------- torq.q: a file is loaded once (Korze's in never matched the loaded-files list)
.et.loadonce:{[] f:.et.tmp[],"/once.q"; (hsym`$f) 0: enlist ".et.loadcount+:1"; .et.loadcount:0; .proc.loadf f; .proc.loadf f; 1=.et.loadcount};

// ---------------------------------------------------------------- torq.q: checkdependency appends to .proc.a
.et.depdefined:{[] (98h=type .proc.a) and all `TorQ`kdb in .proc.a`app};
.et.depappends:{[] n:count .proc.a; .et.lgcapture[.proc.checkdependency;.proc.getconfig["dependency.csv";1]]; (count .proc.a)>n};

// ---------------------------------------------------------------- permissions.q: .h.val only where .z.ph uses it
.et.permissions:{[] saved:`ph`val!(.z.ph;@[value;`.h.val;::]);                       / the test turns permissions on, which replaces .z.ph and .h.val: put them back afterwards
  .pm.init[];
  r:$[.proc.capabilities`hval;.pm.req~@[value;`.h.val;::];not .pm.req~@[value;`.h.val;::]];
  .z.ph:saved`ph; $[(::)~saved`val;![`.h;();0b;enlist`val];.h.val:saved`val];
  r};

// ---------------------------------------------------------------- writeaccess.q: no reval -> an error is logged
.et.readonly:{[] .readonly.enabled:1b;
  e:last .et.lgcapture[system;"l ",getenv[`KDBCODE],"/handlers/writeaccess.q"];
  logged:any (e[;1]) like "*does not support blocking write access*";
  $[.proc.capabilities`reval;not logged;logged]};

// ---------------------------------------------------------------- engine.q: start-up choice, operating systems, reload
.et.enginefile:getenv[`KDBCODE],"/common/engine.q";
// this process's binary, to start a child of the same engine: /proc/<pid>/exe resolved to a real file, when it is one.
// L runs from memory: readlink then gives "/memfd: (deleted)", or on some systems just the /proc path back - neither can
// be started, so .z.X is used instead (looked up on the PATH when it has no directory)
.et.exepick:{[e] $[(0=count e) or (e like "*(deleted)*") or (e like "/proc/*") or (e like "/memfd*") or ()~key hsym`$e;
  $["/" in x:first .z.X;x;first system "command -v ",x];e]};
.et.exe:{[] .et.exepick @[{first system "readlink -f /proc/",string[.z.i],"/exe 2>/dev/null"};::;""]};
// start this engine's binary with engine.q and the given environment/arguments; return the engine it settled on
.et.child:{[envs;args] f:.et.tmp[],"/show.q";
  (hsym`$f) 0: ("system \"l ",.et.enginefile,"\";";"-1 \"ENGINE=\",string .proc.engine;";"exit 0");
  r:@[system;$[count envs;envs," ";""],.et.exe[]," ",f," ",args," -q </dev/null 2>/dev/null";enlist ""];   / no leading space: system " ..." is not a shell command
  `$7_first r where r like "ENGINE=*"};
.et.paramwins:{[] `l~.et.child["KDBENGINE=peachq";"-engine l"]};
.et.envused:{[] `peachq~.et.child["KDBENGINE=peachq";""]};
.et.envtrimmed:{[] `peachq~.et.child["KDBENGINE=' PeachQ '";""]};                     / spaces and case in KDBENGINE are ignored
.et.detected:{[] $[count getenv`KDBENGINE;1b;.proc.engine~.et.child["";""]]};
// a chosen engine decides where capabilities come from: kdb -> version, anything else -> probes
.et.chosenkdb:{[] f:.et.tmp[],"/caps.q";
  (hsym`$f) 0: ("system \"l ",.et.enginefile,"\";";"-1 \"OK=\",string .proc.capabilities~.proc.versioncapabilities[.z.K;.z.k];";"exit 0");
  r:@[system;.et.exe[]," ",f," -engine kdb -q </dev/null 2>/dev/null";enlist ""]; "OK=1"~first r where r like "OK=*"};
// ---------------------------------------------------------------- engine.q: the feature table and how it is probed
.et.bits:{raze string value x};
// run code in a new process of this engine: envs is "NAME=value ..." (or ""), exe the program, args extra arguments; returns its output lines
.et.childout:{[envs;exe;args;code]
  f:.et.tmp[],"/child.q";
  (hsym`$f) 0: ("system \"l ",.et.enginefile,"\";";code;"exit 0");
  @[system;$[count envs;envs," ";""],exe," ",f," ",args," -q </dev/null 2>/dev/null";enlist ""]};
.et.probebits:"-1 \"BITS=\",raze string value .proc.probecapabilities[]";
.et.childbits:{[envs;exe] 5_first r where (r:.et.childout[envs;exe;"";.et.probebits]) like "BITS=*"};

// one row per feature, each naming a probe function that exists; the version rules list every feature; capabilities hold the features checked at start-up (all of them on kdb+), in the same order
.et.featuretable:{[] f:.proc.features;
  ((count f`feature)=count distinct f`feature) and (all 100h=type each .proc f`probe) and ((key .proc.versioncapabilities[.z.K;.z.k])~f`feature) and (.et.atstart[])~(count .et.atstart[])#key .proc.capabilities};
// the .h.val check puts .h.val back as it found it
.et.hvalrestored:{[] had:`val in key `.h; old:$[had;.h.val;::]; .proc.probecapabilities[]; (had~`val in key `.h) and $[had;old~.h.val;1b]};
// off Linux the pipe is not probed (TorQ replays zipped logs through a pipe on Linux only)
.et.pipegate:{[] $[.proc.engine=`kdb;1b;$[.z.o like "l*";1b;not .proc.supports`pipereplay]]};
.et.cleanbits:{[] .et.childbits["";.et.exe[]]};                                  / the answers in a clean new process (the test process has had handlers installed by earlier tests)
// an engine name TorQ does not know is taken as given, shown as unknown, and probed
.et.unknownengine:{[] r:.et.childout["";.et.exe[];"-engine foo";"-1 \"ENGINE=\",string .proc.engine; -1 \"NAME=\",.proc.enginename; -1 \"BITS=\",raze string value .proc.capabilities"];
  (`foo~`$7_first r where r like "ENGINE=*") and ("unknown q engine"~5_first r where r like "NAME=*") and (.et.cleanbits[]~5_first r where r like "BITS=*")};
// started by a bare name found on the PATH (q, and l for L) the engine is still recognised
.et.viasymlink:{[]
  d:.et.tmp[]; names:$[.proc.engine~`l;`q`l;enlist `q];
  one:{[d;n] system "ln -s '",.et.exe[],"' '",d,"/",string[n],"'";
    r:.et.childout["PATH=\"",d,":$PATH\"";string n;"";"-1 \"ENGINE=\",string .proc.engine"]; (`$7_first r where r like "ENGINE=*")~.proc.engine}[d];
  r:all one each names; system "rm -rf '",d,"'"; r};

// loading engine.q again (as code/common does) keeps the capabilities instead of probing again
.et.reloadkeeps:{[] c:.proc.capabilities; .proc.capabilities[`zzmarker]:1b; system "l ",.et.enginefile;
  r:(1b~.proc.capabilities`zzmarker) and .proc.engine~.proc.getengine[]; .proc.capabilities:c; r};

// init runs once: called again (as a second load of engine.q does) it keeps the engine, its name and version, and the capabilities
.et.initonce:{[] c:.proc.capabilities; e:(.proc.engine;.proc.enginename;.proc.engineversion); .proc.capabilities[`zzinit]:1b; .proc.init[];
  r:(.proc.capabilities`zzinit) and e~(.proc.engine;.proc.enginename;.proc.engineversion); .proc.capabilities:c; r};

// starting TorQ runs no shell commands: the answers are the same when there is no PATH to find any command on
.et.noshell:{[] (.et.childbits["PATH=/nonexistent";.et.exe[]])~.et.cleanbits[]};
// pipereplay is not checked at start-up on other engines (it runs shell commands): it is checked when first asked for, then remembered
.et.lazy:{[]
  if[.proc.engine=`kdb; :1b];
  r:.et.childout["";.et.exe[];"";"-1 \"BEFORE=\",string `pipereplay in key .proc.capabilities; x:.proc.supports`pipereplay; -1 \"AFTER=\",string `pipereplay in key .proc.capabilities"];
  ((enlist "0")~7_first r where r like "BEFORE=*") and (enlist "1")~6_first r where r like "AFTER=*"};

// the engine and capabilities go in the log, once, as one line (torq.q calls logengine for every process)
.et.logengine:{[] old:.lg.o; .et.logged:(); .lg.o:{[category;message] .et.logged:.et.logged,enlist message}; .proc.logengine[]; .lg.o:old;
  (1=count .et.logged) and ((first .et.logged) like "q engine *") and 0<count ss[first .et.logged;"capabilities: "]};   / (like cannot match "start*middle*": it signals nyi)

// ---------------------------------------------------------------- the internal functions TorQ calls, as the kx docs describe them
// (code.kx.com/q/basics/internal: -3! is replaced by .Q.s1 and -19! by set; the others have no replacement). TorQ needs these on every engine
.et.int3:{[] (-3!1 2 3)~.Q.s1 1 2 3};
.et.nonblank:{[tokens] tokens where not (enlist " ")~/:tokens};                    / -4! on L leaves out the blank tokens the docs show; TorQ only looks for names in them
.et.int4:{[] ("select";"this";"from";"that")~.et.nonblank -4!"select this from that"};
.et.int89:{[] x:(`a`b!(1 2;"xy");([]c:1 2;d:`p`q)); x~-9!-8!x};
.et.int22:{[] all {(-22!x)=count -8!x} each (til 1000;([]a:1 2 3;b:`x`y`z);`a`b!(1;2))};
.et.int11:{[] d:.et.tmp[]; f:hsym`$d,"/log"; f set (); h:hopen f; do[3;h enlist (`.et.pupd;1)]; hclose h;
  r:(-11!f;-11!(1;f);-11!(-2;f)); system "rm -rf '",d,"'"; r~(3;1;3)};
.et.int0N:{[] (0N!5)~5};
// every capability or supports key the code reads is a feature in the table (a typo would silently read as unsupported)
.et.usedkeys:{[] lines:system "grep -rhoE '[.]proc[.](capabilities|supports)`[a-z]+' ",getenv[`KDBCODE],"/";
  names:distinct `$ {last "`" vs x} each lines; (0<count names) and all names in .proc.features`feature};

// ---------------------------------------------------------------- probes leave nothing behind
.et.tmpbase:{[] t:getenv`TMPDIR; t:$[count t;t;"/tmp"]; $["/"=last t;-1_t;t]};
.et.probecleanup:{[] .proc.probecapabilities[]; .proc.probepipereplay[::]; system "sleep 0.2";
  prefix:.et.tmpbase[],"/torqprobe_",string[.z.i],"_";
  (0=count @[system;"ls -d '",prefix,"'* 2>/dev/null";()]) and 0=count @[system;"pgrep -f '",ssr[prefix;"torqprobe";"[t]orqprobe"],"'";()]};
// starting TorQ writes nothing: with a scratch directory to hand, the start-up probes leave it empty
.et.nofiles:{[]
  d:.et.tmp[];
  r:.et.childout["TMPDIR='",d,"'";.et.exe[];"";"-1 \"BEFORE=\",string count key hsym`$getenv`TMPDIR; .proc.probecapabilities[]; -1 \"AFTER=\",string count key hsym`$getenv`TMPDIR"];
  ((enlist "0")~7_first r where r like "BEFORE=*") and (enlist "0")~6_first r where r like "AFTER=*"};
// the temporary directory comes in forms (macOS has a trailing slash, users have spaces): the named-pipe check, the one probe which uses it, must not change
.et.pipechild:{[envs] r:.et.childout[envs;.et.exe[];"";"-1 \"PIPE=\",string .proc.probepipereplay[::]"]; 5_first r where r like "PIPE=*"};
.et.tmpdirforms:{[] d:.et.tmp[]; clean:.et.pipechild[""];
  r:(clean~.et.pipechild["TMPDIR='",d,"/a dir with spaces/'"]) and clean~.et.pipechild["TMPDIR='",d,"/'"];
  system "rm -rf '",d,"'"; r};

// ---------------------------------------------------------------- kdb+ is decided by version, exactly as TorQ did before engine.q
// the .z.K and .z.k tests as they were in the code engine.q replaced (u.q, gateway.q, writeaccess.q, permissions.q, trackservers.q, tickerlogreplay.q)
.et.originalrules:{[K;k] `broadcast`deferred`unixsockets`reval`hval`pipereplay!(K>=3.4;not K<3.6;3.4<=K;not 3.3>K;(K>=3.5)&k>=2019.11.13;not K<4.0)};
.et.kdbversions:{[]
  grid:((3.3;2016.01.01);(3.4;2016.06.01);(3.5;2017.06.01);(3.5;2019.11.12);(3.5;2019.11.13);(3.6;2018.05.18);(3.6;2020.05.04);(4.0;2020.03.04);(4.0;2023.08.11);(4.1;2024.04.29);(5.0;2026.10.15));
  all {[p] want:.et.originalrules[p 0;p 1]; want~(key want)#.proc.versioncapabilities[p 0;p 1]} each grid};

// ---------------------------------------------------------------- tickerlogreplay.q: a zipped log really replays on Linux: through a named pipe where the engine can, from a temporary unzipped copy where it cannot
.et.gzreplay:{[]
  f:read0 hsym`$getenv[`KDBCODE],"/processes/tickerlogreplay.q";
  grab:{[f;head] i:first where f like head; j:i+first where (i _ f) like " };*"; "\n" sv f i+til 1+j-i};
  d:.et.tmp[]; tplog:hsym`$d,"/tp.log"; tplog set (); h:hopen tplog; do[3;h enlist (`upd;`gzt;1)]; hclose h;
  system "gzip -c '",d,"/tp.log' > '",d,"/tp.log.gz'; true";                   / "; true": q's system returns when stdout closes, which for a lone redirected command is before it finishes
  (hsym`$d,"/fns.q") 0: "\n" vs ".replay.",grab[f;"readintofifo:{*"],"\n.replay.",grab[f;"replayinner:{*"];     / TorQ's own two functions, from the file
  / a clean new process of this engine replays it (the test process has had permissions switched on by earlier tests)
  code:".lg.o:{[c;m] ::}; .lg.e:{[c;m] -1 \"LGE \",m}; system \"l ",d,"/fns.q\"; n:0; `upd set {[t;x] n::n+1}; .replay.zipped:1b; ",
    "r:@[.replay.replayinner[-1];`$\":",d,"/tp.log.gz\";{\"ERR \",x}]; -1 \"COUNT=\",string n";
  r:.et.childout["";.et.exe[];"";code];
  got:first 6_first r where r like "COUNT=*";
  system "rm -rf '",d,"'";
  $[.z.o like "l*";"3"~got;"0"~got]};
