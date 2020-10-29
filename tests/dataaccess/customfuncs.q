//- Script to load in custom functionality:
//- see getrollover/getpartitionrange in config/tableproperties.csv



\d .dataaccess

//- (i) getrollover
//- functions to determine rollover to split the time ranges destined for the rdb and hdb.
testfuncrollover:{[]2000.01.05D};




//- (ii) getpartitionrange
//- offset times for non-primary time columns
testfuncpartitionrange:{[timecolumn;primarytimecolumn;partitionfield;hdbtimerange]@[partitionfield$hdbtimerange;1;+;not timecolumn~primarytimecolumn]};
