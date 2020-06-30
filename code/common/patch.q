\d .patch

// location to read functionversion table from
versiontab:@[value;`.patch.versiontab;hsym`$getenv[`KDBAPPCONFIG],"/functionversion"]

// load the version table
getversiontab:{
 if[null x; 
  .lg.o[`patcher;"functionversion table set to null- not loading"];
  :()];
 if[0=count key x:hsym x;
  .lg.o[`patcher;"functionversion table not found at ",string x];
  :()];
 @[get;x;()]
 }

// this is the function used to set the new definition in the remote process
setdef:{[func;def]
 prevval:@[value;func;{(::)}];
 .lg.o[`patch;"patching ",string[func]," to be ",.Q.s1 def];
 .[set;(func;def);{.lg.e[`patch;"failed to apply patch: ",x]}];
 prevval}

// apply all the patches from the file
applyallpatches:{
 if[count p:getversiontab[versiontab];
  p:select last newversion by function from p where procname=.proc.procname]; 
 if[not count p; .lg.o[`patch;"no patches found to be applied"]; :()];
 setdef'[exec function from p;exec newversion from p];
 }

// make the patching run on start up
.proc.addinitlist(`.patch.applyallpatches;`)
