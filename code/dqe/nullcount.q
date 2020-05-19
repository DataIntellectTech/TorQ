\d .dqe
nullcount:{[tab]
  .lg.o[`nullcount;"Getting count of nulls"];
  (enlist tab)!enlist sum value ({sum$[0h=type x;0=count@'x;null x]}each flip tab)
  }
