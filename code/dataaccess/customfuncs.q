//- Script to load in custom functionality:
//- see getrollover/getpartitionrange in config/tableproperties.csv

\d .dataaccess

//- (i) getrollover
//- functions to determine rollover to split the time ranges destined for the rdb and hdb.
defaultrollover:{[].z.d+0D};

//- (ii) getpartitionrange
//- offset times for non-primary time columns
defaultpartitionrange:{[timecolumn;primarytimecolumn;partitionfield;hdbtimerange]@[partitionfield$hdbtimerange;1;+;not timecolumn~primarytimecolumn]};
