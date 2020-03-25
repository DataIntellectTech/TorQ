\d .dqc
datechk:{[]                                                                                                     /- function to check date vector contains latest date in an hdb
  if[not `PV in key`.Q;
    :(0b;"The directory is not partitioned")];
  if[not `date in .Q.pf;
    :(0b;"date is not a partition field value")];
  ((last .Q.pv)=.z.d-1+k*(k:.z.d mod 7)in 1 2;"Checking if latest date match")
  }
