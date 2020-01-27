\d .dqe
hdbdir:@[value;`hdbdir;`hdb]
symfilecheck:{[directory;filename]                     // if sym file exists
  $[.os.Fex .Q.dd[directory]filename;
    (1b;string filename," exists");
    (0b;string filename," doesn't exist")]
  }
