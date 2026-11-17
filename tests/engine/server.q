// server for the engine tests: started by run.sh with the same engine as the test process
// .z.pg answers "defer" through -30! (deferred response); upd counts rows; .srv.set is called by -25! broadcasts
.srv.cnt:0; .srv.b:0b; .srv.w:0Ni;
.srv.set:{[x] .srv.b:x};
upd:{[t;x] .srv.cnt:.srv.cnt+count x};
.z.pg:{[x] $[x~"defer";[.srv.w:.z.w;-30!(::)];value x]};
.z.ts:{[x] if[not null .srv.w; -30!(.srv.w;0b;`deferredok); .srv.w:0Ni]};
system "t 10";
