t1:([]sym:`a`b`a; exch:`nyse`nyse`cme;price:1 2 3)
t2:([sym:`a`b`a] exch:`nyse`nyse`cme;price:1 2 3)
k:`sym`exch
b1:([]base:`buy`sell`buy`sell)
b2:([]base:`buy`sell`sell`buy;base2:100 200 300 400)

intdic:`intervals.start`intervals.end`intervals.interval!(09:00;12:00;01:00)
intdic2:`intervals.start`intervals.end`intervals.interval!(00:00.000;04:00.000;00:30.000)

dic1:`table`keycols!(t1;k)
dic2:`table`keycols`timeseries`fullexpansion!(t1;k;intdic;1b)
dic3:`table`keycols`timeseries`fullexpansion!(t1;k;intdic;0b)
dic4:`table`keycols`timeseries`base`fullexpansion!(t1;k;intdic2;b1;1b)
dic5:`table`keycols`timeseries`base`fullexpansion!(t2;k;intdic2;b1;1b)
dic6:`table`keycols`timeseries`base`fullexpansion!(t2;k;intdic2;b2;1b)
