.rdb.rdbpartition: enlist 2000.01.06;
// rdbstandard.q advertises the partition with .rdb.getpartition (defined in processes/rdb.q, which this mock RDB does not load)
.rdb.getpartition:{[] .rdb.rdbpartition};
