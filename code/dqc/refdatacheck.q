\d .dqc

/- Check whether the referenced column of a table is in another column of
/- another table. Takes four symbols as input, the table names and the columns
/- to check.
refdatacheck:{[tablea;tableb;cola;colb]
  .lg.o[`refdatacheck;"checking whether reference data is covered in the other column"];
  msg:$[c:all r:tablea[cola]in tableb colb;
    "All data from ",(string cola)," of ",(string tablea),"exists in ",(string colb)," of ",string tableb;
    "The following data did not exist in ",(string colb)," of ",(string tableb),": ","," sv string tablea[cola]where not r];
  .lg.o[`refdatacheck;"refdatacheck completed; All data from ",(string cola),$[c;"did";"did not"]," exist in ",string colb];
  (c;msg)
  }
