\d .dqe
tablecount:{[tab;operator;chkvalue]
  d:(>;=;<)!("greater than";"equal to";"less than");
  statement:d[operator]," ",(string chkvalue),". It's count is ",string count value tab;
  $[.[operator;(count value tab;chkvalue)];
    (1b;"The count of ",(string tab), " is ",statement);
    (0b;"The count of ",(string tab), " is not ",statement)]
  }

tablehasrecords:.dqe.tablecount[;>;0];
