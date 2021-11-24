// IPC connection parameters
.servers.CONNECTIONS:`rdb`segmentedtickerplant;
.servers.USERPASS:`admin:admin;

// Test trade batches
syms:`${x,raze x,/:\: .Q.A}/[1;raze(raze .Q.A ,/:\: .Q.A),/:\: .Q.A];
ls:raze(ls2:til 500)+/:0.01*til 101;
src:`BARX`GETGO`SUN`DB;

q:{[syms;len;ls;ls2;src] len?/:(syms;ls;ls;ls2;ls2;" 89ABCEGJKLNOPRTWZ";"NO";src)}[syms;;ls;ls2;src];
t:{[syms;len;ls;ls2;src] len?/:(syms;ls;`int$ls2;01b;" 89ABCEGJKLNOPRTWZ";"NO";`buy`sell)}[syms;;ls;ls2;src];

// Local trade table schema
trade:flip `time`sym`price`size`stop`cond`ex`side!"PSFIBCCS" $\: ();
quote:flip `time`sym`bid`ask`bsize`asize`mode`ex`src!"PSFFJJCCS" $\: ();

// Striping function
lookup:{[numSeg;maxProc]
    hexDg:lower .Q.nA til maxProc;
    seg:til numSeg;
    hexDg!maxProc#til numSeg
    }[;16];
modMd5:{first each string first each md5'[string x]};
map:{[modMd5;lookup;numSeg;sym] sym@/:group lookup[numSeg]modMd5 sym}[modMd5;lookup];
stripe:{[map;numSeg;input]
    $[numSeg within(1;16);;'"Max number of processes is 16"];
    sym:distinct input;
    $[`subReq in key`.;
        [$[numSeg=1+max key subReq;;`subReq set ()!()];
        $[any new:not sym in raze value subReq;
            `subReq set subReq,'map[numSeg;sym where new];
            ];];
        `subReq set map[numSeg;sym]
        ];}[map];
// Get the number of rdb processes from process.csv
numSeg:sum `rdb=((.proc`readprocs).proc`file)`proctype;
skey:til numSeg;
// Initialize subscription request for all syms to test striping function in stp
stripe[numSeg;syms];
// Get the splits to each rdb
splits:ce%sum ce:value count each group value lookup[numSeg];

// Local upd and error log function
upd:{[t;x] t insert x};
upderr:{[t;x].tst.err:x};

// Test db name
testlogdb:"testlog";