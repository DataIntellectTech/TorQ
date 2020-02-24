\d .dqc
dfilechk:{[tname;dirname]                                                                                       /- function to check .d file. Sample use: .dqe.dfilechk[`trade;getenv `KDBHDB]
  system"l ",dirname;
  if[not `PV in key`.Q;
    .lg.o[`dfilechk;"The directory is not partitioned"]; :0b];
  if[2>count .Q.PV;
    .lg.o[`dfilechk;"There is only one partition, therefore there are no two .d files to compare"]; :1b];
  u:` sv'.Q.par'[`:.;-2#.Q.PV;tname],'`.d;
  $[0=sum {()~key x} each u;
    [.lg.o[`dfilechk;"Checking if two latest .d files match"]; (~). get each u];
    [.lg.o[`dfilechk;"Two partitions are available but there are no two .d files for the given table to compare"]; 0b]]
  }
