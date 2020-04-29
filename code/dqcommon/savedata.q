\d .dqe
savedata:{[dir;pt;savetemp;ns;tabname]
  .lg.o[`dqe;"Saving ",(string tabname)," data to ",.os.pth dir];
  pth:` sv .Q.par[dir;pt;tabname],`;
  err:{[e].lg.e[`savedata;"Failed to save dqe data to disk : ",e];'e};
  tab:.Q.dd[ns;tabname];
  .[upsert;(pth;.Q.en[dir;r:0!.save.manipulate[tabname;select from tab where i in savetemp]]);err];
  .lg.o[`savedata;"number of rows that will be saved down: ", string count savetemp];
  tbl:` sv ns,tabname;
  .dqe.tosavedown[tbl]:.dqe.tosavedown[tbl] except savetemp;
  };

cleartables:{[ns;tabname]
  /- empty the table from memory
  .lg.o[`cleartables;"deleting ",(string tabname)," data from in-memory table"];
  @[ns;tabname;0#];
  };

endofday:{[dir;pt;tabs;ns;savetemp]
  .lg.o[`eod;"end of day message received - ",string pt];
  savedata[dir;pt;savetemp;ns]each tabs;
  cleartables[ns]each tabs;
  .lg.o[`eod;"end of day is now complete"];
  };

/- function to reload an hdb
notifyhdb:{[dir;h]
  .lg.o[`dqc;"notifying the hdb to reload"];
  /- if you can connect to the hdb - call the reload function
  @[h;"system \"l ",dir,"\"";{.lg.e[`notifyhdb;"failed to send reload message to hdb on handle: ",x]}];
  };
