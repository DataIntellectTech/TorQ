// IPC connection parameters
.servers.CONNECTIONS:`housekeeping;
.servers.USERPASS:`admin:admin;

// Paths
testlogs:getenv[`KDBTESTS],"/stp/housekeeping/logs/logs";
copylogs:getenv[`KDBTESTS],"/stp/housekeeping/logs/copy";
copytar:getenv[`KDBTESTS],"/stp/housekeeping/logs/copy.tar.gz";
extrtar:getenv[`KDBTESTS],"/stp/housekeeping/logs/home";
copystr:"cp -r ",testlogs," ",copylogs;
tarstr:"tar -xvf ",copytar," -C ",getenv[`KDBTESTS],"/stp/housekeeping/logs";