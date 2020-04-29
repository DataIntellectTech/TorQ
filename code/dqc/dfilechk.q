\d .dqc

/- function to check .d file. Sample use: .dqc.dfilechk[`trade]
dfilechk:{[tname]
  .lg.o[`dfilechk;"Checking if two latest .d files match"];
  if[not `PV in key`.Q;
    .lg.o[`dfilechk;"The directory is not partitioned"];
    :(0b;"The directory is not partitioned")];
  if[2>count .Q.PV;
    .lg.o[`dfilechk;"There is only one partition"];
    :(1b;"There is only one partition, therefore there are no two .d files to compare")];
  u:` sv'.Q.par'[`:.;-2#.Q.PV;tname],'`.d;
  /- check all .d files exist
  $[all .os.Fex each u;
    (c;"Two latest .d files ",$[c:(~). get each u;"";"do not "],"match");
    (0b;"Two partitions are available but there are no two .d files for the given table to compare")]
  }
