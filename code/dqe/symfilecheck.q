\d .dqe
hdbdir:@[value;`hdbdir;`hdb]
symfilecheck:{[filename]                     // if sym file exists
  fullpath:.Q.dd[hdbdir]filename;
  $[not ()~key hsym fullpath;
    (1b;string filename," exists");
    (0b;string filename," doesn't exist")];
  }
