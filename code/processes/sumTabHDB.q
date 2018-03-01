opts:.Q.def[`host`port`username`password!(`localhost;`9802;`admin;`admin)].Q.opt .z.x

tphandle:hsym `$ ":" sv (string each value opts)

h:@[hopen;(tphandle;2000);0]

if[not h;-2"Cannot create connection to HDB on host: ",.z.x[0]," ,port: ",.z.x[1];-1"";exit 1]

sumt:h({select totalVol:sum size,no.ofTrades:count i by sym from x where date=.z.d-1};`trade)

sumq:h({select time,sym,bid,ask from x where date=.z.d-1};`quote)
sumq:select avgSpread:avg spread,TWAS:dur wavg spread by sym from update dur:(exec last time from sumq)^next[time]-time,spread:ask-bid by sym from sumq

sumtab:sumt lj sumq
