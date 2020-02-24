\d .dqc
tablecount:{[tab;operator;chkvalue]                                                                             /- compare the count of a table to a chosen value
  d:(>;=;<)!("greater than";"equal to";"less than");
  statement:d[operator]," ",(string chkvalue),". Its count is ",string count value tab;
  c:operator .(count value tab;chkvalue);
  (c;"The count of ",(string tab)," is ",$[c;"";"not "],statement)
  }

tablehasrecords:.dqc.tablecount[;>;0];                                                                          /- check if the count of the table is greater than zero

tablecountcomp:{[tab]
  count value tab
  }
