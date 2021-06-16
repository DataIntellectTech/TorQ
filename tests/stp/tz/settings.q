// IPC connection parameters
.servers.CONNECTIONS:`segmentedtickerplant;
.servers.USERPASS:`admin:admin;

// Test STP log directory
testlogdb:"testlog";

// Test trade update
testtrade:((5#`GOOG),5?`4;10?100.0;10?100i;10#0b;10?.Q.A;10?.Q.A;10#`buy);

// Re-initialise the eodtime namespace
eodinit:{
  // Default offset
  off:0D00;
  
  // If adding a synthetic TZ, set roll time to 2 seconds from now +- any rolloffsets
  if[x in `custom`customoffsetplus`customoffsetminus;
    dt:"p"$0;doff:"n"$0;
    adj:("p"$1+.z.d) - .z.p + 00:00:02 + off:(`custom`customoffsetplus`customoffsetminus!(0D00;0D02;-0D02))[x];
    `.tz.t upsert (x;dt;adj;doff;adj;dt);
    .stplg.nextendUTC:"p"$0
    ];
  
  // Re-init eodtime
  .eodtime.datatimezone:x;
  .eodtime.rolltimezone:x;
  .eodtime.rolltimeoffset:neg off;
  .eodtime.dailyadj:.eodtime.getdailyadjustment[];
  .eodtime.d:.eodtime.getday[.z.p];
  .eodtime.nextroll:.eodtime.getroll[.z.p];
  };

eodchange:{
  // change eod, no custom tz
  .eodtime.datatimezone:`GMT;
  .eodtime.rolltimezone:`GMT;
  // eod set to 2 seconds after stp init
  .eodtime.rolltimeoffset:.z.p+00:00:02-"p"$.z.d+1;
  .eodtime.dailyadj:.eodtime.getdailyadjustment[];
  .eodtime.d:.eodtime.getday[.z.p];
  .eodtime.nextroll:.eodtime.getroll[.z.p];
  };

// Local trade table schema and UPD function
trade:flip `time`sym`price`size`stop`cond`ex`side!"PSFIBCCS" $\: ();
upd:{[t;x] t insert x};
