\d .dqc

/- function to check that date vector contains latest date in an hdb
datechk:{[]
  .lg.o[`datechk;"Checking if latest date in hdb is corect"]; 
  if[not `PV in key`.Q;
    .lg.o[`datechk;"The directory is not partitioned"];
    :(0b;"The directory is not partitioned")];
  if[not `date in .Q.pf;
    .lg.o[`datechk;"date is not a partition field value"];
    :(0b;"date is not a partition field value")];
  c:(last .Q.pv)=.z.d-1+k*(k:.z.d mod 7)in 0 1;
  (c;"Latest date in hdb is ", $[c;"correct";"not correct"])
  }
