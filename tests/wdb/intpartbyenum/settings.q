// IPC connection parameters
.servers.CONNECTIONS:`wdb`hdb`idb;
.servers.USERPASS:`admin:admin;

// Filepaths
wdbdir:hsym `$getenv[`KDBTESTS],"/wdb/intpartbyenum/tempwdb";
hdbdir:hsym `$getenv[`KDBTESTS],"/wdb/intpartbyenum/temphdb";
symfile:` sv hdbdir,`sym;

// Test tables with expected int partitions
testtshort:([]enumcol:-0W -1 0 0N 1 0Wh; expint:0 0 0 0 1 32767);
testtint:  ([]enumcol:-0W -1 0 0N 1 0Wi; expint:0 0 0 0 1 2147483647);
testtlong: ([]enumcol:-0W -1 0 0N 1 0W;  expint:0 0 0 0 1 2147483647);
testtsym:  update expint:i from ([]enumcol:`a`b`c`d`e`);

// All expected int partitions
expints:asc distinct raze (testtshort;testtint;testtlong;testtsym)@\:`expint;
