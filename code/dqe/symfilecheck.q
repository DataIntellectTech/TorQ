\d .dqe
hdbdir:@[value;`hdbdir;`hdb]
symfilecheck:{[directory;filename]                     // if sym file exists
  fullpath:.Q.dd[directory]filename;
  $[not ()~key hsym fullpath;
    (1b;string filename," exists");
    (0b;string filename," doesn't exist")];
  }
