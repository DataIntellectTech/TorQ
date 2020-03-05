\d .dqc
datechk:{[dirname]                                                                                              /- function to check date vector contains latest date in an hdb
  system"l ",dirname;
  if[not `PV in key`.Q;
    .lg.o[`datechk;"The directory is not partitioned"]; :0b];
  if[not `date in .Q.pf;
    .lg.o[`datechk;"date is not a partition field value"]; :0b];
  k:.z.d mod 7;
  last date=.z.d-1+k*(k:.z.d mod 7)in 1 2
  }
