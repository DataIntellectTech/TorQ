\d .dataaccessutils

//- utils for reading in config
readtableproperties:{[path] readcsv[path;"sssss"]};
readdataaccess:{[path] readcsv[path;"sbs*"]};

readcsv:{[path;types]
  if[not pathexists path:hsym path;'path];
  :(types;1#",")0:path;
 };

pathexists:{[path] path~key path};



//- misc utils
getvalidparams:{[].dataaccess.dataaccessconfig`parameter};
getrequiredparams:{[]exec parameter from .dataaccess.dataaccessconfig where required};
