\d .stpps

// Function to extract where clause from config table
segmentfilter:{[tbl;segid] string first .stpps.segmentfiltermap[exec wcRef from .stpps.segmentconfig where table=tbl , segmentID=segid]};

// Function to subscribe to particular segment using segmentID based on .u.sub
subsegment:{[tbl;segid];
//tablename and segmentid used to get filters
//filteroutput needs to be tested  
  if[tbl~`;:.z.s[;segid] each .stpps.t]; 
   if[not tbl in .stpps.t;
     .lg.e[`sub;m:"Table ",string[tbl]," not in list of stp pub/sub tables"];
     :(tbl;m)
  ];
  $[segid~`;[filter:`]; [filter: segmentfilter[tbl;segid]]];
  $[filter~`;.stpps.suball[tbl]; .ps.subtablefiltered[string[tbl];filter;""]]
 };

\d .
