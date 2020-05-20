\d .dqe

/- Given a table name as a symbol (tn), returns the number of nulls in tn.
nullcount:{[tn]
  .lg.o[`nullcount;"Getting count of nulls in ",string tn];
  (enlist tn)!enlist sum value{sum$[0h=type x;0=count each x;null x]}each flip get tn
  }
