\d .dqc
dfilechk:{[tname]                                                                                               /- function to check .d file. Sample use: .dqc.dfilechk[`trade]
  if[not `PV in key`.Q;
    :(0b;"The directory is not partitioned")];
  if[2>count .Q.PV;
    :(1b;"There is only one partition, therefore there are no two .d files to compare")];
  u:` sv'.Q.par'[`:.;-2#.Q.PV;tname],'`.d;
  $[0=sum {()~key x} each u;
    [((~). get each u;"Checking if two latest .d files match")];
    [(0b;"Two partitions are available but there are no two .d files for the given table to compare")]]
  }
