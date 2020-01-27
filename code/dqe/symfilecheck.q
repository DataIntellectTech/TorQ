\d .dqe
hdbdir:@[value;`hdbdir;`hdb]
symfilecheck:{[directory;filename]                     // if sym file exists
  (c;"sym file named ",(","sv string(), filename)," ",$[c:.os.Fex .Q.dd[directory]filename;"exists";"doesn't exists"])
//  $[.os.Fex .Q.dd[directory]filename;
//   (1b;string filename," exists");
//    (0b;string filename," doesn't exist")]
  }
