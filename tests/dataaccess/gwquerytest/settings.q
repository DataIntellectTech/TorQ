// IPC connection parameters
.servers.CONNECTIONS:`gateway;
.servers.USERPASS:`admin:admin;

testpath:hsym`$getenv[`KDBTESTS],"/dataaccess/gwquerytest";

sublistvalue:2;

getdict:{exec parameter!get each parametervalue from (("s*";1#",")0: ` sv testpath,`inputs,`$string[x],".csv")}
