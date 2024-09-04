stpHandle:gethandle[`stp1]
wdbHandle:gethandle[`wdb1]
testtrade:((5#`GOOG),5?`4;10?100.0;10?100i;10#0b;10?.Q.A;10?.Q.A;10#`buy)
testquote:(10?`4;(5?50.0),50+5?50.0;10?100.0;10?100i;10?100i;10?.Q.A;10?.Q.A;10#`3)
stpHandle @/: `.u.upd ,/: ((`trade;testtrade);(`quote;testquote))
wdbHandle(`.u.end;`.wdb.currentpartition)
exit 0