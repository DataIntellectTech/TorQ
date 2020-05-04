\d .dqc

/- compare the count of a table to a chosen value
tablecount:{[tab;operator;chkvalue]
  .lg.o["checking count of ",string[tab]," is ",string[operator]," ",string[chkvalue]];
  d:(>;=;<)!("greater than";"equal to";"less than");
  statement:d[operator]," ",(string chkvalue),". Its count is ",string count value tab;
  c:operator .(count value tab;chkvalue);
  (c;"The count of ",(string tab)," is ",$[c;"";"not "],statement)
  }


/- check if the count of the table is greater than zero
tablehasrecords:.dqc.tablecount[;>;0];

/- count the number of rows in a table
tablecountcomp:{[tab]
  count value tab
  }
