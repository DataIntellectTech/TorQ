//variables needed to configure wdb to merge and save data to our test directories
.wdb.writedownmode:`partbyattr;
.wdb.sortcsv:hsym`$getenv[`KDBTESTS],"/merge/wdb/config/sort.csv";
.wdb.hdbdir:hsym`$getenv[`KDBTESTS],"/merge/wdb/testhdb";
.wdb.savedir:hsym`$getenv[`KDBTESTS],"/merge/wdb/testwdbhdb";
.wdb.hdbsettings:(`compression`hdbdir)!(();.wdb.hdbdir);
//this variable will set the merge limit to 30000 for the xdaily table, in mockdata script have configured mock data so there will be a partition less than, equal to and greater than that limiy
.wdb.mergenumbytes:300000;
