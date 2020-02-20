\d .dqe
hdbdir:@[value;`hdbdir;`:hdb]
symfilecheck:{[directory;filename]                             // - function returns a dictionary of count of syms in sym file
  .lg.o[`test;"Counting number of symbols in the symbol file each day"];
  (enlist `symfilecount)!(enlist count get .Q.dd[directory]filename)
  }
