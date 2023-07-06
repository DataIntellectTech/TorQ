/ we can't have bash scripts so we need to set up env variables via q


opts:.Q.opt .z.x;
codeDir:$[`codeDir in key opts; first opts`codeDir; "/opt/kx/app/code"];

/ used for local testing
hdbRoot:$[`hdbRoot in key opts; first opts`hdbRoot; "/opt/kx/app/db"];

/ this is the main hdb param we need to pass in at the command line
hdbDir:hdbRoot,"/",first opts`hdbDir;

setenv[`KDBCODE; codeDir,"/code"];
setenv[`KDBCONFIG; codeDir,"/config"];
setenv[`KDBLOG; codeDir,"/logs"];
setenv[`KDBHTML; codeDir,"/html"]
setenv[`KDBLIB; codeDir,"/lib"];

setenv[`KDBAPPCONFIG; codeDir,"/appconfig"];
setenv[`KDBAPPCODE; codeDir,"/code"];
/ setenv[`KDBHDB; hdbDir];
/ setenv[`KDBWDB; hdbDir];
/ setenv[`KDBTPLOG; ""];

ld:{[x] @[system; "l ",x; {[x;e] -1 "Failed to load ",x,"error was ",e; exit 1}[x;] ]}

if[not `noredirect in key .Q.opt .z.x; -1 "need -noredirect command line flag to run"; exit 1];

ld hdbDir;
ld codeDir,"/torq.q";

