\d .dqe
/ - function to backfill dqedb data with older data from hdb
backfill:{[dqetab;funct;vars;proc;dateof;dir]
  / - empty the table from memory first
  .dqe.cleartables[`.dqe;dqetab];
  / - funct represents the dqe query that you would like to perform on the older data from an old date(dateof)
  .dqe.runquery[funct;(vars;dateof);`table;proc];
  .dqe.savedata[dir;dateof;.dqe.tosavedown[.Q.dd[`.dqe;dqetab]];`.dqe;dqetab];
  .dqe.cleartables[`.dqe;dqetab];
  }
