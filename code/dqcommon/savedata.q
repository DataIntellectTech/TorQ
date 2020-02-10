\d .dqe
savedata:{[dir;pt;ns;tabname]
  .lg.o[`dqe;"Saving ",(string tabname)," data to ",.os.pth dir];
  pth:` sv .Q.par[dir;pt;tabname],`;
  err:{[e].lg.e[`savedata;"Failed to save dqe data to disk : ",e];'e};
  .[upsert;(pth;.Q.en[dir;r:0!.save.manipulate[tabname;ns tabname]]);err];
  .lg.o[`delete;"deleting ",(string tabname)," data from in-memory table"];                                      /- empty the table from memory
  @[ns;tabname;0#];
  };

endofday:{[dir;pt;tabs;ns]
  .lg.o[`eod;"end of day message received - ",string pt];
  savedata[dir;pt;ns]each tabs;
  .lg.o[`eod;"end of day is now complete"];
  };
