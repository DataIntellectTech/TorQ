\d .stpps

// Function to map the where clause from config table extracted by .stpps.segmentfilter function to tablename
// Allows use of ` as argument for tables


filtermap:{[tabs;segid] $[tabs~`;[tabs:.stpps.t; (tabs)!.stpps.segmentfilter\:[tabs;segid]]; (enlist tabs)!(enlist .stpps.segmentfilter\:[tabs;segid])]}

\d . 

