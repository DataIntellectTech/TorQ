\d .dqe

bucketcount:{[agg;tn]
  (enlist tn)!"j"$value agg select rowcount:count i by 60 xbar time.minute from ?[tn;enlist(=;.Q.pf;last .Q.PV);1b;()]
  }

/- Given a table name as a symbol (tn), return the avg number of messages recieved each hour throughout the day
/- Works on partitioned tables in an hdb
avgbucketcount:{[tn]
  .lg.o[`avgbucketcount;"Getting average hourly count of rows in",string tn];
  bucketcount[avg;tn]
  }

/- Given a table name as a symbol (tn), return the max number of messages recieved each hour throughout the day
/- Works on partitioned tables in an hdb
maxbucketcount:{[tn]
  .lg.o[`maxbucketcount;"Getting maximum hourly count of rows in",string tn];
  bucketcount[max;tn]
  }

/- Given a table name as a symbol (tn), return the min number of messages recieved each hour throughout the day
/- Works on partitioned tables in an hdb
minbucketcount:{[tn]
  .lg.o[`minbucketcount;"Getting minimum hourly count of rows in",string tn];
  bucketcount[min;tn]
  }
