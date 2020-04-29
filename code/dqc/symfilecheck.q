\d .dqc
hdbdir:@[value;`hdbdir;`hdb]

/- check that the sym file exists
symfilecheck:{[directory;filename]
  (c;"sym file named ",(string filename)," ",$[c:.os.Fex .Q.dd[directory]filename;"exists";"doesn't exist"])
  }
