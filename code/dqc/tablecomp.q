/- only meant to be used for comparison - not sure if i should create a new function
/- also might need to modify the comparison code
tablecomp:{[tab]
  .lg.o["checking whether two tables from two processes have the same count"];
  (1b;("table count of ",(string tab)," is ",count tab);count tab)
  }
