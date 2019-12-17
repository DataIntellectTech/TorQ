\d .dqe
chkslowsub:{[threshold]                                                                                         /- function to check for slow subscribers
  .lg.o[`dqe;"Checking for slow subscribers"];
  overlimit:(key .z.W) where threshold<sum each value .z.W;
  $[0=count overlimit;
    (1b;"no data queues over the limit, in ",string .proc.procname;overlimit);
    (0b;raze"handle(s) ",("," sv string overlimit)," have queues";overlimit)]
  }
