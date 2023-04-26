.servers.USERPASS:`$"admin:admin";

//- some custom functionality for tests
.dataaccess.testfuncrollover:{[]2000.01.05D}; //- function to determine rollover to split the time ranges destined for the rdb and hdb.
.dataaccess.testfuncpartitionrange:{[timecolumn;primarytimecolumn;partitionfield;hdbtimerange]@[partitionfield$hdbtimerange;1;+;not timecolumn~primarytimecolumn]}; //- offset times for non-primary time columns
