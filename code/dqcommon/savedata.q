\d .dqe
savedata:{[dir;pt;icounts;ns;tabname]
  .lg.o[`dqe;"Saving ",(string tabname)," data to ",.os.pth dir];
  pth:` sv .Q.par[dir;pt;tabname],`;
  err:{[e].lg.e[`savedata;"Failed to save dqe data to disk : ",e];'e};
  tab:.Q.dd[ns;tabname];
  .[upsert;(pth;.Q.en[dir;r:0!.save.manipulate[tabname;select from tab where (i within(icounts;count value tab))&(chkstatus<>`Started)]]);err];
  .dqe.icounts:count select from  tab where chkstatus<>`Started;
  };

cleartables:{[ns;tabname]
  .lg.o[`cleartables;"deleting ",(string tabname)," data from in-memory table"];                                /- empty the table from memory
  @[ns;tabname;0#];
  };

endofday:{[dir;pt;tabs;ns;icounts]
  .lg.o[`eod;"end of day message received - ",string pt];
  savedata[dir;pt;icounts;ns]each tabs;
  cleartables[ns]each tabs;
  .lg.o[`eod;"end of day is now complete"];
  };

notifyhdb:{[dir;h]                                                                                              /-function to reload an hdb
  @[h;"system \"l ",dir,"\"";{.lg.e[`notifyhdb;"failed to send reload message to hdb on handle: ",x]}];         /-if you can connect to the hdb - call the reload function
  };
