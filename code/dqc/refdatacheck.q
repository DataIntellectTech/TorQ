\d .dqc

/- Check whether the referenced column of a table is in another column of another table
refdatacheck:{[tablea;tableb;cola;colb]
  .lg.o[`dqe;"checking whether refrence date is covered in the other column"];
  $[all tablea[cola] in tableb[colb];
    (1b;"All data from ",(string cola)," of ",(string tablea), "exists in ",(string colb), " of ",string tableb);
    (0b;"The following data did not exist in",(string colb), " of ",(string tableb),": ",string tablea[cola][where not (tablea[cola] in tableb[colb])])
]
}
