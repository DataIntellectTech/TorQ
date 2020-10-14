.dataccess.checkinputs:{[dict]
  if[not .dataccess.isdictionary dict;'`$"Input parameter must be a dictionary"];
  if[not .dataccess.checkkeytype dict;'`$"keys must be of type symbol"];
  if[not .dataccess.checkrequiredparams dict;'`$"required params missing:",.Q.s .dataaccessutils.getrequiredparams[]except key dict];
  if[not .dataccess.checkparamnames dict;'`$"invalid param names:",.Q.s key[dict]except .dataaccessutils.getvalidparams[]];
 };

.dataccess.isdictionary:{[dict]99h~type dict};
.dataccess.checkkeytype:{[dict]11h~type key dict};
.dataccess.checkrequiredparams:{[dict]all .dataaccessutils.getrequiredparams[]in key dict};
.dataccess.checkparamnames:{[dict]all key[dict]in .dataaccessutils.getvalidparams[]};


.dataaccess.gettimecolumntype:{[]};
.dataaccess.issymbol:{[]};
.dataaccess.allsymbols:{[]};
.dataaccess.checkaggregations:{[]};
.dataaccess.checktimebar:{[]};
.dataaccess.checkfilterformat:{[]};
.dataaccess.isstring:{[]};
