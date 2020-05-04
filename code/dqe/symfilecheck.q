\d .dqe
/- should be run on hdb process - function returns a dictionary of count of syms
/- in sym file
symfilecheck:{[filename]
  .lg.o[`test;"Counting number of symbols in the symbol file each day"];
  (enlist `symfilecount)!enlist count get filename
  }
