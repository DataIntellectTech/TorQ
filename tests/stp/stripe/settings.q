// IPC connection parameters
.servers.CONNECTIONS:`rdb`segmentedtickerplant;
.servers.USERPASS:`admin:admin;

// Test trade batches
syms:`${x,raze x,/:\: .Q.A}/[1;raze(raze .Q.A ,/:\: .Q.A),/:\: .Q.A];
ls:raze(ls2:til 500)+/:0.01*til 101;
src:`BARX`GETGO`SUN`DB;

q:{[syms;len;ls;ls2;src] len?/:(syms;ls;ls;ls2;ls2;" 89ABCEGJKLNOPRTWZ";"NO";src)}[syms;;ls;ls2;src];
t:{[syms;len;ls;ls2;src] len?/:(syms;ls;`int$ls2;01b;" 89ABCEGJKLNOPRTWZ";"NO";`buy`sell)}[syms;;ls;ls2;src];
// For performance testing
qu:{[syms;len;uniq;ls;ls2;src] len?/:(neg[uniq]?syms;ls;ls;ls2;ls2;" 89ABCEGJKLNOPRTWZ";"NO";src)}[syms;;;ls;ls2;src];
tu:{[syms;len;uniq;ls;ls2;src] len?/:(neg[uniq]?syms;ls;`int$ls2;01b;" 89ABCEGJKLNOPRTWZ";"NO";`buy`sell)}[syms;;;ls;ls2;src];

// Local trade table schema
trade:flip `time`sym`price`size`stop`cond`ex`side!"PSFIBCCS" $\: ();
quote:flip `time`sym`bid`ask`bsize`asize`mode`ex`src!"PSFFJJCCS" $\: ();

// Get the number of rdb processes from process.csv
numseg:sum `rdb=((.proc`readprocs).proc`file)`proctype;
skey:til numseg;
// Get the splits to each rdb
splits:numseg#1%numseg;

// Local upd and error log function
upd:{[t;x] t insert x};
upderr:{[t;x].tst.err:x};

// Test db name
testlogdb:"testlog";