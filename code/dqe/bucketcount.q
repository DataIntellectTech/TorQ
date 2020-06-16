\d .dqe

bucketcount:{[agg;tn]
  (enlist tn)!"j"$value agg select rowcount:count i by 60 xbar time.minute from ?[tn;enlist(=;.Q.pf;last .Q.PV);1b;()]
  }

/- Given a table name as a symbol (tn), return the avg number of messages recieved each hour throughout the day
/- Works on partitioned tables in an hdb
avgbucketcount:bucketcount[avg;]

/- Given a table name as a symbol (tn), return the max number of messages recieved each hour throughout the day
/- Works on partitioned tables in an hdb
maxbucketcount:bucketcount[max;]

/- Given a table name as a symbol (tn), return the min number of messages recieved each hour throughout the day
/- Works on partitioned tables in an hdb
minbucketcount:bucketcount[min;]

