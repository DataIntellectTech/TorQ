\d .dqe
savedata:{[dir;pt;tabname]                                                                                       /- function to save data persistently
  .lg.o[`dqe;"Saving ",(string tabname)," data to ",.os.pth dir];
  pth:` sv .Q.par[dir;pt;tabname],`;
  err:{[e].lg.e[`savedata;"Failed to save dqe data to disk : ",e];'e};
  .[upsert;(pth;.Q.en[dir;r:0!.save.manipulate[tabname;`. tabname]]);err];
  .lg.o[`delete;"deleting ",(string tabname)," data from in-memory table"];                                      /- empty the table from memory
  @[`.;tabname;0#];
  };

endofday:{[pt]
  .lg.o[`eod;"end of day message received - ",string pt];
  savedata[.dqe.dqedbdir;pt]each `.dqe.results`.dqe.configtable;
  .lg.o[`eod;"end of day is now complete"];
  };
