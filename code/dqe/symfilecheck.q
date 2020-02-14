\d .dqe
hdbdir:@[value;`hdbdir;`hdb]
symfilecheck:{[directory;filename]
  .lg.o[`test;"Counting number of symbols in the symbol file each day"];
  count get .Q.dd[directory]filename
  }
