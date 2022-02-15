

\d .stpps
// Function to subscribe to particular segment using segmentID based on .u.sub
subsegment:{[tbl;segmentid]
//tablename and segmentid used to get filters
//filteroutput needs to be tested  
  $[segmentid~`;filter:`; filter: filteroutput[tbl;segmentid]];
  if[tbl~`;:.z.s[;filter] each .stpps.t];
  if[not tbl in .stpps.t;
    .lg.e[`sub;m:"Table ",string[tbl]," not in list of stp pub/sub tables"];
    :(tbl;m)
  ];
  $[filter~`;.stpps.suball[tbl];.ps.subtablefiltered[string[tbl];filter;""]]
 };

\d .
