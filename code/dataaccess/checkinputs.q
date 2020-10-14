\d .checkinputs

checkinputs:{[dict]
  if[not isdictionary dict;'`$"Input parameter must be a dictionary"];
  if[not checkkeytype dict;'`$"keys must be of type symbol"];
  if[not checkrequiredparams dict;'`$"required params missing:",.Q.s .dataaccessutils.getrequiredparams[]except key dict];
  if[not checkparamnames dict;'`$"invalid param names:",.Q.s key[dict]except .dataaccessutils.getvalidparams[]];
 };

isdictionary:{[dict]99h~type dict};
checkkeytype:{[dict]11h~type key dict};
checkrequiredparams:{[dict]all .dataaccessutils.getrequiredparams[]in key dict};
checkparamnames:{[dict]all key[dict]in .dataaccessutils.getvalidparams[]};


gettimecolumntype:{[]};
issymbol:{[]};
allsymbols:{[]};
checkaggregations:{[]};
checktimebar:{[]};
checkfilterformat:{[]};
isstring:{[]};
