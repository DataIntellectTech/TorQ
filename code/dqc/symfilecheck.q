\d .dqc
hdbdir:@[value;`hdbdir;`hdb]
symfilecheck:{[directory;filename]                     // if sym file exists
  (c;"sym file named ",(string filename)," ",$[c:.os.Fex .Q.dd[directory]filename;"exists";"doesn't exist"])
  }
