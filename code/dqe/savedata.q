\d .dqe
savedata:{[dir;pt;tabname]                                                                                       /- function to save data persistently
  .lg.o[`dqe;"Saving ",(string tabname)," data to ", string dir];
  .[
    upsert;
    (` sv .Q.par[dir;pt;tabname],`;.Q.en[dir;r:0!.save.manipulate[tabname;`. tabname]]);                         /- upsert data to partition
    {[e] .lg.e[`savedata;"Failed to save dqe data to disk : ",e];`e}
  ];
  .lg.o[`delete;"deleting ",(string tabname)," data from in-memory table"];                                      /- empty the table from memory
  @[`.;tabname;0#];
  }
