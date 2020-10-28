//- common script to enable remote data access via generic function
//- loads in scripts from code/common/dataaccess

\d .dataaccess

isenabled:{[]"B"$first first .proc.params`dataaccess};
enabled:@[isenabled;`;0n];

init:{
  .lg.o[`.dataaccess.init;"running .dataaccess.init[]"];
  additionalscripts:getenv[`KDBCODE],"/dataaccess";                                         //- load all q scripts in this path
  .proc.loaddir additionalscripts;
  .servers.startup[];
  .dataaccess.tablepropertiesconfig:readtableproperties[];
  .dataaccess.checkinputsconfig:readcheckinputs[];
  .lg.o[`.dataaccess.init;"running .dataaccess.init[] - finished"];
 };

\d .

if[.dataaccess.enabled;.dataaccess.init[]];
