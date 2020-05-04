\d .dqc
hdbdir:@[value;`hdbdir;`hdb]

/- check that the sym file exists
symfilecheck:{[directory;filename]
  .lg.o[`dqc;"checking ",(1_string[filename])," exists in ",(1_string[directory])];
  (c;"sym file named ",(string filename)," ",$[c:.os.Fex .Q.dd[directory]filename;"exists";"doesn't exist"])
  }
