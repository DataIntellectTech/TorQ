\d .dqe

/- Given a table name as a symbol (tn), and a inbuilt aggregate function in kdb (agg), return the number of messages reieved each hour throughout the day after applying the aggregate function
bucketcount:{[agg;tn]
  .lg.o[.Q.dd[`$string agg;`bucketcount];"Getting ",(string agg)," hourly count of rows in ",string tn];
  (enlist tn)!"j"$value agg select rowcount:count i by 60 xbar time.minute from ?[tn;enlist(=;.Q.pf;last .Q.PV);1b;()]
  }

/- Given a table name as a symbol (tn), return the average number of messages received throughout the day based on hourly counts
/- Works on partitioned tables in an hdb
avgbucketcount:bucketcount[avg;]

/- Given a table name as a symbol (tn), return the maximum number of messages received throughout the day based on hourly counts
maxbucketcount:bucketcount[max;]

/- Given a table name as a symbol (tn), return the minimum number of messages received throughout the day based on hourly counts
/- Works on partitioned tables in an hdb
minbucketcount:bucketcount[min;]

